"""Tool registry.

Each module in this package exposes a `register(mcp)` function that
attaches its tools to the FastMCP instance. New tool categories should
be added to the imports below.
"""
from mcp.server.fastmcp import FastMCP


def register(mcp: FastMCP) -> None:
    # Tool modules will be wired up here as they get ported.
    # from . import components, materials, transforms, selection, joints, scene, ruby
    # for module in (components, materials, transforms, selection, joints, scene, ruby):
    #     module.register(mcp)
    pass
