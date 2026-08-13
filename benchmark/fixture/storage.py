"""Append-only JSONL storage layer.

Every write appends one JSON object per line to STORAGE_PATH. Nothing in
this module rewrites or truncates the file.
"""

import json
import os

from config import STORAGE_PATH


def append(record: dict) -> None:
    os.makedirs(os.path.dirname(STORAGE_PATH), exist_ok=True)
    with open(STORAGE_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(record, separators=(",", ":")) + "\n")


def scan():
    """Yield every record in write order (including tombstones)."""
    if not os.path.exists(STORAGE_PATH):
        return
    with open(STORAGE_PATH, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                yield json.loads(line)
