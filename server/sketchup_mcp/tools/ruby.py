from mcp.server.fastmcp import FastMCP

from .. import connection


def register(mcp: FastMCP) -> None:
    @mcp.tool()
    def eval_ruby(code: str, timeout: int = 30) -> dict:
        """Evaluate arbitrary Ruby code inside SketchUp.

        - `timeout`: max seconds the code may run (default 30). A runaway
          loop would otherwise freeze SketchUp's UI thread permanently.

        Returns a dict with `success` and either `result` (Ruby `inspect`
        of the value) or `error` (the exception message).
        """
        try:
            return connection.send("eval_ruby", {"code": code, "timeout": timeout})
        except connection.SketchUpError as e:
            return {"success": False, "error": str(e)}
