#!/usr/bin/env bash
set -euo pipefail

MODEL="/home/oleg/models/Qwen3.6-35B-A3B-UD-IQ2_XXS.gguf"
LLAMA_SERVER="/home/oleg/llama.cpp/build-cublas/bin/llama-server"

exec "$LLAMA_SERVER" \
  -m "$MODEL" \
  -c 4096 \
  -ngl 999 \
  --flash-attn on \
  --jinja \
  --host 127.0.0.1 \
  --port 8999 \
  --alias qwen3.6-35b-experiment
