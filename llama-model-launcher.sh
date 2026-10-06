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

if [[ "$ALIAS" == "deepseek-r1-7b" ]]; then
  REASONING_MODE="off"
  CHAT_TEMPLATE_ARGS=(
    --chat-template-file
    "$HOME/local-llm-stack/deepseek-r1-controllable.jinja"
  )
elif [[ "$ALIAS" == "qwen3-8b" ]]; then
  REASONING_MODE="auto"
  CHAT_TEMPLATE_ARGS=()
else
  REASONING_MODE="off"
  CHAT_TEMPLATE_ARGS=()
fi

exec "$LLAMA/llama-server" \
  -m "$MODEL" \
  -c "$CTX" \
  -ngl 999 \
  --flash-attn on \
  --jinja \
  --reasoning "$REASONING_MODE" \
  --no-reasoning-preserve \
  "${CHAT_TEMPLATE_ARGS[@]}" \
  --parallel 1 \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --cache-ram 0 \
  --no-cache-idle-slots \
  --alias "$ALIAS" \
  --host 127.0.0.1 \
  --port "$PORT"
