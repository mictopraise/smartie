#!/usr/bin/env bash
set -euo pipefail

MODEL_DIR="model"
MODEL_PATH="$MODEL_DIR/qwen2.5-1.5b-instruct-q4_k_m.gguf"
MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf?download=true"

mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_PATH" ] && [ "$(head -c 4 "$MODEL_PATH")" = "GGUF" ]; then
  echo "Model already present and has a GGUF header: $MODEL_PATH"
  exit 0
fi

rm -f "$MODEL_PATH.part"
echo "Downloading the public model (approximately 1.12 GB)..."
curl --fail --location --retry 3 --retry-delay 2 \
  --output "$MODEL_PATH.part" "$MODEL_URL"

if [ "$(head -c 4 "$MODEL_PATH.part")" != "GGUF" ]; then
  echo "Downloaded file does not have a GGUF header." >&2
  rm -f "$MODEL_PATH.part"
  exit 1
fi

mv "$MODEL_PATH.part" "$MODEL_PATH"
echo "Ready: $MODEL_PATH"


