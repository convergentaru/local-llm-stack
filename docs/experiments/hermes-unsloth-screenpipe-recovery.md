---
id: OPS-HERMES-UNSLOTH-SCREENPIPE-001
type: runbook
status: planned
created: 2026-10-10
updated: 2026-10-10
tags: [hermes, unsloth, screenpipe, browser-skill, recovery, local-llm]
---

# Recovery plan: Hermes + Unsloth + BrowserSkill + Screenpipe

## Goal

Restore one understandable local workflow on Ubuntu. Hermes is the agent/tool layer; Unsloth Studio serves the local model; BrowserSkill provides browser automation; Screenpipe supplies local computer-activity history through CLI/API and agent integration.

```text
Hermes Agent/Desktop
 ├─ BrowserSkill → browser automation
 ├─ Screenpipe CLI/API → local activity history/search
 └─ Hermes tools / approved integrations
          ↓ OpenAI-compatible API
Unsloth Studio → ministral-3-8b
```

For this experiment, Hermes must connect directly to Unsloth: **no Nous Portal and no LiteLLM in between**. This does not mean removing LiteLLM or llama-swap from other projects; they are simply outside this connection path.

## Confirmed state on 2026-10-10

### Hermes

- The former Hermes Agent was removed with `hermes uninstall --full`.
- Post-uninstall checks confirmed that `hermes` is not in PATH and the old `~/.hermes`, `~/.config/Hermes`, and desktop launcher are gone.
- A fresh install has **not yet been run**. Next step: install using the official Linux installer, then verify `hermes --version`.
- Do not choose Nous Portal or import the old backup.

### Local-only backups (do not publish the archives)

Three backups exist in the user's home directory:

- `hermes-backup-20261010-231625.tar.gz` (~2.1 GB): readable, but tar warned the source directory changed while archiving and skipped Unix sockets. Treat as an extra fallback, not a guaranteed consistent snapshot.
- `hermes-backup-20261010-232501.zip` (~8.6 MB): official Hermes backup with 630 files; `unzip -t` passed. It contains config/auth, sessions, skills and data. **Do not import it wholesale** because that can restore obsolete provider settings and authentication.
- `screenpipe-data-backup-20261010-233848.tar.gz` (~432 KB): verified archive of `~/.screenpipe`.

Never publish the archives, API keys, tokens, cookies, `auth.json`, or `.env` files.

### BrowserSkill and Screenpipe

- The Hermes ZIP contains `skills/browser-skill/` and these Screenpipe-related skills: `screenpipe-cli`, `screenpipe-meeting-prep`, `screenpipe-durable-learning`, `screenpipe-focus-review`, `screenpipe-research-synthesis`.
- The existing `~/.screenpipe` contains SQLite database files (`db.sqlite`, `db.sqlite-wal`, `db.sqlite-shm`), `secrets.sqlite`, logs, and supporting state. A separate data backup was made.
- At the last check, no Screenpipe process was running, ports 3030–3032 were not listening, and no Snap/Flatpak/dpkg package, desktop launcher, or user systemd unit was found.
- Node.js and `npx` are installed. Screenpipe CLI `0.4.52` was found in the local npm cache at `~/.npm/_npx/.../node_modules/screenpipe`. This proves the cached package exists, not how it was originally launched.
- **Do not remove `~/.screenpipe`, delete the WAL file, or start new capture before checking the CLI's data directory and privacy settings.** SQLite WAL may contain changes not yet checkpointed into the main database.

## Ordered recovery plan

### 1. Fresh Hermes install

Use the official Nous Research Linux installer:

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

Then run `source ~/.bashrc`, `hash -r`, and `hermes --version`. Do not run `hermes setup --portal`. Start/build Desktop only after the CLI check. The CLI agent and Desktop can share state; do not infer there are two separate installations merely because there are two menu entries.

