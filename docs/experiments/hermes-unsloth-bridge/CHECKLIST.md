# Hermes + Unsloth Studio connection checklist

Use this checklist for architecture variant B only:
Hermes → Unsloth Studio OpenAI-compatible API → locally served model.

- [ ] Confirm Unsloth Studio is open and the intended model is loaded.
- [ ] Run the read-only endpoint check:
      `curl -sS --max-time 3 http://127.0.0.1:48955/v1/models`
- [ ] Record the actual model ID returned by `/v1/models` (do not guess).
- [ ] Confirm Hermes `model.base_url` matches the actual server URL.
- [ ] Confirm Hermes `model.default` matches the model ID expected by the API.
- [ ] Confirm the API mode is compatible with the server's chat-completions API.
- [ ] Test a minimal API chat-completions request.
- [ ] Test a simple prompt in Hermes.
- [ ] Confirm the “Provider temporarily unavailable” retries stop.
- [ ] Document the verified endpoint, model ID, and test result here.

## Current snapshot (2026-10-10)

- Hermes provider: `custom`
- Hermes model ID configured: `ministral-8b` (not yet verified against API)
- Base URL configured: `http://127.0.0.1:48955/v1`
- API mode: `chat_completions`
- Endpoint reachability: **unknown / test pending**
- Hermes request success: **not yet confirmed**
- Error observed: `Provider temporarily unavailable`

Do not paste API keys into this file or into GitHub.
