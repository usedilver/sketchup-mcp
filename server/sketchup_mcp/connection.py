"""TCP client that talks JSON-RPC to the SketchUp extension.

Each `send` opens a fresh connection. This is intentional: SketchUp's
extension closes the socket after every response, and a long-lived
connection introduced subtle protocol-desync bugs in the previous
implementation. Connection cost on localhost is negligible.
"""
from __future__ import annotations

import json
import socket
from typing import Any

from . import config

RECV_TIMEOUT_SECONDS = 30.0
RECV_CHUNK_BYTES = 8192


class SketchUpError(RuntimeError):
    pass


def endpoint() -> str:
    """Return the configured SketchUp extension endpoint for messages."""
    return f"{config.host()}:{config.port()}"


def send(method: str, params: dict[str, Any] | None = None, request_id: int = 1) -> Any:
    """Send a JSON-RPC request to SketchUp and return the `result` field.

    Raises SketchUpError if SketchUp returns an error or the response
    cannot be parsed.
    """
    request = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params or {},
        "id": request_id,
    }
    payload = json.dumps(request).encode("utf-8") + b"\n"

    try:
        with socket.create_connection((config.host(), config.port()), timeout=RECV_TIMEOUT_SECONDS) as sock:
            sock.sendall(payload)
            sock.settimeout(RECV_TIMEOUT_SECONDS)
            data = _recv_json(sock)
    except (ConnectionRefusedError, TimeoutError, socket.timeout, OSError) as exc:
        raise SketchUpError(
            f"SketchUp extension is not available at {endpoint()}. "
            "Open SketchUp with the SU MCP extension enabled, then try again."
        ) from exc

    try:
        response = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SketchUpError("Invalid JSON response from SketchUp") from exc
    if "error" in response:
        err = response["error"]
        raise SketchUpError(err.get("message", "Unknown error from SketchUp"))
    return response.get("result")


def _recv_json(sock: socket.socket) -> bytes:
    """Read until the buffer parses as a complete JSON document."""
    chunks: list[bytes] = []
    while True:
        chunk = sock.recv(RECV_CHUNK_BYTES)
        if not chunk:
            if not chunks:
                raise SketchUpError("Connection closed before any data was received")
            break
        chunks.append(chunk)
        try:
            data = b"".join(chunks)
            json.loads(data.decode("utf-8"))
            return data
        except json.JSONDecodeError:
            continue
    raise SketchUpError("Incomplete JSON response from SketchUp")
