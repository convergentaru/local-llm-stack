# Hermes + Unsloth Studio connection checklist

Use this checklist for architecture variant B only:
Hermes → Unsloth Studio API → model served by Unsloth Studio.

- [x] Confirm Unsloth Studio process is running.
- [x] Identify the active Studio API process and port from process/socket output.
- [ ] Determine which endpoint is intended for OpenAI-compatible client requests.
- [ ] Check `/v1/models` on the verified endpoint.
- [ ] Record the actual model ID returned by the API.
- [ ] Align Hermes `model.base_url` and `model.default` with verified values.
- [ ] Test a minimal API chat-completions request.
- [ ] Test a simple prompt in Hermes.
- [ ] Confirm the “Provider temporarily unavailable” retries stop.

## Current snapshot (2026-10-10)

Hermes configuration in `~/.hermes/config.yaml`:
- Provider: `custom`
- Configured model ID: `ministral-8b` (not yet verified against API)
- Configured base URL: `http://127.0.0.1:48955/v1`
- API mode: `chat_completions`

Observed processes and listening ports:
- Unsloth Studio launcher: `/usr/bin/unsloth-studio` (PID 42654)
- Studio API process: `unsloth studio --api-only -H 127.0.0.1 -p 8888` (PID 43041)
- Studio API port: `127.0.0.1:8888` is listening
- Model server: `llama-server` on `127.0.0.1:34559`
- Model server alias: `ministral-3-8b`
- Model file: `/home/oleg/models/ministral-3-8b/Ministral-3-8B-Instruct-2512-Q4_K_M.gguf`
- `127.0.0.1:48955`: connection refused

Important: port 8888 belongs to the Studio API-only process, while 34559 belongs to the underlying llama-server. Do not change Hermes to either port until the expected OpenAI-compatible route is verified by a read-only `/v1/models` request. No services were started or stopped during this diagnostic.

Do not paste API keys into this file or into GitHub.
