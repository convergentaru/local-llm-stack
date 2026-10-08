#!/usr/bin/env bash
set -euo pipefail
APP_NAME="AI Workstation Desktop"
BACKUP_DIR="${HOME}/.local/share/ai-workstation-desktop/backups"
STATE_DIR="${HOME}/.local/share/ai-workstation-desktop"
AUTOSTART_DIR="${HOME}/.config/autostart"
PLANK_AUTOSTART="${AUTOSTART_DIR}/ai-workstation-plank.desktop"
usage(){ cat <<USAGE
${APP_NAME}
Usage: $0 install | apply | status | rollback
USAGE
}
need_user(){ [[ ${EUID} -ne 0 ]] || { echo 'ERROR: run as normal user, not root.'; exit 1; }; }
backup_file(){ local f="$1"; [[ -e "$f" ]] || return 0; mkdir -p "$BACKUP_DIR"; local safe; safe="$(echo "$f" | sed 's#^/##; s#/#__#g')"; [[ -e "$BACKUP_DIR/$safe" ]] || cp -a "$f" "$BACKUP_DIR/$safe"; }
apply_session(){
  mkdir -p "$STATE_DIR" "$AUTOSTART_DIR"
  backup_file "$HOME/.dmrc"
  cat > "$HOME/.dmrc" <<'DMRC'
[Desktop]
Session=xfce
DMRC
  chmod 600 "$HOME/.dmrc"
  if command -v xfconf-query >/dev/null 2>&1; then
    xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s false 2>/dev/null || true
  fi
  if command -v plank >/dev/null 2>&1; then
    cat > "$PLANK_AUTOSTART" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=AI Workstation Plank
Exec=plank
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
DESKTOP
  fi
  cat > "$STATE_DIR/README" <<'TXT'
AI Workstation Desktop state.
This setup does not remove GNOME.
It does not modify PAM or GNOME Keyring.
It does not modify system-wide AccountsService configuration.
TXT
}
install_setup(){
  echo "=== ${APP_NAME}: INSTALL ==="
  command -v xfce4-session >/dev/null 2>&1 || { echo 'XFCE is not installed. Install: sudo apt install xfce4 xfce4-goodies xfce4-power-manager xfce4-notifyd'; exit 1; }
  apply_session
  echo; echo 'XFCE is ready as the default desktop session.'; echo 'GNOME remains installed and available.'; echo 'GNOME Keyring/PAM were not modified.'; echo; echo 'No reboot required yet. Log out and choose Xfce Session at login.'
}
status(){
  echo '=== SESSION ==='; echo "DESKTOP=${XDG_CURRENT_DESKTOP:-}"; echo "SESSION=${XDG_SESSION_DESKTOP:-}"; echo "TYPE=${XDG_SESSION_TYPE:-}"
  echo; echo '=== DEFAULT SESSION ==='; [[ -f "$HOME/.dmrc" ]] && cat "$HOME/.dmrc" || echo '~/.dmrc: absent'
  echo; echo '=== GNOME ==='; printf 'gnome-shell: '; command -v gnome-shell >/dev/null 2>&1 && echo installed || echo missing; printf 'running: '; pgrep -x gnome-shell >/dev/null 2>&1 && echo yes || echo no
  echo; echo '=== XFCE ==='; for c in xfce4-session xfce4-panel plank; do printf '%s: ' "$c"; command -v "$c" >/dev/null 2>&1 && echo installed || echo missing; done
  echo; echo '=== MEMORY ==='; free -h
  echo; echo '=== GPU ==='; command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader || echo unavailable
  echo; echo '=== DESKTOP PROCESSES ==='; ps -eo pid,comm,%mem,rss --sort=-rss 2>/dev/null | grep -Ei 'gnome|xfce|xfwm|xfdesktop|xfce4-panel|plank|ulauncher' | head -30 || true
  echo; echo '=== LLM STACK ==='; for port in 4000 8080; do ss -ltn 2>/dev/null | grep -q ":${port} " && echo "port ${port}: LISTENING" || echo "port ${port}: not listening"; done
}
rollback(){
  echo "=== ${APP_NAME}: ROLLBACK ==="
  local backup; backup="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name '.home__*__dmrc' -print -quit 2>/dev/null || true)"
  if [[ -n "$backup" ]]; then cp -a "$backup" "$HOME/.dmrc"; echo 'Restored previous ~/.dmrc from backup.'; else printf '[Desktop]\nSession=ubuntu\n' > "$HOME/.dmrc"; chmod 600 "$HOME/.dmrc"; echo 'Set GNOME/Ubuntu session as default.'; fi
  rm -f "$PLANK_AUTOSTART"
  echo; echo 'GNOME was not removed.'; echo 'XFCE packages were not removed.'; echo 'GNOME Keyring/PAM were not modified.'; echo; cat "$HOME/.dmrc"
}
need_user
case "${1:-status}" in install) install_setup;; apply) apply_session;; status) status;; rollback) rollback;; -h|--help|help) usage;; *) usage; exit 2;; esac
