# Manual Local LLM Stack controls

These scripts manage the existing **user-level systemd services** without deleting or changing their unit files.

- `start-local-llm.sh`: starts llama-swap, waits for port 8080, then starts LiteLLM and waits for port 4000.
- `stop-local-llm.sh`: stops LiteLLM first, then llama-swap, and checks the ports.

## Install into the home directory

Run on the Ubuntu computer:

```bash
curl -fL https://raw.githubusercontent.com/convergentaru/local-llm-stack/main/scripts/start-local-llm.sh -o ~/start-local-llm.sh &&
curl -fL https://raw.githubusercontent.com/convergentaru/local-llm-stack/main/scripts/stop-local-llm.sh -o ~/stop-local-llm.sh &&
chmod +x ~/start-local-llm.sh ~/stop-local-llm.sh
```

## Disable autostart and stop the stack now

After downloading, run:

```bash
systemctl --user disable llama-swap.service litellm.service
~/stop-local-llm.sh
```

Disabling prevents automatic startup at user login; it does not uninstall the services and does not prevent manual starts. The scripts still use `systemctl --user start/stop`.

## Use

```bash
~/start-local-llm.sh
~/stop-local-llm.sh
```

No sudo is required. These scripts do not kill arbitrary processes. If a port remains occupied after stopping, inspect the process shown by `ss` before taking further action.
