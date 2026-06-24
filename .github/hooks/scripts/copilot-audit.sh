#!/usr/bin/env bash
set +e

payload="$(cat)"

run_python_audit() {
  local python_bin="$1"
  COPILOT_AUDIT_PAYLOAD="$payload" "$python_bin" - <<'PY'
import datetime
import hashlib
import json
import os
import pathlib
import socket

SECRET_KEYWORDS = ("authorization", "credential", "password", "passwd", "secret", "token", "api_key", "apikey", "api-key")


def get_field(value, *names):
    if isinstance(value, dict):
        for name in names:
            if name in value:
                return value[name]
    return None


def sanitize(value):
    if isinstance(value, dict):
        safe = {}
        for key, item in value.items():
            key_text = str(key)
            if any(keyword in key_text.lower() for keyword in SECRET_KEYWORDS):
                safe[key_text] = "[REDACTED]"
            else:
                safe[key_text] = sanitize(item)
        return safe
    if isinstance(value, list):
        return [sanitize(item) for item in value]
    return value


def as_json(value):
    if value is None:
        return None
    return json.dumps(value, separators=(",", ":"), ensure_ascii=False)


def truncate(value, limit):
    if value is None:
        return None
    text = str(value)
    if len(text) <= limit:
        return text
    return text[:limit] + "...[truncated]"


def approx_tokens(value):
    if not value:
        return 0
    return int((len(str(value)) + 3) / 4)


raw_payload = os.environ.get("COPILOT_AUDIT_PAYLOAD", "")
try:
    payload = json.loads(raw_payload) if raw_payload.strip() else {}
except Exception:
    payload = {"unparsedPayloadPreview": truncate(raw_payload, 4096)}

event_name = os.environ.get("COPILOT_HOOK_EVENT") or get_field(payload, "hook_event_name") or "unknown"
session_id = get_field(payload, "sessionId", "session_id")
cwd = get_field(payload, "cwd")
tool_name = get_field(payload, "toolName", "tool_name")
tool_args = get_field(payload, "toolArgs", "tool_input")
tool_result = get_field(payload, "toolResult", "tool_result") or {}
prompt = get_field(payload, "prompt", "initialPrompt", "initial_prompt")
error_object = get_field(payload, "error")
transcript_path = get_field(payload, "transcriptPath", "transcript_path")

safe_tool_args_json = as_json(sanitize(tool_args))
tool_result_text = get_field(tool_result, "textResultForLlm", "text_result_for_llm")
error_text = get_field(error_object, "message")
if error_text is None and error_object is not None:
    error_text = as_json(sanitize(error_object))

transcript_bytes = None
if transcript_path:
    try:
        transcript_bytes = pathlib.Path(transcript_path).stat().st_size
    except OSError:
        transcript_bytes = None

input_text = "".join(part or "" for part in (prompt, safe_tool_args_json))
output_text = "".join(part or "" for part in (tool_result_text, error_text))

record = {
    "schemaVersion": 1,
    "createdAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "source": "github-copilot-hook",
    "mode": "observe_only",
    "event": event_name,
    "sessionId": session_id,
    "cwd": cwd,
    "actor": {
        "user": os.environ.get("USER") or os.environ.get("USERNAME"),
        "machine": socket.gethostname(),
        "processId": os.getpid(),
    },
    "summary": {
        "toolName": tool_name,
        "notificationType": get_field(payload, "notification_type"),
        "reason": get_field(payload, "reason", "stopReason", "stop_reason"),
        "errorContext": get_field(payload, "errorContext", "error_context"),
        "recoverable": get_field(payload, "recoverable"),
        "transcriptPath": transcript_path,
        "transcriptBytes": transcript_bytes,
        "promptPreview": truncate(prompt, 512),
        "toolArgsPreview": truncate(safe_tool_args_json, 1024),
        "toolResultPreview": truncate(tool_result_text, 1024),
        "errorPreview": truncate(error_text, 1024),
    },
    "tokenUsage": {
        "official": False,
        "estimationMethod": "approx_chars_div_4",
        "inputApproxTokens": approx_tokens(input_text),
        "outputApproxTokens": approx_tokens(output_text),
        "totalApproxTokens": approx_tokens(input_text) + approx_tokens(output_text),
    },
    "payload": {
        "sha256": hashlib.sha256(raw_payload.encode("utf-8")).hexdigest(),
        "preview": truncate(as_json(sanitize(payload)), 4096),
    },
}

log_path = pathlib.Path(os.environ.get("COPILOT_AUDIT_LOG") or ".copilot-audit/copilot-audit.jsonl")
log_path.parent.mkdir(parents=True, exist_ok=True)
with log_path.open("a", encoding="utf-8") as audit_log:
    audit_log.write(json.dumps(record, separators=(",", ":"), ensure_ascii=False) + "\n")
PY
}

if command -v python3 >/dev/null 2>&1; then
  run_python_audit python3
elif command -v python >/dev/null 2>&1; then
  run_python_audit python
else
  mkdir -p .copilot-audit
  escaped_payload="$(printf '%s' "$payload" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')"
  printf '{"schemaVersion":1,"createdAt":"%s","source":"github-copilot-hook","mode":"observe_only","event":"%s","payload":{"preview":"%s"}}\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "${COPILOT_HOOK_EVENT:-unknown}" "$escaped_payload" >> .copilot-audit/copilot-audit.jsonl
fi

printf '{}\n'
exit 0
