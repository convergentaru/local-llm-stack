#!/bin/bash
# =============================================================================
# LOCKSCREEN — i3lock with ImageMagick blur
# =============================================================================

# Tokyo Night colors
BG="1a1b26"
FG="c0caf5ff"
ACCENT="7aa2f7ff"
DIM="565f89ff"
RED="f7768eff"
RING="414868ff"

# Screenshot and blur
TMPIMG=$(mktemp /tmp/lock-XXXX.png)
maim --format png "$TMPIMG"
convert "$TMPIMG" -filter Gaussian -blur 0x10 "$TMPIMG"

# i3lock with color support if available
if i3lock --help 2>&1 | grep -q "time-color"; then
    i3lock \
        --image="$TMPIMG" \
        --clock \
        --indicator \
        --time-str="%H:%M" \
        --date-str="%A, %d %B" \
        --time-font="JetBrainsMono Nerd Font" \
        --date-font="JetBrainsMono Nerd Font" \
        --time-size=72 \
        --date-size=18 \
        --time-color="$FG" \
        --date-color="$DIM" \
        --inside-color="${BG}cc" \
        --insidever-color="${BG}99" \
        --insidewrong-color="${BG}99" \
        --ring-color="$RING" \
        --ringver-color="$ACCENT" \
        --ringwrong-color="$RED" \
        --line-color="${BG}00" \
        --keyhl-color="$ACCENT" \
        --bshl-color="$RED" \
        --separator-color="${BG}00" \
        --verif-text="" \
        --wrong-text="✗" \
        --radius=60 \
        --ring-width=3 \
        --nofork
else
    # Fallback for standard i3lock
    i3lock --image="$TMPIMG" --nofork
fi

rm -f "$TMPIMG"
