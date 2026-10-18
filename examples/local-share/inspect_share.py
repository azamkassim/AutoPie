"""Inspect explicitly shared text locally using only the Python standard library."""
import json
import os
import re
import sys
from urllib.parse import urlsplit

MAX_CHARS = 65536


def inspect_text(text):
    if len(text) > MAX_CHARS:
        raise ValueError("Input exceeds 65,536 characters. Share a smaller selection.")
    normalized = text.replace("\r\n", "\n").replace("\r", "\n").strip()
    links = []
    seen = set()
    for match in re.finditer(r"https?://[^\s<>\"']+", normalized, re.IGNORECASE):
        url = match.group().rstrip(".,;!?")
        # Remove sentence-closing brackets while retaining balanced URL brackets.
        for left, right in (("(", ")"), ("[", "]"), ("{", "}")):
            while url.endswith(right) and url.count(right) > url.count(left):
                url = url[:-1]
        try:
            parsed = urlsplit(url)
            host = parsed.hostname
            parsed.port  # Reject malformed ports.
        except ValueError:
            continue
        if host and not parsed.username and not parsed.password and url not in seen:
            seen.add(url)
            links.append({"url": url, "host": host.lower()})
    return {
        "status": "ok" if normalized else "empty",
        "characters": len(normalized),
        "lines": len(normalized.splitlines()),
        "words": len(normalized.split()),
        "links": links,
        "network_used": False,
    }


def main():
    # Never read shared file paths or execute input. Prefer the text supplied by Android.
    text = os.environ.get("INPUT_TEXT") or os.environ.get("INPUT_URL") or os.environ.get("INPUT", "")
    try:
        result = inspect_text(text)
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return 1
    print("#@AUTOPIE " + json.dumps({"type": "output", "value": result}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
