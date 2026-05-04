from typing import Literal

from mcp.server.fastmcp import FastMCP

from .. import connection

ExportFormat = Literal["skp", "obj", "dae", "stl", "png", "jpg", "jpeg"]


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

    @mcp.tool()
    def set_selection(ids: list[int]) -> dict:
        """Replace the model selection with the entities matching `ids`.

        Returns `{requested, selected, missing}` so the client can
        detect stale IDs that no longer exist in the model.
        """
        return connection.send("set_selection", {"ids": ids})

    @mcp.tool()
    def export_scene(
        format: ExportFormat = "skp",
        path: str | None = None,
        width: int | None = None,
        height: int | None = None,
    ) -> dict:
        """Export the active model.

        - `format`: skp | obj | dae | stl | png | jpg
        - `path`: optional override; defaults to a temp directory
        - `width`, `height`: image size for png/jpg (default 1920x1080)
        """
        params: dict = {"format": format}
        if path is not None:
            params["path"] = path
        if width is not None:
            params["width"] = width
        if height is not None:
            params["height"] = height
        return connection.send("export_scene", params)
