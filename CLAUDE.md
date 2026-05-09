# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

Two processes communicate over a local TCP socket using JSON-RPC 2.0:

```
MCP client  ──stdio──▶  Python MCP server (server/)  ──TCP──▶  SketchUp Ruby extension (extension/)
```

- **Python server (`server/sketchup_mcp/`)** — FastMCP server. Each tool is a thin wrapper that calls `connection.send(method, params)`. New connection per call (intentional — see `connection.py` for why).
- **SketchUp extension (`extension/su_mcp/`)** — Ruby extension that runs a TCP server inside SketchUp's UI thread via `UI.start_timer`. Non-blocking via `accept_nonblock` + `IO.select` so SketchUp stays responsive.

### Adding a tool

A tool exists in two places. Both must be edited:

1. **Ruby handler** (`extension/su_mcp/tools/<category>.rb`): implement the function, then register it at the bottom of the file: `SU_MCP::Dispatcher.register("tool_name") { |params| ... }`.
2. **Python wrapper** (`server/sketchup_mcp/tools/<category>.py`): add an `@mcp.tool()` function that calls `connection.send("tool_name", params)`.
3. If creating a new category file in Python, add it to the imports and the registration loop in `server/sketchup_mcp/tools/__init__.py`.

`tools/*.rb` files are auto-loaded by `main.rb` — no manual registration needed on the Ruby side beyond the `Dispatcher.register` call.

### Dispatcher MCP framing

`Dispatcher.dispatch` (in `extension/su_mcp/dispatcher.rb`) unwraps the MCP `tools/call` envelope: when `method == "tools/call"`, it pulls the real method out of `params["name"]` and arguments out of `params["arguments"]`. This means handlers are reachable both as raw JSON-RPC methods and as MCP tool calls — important for the `batch` tool, which dispatches sub-requests directly.

### Entity IDs and helpers

Tool handlers that take an entity ID should use `SU_MCP::Entities.find!(id)` (in `entities.rb`) — it tolerates ints, strings, and quoted strings (`"123"`). For joinery/booleans, use `find_solid!` to enforce that the entity is a Group or ComponentInstance, and `Entities.contents(solid)` to get the right entities collection.

### Atomic batches

The `batch` tool (`extension/su_mcp/tools/system.rb`) wraps multiple tool calls in `model.start_operation` / `commit_operation` so they undo as one. On failure with `wrap_undo: true` and `stop_on_error: true` (the defaults), it calls `abort_operation` to roll back. Reach for batch when an LLM is generating multiple sub-calls that should appear atomic in SketchUp's undo stack.

## Common commands

### Build the SketchUp extension

```bash
cd extension && ruby package.rb
```

Produces `su_mcp_v<VERSION>.rbz`. Install via SketchUp's Extension Manager. The `.rbz` is gitignored — it's a build artifact.

### Run the MCP server locally

```bash
cd server && uv sync
uv run sketchup-mcp
```

### Quick tool registration check

```bash
cd server && uv run python -c "from sketchup_mcp.server import mcp; print(list(mcp._tool_manager._tools.keys()))"
```

### Configuration

| Env var | Default | Notes |
|---|---|---|
| `SKETCHUP_HOST` | `127.0.0.1` | |
| `SKETCHUP_PORT` | `9876` | Must match the extension's port (set via `Plugins → SketchUp MCP → Configure Port…` or `Sketchup.read_default("SU_MCP", "port")`). |

## Releases

Version is locked in lockstep across **four** files:
- `server/pyproject.toml` (`version = "X.Y.Z"`)
- `extension/su_mcp.rb` (`extension.version`)
- `extension/extension.json` (`"version"`)
- `extension/package.rb` (`VERSION`)

Use the `/release` skill — it parses conventional commits since the last `v*` tag, bumps all four files, rebuilds the `.rbz`, commits as `chore(release): vNEW`, and creates an annotated tag. Pre-1.0 rule: would-be MAJOR bumps become MINOR while version starts with `0.`. Never pushes automatically.

## Conventions

- **Conventional commits** are required (`feat:`, `fix:`, `chore:`, `feat!:` for breaking, etc.) — the `/release` skill parses them to decide bump level.
- **No tests yet.** This is an early rewrite; there is no test suite or CI. Verify changes by running the server and exercising tools against a live SketchUp.
- The Ruby `eval_ruby` tool runs arbitrary code in `TOPLEVEL_BINDING.dup` with a 30s timeout — it's the escape hatch for SketchUp API calls that don't yet have a dedicated tool.
