# Unified Godot runner for local checks, tests, and web export.
param(
    [ValidateSet("parse", "boot", "test", "all", "install-web-templates", "check-web-compile-env", "export-web", "serve-web")]
    [string]$Command = "all",

    [string]$GodotExe = "",

    [string]$Test = "",

    [int]$Port = 8060
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectRoot {
    $dir = Split-Path -Parent $PSScriptRoot
    if (-not (Test-Path (Join-Path $dir "project.godot"))) {
        throw "Could not locate project.godot from $PSScriptRoot"
    }
    return $dir
}

function Resolve-GodotExe {
    param([string]$Requested)

    $candidates = @()
    if ($Requested) {
        $candidates += $Requested
    }
    if ($env:GODOT_EXE) {
        $candidates += $env:GODOT_EXE
    }
    $candidates += "C:\Users\roelv\Downloads\Godot_v4.6.1-stable_win64.exe"
    $pathCommand = Get-Command godot -ErrorAction SilentlyContinue
    if ($pathCommand) {
        $candidates += $pathCommand.Source
    }

    foreach ($candidate in $candidates) {
        if (-not $candidate) {
            continue
        }
        if (Test-Path $candidate -PathType Container) {
            $consoleExe = Get-ChildItem $candidate -Filter "*console.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($consoleExe) {
                return $consoleExe.FullName
            }
            $regularExe = Get-ChildItem $candidate -Filter "*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($regularExe) {
                return $regularExe.FullName
            }
        }
        if (Test-Path $candidate -PathType Leaf) {
            return (Resolve-Path $candidate).Path
        }
    }

    throw "Godot not found. Pass -GodotExe or set GODOT_EXE."
}

function Invoke-Godot {
    param(
        [string]$Exe,
        [string[]]$Arguments
    )

    Write-Host "godot $($Arguments -join ' ')" -ForegroundColor DarkCyan
    $output = & $Exe @Arguments 2>&1
    $output | ForEach-Object { Write-Host $_ }
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) {
        $exitCode = 0
    }
    $errorLines = @($output | Where-Object { $_ -match "(^|\s)(ERROR|SCRIPT ERROR|Parse Error):" })
    if ($errorLines.Count -gt 0) {
        throw "Godot reported $($errorLines.Count) error line(s)."
    }
    if ($exitCode -ne 0) {
        throw "Godot command failed with exit code $exitCode."
    }
}

function Invoke-ParseCheck {
    param([string]$Exe, [string]$Root)
    Invoke-Godot $Exe @("--headless", "--audio-driver", "Dummy", "--path", $Root, "--quit")
}

function Invoke-BootCheck {
    param([string]$Exe, [string]$Root)
    Invoke-Godot $Exe @("--headless", "--audio-driver", "Dummy", "--path", $Root, "-s", "res://tests/headless_boot.gd")
}

function Invoke-GutTests {
    param([string]$Exe, [string]$Root, [string]$TestPath)

    $args = @(
        "--headless",
        "--audio-driver",
        "Dummy",
        "--path",
        $Root,
        "-s",
        "addons/gut/gut_cmdln.gd",
        "--",
        "-gexit"
    )
    if ($TestPath) {
        $args += @("-gtest", $TestPath)
    } else {
        $args += @(
            "-gdir",
            "res://tests/unit",
            "-ginclude_subdirs",
            "-gprefix",
            "test_",
            "-gsuffix",
            ".gd"
        )
    }
    Invoke-Godot $Exe $args
}

function Invoke-WebExport {
    param([string]$Exe, [string]$Root)

    $outDir = Join-Path $Root "build/web"
    $outFile = Join-Path $outDir "index.html"
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    $arguments = @("--headless", "--path", $Root, "--export-release", "Web", $outFile)
    Write-Host "godot $($arguments -join ' ')" -ForegroundColor DarkCyan
    $output = & $Exe @arguments 2>&1
    $output | ForEach-Object { Write-Host $_ }
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) {
        $exitCode = 0
    }
    $runtimeCsvNullFollowUpsToIgnore = 0
    $errorLines = @()
    foreach ($line in $output) {
        $text = [string]$line
        $plainText = $text -replace "`e\[[0-9;]*m", ""
        $isRuntimeCsvIncludeNoise = $plainText -match "^\s*ERROR: No loader found for resource: res://data/discovery_editor/runtime/.+\.csv\.txt\b"
        if ($isRuntimeCsvIncludeNoise) {
            $runtimeCsvNullFollowUpsToIgnore += 1
        }
        $isRuntimeCsvNullFollowUp = $runtimeCsvNullFollowUpsToIgnore -gt 0 -and $plainText -match '^\s*ERROR: Condition "res\.is_null\(\)" is true\. Returning: p_path'
        if ($isRuntimeCsvNullFollowUp) {
            $runtimeCsvNullFollowUpsToIgnore -= 1
        }
        if ($plainText -match "(^|\s)(ERROR|SCRIPT ERROR|Parse Error):" -and -not ($isRuntimeCsvIncludeNoise -or $isRuntimeCsvNullFollowUp)) {
            $errorLines += $line
        }
    }
    if ($errorLines.Count -gt 0) {
        throw "Godot reported $($errorLines.Count) error line(s)."
    }
    if ($exitCode -ne 0) {
        throw "Godot command failed with exit code $exitCode."
    }
    Repair-WebExportShell (Join-Path $outDir "index.js")
    Write-Host "Web export written to $outDir" -ForegroundColor Green
}

