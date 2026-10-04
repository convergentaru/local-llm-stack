#!/usr/bin/env bash
set -euo pipefail

MODEL="$1"
CTX="$2"
PORT="$3"
ALIAS="$4"

LLAMA="$HOME/llama.cpp/build-cublas/bin"

echo "========================================"
echo "Model:   $ALIAS"
echo "Context: $CTX"
echo "Port:    $PORT"
echo "========================================"

exec "$LLAMA/llama-server" \
  -m "$MODEL" \
  -c "$CTX" \
  -ngl 21 \
  --flash-attn on \
  --jinja \
  --reasoning off \
  --no-reasoning-preserve \
  --parallel 1 \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --cache-ram 0 \
  --no-cache-idle-slots \
  --alias "$ALIAS" \
  --host 127.0.0.1 \
  --port "$PORT"
