#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Local LLM Stack — installer
# ============================================================
#
# Architecture:
#   Hermes → LiteLLM :4000 → llama-swap :8080 → llama.cpp
#
# This script is intentionally a SAFE INSTALLER:
# - does not use Docker
# - preserves existing configuration
# - creates backups before modifying anything
# - validates files before restarting services
#
# ============================================================

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$REPO_ROOT/backups"

log() {
    printf '[install] %s\n' "$*"
}

warn() {
    printf '[install] WARNING: %s\n' "$*" >&2
}

die() {
    printf '[install] ERROR: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

backup_file() {
    local source="$1"
    local relative_name="${2:-$(basename -- "$source")}"

    [[ -e "$source" ]] || return 0

    if [[ -z "${BACKUP_DIR:-}" ]]; then
        die "BACKUP_DIR is not initialized"
    fi

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

    BACKUP_DIR="$BACKUP_ROOT/install-$timestamp"

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

check_dependencies() {
    log "Checking dependencies"

    local commands=(
        bash
        systemctl
        systemd-analyze
        cp
        mkdir
        dirname
        chmod
        stat
        date
        sed
        grep
        find
        curl
    )

    local command
    for command in "${commands[@]}"; do
        command -v "$command" >/dev/null 2>&1             || die "Required command not found: $command"
    done

    [[ -x "$HOME/bin/llama-swap" ]]         || die "llama-swap not found: $HOME/bin/llama-swap"

    [[ -x "$HOME/llama.cpp/build-cublas/bin/llama-server" ]]         || die "CUDA llama-server not found"

    [[ -x "$REPO_ROOT/litellm/venv/bin/litellm" ]]         || die "LiteLLM executable not found"

    log "Dependencies OK"
}

check_environment() {
    log "Checking repository environment"

    local required_files=(
        "$REPO_ROOT/llama-swap.yaml"
        "$REPO_ROOT/litellm/config.yaml"
        "$REPO_ROOT/systemd/user/llama-swap.service"
        "$REPO_ROOT/systemd/user/litellm.service"
        "$REPO_ROOT/llama-model-launcher.sh"
    )

    local file
    for file in "${required_files[@]}"; do
        [[ -f "$file" ]] || die "Required file not found: $file"
    done

    [[ -x "$REPO_ROOT/llama-model-launcher.sh" ]]         || die "Launcher is not executable: $REPO_ROOT/llama-model-launcher.sh"


    log "Repository environment OK"
}

prepare_environment() {
    log "Preparing local environment"

    local env_file="$REPO_ROOT/litellm/.env.gateway"

    if [[ -f "$env_file" ]]; then
        chmod 600 "$env_file"
        [[ "$(stat -c '%a' "$env_file")" == "600" ]] || die "Unsafe permissions on $env_file; expected 600"

        grep -qE '(^|=)(sk-change-me|change-me-with-a-random-secret)($|[[:space:]])' "$env_file"             && die "Placeholder secrets found in $env_file; replace them before installation"

        log "Existing .env.gateway preserved"
        return 0
    fi

    die "Missing $env_file; copy .env.example there and set unique secrets before installation"
}

install_llama_swap() {
    log "Installing llama-swap systemd user unit"

    local source="$REPO_ROOT/systemd/user/llama-swap.service"
    local target="$HOME/.config/systemd/user/llama-swap.service"

    [[ -f "$source" ]] || die "llama-swap unit template not found: $source"

    mkdir -p -- "$(dirname -- "$target")"

    cp -- "$source" "$target"

    systemd-analyze verify "$target"         || die "Invalid llama-swap systemd unit"

    log "llama-swap systemd unit installed"
}

install_litellm() {
    log "Installing LiteLLM systemd user unit"

    local source="$REPO_ROOT/systemd/user/litellm.service"
    local target="$HOME/.config/systemd/user/litellm.service"

    [[ -f "$source" ]] || die "LiteLLM unit template not found: $source"

    mkdir -p -- "$(dirname -- "$target")"

    cp -- "$source" "$target"

    systemd-analyze verify "$target"         || die "Invalid LiteLLM systemd unit"

    log "LiteLLM systemd unit installed"
}

validate_configuration() {
    log "Validating configuration"

    local files=(
        "$REPO_ROOT/llama-swap.yaml"
        "$REPO_ROOT/litellm/config.yaml"
        "$REPO_ROOT/litellm/.env.gateway"
        "$REPO_ROOT/systemd/user/llama-swap.service"
        "$REPO_ROOT/systemd/user/litellm.service"
    )

    local file
    for file in "${files[@]}"; do
        [[ -s "$file" ]] || die "Configuration file missing or empty: $file"
    done

    systemd-analyze verify "$REPO_ROOT/systemd/user/llama-swap.service"         || die "Invalid llama-swap unit template"

    systemd-analyze verify "$REPO_ROOT/systemd/user/litellm.service"         || die "Invalid LiteLLM unit template"

    if [[ -f "$HOME/.config/systemd/user/llama-swap.service" ]]; then
        systemd-analyze verify "$HOME/.config/systemd/user/llama-swap.service"             || die "Invalid installed llama-swap unit"
    fi

    if [[ -f "$HOME/.config/systemd/user/litellm.service" ]]; then
        systemd-analyze verify "$HOME/.config/systemd/user/litellm.service"             || die "Invalid installed LiteLLM unit"
    fi

    log "Configuration validation OK"
}

start_services() {
    log "Starting local LLM stack"

    systemctl --user daemon-reload

    systemctl --user enable llama-swap.service >/dev/null

    if systemctl --user is-active --quiet llama-swap.service; then
        log "llama-swap already active; leaving it running"
    else
        systemctl --user start llama-swap.service
    fi

    systemctl --user enable litellm.service >/dev/null

    if systemctl --user is-active --quiet litellm.service; then
        log "LiteLLM already active; leaving it running"
    else
        systemctl --user start litellm.service
    fi

    curl --fail --silent --show-error http://127.0.0.1:4000/health/readiness >/dev/null || die "LiteLLM health check failed"

    log "Local LLM stack is healthy"
}

print_summary() {
    log "Installation summary"
    printf '\n'
    printf '  llama-swap: %s\n' "$(systemctl --user is-active llama-swap.service)"
    printf '  LiteLLM:    %s\n' "$(systemctl --user is-active litellm.service)"
    printf '\n'
    printf '  llama-swap API: http://127.0.0.1:8080/v1\n'
    printf '  LiteLLM API:    http://127.0.0.1:4000/v1\n'
    printf '  Health:         http://127.0.0.1:4000/health/readiness\n'
    printf '  Config:         %s\n' "$REPO_ROOT/llama-swap.yaml"
    printf '  LiteLLM config: %s\n' "$REPO_ROOT/litellm/config.yaml"
    printf '  Backup:         %s\n' "$BACKUP_DIR"
    printf '\n'
}

main() {
    log "Local LLM Stack installer"
    log "Repository: $REPO_ROOT"

    check_dependencies
    check_environment

    init_backup_dir
    backup_existing_state

    prepare_environment
    install_llama_swap
    install_litellm
    validate_configuration
    start_services
    print_summary

    log "Installation complete."
}

main "$@"
