#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/litellm/.env.gateway"

LITELLM_URL="${LITELLM_URL:-http://127.0.0.1:4000}"
RESULTS_DIR="$ROOT_DIR/benchmark/results"

MODELS=(
    "qwen3.5-4b"
    "ministral-3b"
    "ministral-8b"
    "deepseek-r1-7b"
)

mkdir -p "$RESULTS_DIR"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: $ENV_FILE not found"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [[ -z "${LITELLM_MASTER_KEY:-}" ]]; then
    echo "ERROR: LITELLM_MASTER_KEY is not set"
    unset LITELLM_MASTER_KEY
    exit 1
fi

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
FILE_TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
RESULT_FILE="$RESULTS_DIR/benchmark-$FILE_TIMESTAMP.txt"

echo
echo "╔════════════════════════════════════════════════════════════╗"
echo "║        LOCAL LLM STACK — END-TO-END BENCHMARK             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo
echo "Time:    $TIMESTAMP"
echo "Gateway: $LITELLM_URL"
echo

printf "%-20s %-6s %-10s %-12s %-12s\n" \
    "MODEL" "HTTP" "TOTAL" "PROMPT t/s" "GEN t/s"
printf "%-20s %-6s %-10s %-12s %-12s\n" \
    "--------------------" "------" "----------" "------------" "------------"

PASS=0
FAIL=0

{
    echo "Local LLM Stack — End-to-End Benchmark"
    echo "Time: $TIMESTAMP"
    echo "Gateway: $LITELLM_URL"
    echo
    printf "%-20s %-6s %-10s %-12s %-12s %-8s\n" \
        "MODEL" "HTTP" "TOTAL" "PROMPT_TPS" "GEN_TPS" "STATUS"
} > "$RESULT_FILE"

for MODEL in "${MODELS[@]}"; do
    RESPONSE_FILE="$(mktemp)"
    HEADERS_FILE="$(mktemp)"

    START_NS="$(date +%s%N)"

    HTTP_CODE="$(
        curl -sS \
            --max-time 180 \
            -o "$RESPONSE_FILE" \
            -D "$HEADERS_FILE" \
            -w '%{http_code}' \
            -X POST \
            "$LITELLM_URL/v1/chat/completions" \
            -H "Authorization: Bearer ${LITELLM_MASTER_KEY}" \
            -H "Content-Type: application/json" \
            -d "{
                \"model\": \"$MODEL\",
                \"messages\": [
                    {
                        \"role\": \"user\",
                        \"content\": \"Ответь ровно одним словом: OK\"
                    }
                ],
                \"max_tokens\": 10,
                \"temperature\": 0
            }" \
        2>/dev/null
    )"

    END_NS="$(date +%s%N)"

    TOTAL_SEC="$(
        awk -v start="$START_NS" -v end="$END_NS" \
            'BEGIN { printf "%.3f", (end-start)/1000000000 }'
    )"

    if [[ "$HTTP_CODE" == "200" ]]; then
        PROMPT_TPS="$(
            python3 - "$RESPONSE_FILE" <<'PY2'
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as f:
        data = json.load(f)
    value = data.get("timings", {}).get("prompt_per_second")
    print(f"{float(value):.2f}" if value is not None else "n/a")
except Exception:
    print("n/a")
PY2
        )"

        GEN_TPS="$(
            python3 - "$RESPONSE_FILE" <<'PY3'
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as f:
        data = json.load(f)
    value = data.get("timings", {}).get("predicted_per_second")
    print(f"{float(value):.2f}" if value is not None else "n/a")
except Exception:
    print("n/a")
PY3
        )"

        STATUS="PASS"
        PASS=$((PASS + 1))
    else
        PROMPT_TPS="n/a"
        GEN_TPS="n/a"
        STATUS="FAIL"
        FAIL=$((FAIL + 1))
    fi

    printf "%-20s %-6s %-10s %-12s %-12s\n" \
        "$MODEL" "$HTTP_CODE" "${TOTAL_SEC}s" "$PROMPT_TPS" "$GEN_TPS"

    printf "%-20s %-6s %-10s %-12s %-12s %-8s\n" \
        "$MODEL" "$HTTP_CODE" "${TOTAL_SEC}s" "$PROMPT_TPS" "$GEN_TPS" "$STATUS" \
        >> "$RESULT_FILE"

    rm -f "$RESPONSE_FILE" "$HEADERS_FILE"

    sleep 1
done

unset LITELLM_MASTER_KEY

echo
echo "────────────────────────────────────────────────────────────"
echo "RESULT: $PASS/${#MODELS[@]} PASS"

if [[ "$FAIL" -gt 0 ]]; then
    echo "FAIL:   $FAIL"
    echo
    echo "Results saved to:"
    echo "$RESULT_FILE"
    exit 1
fi

echo "STATUS: ALL MODELS PASSED"
echo
echo "Results saved to:"
echo "$RESULT_FILE"
