# Network-Extended Displays for Ubuntu i3 — Research Plan

**Status:** research plan only; not installed or tested yet.

## Goal
Investigate using older Linux computers and laptops as thin-client receivers for extra display areas, so the main Ubuntu workstation can have more workspace than its physical GPU outputs alone provide.

## Current baseline (observed 2026-10-13)
- Main workstation: Ubuntu 26, i3, Xorg/X11, NVIDIA GPU.
- Session type: `x11`; X server: `/usr/bin/Xorg`; display manager: `gdm.service` (active).
- XRandR reports one provider, `NVIDIA-0`, with Source Output capability, 4 CRTCs and 7 outputs.
- X screen: `2944x1080`; reported maximum `32767x32767`.
- `HDMI-0`: connected, primary, `1920x1080+0+0`.
- `DP-0`: connected, `1024x768+1920+216`.
- `DP-1` through `DP-5`: disconnected.
- Loaded modules include `nvidia`, `nvidia_modeset`, `nvidia_drm`; `vkms` and `evdi` were not shown by `lsmod`.
- `xserver-xorg-video-dummy` is not installed. APT reports candidate `1:0.4.0-1ubuntu1` from Ubuntu Resolute `universe`.
- The working physical monitor layout is saved in `~/.screenlayout/monitors.sh` and launched by i3. Preserve it as the known-good fallback.

## Important distinction
`xrandr` configures outputs exposed by the current X server; it does not transmit video over the network. `xrandr --newmode` creates a mode, not a new output. A name such as `VIRTUAL1` must already be provided by a compatible driver or server configuration.

The Xorg `dummy` driver may create a separate virtual X screen, which is not automatically the same as adding an output to the existing NVIDIA-backed desktop. The project must prove that normal i3 windows can be moved to the remote display region before calling it a successful solution.

## Desired architecture
1. Create a virtual display/output integrated into the existing desktop.
2. Capture and transmit that display region over the local network.
3. Use an old Linux PC or laptop as a full-screen receiver/thin client.
4. Verify that windows and the pointer cross naturally between local and remote regions.
5. Only after a successful manual test, automate startup and reconnection.

## Candidate approaches to research
These are candidates, not confirmed recommendations for this exact setup:
- A maintained Linux virtual-display driver plus a network display transport, with verified Ubuntu 26, NVIDIA and Xorg compatibility.
- `xserver-xorg-video-dummy`: check whether it creates a separate X screen or an output usable by the existing desktop before installing it.
- VNC / `x11vnc`: useful for remote viewing/control, but a VNC session alone does not automatically extend the current desktop. Verify region capture and unified-desktop behavior.
- Deskreen: convenient browser receiver; verify whether the current Linux workflow creates a true extended display or only shares a screen/window.
- Xpra: useful for remote applications or sessions, but not necessarily native multi-monitor extension.
- Barrier or similar software KVM: shares mouse/keyboard between separate computers; it does not merge their desktops.
- HDMI dummy plug: may make a GPU detect a physical-looking output, but does not itself transmit video.

## Proof-of-concept phases

### Phase 1 — research only
- Read current project documentation and check maintenance and Ubuntu 26 compatibility.
- Determine exactly how the candidate exposes a display output inside the existing X server.
- Confirm NVIDIA/Xorg compatibility and whether logout, restart, or custom Xorg configuration is required.
- Assess latency, compression, resolution, refresh rate, security, and LAN requirements.
- Prefer wired Ethernet for the first test if available.

### Phase 2 — one receiver
- Use one spare Linux computer with its own monitor.
- Keep `HDMI-0` and `DP-0` unchanged.
- Back up any configuration before installation or display-server changes.
- Test one virtual display at a conservative resolution.
- Confirm: (1) the remote screen is additional, not mirrored; (2) normal windows can be dragged onto it; (3) the pointer crosses naturally.
- If any criterion fails, stop and roll back rather than layering on more tools.

### Phase 3 — persistence
Only after Phase 2 succeeds, document installation/removal, startup/reconnect, logout/login and reboot behavior, geometry, receiver address, and recovery to the known-good two-monitor setup.

### Phase 4 — scale
Add one receiver at a time. Measure network traffic and CPU/GPU overhead; choose practical resolution and refresh rate per client. Keep an inventory of client name, address, resolution, and display position. Do not assume extra streams are free of compute or bandwidth cost.

## Safety and rollback rules
- Research first; this plan has not installed a driver or changed Xorg.
- Do not use sample commands referring to `VIRTUAL1` until that output actually exists.
- Do not overwrite `~/.screenlayout/monitors.sh`.
- Back up configuration files before editing.
- Do not restart GDM or the graphical session without an explicit decision; this may terminate the current desktop session.
- Keep the current two-monitor layout as the fallback.

## Current status and next task
No virtual display driver or network-display software has been installed or configured for this project; the checks so far were read-only. Next: compare candidates and choose a solution that integrates with the existing X11 desktop instead of assuming a separate virtual X screen will behave like an extra monitor.

## Related guide
See [ARandR multi-monitor setup for i3](MULTI-MONITOR-ARANDR-I3.md) for the working physical-monitor configuration and persistence steps.
