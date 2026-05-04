"""Tool registry.

Each module in this package exposes a `register(mcp)` function that
attaches its tools to the FastMCP instance. New tool categories should
be added to the imports below.
"""
from mcp.server.fastmcp import FastMCP

from . import components, materials, ruby, scene, transforms


def register(mcp: FastMCP) -> None:
    for module in (ruby, scene, components, transforms, materials):
        module.register(mcp)
