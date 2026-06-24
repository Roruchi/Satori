$ErrorActionPreference = "Stop"

function Get-Field {
    param(
        [object]$InputObject,
        [string[]]$Names
    )

    if ($null -eq $InputObject) {
        return $null
    }

    foreach ($name in $Names) {
        if ($InputObject -is [System.Collections.IDictionary] -and $InputObject.Contains($name)) {
            return $InputObject[$name]
        }

        $property = $InputObject.PSObject.Properties[$name]
        if ($null -ne $property) {
            return $property.Value
        }
    }

    return $null
}

function ConvertTo-SafeObject {
    param([object]$Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [string] -or $Value -is [ValueType]) {
        return $Value
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $safe = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $keyText = [string]$key
            if ($keyText -match "(?i)(authorization|credential|password|passwd|secret|token|api[_-]?key)") {
                $safe[$keyText] = "[REDACTED]"
            } else {
                $safe[$keyText] = ConvertTo-SafeObject $Value[$key]
            }
        }
        return $safe
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $items = @()
        foreach ($item in $Value) {
            $items += ConvertTo-SafeObject $item
        }
        return $items
    }

    $object = [ordered]@{}
    foreach ($property in $Value.PSObject.Properties) {
        if ($property.Name -match "(?i)(authorization|credential|password|passwd|secret|token|api[_-]?key)") {
            $object[$property.Name] = "[REDACTED]"
        } else {
            $object[$property.Name] = ConvertTo-SafeObject $property.Value
        }
    }
    return $object
}

function Truncate-Text {
    param(
        [AllowNull()][string]$Text,
        [int]$MaxLength = 2048
    )

    if ($null -eq $Text) {
        return $null
    }

    if ($Text.Length -le $MaxLength) {
        return $Text
    }

    return $Text.Substring(0, $MaxLength) + "...[truncated]"
}

function Get-ApproxTokens {
    param([AllowNull()][string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return 0
    }

    return [int][Math]::Ceiling($Text.Length / 4.0)
}

function ConvertTo-JsonText {
    param([object]$Value)

    if ($null -eq $Value) {
        return $null
    }

    return ($Value | ConvertTo-Json -Depth 20 -Compress)
}

function Get-Sha256 {
    param([string]$Text)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash = $sha.ComputeHash($bytes)
    return ([BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
}

function Get-AuditLogPath {
    $configuredPath = $env:COPILOT_AUDIT_LOG
    if ([string]::IsNullOrWhiteSpace($configuredPath)) {
        $configuredPath = ".copilot-audit/copilot-audit.jsonl"
    }

    if ([System.IO.Path]::IsPathRooted($configuredPath)) {
        return $configuredPath
    }

    return Join-Path (Get-Location) $configuredPath
}

try {
    $rawPayload = (@($input) -join [Environment]::NewLine)
    if ([string]::IsNullOrWhiteSpace($rawPayload)) {
        $rawPayload = [Console]::In.ReadToEnd()
    }
    if ([string]::IsNullOrWhiteSpace($rawPayload)) {
        $payload = [pscustomobject]@{}
    } else {
        $payload = $rawPayload | ConvertFrom-Json
    }

    $eventName = $env:COPILOT_HOOK_EVENT
    if ([string]::IsNullOrWhiteSpace($eventName)) {
        $eventName = Get-Field $payload @("hook_event_name")
    }
    if ([string]::IsNullOrWhiteSpace($eventName)) {
        $eventName = "unknown"
    }

    $sessionId = Get-Field $payload @("sessionId", "session_id")
    $cwd = Get-Field $payload @("cwd")
    $toolName = Get-Field $payload @("toolName", "tool_name")
    $toolArgs = Get-Field $payload @("toolArgs", "tool_input")
    $toolResult = Get-Field $payload @("toolResult", "tool_result")
    $prompt = Get-Field $payload @("prompt", "initialPrompt", "initial_prompt")
    $errorObject = Get-Field $payload @("error")
    $transcriptPath = Get-Field $payload @("transcriptPath", "transcript_path")

    $toolArgsJson = ConvertTo-JsonText (ConvertTo-SafeObject $toolArgs)
    $toolResultText = Get-Field $toolResult @("textResultForLlm", "text_result_for_llm")
    $errorText = Get-Field $errorObject @("message")
    if ([string]::IsNullOrEmpty($errorText) -and $null -ne $errorObject) {
        $errorText = ConvertTo-JsonText (ConvertTo-SafeObject $errorObject)
    }

    $inputText = @($prompt, $toolArgsJson) -join ""
    $outputText = @($toolResultText, $errorText) -join ""
    $payloadPreview = Truncate-Text (ConvertTo-JsonText (ConvertTo-SafeObject $payload)) 4096

    $transcriptBytes = $null
    if (-not [string]::IsNullOrWhiteSpace($transcriptPath) -and (Test-Path -LiteralPath $transcriptPath)) {
        $transcriptBytes = (Get-Item -LiteralPath $transcriptPath).Length
    }

    $record = [ordered]@{
        schemaVersion = 1
        createdAt = (Get-Date).ToUniversalTime().ToString("o")
        source = "github-copilot-hook"
        mode = "observe_only"
        event = $eventName
        sessionId = $sessionId
        cwd = $cwd
        actor = [ordered]@{
            user = $env:USERNAME
            machine = $env:COMPUTERNAME
            processId = $PID
        }
        summary = [ordered]@{
            toolName = $toolName
            notificationType = Get-Field $payload @("notification_type")
            reason = Get-Field $payload @("reason", "stopReason", "stop_reason")
            errorContext = Get-Field $payload @("errorContext", "error_context")
            recoverable = Get-Field $payload @("recoverable")
            transcriptPath = $transcriptPath
            transcriptBytes = $transcriptBytes
            promptPreview = Truncate-Text $prompt 512
            toolArgsPreview = Truncate-Text $toolArgsJson 1024
            toolResultPreview = Truncate-Text $toolResultText 1024
            errorPreview = Truncate-Text $errorText 1024
        }
        tokenUsage = [ordered]@{
            official = $false
            estimationMethod = "approx_chars_div_4"
            inputApproxTokens = Get-ApproxTokens $inputText
            outputApproxTokens = Get-ApproxTokens $outputText
            totalApproxTokens = (Get-ApproxTokens $inputText) + (Get-ApproxTokens $outputText)
        }
        payload = [ordered]@{
            sha256 = Get-Sha256 $rawPayload
            preview = $payloadPreview
        }
    }

    $logPath = Get-AuditLogPath
    $logDirectory = Split-Path -Parent $logPath
    if (-not [string]::IsNullOrWhiteSpace($logDirectory)) {
        New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
    }

    $line = $record | ConvertTo-Json -Depth 20 -Compress
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
} catch {
    # Hooks are observe-only in this repo. Never block Copilot because audit logging failed.
}

Write-Output "{}"
exit 0
