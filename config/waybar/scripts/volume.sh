#!/bin/bash
# Volume display for waybar using Nerd Font icons
# Caps volume at 100% using -l 1.0

SINK="@DEFAULT_AUDIO_SINK@"

case "${1:-}" in
    up)
        wpctl set-volume -l 1.0 "$SINK" 5%+ >/dev/null
        ;;
    down)
        wpctl set-volume -l 1.0 "$SINK" 5%- >/dev/null
        ;;
    toggle)
        wpctl set-mute "$SINK" toggle >/dev/null
        ;;
    *)
        output=$(wpctl get-volume "$SINK" 2>/dev/null)
        vol=$(echo "$output" | awk '{printf "%.0f", $2 * 100}')

        if echo "$output" | grep -q "MUTED"; then
            echo " $vol%"
        elif [[ $vol -gt 50 ]]; then
            echo " $vol%"
        elif [[ $vol -gt 0 ]]; then
            echo " $vol%"
        else
            echo " $vol%"
        fi
        ;;
esac
