from typing import Literal

from mcp.server.fastmcp import FastMCP

from .. import connection

ComponentType = Literal["box", "cube", "cylinder", "sphere", "cone"]


def register(mcp: FastMCP) -> None:
    @mcp.tool()
    def create_component(
        type: ComponentType,
        position: list[float] | None = None,
        dimensions: list[float] | None = None,
    ) -> dict:
        """Create a primitive shape (box, cylinder, sphere, cone) as a group.

        - `position`: [x, y, z] min corner of the shape's bounding box.
          Defaults to [0, 0, 0].
        - `dimensions`: [width, depth, height]. Defaults to [1, 1, 1].
          For cylinder/cone the base diameter equals `width` (and `depth`
          is ignored). For sphere the diameter equals `width`.

        Returns `{success, id, type}` where `id` is SketchUp's entityID,
        usable in transform_component / delete_component / set_material.
        """
        params: dict = {"type": type}
        if position is not None:
            params["position"] = position
        if dimensions is not None:
            params["dimensions"] = dimensions
        return connection.send("create_component", params)
