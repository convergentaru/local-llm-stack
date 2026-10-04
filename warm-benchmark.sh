#!/usr/bin/env bash
set -u

LITELLM="http://127.0.0.1:4000"
STACK_DIR="$HOME/local-llm-stack"

if [ -f "$STACK_DIR/.env" ]; then
    ENV_FILE="$STACK_DIR/.env"
elif [ -f "$STACK_DIR/litellm/.env" ]; then
    ENV_FILE="$STACK_DIR/litellm/.env"
else
    echo "ERROR: LiteLLM .env not found"
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

echo "============================================================"
echo "        LOCAL LLM STACK — WARM BENCHMARK"
echo "============================================================"
echo
echo "First request = warm-up"
echo "Second request = measured warm inference"
echo

test_model() {
    local model="$1"

    echo "----- $model -----"

    # First request: warm-up / model loading
    echo "  Warm-up..."

    local warmup
    warmup="$(
        curl -sS \
            --max-time 180 \
            -o /tmp/warm-benchmark-warmup.json \
            -w '%{http_code}' \
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
                \"max_tokens\": 16,
                \"temperature\": 0
            }"
    )"

    if [ "$warmup" != "200" ]; then
        echo "  ✗ Warm-up failed: HTTP $warmup"
        echo
        return 1
    fi

    echo "  ✓ Warm-up complete"

    # Second request: measured warm inference
    echo "  Measuring warm inference..."

    local result
    result="$(
        curl -sS \
            --max-time 120 \
            -w $'\nHTTP_STATUS:%{http_code}\nTIME_TOTAL:%{time_total}' \
            -H "Authorization: Bearer $MASTER_KEY" \
            -H "Content-Type: application/json" \
            "$LITELLM/v1/chat/completions" \
            -d "{
                \"model\": \"$model\",
                \"messages\": [
                    {
                        \"role\": \"user\",
                        \"content\": \"Ответь одним словом: готов?\"
                    }
                ],
                \"max_tokens\": 16,
                \"temperature\": 0
            }"
    )"

    local http
    local time_total

    http="$(
        printf '%s\n' "$result" |
        sed -n 's/^HTTP_STATUS://p'
    )"

    time_total="$(
        printf '%s\n' "$result" |
        sed -n 's/^TIME_TOTAL://p'
    )"

    if [ "$http" = "200" ]; then
        echo "  ✓ HTTP 200"
        echo "  Warm inference: ${time_total} s"
    else
        echo "  ✗ HTTP $http"
    fi

    echo
}

test_model "qwen3.5-4b"
test_model "ministral-3b"
test_model "ministral-8b"
test_model "deepseek-r1-7b"

echo "============================================================"
echo "WARM BENCHMARK COMPLETE"
echo "============================================================"
