#!/bin/bash
# =============================================================================
# BRIGHTNESS — brightnessctl control with dunst notifications
# Usage: brightness.sh up | down
#
# Requirements: sudo usermod -aG video $USER (then logout)
#               OR sudo chmod +s /usr/bin/brightnessctl
# =============================================================================

get_bri() { brightnessctl -m | cut -d',' -f4 | tr -d '%'; }

notify() {
    local icon="$1" val="$2"
    dunstify -a "brightness" -u low \
        -h string:x-dunst-stack-tag:brightness \
        -h int:value:"$val" \
        "$icon  Brightness: ${val}%"
}

case "$1" in
    up)
        brightnessctl set +10% -q
        VAL=$(get_bri)
        notify "󰃠" "$VAL"
        ;;
    down)
        brightnessctl set 10%- -q
        VAL=$(get_bri)
        notify "󰃞" "$VAL"
        ;;
esac
