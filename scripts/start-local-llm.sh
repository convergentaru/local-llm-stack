#!/usr/bin/env bash
set -Eeuo pipefail

# Manually start the existing Local LLM Stack user services.
# Services remain installed; this script does not install/remove packages.
SWAP_SERVICE="llama-swap.service"
LITELLM_SERVICE="litellm.service"

for service in "$SWAP_SERVICE" "$LITELLM_SERVICE"; do
  if ! systemctl --user cat "$service" >/dev/null 2>&1; then
    echo "ERROR: user service not found: $service" >&2
    echo "Check names with: systemctl --user list-unit-files" >&2
    exit 1
  fi
done

wait_for_port() {
  local port="$1" label="$2" timeout_seconds="$3"
  local elapsed=0
  printf 'Waiting for %s (port %s)' "$label" "$port"
  while (( elapsed < timeout_seconds )); do
    if (echo >"/dev/tcp/127.0.0.1/$port") >/dev/null 2>&1; then
      echo " — ready."
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
    printf '.'
  done
  echo
  echo "ERROR: $label did not open port $port within ${timeout_seconds}s." >&2
  return 1
}

echo "Starting llama-swap..."
systemctl --user start "$SWAP_SERVICE"
if ! wait_for_port 8080 "llama-swap" 600; then
  systemctl --user --no-pager --full status "$SWAP_SERVICE" || true
  exit 1
fi

echo "Starting LiteLLM..."
systemctl --user start "$LITELLM_SERVICE"
if ! wait_for_port 4000 "LiteLLM" 180; then
  systemctl --user --no-pager --full status "$LITELLM_SERVICE" || true
  exit 1
fi

echo
echo "Local LLM Stack is running."
echo "  llama-swap: http://127.0.0.1:8080"
echo "  LiteLLM:    http://127.0.0.1:4000"
systemctl --user --no-pager --full status "$SWAP_SERVICE" "$LITELLM_SERVICE" || true