Docs:
- [Hermes installation](https://hermes-agent.nousresearch.com/docs/getting-started/installation/)
- [Hermes Desktop](https://hermes-agent.nousresearch.com/docs/user-guide/desktop)

### 2. Connect Hermes directly to Unsloth

1. Start Unsloth Studio, load the target model, and verify `GET http://127.0.0.1:8888/v1/models` returns the exact model ID `ministral-3-8b` (use the actual JSON spelling if it differs).
2. Inspect the installed CLI before selecting the connection path:
   ```bash
   unsloth --version
   unsloth start hermes --help
   unsloth run --help
   ```
3. Current Unsloth docs recommend `unsloth start hermes`. This may use a separate managed Hermes home; docs say use `--persist` from first launch and again on later launches when retaining sessions. Do not assume the older `--app` option still exists: use it only if local help confirms it.
4. For a long-lived Desktop, choose **one** verified path: (a) app integration via `unsloth start hermes --app` if supported in this installed version; or (b) a Custom OpenAI-compatible endpoint in Hermes at `http://127.0.0.1:8888/v1` with a newly generated Unsloth API key. Do not set up both blindly.
5. Do not put keys into Git, this public documentation, shell command history, or Obsidian. Use a new key from Unsloth.
6. Confirm the selected model and send a small test request. Adding a provider does not necessarily change the Desktop's default model.

Docs:
- [Unsloth + Hermes](https://unsloth.ai/docs/integrations/hermes-agent.md)
- [Unsloth Start reference](https://unsloth.ai/docs/integrations/unsloth-start.md)
- [Unsloth API](https://unsloth.ai/docs/basics/api.md)
- [Hermes provider configuration](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/integrations/providers.md)

### 3. Requested context 64K and Q8 KV cache

Desired settings, if they fit the selected model and memory budget:

- Context length: `65536` tokens (64K).
- KV cache K: `q8_0`.
- KV cache V: `q8_0`.

**These are not all one “Q8-4” switch.** `q8_0` for KV cache is separate from quantization of model weights. If the intent is Q4 weights plus Q8 KV cache, pick a Q4 weights variant in the model selection and configure K/V cache separately.

The llama.cpp server parameter names are:

```text
-c 65536
--cache-type-k q8_0
--cache-type-v q8_0
```

Current Unsloth Start documentation supports `--context-length` when it launches/reconciles a model. The documented flag list does not promise that `--cache-type-k/v` are Unsloth Start options. Therefore, **do not blindly paste llama-server flags into the Hermes command**. They configure the model server, not Hermes itself. First inspect `unsloth run --help`; use the supported Unsloth server-launch path, then confirm the actual llama-server command/logs show context 65536 and K/V `q8_0` with no later context auto-reduction.

Unsloth documents `--disable-tools` for a server used by Hermes or another external agent so the server-side tools do not swallow agent tool calls. Only add it when using the corresponding `unsloth run` server path and after confirming local CLI help.

The machine has an RTX 3060 with 12 GB VRAM. Context 64K is a target, not a guarantee: model weights and KV cache may exceed available VRAM, and Unsloth may lower context or use host RAM. Record the effective context, VRAM/RAM usage, speed and stability from logs rather than trusting the UI field alone.

Docs:
- [Unsloth Start options](https://unsloth.ai/docs/integrations/unsloth-start.md)
- [llama.cpp server options](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md)

### 4. Restore only needed skills

Use the Hermes ZIP as a source for selected directories only:

- `skills/browser-skill/`
- `skills/screenpipe-cli/`
- `skills/screenpipe-meeting-prep/`
- `skills/screenpipe-durable-learning/`
- `skills/screenpipe-focus-review/`
- `skills/screenpipe-research-synthesis/`

Do **not** run `hermes import` on the whole archive. Do not restore `config.yaml`, `.env`, `auth.json`, old model/provider settings, sessions or Desktop application data. After selective extraction to the new Hermes home, check paths and `SKILL.md` files, then verify that Hermes lists the skills. Skill files alone do not prove the integration works.

### 5. Restore Screenpipe in CLI-only mode

1. Read the restored `screenpipe-cli/SKILL.md` and inspect the saved CLI `0.4.52` help without starting capture.
2. Verify which directory the installed version expects for data. Preserve the existing `~/.screenpipe` directory and its separate backup.
3. Prefer the cached package if it runs and its dependencies are intact. Avoid an automatic upgrade until its migration and storage behavior are understood.
4. Screenpipe supports a `screenpipe record` CLI command (commonly `npx screenpipe record`) and some versions support a setup command for agent integrations. Use the exact command shown by the locally installed version's `--help`; do not assume commands match across versions.
5. Check privacy/storage settings before enabling recording. Then test capture, recent search, and the local API if available. The goal is CLI-only capture controlled/queried by agents; no Desktop GUI is required for this phase.
6. Give Hermes read/search access through the restored skill and/or MCP first. Avoid broad write/delete rights over Screenpipe's database.

Project: [Screenpipe](https://github.com/screenpipe/screenpipe)

### 6. BrowserSkill smoke test

On a harmless test page: connect → navigate → take a page snapshot → locate an element → perform a safe click/type → return a result to Hermes. Do not begin with ChatGPT, financial websites, or irreversible actions.

### 7. Acceptance checklist

- [ ] Fresh `hermes --version` confirmed.
- [ ] One known Hermes CLI/Desktop setup; selected model source is understood.
- [ ] Nous Portal is not selected or required.
- [ ] Hermes connects directly to `127.0.0.1:8888/v1`; LiteLLM is not in this path.
- [ ] `/v1/models` reports the exact intended Ministral model ID.
- [ ] A new Hermes request succeeds through Unsloth.
- [ ] Effective context and both KV-cache types are verified from server logs if supported.
- [ ] BrowserSkill passes its safe smoke test.
- [ ] Screenpipe runs in CLI-only mode against the intended data directory, with local capture/search verified.
- [ ] All backup archives remain local and intact.

## Do not do

- Do not publish backups, keys, tokens, cookies, `auth.json` or `.env`.
- Do not restore the full Hermes archive.
- Do not re-enable Nous Portal or put LiteLLM between Hermes and Unsloth for this experiment.
- Do not delete Screenpipe's database/WAL or run migrations without a backup.
- Do not claim 64K/Q8 works until launch logs confirm the effective settings.
- Do not enable Screenpipe recording before checking privacy and storage.

## Continuation note

**Next action:** install Hermes from the official installer, verify the new CLI version, and do not select Nous Portal. Then confirm the Unsloth model endpoint and choose the Desktop connection path based on installed CLI help. Continue with server context/KV settings, selective skill restoration, Screenpipe CLI recovery, and the browser smoke test.

Work one step at a time. Record the actual command, version, result and any caveats after each stage.
