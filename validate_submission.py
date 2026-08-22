#!/usr/bin/env python3
"""Fast local checks before invoking the official profiler."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PLACEHOLDER = re.compile(r"REPLACE_|your-|example\\.com", re.IGNORECASE)


def main() -> int:
    errors: list[str] = []
    metadata_path = ROOT / "metadata.json"
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"FAIL: cannot read metadata.json: {exc}")
        return 1

    if metadata.get("domain") != "corporate_enterprise":
        errors.append("domain must be corporate_enterprise")
    if len(metadata.get("test_prompts", [])) != 2:
        errors.append("test_prompts must contain exactly two prompts")
    if PLACEHOLDER.search(metadata_path.read_text(encoding="utf-8")):
        errors.append("replace all REPLACE_WITH_* identity fields in metadata.json")
    model_rel = (metadata.get("_runtime") or {}).get("model_path")
    if not model_rel:
        errors.append("_runtime.model_path is missing")
    elif Path(model_rel).is_absolute() or ".." in Path(model_rel).parts:
        errors.append("_runtime.model_path must be a safe repository-relative path")
    elif (ROOT / model_rel).exists():
        with (ROOT / model_rel).open("rb") as handle:
            if handle.read(4) != b"GGUF":
                errors.append("model file exists but does not start with GGUF")
    else:
        print(f"NOTE: model not downloaded yet: {model_rel}")

    for required in ("REPORT.md", "download_model.sh", ".gitignore", "README.md"):
        if not (ROOT / required).is_file():
            errors.append(f"missing {required}")

    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1
    print("PASS: repository-level preflight checks completed")
    return 0


if __name__ == "__main__":
    sys.exit(main())


