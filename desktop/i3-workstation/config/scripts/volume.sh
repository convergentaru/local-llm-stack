#!/bin/bash
# =============================================================================
# VOLUME — pactl control with dunst notifications
# Usage: volume.sh up | down | mute
# =============================================================================

get_vol()   { pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1; }
is_muted()  { pactl get-sink-mute  @DEFAULT_SINK@ | grep -q "yes"; }

notify() {
    local icon="$1" text="$2" val="$3"
    dunstify -a "volume" -u low \
        -h string:x-dunst-stack-tag:volume \
        -h int:value:"${val:-0}" \
        "$icon  $text"
}

case "$1" in
    up)
        pactl set-sink-volume @DEFAULT_SINK@ +5%
        VOL=$(get_vol)
        notify "󰕾" "Volume: ${VOL}%" "$VOL"
        ;;
    down)
        pactl set-sink-volume @DEFAULT_SINK@ -5%
        VOL=$(get_vol)
        notify "󰖀" "Volume: ${VOL}%" "$VOL"
        ;;
    mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        if is_muted; then
            notify "󰝟" "Muted" "0"
        else
            VOL=$(get_vol)
            notify "󰕾" "Volume: ${VOL}%" "$VOL"
        fi
        ;;
esac
