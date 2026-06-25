#!/usr/bin/env python3
"""Validate the canonical lesson seed JSON used by generate_content_json.py."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SEED = ROOT / "tool" / "lessons_seed.json"

if __name__ == "__main__":
    if not SEED.exists():
        raise SystemExit(
            "Missing tool/lessons_seed.json. Edit that file to change lesson content."
        )
    lessons = json.loads(SEED.read_text(encoding="utf-8"))
    print(f"Loaded {len(lessons)} lessons from {SEED}")
