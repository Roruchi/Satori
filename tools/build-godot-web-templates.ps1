# Build Godot Web export templates from source.
# Based on Godot's "Compiling for the Web" docs:
# https://docs.godotengine.org/en/latest/engine_details/development/compiling/compiling_for_web.html
param(
    [string]$GodotTag = "4.6.1-stable",
    [string]$EmsdkVersion = "4.0.0",
    [string]$WorkRoot = (Join-Path $env:USERPROFILE ".godot-web-build"),
    [switch]$Threads,
    [switch]$InstallTemplates,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"

function Invoke-Logged {
    param([string]$CommandLine)

    Write-Host $CommandLine -ForegroundColor DarkCyan
    cmd.exe /d /c $CommandLine
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code $LASTEXITCODE."
    }
}

$emsdkDir = Join-Path $WorkRoot "emsdk"
$sourceDir = Join-Path $WorkRoot "godot"
$templateDir = Join-Path $env:APPDATA "Godot/export_templates/4.6.1.stable"
$pythonExe = (Get-Command python -ErrorAction Stop).Source

New-Item -ItemType Directory -Force -Path $WorkRoot | Out-Null

if (-not (Test-Path $emsdkDir)) {
    Invoke-Logged "git clone https://github.com/emscripten-core/emsdk.git `"$emsdkDir`""
}

Invoke-Logged "`"$emsdkDir\emsdk.bat`" install $EmsdkVersion"
Invoke-Logged "`"$emsdkDir\emsdk.bat`" activate $EmsdkVersion"

if (-not (Test-Path $sourceDir)) {
    Invoke-Logged "git clone --branch $GodotTag --depth 1 https://github.com/godotengine/godot.git `"$sourceDir`""
} else {
    Invoke-Logged "cd /d `"$sourceDir`" && git fetch --tags --depth 1 origin $GodotTag && git checkout $GodotTag"
}

Invoke-Logged "`"$pythonExe`" -m SCons --version"
Invoke-Logged "call `"$emsdkDir\emsdk_env.bat`" >nul && emcc --version"

if ($CheckOnly) {
    Write-Host "Web template build prerequisites are ready." -ForegroundColor Green
    return
}

$threadArg = if ($Threads) { "" } else { " threads=no" }
$releaseCommand = "call `"$emsdkDir\emsdk_env.bat`" >nul && cd /d `"$sourceDir`" && `"$pythonExe`" -m SCons platform=web target=template_release$threadArg"
$debugCommand = "call `"$emsdkDir\emsdk_env.bat`" >nul && cd /d `"$sourceDir`" && `"$pythonExe`" -m SCons platform=web target=template_debug$threadArg"

Invoke-Logged $releaseCommand
Invoke-Logged $debugCommand

$suffix = if ($Threads) { "" } else { ".nothreads" }
$releaseZip = Join-Path $sourceDir "bin/godot.web.template_release.wasm32$suffix.zip"
$debugZip = Join-Path $sourceDir "bin/godot.web.template_debug.wasm32$suffix.zip"
$releaseTemplateName = if ($Threads) { "web_release.zip" } else { "web_nothreads_release.zip" }
$debugTemplateName = if ($Threads) { "web_debug.zip" } else { "web_nothreads_debug.zip" }

if (-not (Test-Path $releaseZip)) {
    throw "Release template not found: $releaseZip"
}
if (-not (Test-Path $debugZip)) {
    throw "Debug template not found: $debugZip"
}

Copy-Item -LiteralPath $releaseZip -Destination (Join-Path $sourceDir "bin/$releaseTemplateName") -Force
Copy-Item -LiteralPath $debugZip -Destination (Join-Path $sourceDir "bin/$debugTemplateName") -Force

if ($InstallTemplates) {
    New-Item -ItemType Directory -Force -Path $templateDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $sourceDir "bin/$releaseTemplateName") -Destination (Join-Path $templateDir $releaseTemplateName) -Force
    Copy-Item -LiteralPath (Join-Path $sourceDir "bin/$debugTemplateName") -Destination (Join-Path $templateDir $debugTemplateName) -Force
    Write-Host "Installed compiled templates to $templateDir" -ForegroundColor Green
}

Write-Host "Built templates in $(Join-Path $sourceDir "bin")" -ForegroundColor Green
