# i3 workstation backup

Backup of the working Ubuntu i3 desktop configuration.

## Included
- i3 window manager config, including US/RU Alt+Shift layout.
- Polybar config and launcher.
- GPU temperature and VRAM status script.
- Rofi app menu theme.
- Picom, Dunst, lock, volume and brightness scripts.

## Multi-monitor setup guide

See [ARandR multi-monitor setup for i3](docs/MULTI-MONITOR-ARANDR-I3.md) for a beginner-friendly walkthrough covering monitor arrangement, applying and saving an ARandR profile, checking executable permissions, enabling i3 autostart, validating the configuration, and recovering from mistakes.

## Validation
The saved i3 config passed: `i3 -C -c desktop/i3-workstation/config/i3/config`

## Restore
From the local-llm-stack repository root, first back up ~/.config/i3, polybar, scripts, rofi, picom and dunst.
Then copy the matching directories from desktop/i3-workstation/config/ into ~/.config/.
Restore executable permissions on the shell scripts.
Run `i3 -C -c ~/.config/i3/config` before reloading i3.
Restart Polybar after restoring its configuration.

## Notes
- Polybar targets HDMI-0.
- The GPU indicator uses nvidia-smi.
- JetBrainsMono Nerd Font and Noto Color Emoji are expected.
- The wallpaper image itself is not included.
- This backup is configuration only; it excludes model weights and API keys.
