from mcp.server.fastmcp import FastMCP

from .. import connection


def register(mcp: FastMCP) -> None:
    @mcp.tool()
    def create_mortise_tenon(
        mortise_id: int,
        tenon_id: int,
        width: float = 1.0,
        height: float = 1.0,
        depth: float = 1.0,
        offset_x: float = 0.0,
        offset_y: float = 0.0,
        offset_z: float = 0.0,
    ) -> dict:
        """Cut a mortise pocket in one board and extrude a matching tenon
        on another. The face on each board is auto-detected as the one
        closest to the other board."""
        return connection.send("create_mortise_tenon", {
            "mortise_id": mortise_id, "tenon_id": tenon_id,
            "width": width, "height": height, "depth": depth,
            "offset_x": offset_x, "offset_y": offset_y, "offset_z": offset_z,
        })

    @mcp.tool()
    def create_dovetail(
        tail_id: int,
        pin_id: int,
        width: float = 1.0,
        height: float = 2.0,
        depth: float = 1.0,
        angle: float = 15.0,
        num_tails: int = 3,
        offset_x: float = 0.0,
        offset_y: float = 0.0,
        offset_z: float = 0.0,
    ) -> dict:
        """Build dovetail tails on one board and matching pin cutouts on
        another. `angle` is the dovetail flare in degrees."""
        return connection.send("create_dovetail", {
            "tail_id": tail_id, "pin_id": pin_id,
            "width": width, "height": height, "depth": depth,
            "angle": angle, "num_tails": num_tails,
            "offset_x": offset_x, "offset_y": offset_y, "offset_z": offset_z,
        })

    @mcp.tool()
    def create_finger_joint(
        board1_id: int,
        board2_id: int,
        width: float = 1.0,
        height: float = 2.0,
        depth: float = 1.0,
        num_fingers: int = 5,
        offset_x: float = 0.0,
        offset_y: float = 0.0,
        offset_z: float = 0.0,
    ) -> dict:
        """Build a box/finger joint: alternating fingers on board1 and
        matching slots on board2."""
        return connection.send("create_finger_joint", {
            "board1_id": board1_id, "board2_id": board2_id,
            "width": width, "height": height, "depth": depth,
            "num_fingers": num_fingers,
            "offset_x": offset_x, "offset_y": offset_y, "offset_z": offset_z,
        })
