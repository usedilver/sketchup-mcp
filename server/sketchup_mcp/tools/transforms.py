from mcp.server.fastmcp import FastMCP

from .. import connection


def register(mcp: FastMCP) -> None:
    @mcp.tool()
    def delete_component(id: int) -> dict:
        """Delete a component by SketchUp entity ID."""
        return connection.send("delete_component", {"id": id})

    @mcp.tool()
    def transform_component(
        id: int,
        translate: list[float] | None = None,
        rotate: list[float] | None = None,
        scale: list[float] | None = None,
    ) -> dict:
        """Translate, rotate, and/or scale a component about its bounds center.

        - `translate`: [dx, dy, dz] — relative move (added to current position).
        - `rotate`: [deg_x, deg_y, deg_z] — degrees around each axis.
        - `scale`: [sx, sy, sz] — per-axis scale factors.

        All three are optional; applied in translate → rotate → scale order.
        """
        params: dict = {"id": id}
        if translate is not None:
            params["translate"] = translate
        if rotate is not None:
            params["rotate"] = rotate
        if scale is not None:
            params["scale"] = scale
        return connection.send("transform_component", params)
