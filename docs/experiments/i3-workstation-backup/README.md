# Ubuntu i3 + Polybar workstation — baseline snapshot

**Status:** operational notes recorded from the working session; this is not yet a byte-for-byte backup of the machine's configuration files.

This document records the settings confirmed during the October 2026 workstation setup. The exact live files must still be copied from the machine by the local JARVIS/OpenCode session before this folder can be treated as a complete restore backup.

## Environment

- Ubuntu Linux, X11, i3 window manager.
- NVIDIA GeForce RTX 3060 with 12 GB VRAM; system RAM 12 GB.
- Polybar is used instead of the built-in i3bar.
- Two active displays.
- Keyboard layouts: US and Russian, toggled with Alt+Shift.

## Confirmed i3 settings

The following lines were added to the user's i3 configuration and passed `i3 -C` validation:

```i3
exec --no-startup-id setxkbmap -layout 'us,ru' -option 'grp:alt_shift_toggle'
exec --no-startup-id sh -c "pgrep -x polybar >/dev/null || polybar -c ~/.config/polybar/config.ini example"
```

The original i3 `bar { ... }` block was commented out so that the built-in bar would not compete with Polybar. A backup was created locally at:

```text
~/.config/i3/config.bak-disable-i3bar
~/.config/i3/config.bak-polybar-autostart
```

These local backup files have **not** been copied into this GitHub repository by this commit.

## Confirmed Polybar configuration

- User configuration path: `~/.config/polybar/config.ini`
- It was copied from `/etc/polybar/config.ini` and then modified.
- Relevant settings:
  - `position = top`
  - `wm-restack = i3`
  - `modules-right = systray filesystem pulseaudio xkeyboard memory cpu wlan eth date`
- The active launch command was:

```bash
polybar -c "$HOME/.config/polybar/config.ini" example
```

At the last check, only one Polybar process was present. Some non-fatal log warnings were seen (systray selection, root pixmap, and unavailable WLAN interface); review them on the target machine before troubleshooting.

## Confirmed monitor layout

The last working arrangement placed the primary 1920×1080 HDMI-0 display on the left and the 1024×768 DP-0 display on the right:

```bash
xrandr --output HDMI-0 --mode 1920x1080 --pos 0x0 --primary --output DP-0 --mode 1024x768 --pos 1920x0
```

This command was applied successfully during the session, but persistence across logins/reboots has not yet been verified.

## Safe inspection commands

Run these locally to capture the current state before making any changes:

```bash
i3 -C
xrandr --query
pgrep -a 'i3bar|polybar'
sed -n '1,240p' ~/.config/i3/config
sed -n '1,260p' ~/.config/polybar/config.ini
```

Inspect the output before sharing it publicly. Redact tokens, private paths, usernames or other personal data if present.

## Recovery guidance

1. Back up the current files before replacing anything.
2. Restore only the configuration file that was intentionally changed.
3. Validate i3 syntax with `i3 -C` before reloading i3.
4. Test monitor layout separately with `xrandr --query`; do not assume connector names or modes are identical on another machine.
5. Start Polybar manually and inspect its log before changing autostart settings.
6. Do not blindly overwrite live configuration with the excerpts in this document: they are verified snippets, not a complete config.

## Follow-up required for a complete backup

The local machine must supply sanitized, exact copies of:

- `~/.config/i3/config`
- `~/.config/polybar/config.ini`

Also record the current Git state, actual display output, and any required user-level startup configuration. Do not publish secrets or unrelated personal data. Keep original files untouched and do not apply settings automatically.