function Repair-WebExportShell {
    param([string]$IndexJsPath)

    if (-not (Test-Path $IndexJsPath -PathType Leaf)) {
        throw "Web export shell not found at $IndexJsPath"
    }
    $content = Get-Content -Raw -LiteralPath $IndexJsPath
    $asyncInstantiateBlock = @'
			'instantiateWasm': function (imports, onSuccess) {
				function done(result) {
					onSuccess(result['instance'], result['module']);
				}
				if (typeof (WebAssembly.instantiateStreaming) !== 'undefined') {
					WebAssembly.instantiateStreaming(Promise.resolve(r), imports).then(done);
				} else {
					r.arrayBuffer().then(function (buffer) {
						WebAssembly.instantiate(buffer, imports).then(done);
					});
				}
				r = null;
				return {};
			},
'@
    if ($content.Contains($asyncInstantiateBlock)) {
        $repairedContent = $content.Replace($asyncInstantiateBlock, "").Replace("`r`n", "`n")
        $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($IndexJsPath, $repairedContent, $utf8NoBom)
        Write-Host "Removed async WebAssembly loader override from web shell" -ForegroundColor DarkCyan
    }
}

function Install-WebTemplates {
    $version = "4.6.1.stable"
    $templateDir = Join-Path $env:APPDATA "Godot/export_templates/$version"
    $archive = Join-Path $env:TEMP "Godot_v4.6.1-stable_export_templates.tpz"
    $extractDir = Join-Path $env:TEMP "godot_461_templates_extract"
    $url = "https://github.com/godotengine/godot/releases/download/4.6.1-stable/Godot_v4.6.1-stable_export_templates.tpz"

    New-Item -ItemType Directory -Force -Path $templateDir | Out-Null
    Write-Host "Downloading Godot export templates..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $archive

    if (Test-Path $extractDir) {
        Remove-Item -LiteralPath $extractDir -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
    Expand-Archive -Path $archive -DestinationPath $extractDir -Force
    Get-ChildItem $extractDir -Recurse -File | Copy-Item -Destination $templateDir -Force

    foreach ($required in @("web_nothreads_debug.zip", "web_nothreads_release.zip")) {
        if (-not (Test-Path (Join-Path $templateDir $required))) {
            throw "Template install failed: missing $required in $templateDir"
        }
    }
    Write-Host "Web templates installed in $templateDir" -ForegroundColor Green
}

function Invoke-WebServer {
    param([string]$Root, [int]$Port)

    $webDir = Join-Path $Root "build/web"
    if (-not (Test-Path (Join-Path $webDir "index.html"))) {
        throw "No web export found at $webDir. Run export-web first."
    }

    Write-Host "Serving http://localhost:$Port from $webDir" -ForegroundColor Green
    Push-Location $webDir
    try {
        python -m http.server $Port
    } finally {
        Pop-Location
    }
}

$projectRoot = Resolve-ProjectRoot
$resolvedGodot = Resolve-GodotExe $GodotExe
Write-Host "Using Godot: $resolvedGodot" -ForegroundColor Cyan
Write-Host "Project: $projectRoot" -ForegroundColor Cyan

switch ($Command) {
    "parse" { Invoke-ParseCheck $resolvedGodot $projectRoot }
    "boot" { Invoke-BootCheck $resolvedGodot $projectRoot }
    "test" { Invoke-GutTests $resolvedGodot $projectRoot $Test }
    "all" {
        Invoke-ParseCheck $resolvedGodot $projectRoot
        Invoke-BootCheck $resolvedGodot $projectRoot
        if ($Test) {
            Invoke-GutTests $resolvedGodot $projectRoot $Test
        } else {
            Invoke-GutTests $resolvedGodot $projectRoot "res://tests/unit/seeds/test_seed_crafting_grid.gd"
            Invoke-GutTests $resolvedGodot $projectRoot "res://tests/unit/seeds/test_ritual_recipe_catalog.gd"
            Invoke-GutTests $resolvedGodot $projectRoot "res://tests/unit/seeds/test_ritual_menu_slots.gd"
            Invoke-GutTests $resolvedGodot $projectRoot "res://tests/unit/test_building_placement_session.gd"
        }
    }
    "install-web-templates" { Install-WebTemplates }
    "check-web-compile-env" { & (Join-Path $PSScriptRoot "build-godot-web-templates.ps1") -CheckOnly }
    "export-web" { Invoke-WebExport $resolvedGodot $projectRoot }
    "serve-web" { Invoke-WebServer $projectRoot $Port }
}
