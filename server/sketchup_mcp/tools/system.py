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
