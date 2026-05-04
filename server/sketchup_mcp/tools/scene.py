from mcp.server.fastmcp import FastMCP

from .. import connection


def register(mcp: FastMCP) -> None:
    @mcp.tool()
    def get_scene_info() -> dict:
        """Return metadata about the active SketchUp model.

        Includes title, file path, units, and counts of entities,
        layers, materials, and component definitions.
        """
        return connection.send("get_scene_info")

    @mcp.tool()
    def get_selection() -> dict:
        """Return the currently selected entities (id, type, name)."""
        return connection.send("get_selection")
