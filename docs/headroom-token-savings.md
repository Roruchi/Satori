# Headroom Token Savings Setup

This repo includes a lightweight Headroom setup for Codex, Claude Code, and GitHub Copilot. Headroom is optional: it does not change the Godot project, build, or runtime behavior. It only gives agents a local MCP/proxy path for compressing large context before it reaches the model.

## What is included

- `llms.txt` - compact project/context index for agents.
- `.mcp.json` - root MCP server config for MCP-compatible coding agents.
- `.vscode/mcp.json` - workspace MCP config for VS Code and GitHub Copilot Chat/agent mode.
- `.github/workflows/copilot-setup-steps.yml` - installs Headroom in GitHub Copilot cloud agent environments.
- `.github/copilot-headroom-mcp.json` - JSON snippet to paste into GitHub repository MCP settings.
- `tools/headroom.ps1` - local PowerShell helper for install verification, MCP status, and proxy startup.

## Local install

Run this once on the machine where the agent runs:

```powershell
pip install "headroom-ai[all]"
npm install headroom-ai
```

Verify from the repo root:

```powershell
.\tools\headroom.ps1 -Action Verify
.\tools\headroom.ps1 -Action McpStatus
```

The MCP configs call:

```text
headroom mcp serve
```

If an agent cannot find `headroom`, make sure Python's scripts directory is on `PATH`, or run `python -m pip show headroom-ai` to locate the install.

Current local note: the Node/TypeScript package installed in this repo. The Python `[all]` install failed on Windows Python 3.12 while a Rust build helper tried to bootstrap `rustup-init.exe`. Until that is fixed, the `headroom` CLI, MCP server, proxy, `perf`, and `dashboard` commands will not be available on this machine.

## Codex and Claude

Use `.mcp.json` for local MCP clients. Claude Code can also register Headroom globally:

```powershell
headroom mcp install
```

For automatic HTTP proxy mode:

```powershell
.\tools\headroom.ps1 -Action Proxy
```

Then start clients with their provider base URL pointed at `http://127.0.0.1:8787` where supported.

For wrapped agent mode after the Python CLI is installed:

```powershell
headroom wrap claude
headroom wrap codex
headroom wrap copilot
```

For savings inspection:

```powershell
headroom perf
headroom dashboard
```

## GitHub Copilot

For VS Code Copilot, `.vscode/mcp.json` is checked in intentionally. VS Code will ask whether you trust the local MCP server before starting it.

For Copilot cloud agent on GitHub.com, repository administrators must paste MCP JSON in repository settings. Use the checked-in snippet:

```text
.github/copilot-headroom-mcp.json
```

The companion workflow `.github/workflows/copilot-setup-steps.yml` installs `headroom-ai[mcp,code]` before Copilot cloud agent starts, so the `headroom` command exists in that environment.

## Agent usage guidance

Ask the agent to use Headroom for large, low-signal context:

- long `rg` output
- Godot parse/test logs
- generated JSON or CSV
- large specs
- broad diffs
- copied external docs

Avoid compressing tiny files or exact code spans where line-level fidelity matters. Retrieve originals with `headroom_retrieve` before making edits that depend on exact text.
