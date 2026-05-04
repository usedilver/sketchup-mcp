from mcp.server.fastmcp import FastMCP

from .. import connection


def register(mcp: FastMCP) -> None:
    @mcp.tool()
    def ping() -> dict:
        """Health check — round-trip to the SketchUp extension."""
        return connection.send("ping")

    @mcp.tool()
    def undo_last(steps: int = 1) -> dict:
        """Undo the last `steps` operations in the active model.

        Returns `{undone, requested}` — `undone` may be smaller if the
        undo stack is shorter than requested.
        """
        return connection.send("undo_last", {"steps": steps})

    @mcp.tool()
    def batch(
        calls: list[dict],
        wrap_undo: bool = True,
        stop_on_error: bool = True,
        undo_name: str = "MCP batch",
    ) -> dict:
        """Run multiple tool calls under a single undo operation.

        - `calls`: list of `{"tool": "name", "args": {...}}`
        - `wrap_undo`: wrap the whole batch in start_operation /
          commit_operation so it counts as one undo (default True)
        - `stop_on_error`: abort the batch (rolling back if wrapped)
          on the first failure (default True)

        Returns per-call results in `results[]` with `{index, success,
        result}` or `{index, success, error}`.
        """
        return connection.send("batch", {
            "calls": calls,
            "wrap_undo": wrap_undo,
            "stop_on_error": stop_on_error,
            "undo_name": undo_name,
        })
