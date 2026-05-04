import os

DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 9876


def host() -> str:
    return os.getenv("SKETCHUP_HOST", DEFAULT_HOST)


def port() -> int:
    raw = os.getenv("SKETCHUP_PORT")
    if not raw:
        return DEFAULT_PORT
    try:
        value = int(raw)
    except ValueError:
        return DEFAULT_PORT
    if value < 1 or value > 65535:
        return DEFAULT_PORT
    return value
