from mcp.server.fastmcp import FastMCP

from . import tools

mcp = FastMCP(
    "sketchup",
    instructions=(
        "Tools to drive SketchUp: create and transform components, apply "
        "materials, manage selection, export scenes, and run arbitrary Ruby."
    ),
)

tools.register(mcp)
