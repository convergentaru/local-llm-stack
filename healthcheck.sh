#!/usr/bin/env bash
set -u

BASE="http://127.0.0.1"
SWAP="$BASE:8080"
LITELLM="$BASE:4000"

PASS=0
FAIL=0

ok() {
    echo "  ✓ $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "  ✗ $1"
    FAIL=$((FAIL + 1))
}

echo "============================================================"
echo "        LOCAL LLM STACK — HEALTH CHECK"
echo "============================================================"
echo

echo "========== SERVICES =========="

if systemctl --user is-active --quiet llama-swap.service; then
    ok "llama-swap.service active"
else
    fail "llama-swap.service inactive"
fi

if systemctl --user is-active --quiet litellm.service; then
    ok "litellm.service active"
else
    fail "litellm.service inactive"
fi

echo
echo "========== LLAMA-SWAP =========="

if curl -fsS --max-time 5 "$SWAP/v1/models" \
    >/tmp/local-llm-swap-models.json 2>/dev/null; then
    ok "llama-swap :8080 reachable"
else
    fail "llama-swap :8080 unreachable"
fi

echo
echo "Models registered in llama-swap:"

python3 - <<'PY'
import json

try:
    with open("/tmp/local-llm-swap-models.json") as f:
        data = json.load(f)

    models = [x.get("id") for x in data.get("data", [])]

    for model in models:
        print(f"  - {model}")

except Exception as e:
    print(f"  unable to read model list: {e}")
PY

echo
echo "========== LITELLM =========="

if curl -fsS --max-time 5 \
    "$LITELLM/health/readiness" >/tmp/local-llm-litellm-health 2>/dev/null; then
    ok "LiteLLM :4000 readiness"
else
    fail "LiteLLM :4000 readiness"
fi

echo
echo "========== LITELLM MODELS =========="

if [ -f "$HOME/local-llm-stack/.env" ]; then
    ENV_FILE="$HOME/local-llm-stack/.env"
elif [ -f "$HOME/local-llm-stack/litellm/.env" ]; then
    ENV_FILE="$HOME/local-llm-stack/litellm/.env"
else
    fail "No LiteLLM .env found"
    ENV_FILE=""
fi

if [ -n "$ENV_FILE" ]; then
    MASTER_KEY="$(
        grep '^LITELLM_MASTER_KEY=' "$ENV_FILE" |
        cut -d= -f2-
    )"

    if [ -n "$MASTER_KEY" ]; then
        if curl -fsS --max-time 10 \
            -H "Authorization: Bearer $MASTER_KEY" \
            "$LITELLM/v1/models" \
            >/tmp/local-llm-litellm-models.json 2>/dev/null; then

            ok "LiteLLM /v1/models"

            python3 - <<'PY'
import json

try:
    with open("/tmp/local-llm-litellm-models.json") as f:
        data = json.load(f)

    models = [x.get("id") for x in data.get("data", [])]

    print("  Models:")
    for model in models:
        print(f"    - {model}")

except Exception as e:
    print(f"  unable to read model list: {e}")
PY

        else
            fail "LiteLLM /v1/models"
        fi
    else
        fail "LITELLM_MASTER_KEY is empty"
    fi
fi

echo
echo "============================================================"
echo "RESULT"
echo "============================================================"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "LOCAL LLM STACK: HEALTHY"
    exit 0
else
    echo "LOCAL LLM STACK: NEEDS ATTENTION"
    exit 1
fi
