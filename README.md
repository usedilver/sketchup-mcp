# sketchup-mcp

Model Context Protocol (MCP) server for SketchUp. Lets Claude (and other MCP clients) drive SketchUp: create geometry, manage components, apply materials, run Ruby, export scenes, and more.

> Conceptually inspired by the MCP-as-DCC-bridge approach popularized by [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp) for Blender. This project takes the same idea to SketchUp with a different focus (woodworking, boolean ops, atomic batches) and a modular, non-blocking architecture.

## Architecture

Two pieces talk over a local TCP socket:

```
┌──────────────┐   stdio    ┌───────────────────┐   TCP/JSON-RPC   ┌─────────────────┐
│ MCP client   │ ─────────▶ │ Python MCP server │ ───────────────▶ │ SketchUp ext.   │
│ (Claude etc) │            │ (server/)         │                  │ (extension/)    │
└──────────────┘            └───────────────────┘                  └─────────────────┘
```

- **`server/`** — Python MCP server (FastMCP). Exposes tools to MCP clients and forwards them as JSON-RPC requests to the SketchUp extension.
- **`extension/`** — SketchUp Ruby extension. Runs a small TCP server inside SketchUp, dispatches requests to tool modules, returns results.

## Status

🚧 Early rewrite. Not feature-complete yet.

## Install

### SketchUp extension

1. Build the `.rbz`:
   ```bash
   cd extension && ruby package.rb
   ```
2. In SketchUp: **Window → Extension Manager → Install Extension** → select the `.rbz`.
3. Restart SketchUp.

### MCP server

```bash
cd server
uv sync
```

Add to your MCP client config (e.g. Claude Desktop):

```json
{
  "mcpServers": {
    "sketchup": {
      "command": "uv",
      "args": ["--directory", "/absolute/path/to/sketchup-mcp/server", "run", "sketchup-mcp"]
    }
  }
}
```

## Configuration

| Env var          | Default     | Description                              |
|------------------|-------------|------------------------------------------|
| `SKETCHUP_HOST`  | `127.0.0.1` | Host where the SketchUp extension listens|
| `SKETCHUP_PORT`  | `9876`      | Port the SketchUp extension listens on   |

The SketchUp extension reads its port from SketchUp's `Sketchup.read_default("SU_MCP", "port")`.

## License

MIT — see [LICENSE](LICENSE).
