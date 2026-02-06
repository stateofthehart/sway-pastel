#!/usr/bin/env bash
set -euo pipefail

# Bluetooth status script for waybar

# Check if bluetooth is powered on
powered=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}' || echo "no")

if [[ "$powered" == "no" ]]; then
    echo "{\"text\": \"󰂲 Off\", \"class\": \"off\", \"alt\": \"off\"}"
    exit 0
fi

# Check connected devices
connected=$(bluetoothctl devices Connected 2>/dev/null | head -1 || true)

if [[ -n "$connected" ]]; then
    device_name=$(echo "$connected" | cut -d' ' -f3-)
    # Truncate long names
    if [[ ${#device_name} -gt 15 ]]; then
        device_name="${device_name:0:12}..."
    fi
    # Include icon directly in text
    echo "{\"text\": \"󰂱 $device_name\", \"class\": \"connected\", \"alt\": \"connected\"}"
else
    echo "{\"text\": \"󰂯 On\", \"class\": \"on\", \"alt\": \"on\"}"
fi
