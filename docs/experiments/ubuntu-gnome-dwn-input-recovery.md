# Ubuntu GNOME / DWN input failure: recovery log

**Status:** GNOME recovery succeeded on 2026-10-12. Root cause of DWN keyboard/mouse failure is not yet established.

## Summary

Two incidents have been reported, on 2026-10-05 and 2026-10-12. In both cases, the custom DWN graphical session appeared to start, but the user could not operate the desktop with the keyboard and mouse. Returning the user's AccountsService session selection to Ubuntu GNOME restored a usable desktop.

This is a repeatable recovery procedure, but it does **not** yet prove that the AccountsService values caused the DWN input failure. Investigate the session-selection change and the DWN input stack as related but separate questions.

## Confirmed recovery procedure

File:

`/var/lib/AccountsService/users/oleg`

Relevant settings before recovery (reported on 2026-10-05):

```ini
Session=xfce
XSession=xfce
```

Settings after recovery:

```ini
Session=ubuntu
XSession=ubuntu
```

A backup was made at `/root/oleg` during the 2026-10-05 recovery. On 2026-10-12 the user found the XFCE selection again, changed both values to `ubuntu`, saved the file, and rebooted. The ordinary Ubuntu GNOME desktop then loaded successfully.

### Recovery steps (Midnight Commander)

1. Open `/var/lib/AccountsService/users/` in Midnight Commander.
2. Back up the `oleg` file before editing.
3. Edit `oleg` and set the existing `Session` and `XSession` entries to `ubuntu` (do not add duplicate entries).
4. Save, exit the editor, and reboot.
5. Confirm GNOME, keyboard, and mouse work.

This is a recovery workaround, not a root-cause fix. Do not delete DWN or reinstall GNOME as part of this procedure.

## Incident timeline

### 2026-10-05

- DWN/alternate graphical session was reported to load while keyboard/mouse control failed.
- `/var/lib/AccountsService/users/oleg` contained `Session=xfce` and `XSession=xfce`.
- Both were changed to `ubuntu`; a backup was made at `/root/oleg`.
- User confirmed Ubuntu GNOME booted successfully.

### 2026-10-12

- The issue recurred: DWN loaded as a full graphical desktop, but keyboard and mouse were not usable.
- GNOME packages `gdm3` and `gnome-shell` were installed.
- During recovery, `gdm.service` was observed as `inactive (dead)`, and `systemctl get-default` returned `friendly-recovery.target`. These observations were made while in recovery mode and must not be interpreted as proof that the normal boot configuration is broken.
- `/var/lib/AccountsService/users/oleg` again showed the XFCE session selection.
- Changing `Session` and `XSession` to `ubuntu` and rebooting restored Ubuntu GNOME.
- User reported that Ubuntu asked for the password twice after the Ubuntu greeting. This is an observation to investigate, not yet diagnosed.
- The user read journal errors including ACPI BIOS messages and repeated input/event messages resembling “failed to call … scan code … invalid argument”. Exact wording and originating component were not captured; do not attribute these errors to DWN without collecting the full journal.

### Important clarification from the user (2026-10-12)

The user is **not** claiming that the system spontaneously changes the session selection back to XFCE. During the 2026-10-12 recovery, while making a backup, the user found the older backup file at `/root/oleg` from the 2026-10-05 incident. The backup still contained the XFCE value (including `XSession=xfce`), which helped the user recognize the same recovery pattern. The user left that backup untouched, created a separate directory named `DWN`, copied the file there for safekeeping, edited the live AccountsService file to select Ubuntu, and rebooted successfully. The exact full contents and paths of the additional copy have not yet been independently inspected.

The recurring pattern to document is:

1. Select/launch the alternate DWN graphical session.
2. The graphical desktop appears to load, but keyboard and mouse input are unusable.
3. Return to recovery/command-line access.
4. Restore the AccountsService session selection to `Session=ubuntu` and `XSession=ubuntu` using Midnight Commander.
5. Reboot; the regular Ubuntu GNOME desktop and input work again.

This sequence has now been reported twice (2026-10-05 and 2026-10-12). It is evidence of a repeatable **recovery path**; it does not establish that XFCE is automatically written back, nor does it yet identify the DWN input failure's root cause.

## Investigation plan

Keep GNOME as the known-good recovery path. Diagnose DWN without making speculative system-wide changes.

1. **Capture the actual DWN launch path and session environment** before changing configuration:
   - DWN launcher / desktop entry and how the session is selected.
   - `~/.local/share/xsessions/`, `/usr/share/xsessions/`, and relevant AccountsService configuration.
   - Identify whether DWN uses X11, Wayland, or another compositor/backend; do not assume.
2. **Capture logs from the failed DWN boot**, preferably before rebooting back to GNOME:
   - `journalctl -b --no-pager`
   - `journalctl -b -p warning..alert --no-pager`
   - Relevant user-session logs, plus DWN and input stack messages.
   - Record the exact command, timestamp, and complete error line for any scan-code / invalid-argument message.
3. **Identify input backend and permissions** used by DWN (for example libinput/evdev, seat/session management, device access). Compare against a working GNOME session.
4. **Investigate why AccountsService returns to XFCE** after the successful Ubuntu selection. Determine whether the session selector, login flow, or another configuration writes the values back.
5. **Investigate the two password prompts** independently: note which screen/application asks each time and whether each prompt occurs before or after the desktop appears. Do not store passwords in logs or documentation.
6. Only make changes after the failing component is identified. Keep a known-good GNOME path available.

## Evidence and uncertainty

- **Confirmed:** setting both AccountsService entries to `ubuntu` and rebooting restored GNOME on both reported dates.
- **Reported symptom:** DWN graphical desktop appeared but keyboard/mouse did not work.
- **Not yet confirmed:** whether the GNOME session-selection setting directly causes DWN input failure; whether the ACPI errors are relevant; why XFCE is selected again; why the password prompt appeared twice.
- **Next useful artifact:** a text capture of the full journal from a failed DWN session, along with the DWN session launcher/configuration. Preserve exact error messages.

## Safety notes

- Do not edit binary `.journal` files directly in Midnight Commander; use `journalctl` to render them as text.
- Do not disable GDM or change the system default target based only on output collected while in recovery mode.
- Do not remove DWN. The objective is to understand and fix its input handling while retaining GNOME as a working fallback.
