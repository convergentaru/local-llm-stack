#!/usr/bin/env bash
set -u

BASE="http://127.0.0.1"
LITELLM="$BASE:4000"
SWAP="$BASE:8080"

STACK_DIR="$HOME/local-llm-stack"

if [ -f "$STACK_DIR/litellm/.env.gateway" ]; then
    ENV_FILE="$STACK_DIR/litellm/.env.gateway"
elif [ -f "$STACK_DIR/.env" ]; then
    ENV_FILE="$STACK_DIR/.env"
elif [ -f "$STACK_DIR/litellm/.env" ]; then
    ENV_FILE="$STACK_DIR/litellm/.env"
else
    echo "ERROR: LiteLLM environment file not found"
    exit 1
fi

MASTER_KEY="$(
    grep '^LITELLM_MASTER_KEY=' "$ENV_FILE" |
    cut -d= -f2-
)"

if [ -z "$MASTER_KEY" ]; then
    echo "ERROR: LITELLM_MASTER_KEY is empty"
    exit 1
fi

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
echo "        LOCAL LLM STACK — FULL INFERENCE TEST"
echo "============================================================"
echo

echo "========== 1. SERVICES =========="

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
echo "========== 2. LLAMA-SWAP =========="

if curl -fsS --max-time 5 \
    "$SWAP/v1/models" >/tmp/full-test-swap.json 2>/dev/null; then
    ok "llama-swap :8080 reachable"
else
    fail "llama-swap :8080 unreachable"
fi

echo
echo "========== 3. LITELLM =========="

if curl -fsS --max-time 5 \
    "$LITELLM/health/readiness" >/dev/null 2>&1; then
    ok "LiteLLM :4000 ready"
else
    fail "LiteLLM :4000 not ready"
fi

echo
echo "========== 4. MODEL INFERENCE =========="

test_model() {
    local model="$1"

    echo
    echo "----- $model -----"

    local start
    local end
    local elapsed
    local response
    local http
    local content

    start="$(python3 -c "import time; print(time.monotonic_ns())")"

    response="$(
        curl -sS \
            --max-time 180 \
            -w $'\nHTTP_STATUS:%{http_code}' \
            -H "Authorization: Bearer $MASTER_KEY" \
            -H "Content-Type: application/json" \
            "$LITELLM/v1/chat/completions" \
            -d "{
                \"model\": \"$model\",
                \"messages\": [
                    {
                        \"role\": \"user\",
                        \"content\": \"Ответь одним словом: работает?\"
                    }
                ],
                \"max_tokens\": 32,
                \"temperature\": 0
            }"
    )"

    end="$(python3 -c "import time; print(time.monotonic_ns())")"
    elapsed="$(((end - start) / 1000000))"

    http="$(
        printf '%s\n' "$response" |
        sed -n 's/^HTTP_STATUS://p'
    )"

    if [ "$http" = "200" ]; then
        content="$(
            printf '%s\n' "$response" |
            sed '/^HTTP_STATUS:/d' |
            python3 -c '
import json,sys

try:
    d=json.load(sys.stdin)
    message=d["choices"][0]["message"]
    content=message.get("content","")
    reasoning=message.get("reasoning_content","")

    if content:
        print(content.replace("\n"," ")[:300])
    elif reasoning:
        print("[reasoning-only response]")
        print(reasoning.replace("\n"," ")[:300])
    else:
        print("[empty response]")

except Exception as e:
    print("[parse error]", e)
'
        )"

        ok "$model → HTTP 200 (${elapsed} ms)"
        echo "  Response: $content"

    else
        fail "$model → HTTP $http (${elapsed} ms)"

        printf '%s\n' "$response" |
            sed '/^HTTP_STATUS:/d' |
            tail -c 1200

        echo
    fi
}

test_model "qwen3.5-4b"
test_model "ministral-3b"
test_model "ministral-8b"
test_model "deepseek-r1-7b"

echo
echo "========== 5. RECENT LITELLM LOG ERRORS =========="

ERRORS="$(
    journalctl --user \
        -u litellm.service \
        --since "5 minutes ago" \
        --no-pager \
        2>/dev/null |
    grep -Ei \
        "ERROR|Exception|Traceback|500 Internal Server Error|Jinja Exception|SYSTEM MERGE ERROR" |
    tail -30 || true
)"

if [ -z "$ERRORS" ]; then
    ok "No recent LiteLLM errors"
else
    echo "$ERRORS"
    fail "Recent LiteLLM errors detected"
fi

echo
echo "============================================================"
echo "RESULT"
echo "============================================================"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "LOCAL LLM STACK: FULL TEST PASSED"
    exit 0
else
    echo "LOCAL LLM STACK: FULL TEST FAILED"
    exit 1
fi
