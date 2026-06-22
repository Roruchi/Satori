# check-errors.ps1 — Run Godot headless and surface parse/script errors.
# Usage: pwsh check-errors.ps1
# Usage with custom path: pwsh check-errors.ps1 -GodotExe "C:\path\to\godot.exe"
param(
    [string]$GodotExe = "C:\Users\roelv\Downloads\Godot_v4.6.1-stable_win64.exe"
)

& (Join-Path $PSScriptRoot "tools/godot.ps1") -Command parse -GodotExe $GodotExe
exit $LASTEXITCODE
