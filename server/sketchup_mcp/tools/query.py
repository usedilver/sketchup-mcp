from mcp.server.fastmcp import FastMCP

from .. import connection


def register(mcp: FastMCP) -> None:
    @mcp.tool()
    def measure(id: int) -> dict:
        """Return bounds, position, material, and class for an entity."""
        return connection.send("measure", {"id": id})

    @mcp.tool()
    def list_definitions(
        name_match: str | None = None,
        include_bounds: bool = True,
    ) -> dict:
        """List component definitions in the active model.

        - `name_match`: optional case-insensitive regex to filter names
        - `include_bounds`: include each definition's bounding box size
        """
        params: dict = {"include_bounds": include_bounds}
        if name_match is not None:
            params["name_match"] = name_match
        return connection.send("list_definitions", params)

    @mcp.tool()
    def list_instances(
        definition_name: str | None = None,
        bounds: dict | None = None,
        limit: int = 500,
    ) -> dict:
        """List top-level component instances and groups.

        - `definition_name`: filter by exact definition/group name
        - `bounds`: `{"min": [x,y,z], "max": [x,y,z]}` AABB filter
        - `limit`: cap (default 500); response includes `truncated` flag
        """
        params: dict = {"limit": limit}
        if definition_name is not None:
            params["definition_name"] = definition_name
        if bounds is not None:
            params["bounds"] = bounds
        return connection.send("list_instances", params)
