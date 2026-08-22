#!/usr/bin/env bash
set -euo pipefail

python3 validate_submission.py

if ! command -v adtc-profiler >/dev/null 2>&1; then
  echo 'adtc-profiler is missing. Install it with:' >&2
  echo 'python3 -m pip install "git+https://github.com/Africa-Deep-Tech-Foundation/adtc-profiler.git"' >&2
  exit 1
fi

adtc-profiler run \
  --submission . \
  --mode participant \
  --output submission.json \
  "$@"

echo "Profiler output written to submission.json"


