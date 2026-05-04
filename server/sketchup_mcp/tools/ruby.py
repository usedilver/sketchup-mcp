from mcp.server.fastmcp import FastMCP

from .. import connection


def register(mcp: FastMCP) -> None:
    @mcp.tool()
    def eval_ruby(code: str) -> dict:
        """Evaluate arbitrary Ruby code inside SketchUp.

        Returns a dict with `success` and either `result` (Ruby `inspect`
        of the value) or `error` (the exception message).
        """
        try:
            return connection.send("eval_ruby", {"code": code})
        except connection.SketchUpError as e:
            return {"success": False, "error": str(e)}
