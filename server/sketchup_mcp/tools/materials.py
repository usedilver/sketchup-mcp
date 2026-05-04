from mcp.server.fastmcp import FastMCP

from .. import connection


def register(mcp: FastMCP) -> None:
    @mcp.tool()
    def set_material(id: int, material: str) -> dict:
        """Apply a material to a component.

        `material` accepts:
        - Named colors: red, green, blue, yellow, cyan, magenta, white,
          black, brown, orange, gray, wood
        - Hex codes: "#RRGGBB" (e.g. "#8B4513")
        - Any existing material name already in the model
        """
        return connection.send("set_material", {"id": id, "material": material})
