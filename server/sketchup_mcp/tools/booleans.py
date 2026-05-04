from typing import Literal

from mcp.server.fastmcp import FastMCP

from .. import connection

BooleanOp = Literal["union", "subtract", "difference", "intersect", "intersection"]


def register(mcp: FastMCP) -> None:
    @mcp.tool()
    def boolean_operation(operation: BooleanOp, target_id: int, tool_id: int) -> dict:
        """Perform a solid boolean operation between two groups/components.

        - `union`: combine the two solids into one
        - `subtract` (alias `difference`): remove `tool_id` from `target_id`
        - `intersect` (alias `intersection`): keep only the overlap

        Both inputs are consumed and replaced by the result. The
        returned `id` refers to the resulting group.
        """
        return connection.send("boolean_operation", {
            "operation": operation,
            "target_id": target_id,
            "tool_id": tool_id,
        })
