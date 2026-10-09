#!/usr/bin/env bash
set -Eeuo pipefail

# Stop the existing Local LLM Stack user services without removing them.
# LiteLLM is stopped first; llama-swap is stopped second so managed model
# server processes can be cleaned up by their service manager.

echo "Stopping LiteLLM..."
systemctl --user stop litellm.service || echo "WARNING: LiteLLM stop returned an error." >&2

echo "Stopping llama-swap and its managed model servers..."
systemctl --user stop llama-swap.service || echo "WARNING: llama-swap stop returned an error." >&2

echo
echo "Service states:"
systemctl --user --no-pager --full status litellm.service llama-swap.service || true

echo
echo "Port check:"
for port in 4000 8080; do
  if ss -ltnH "sport = :$port" 2>/dev/null | grep -q .; then
    echo "WARNING: port $port still has a listener:"
    ss -ltnp "sport = :$port" || true
  else
    echo "Port $port: no listener detected."
  fi
done

echo
echo "Stack services have been asked to stop."
echo "For remaining GPU memory usage, inspect: nvidia-smi"
