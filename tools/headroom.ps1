param(
    [ValidateSet("Verify", "Install", "InstallPython", "InstallNode", "NodeVerify", "McpStatus", "Proxy", "WrapClaude", "WrapCodex", "WrapCopilot", "Perf", "Dashboard")]
    [string]$Action = "Verify",

    [int]$Port = 8787
)

$ErrorActionPreference = "Stop"

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-Python {
    param([string[]]$Arguments)

    if (Test-Command "python") {
        & python @Arguments
        return
    }

    if (Test-Command "py") {
        & py @Arguments
        return
    }

    throw "Python was not found on PATH. Install Python 3.10+ before installing Headroom."
}

switch ($Action) {
    "Install" {
        Invoke-Python -Arguments @("-m", "pip", "install", "headroom-ai[all]")
        & npm install headroom-ai
        break
    }

    "InstallPython" {
        Invoke-Python -Arguments @("-m", "pip", "install", "headroom-ai[all]")
        break
    }

    "InstallNode" {
        & npm install headroom-ai
        break
    }

    "NodeVerify" {
        & node -e "const h=require('headroom-ai'); if (!h.compress) process.exit(1); console.log('headroom-ai loaded')"
        break
    }

    "Verify" {
        Invoke-Python -Arguments @("-c", "import headroom; print(headroom.__version__)")
        if (-not (Test-Command "headroom")) {
            throw "The Python package imports, but the 'headroom' CLI is not on PATH."
        }
        & headroom mcp status
        break
    }

    "McpStatus" {
        if (-not (Test-Command "headroom")) {
            throw "The 'headroom' CLI was not found. Run '.\tools\headroom.ps1 -Action Install' first."
        }
        & headroom mcp status
        break
    }

    "Proxy" {
        if (-not (Test-Command "headroom")) {
            throw "The 'headroom' CLI was not found. Run '.\tools\headroom.ps1 -Action Install' first."
        }
        & headroom proxy --port $Port
        break
    }

    "WrapClaude" {
        if (-not (Test-Command "headroom")) {
            throw "The 'headroom' CLI was not found. Run '.\tools\headroom.ps1 -Action InstallPython' first."
        }
        & headroom wrap claude
        break
    }

    "WrapCodex" {
        if (-not (Test-Command "headroom")) {
            throw "The 'headroom' CLI was not found. Run '.\tools\headroom.ps1 -Action InstallPython' first."
        }
        & headroom wrap codex
        break
    }

    "WrapCopilot" {
        if (-not (Test-Command "headroom")) {
            throw "The 'headroom' CLI was not found. Run '.\tools\headroom.ps1 -Action InstallPython' first."
        }
        & headroom wrap copilot
        break
    }

    "Perf" {
        if (-not (Test-Command "headroom")) {
            throw "The 'headroom' CLI was not found. Run '.\tools\headroom.ps1 -Action InstallPython' first."
        }
        & headroom perf
        break
    }

    "Dashboard" {
        if (-not (Test-Command "headroom")) {
            throw "The 'headroom' CLI was not found. Run '.\tools\headroom.ps1 -Action InstallPython' first."
        }
        & headroom dashboard
        break
    }
}
