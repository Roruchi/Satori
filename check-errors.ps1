# check-errors.ps1 — Run Godot headless and surface parse/script errors.
# Usage: pwsh check-errors.ps1
# Usage with custom path: pwsh check-errors.ps1 -GodotExe "C:\path\to\godot.exe"
param(
    [string]$GodotExe = "C:\Users\roelv\Downloads\Godot_v4.6.1-stable_win64.exe"
)

if (-not (Test-Path $GodotExe)) {
    # Try to find Godot anywhere on common search paths
    $candidates = @(
        "C:\Users\roelv\Downloads\Godot_v4.6.1-stable_win64.exe",
        "C:\Users\roelv\AppData\Local\Programs\Godot\godot.exe",
        (Get-Command godot -ErrorAction SilentlyContinue)?.Source
    ) | Where-Object { $_ -and (Test-Path $_) }
    if ($candidates) {
        $GodotExe = $candidates[0]
    } else {
        Write-Error "Godot not found. Pass -GodotExe 'C:\path\to\godot.exe'"
        exit 1
    }
}

Write-Host "Using Godot: $GodotExe" -ForegroundColor Cyan
Write-Host "Checking project at: $PSScriptRoot" -ForegroundColor Cyan

$proc = Start-Process -FilePath $GodotExe `
    -ArgumentList "--headless", "--path", "`"$PSScriptRoot`"", "--quit" `
    -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\godot_out.txt" `
    -RedirectStandardError  "$env:TEMP\godot_err.txt"

$combined = (Get-Content "$env:TEMP\godot_out.txt" -ErrorAction SilentlyContinue) +
            (Get-Content "$env:TEMP\godot_err.txt" -ErrorAction SilentlyContinue)

$errors   = $combined | Where-Object { $_ -match "(ERROR|SCRIPT ERROR|Parse Error)" }
$warnings = $combined | Where-Object { $_ -match "WARNING:" }

if ($errors) {
    Write-Host "`nERRORS ($($errors.Count)):" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
} else {
    Write-Host "`nNo errors found." -ForegroundColor Green
}

if ($warnings) {
    Write-Host "`nWARNINGS ($($warnings.Count)):" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}

exit ($errors.Count -gt 0 ? 1 : 0)
