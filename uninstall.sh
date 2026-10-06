#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Local LLM Stack — uninstaller
# ============================================================
#
# Removes only the systemd user units installed by this project.
#
# It does NOT remove:
# - models
# - llama.cpp
# - llama-swap binary
# - LiteLLM virtualenv
# - project configuration
# - .env.gateway
# - backups
# - desktop/
#
# Existing local state is backed up before removal.
# ============================================================

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$REPO_ROOT/backups"

log() {
    printf '[uninstall] %s\n' "$*"
}

die() {
    printf '[uninstall] ERROR: %s\n' "$*" >&2
    exit 1
}

backup_file() {
    local source="$1"
    local relative_name="$2"

    [[ -e "$source" ]] || return 0

    local destination="$BACKUP_DIR/$relative_name"

    mkdir -p -- "$(dirname -- "$destination")"

    if [[ -e "$destination" ]]; then
        die "Backup destination already exists: $destination"
    fi

    cp -a -- "$source" "$destination"

    log "Backup created: $destination"
}

init_backup_dir() {
    local timestamp
    timestamp="$(date '+%Y%m%d-%H%M%S')"

    BACKUP_DIR="$BACKUP_ROOT/uninstall-$timestamp"

    if [[ -e "$BACKUP_DIR" ]]; then
        die "Backup directory already exists: $BACKUP_DIR"
    fi

    mkdir -p -- "$BACKUP_DIR"

    log "Backup directory: $BACKUP_DIR"
}

backup_existing_state() {
    log "Backing up existing local LLM stack state"

    backup_file \
        "$HOME/.config/systemd/user/llama-swap.service" \
        "systemd/user/llama-swap.service"

    backup_file \
        "$HOME/.config/systemd/user/litellm.service" \
        "systemd/user/litellm.service"

    backup_file \
        "$HOME/.config/systemd/user/litellm.service.d" \
        "systemd/user/litellm.service.d"

    backup_file \
        "$REPO_ROOT/llama-swap.yaml" \
        "config/llama-swap.yaml"

    backup_file \
        "$REPO_ROOT/litellm/config.yaml" \
        "config/litellm/config.yaml"

    backup_file \
        "$REPO_ROOT/litellm/.env.gateway" \
        "config/litellm/.env.gateway"

    log "Existing state backup complete"
}

stop_services() {
    log "Stopping local LLM stack"

    if systemctl --user is-active --quiet litellm.service; then
        systemctl --user disable --now litellm.service
    else
        systemctl --user disable litellm.service >/dev/null 2>&1 || true
    fi

    if systemctl --user is-active --quiet llama-swap.service; then
        systemctl --user disable --now llama-swap.service
    else
        systemctl --user disable llama-swap.service >/dev/null 2>&1 || true
    fi
}

unit_belongs_to_stack() {
    local unit="$1"
    local marker="$2"

    [[ -f "$unit" ]] || return 1
    grep -Fq -- "$marker" "$unit"
}

validate_units() {
    log "Validating installed systemd user units"

    local llama_unit="$HOME/.config/systemd/user/llama-swap.service"
    local litellm_unit="$HOME/.config/systemd/user/litellm.service"

    if [[ -f "$llama_unit" ]] &&
       ! unit_belongs_to_stack \
           "$llama_unit" \
           'ExecStart=%h/bin/llama-swap -config %h/local-llm-stack/llama-swap.yaml'; then
        die "Refusing to touch unexpected llama-swap.service"
    fi

    if [[ -f "$litellm_unit" ]] &&
       ! unit_belongs_to_stack \
           "$litellm_unit" \
           'ExecStart=%h/local-llm-stack/litellm/venv/bin/litellm --config %h/local-llm-stack/litellm/config.yaml'; then
        die "Refusing to touch unexpected litellm.service"
    fi

    log "Installed systemd units validated"
}

remove_units() {
    log "Removing installed systemd user units"

    local llama_unit="$HOME/.config/systemd/user/llama-swap.service"
    local litellm_unit="$HOME/.config/systemd/user/litellm.service"

    rm -f -- "$litellm_unit"
    rm -rf -- "$HOME/.config/systemd/user/litellm.service.d"
    rm -f -- "$llama_unit"

    systemctl --user daemon-reload
}

print_summary() {
    log "Uninstallation summary"
    printf '\n'
    printf '  llama-swap: %s\n' "$(systemctl --user is-active llama-swap.service 2>/dev/null || true)"
    printf '  LiteLLM:    %s\n' "$(systemctl --user is-active litellm.service 2>/dev/null || true)"
    printf '\n'
    printf '  Project:    %s\n' "$REPO_ROOT"
    printf '  Backup:     %s\n' "$BACKUP_DIR"
    printf '\n'
    printf 'Models, llama.cpp, llama-swap binary, LiteLLM venv, configuration, and secrets were preserved.\n'
}

main() {
    log "Local LLM Stack uninstaller"
    log "Repository: $REPO_ROOT"

    validate_units
    init_backup_dir
    backup_existing_state
    stop_services
    remove_units
    print_summary

    log "Uninstallation complete."
}

main "$@"
