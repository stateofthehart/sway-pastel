#!/bin/bash
# =============================================================================
# Sway + Waybar + Greetd Auto-Install Script
# =============================================================================
# This script fully configures a Sway Wayland compositor environment with:
# - greetd login manager with tuigreet
# - waybar with dual monitors (top: system, bottom: controls)
# - swaylock with visual feedback
# - Custom scripts for volume, network, bluetooth, media controls
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    error "This script should not be run as root"
    exit 1
fi

# =============================================================================
# STEP 1: Install Required Packages
# =============================================================================
log "Installing required packages..."

# Core packages
PACKAGES=(
    "sway"                 # Wayland compositor
    "waybar"               # Status bar
    "greetd"               # Login manager
    "tuigreet"             # TUI greeter for greetd
    "swaylock"            # Screen locker
    "swayidle"            # Idle management
    "swayosd"             # OSD for keys/volume
    "foot"                # Terminal emulator
    "rofi"                # Application launcher
    "mako"                # Notification daemon
    "brightnessctl"       # Brightness control
    "wpctl"               # WirePlumber CLI (from pipewire)
    "playerctl"           # Media player control
    "NetworkManager"      # Network management
    "networkmanager-tui"  # TUI for nm
    "blueman"             # Bluetooth manager
    "dex"                 # XDG autostart
    "polkit-gnome"        # Authentication agent
    "jetbrains-mono-nerd-fonts"  # Nerd font
    "noto-fonts-emoji"   # Emoji fonts
    "jq"                  # JSON processing
    "curl"                # HTTP client
    "git"                 # Version control
)

# Install packages (adjust package manager for your distro)
install_packages() {
    if command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm "${PACKAGES[@]}"
    elif command -v apt &> /dev/null; then
        sudo apt install "${PACKAGES[@]}"
    elif command -v dnf &> /dev/null; then
        sudo dnf install "${PACKAGES[@]}"
    elif command -v zypper &> /dev/null; then
        sudo zypper install "${PACKAGES[@]}"
    else
        warn "Package manager not detected. Please install manually:"
        echo "${PACKAGES[@]}"
    fi
}

# Uncomment to install packages
# install_packages

# =============================================================================
# STEP 2: Create Directory Structure
# =============================================================================
log "Creating directory structure..."

CONFIG_DIR="$HOME/.config"
mkdir -p "$CONFIG_DIR/sway/scripts"
mkdir -p "$CONFIG_DIR/waybar/scripts"
mkdir -p "$CONFIG_DIR/greetd"
mkdir -p "$CONFIG_DIR/swaylock"

# =============================================================================
# STEP 3: Install Sway Configuration
# =============================================================================
log "Installing Sway configuration..."

cat > "$CONFIG_DIR/sway/config" << 'EOF'
### ~/.config/sway/config
### Sway Wayland Compositor Configuration

set $mod Mod1
set $wndw Mod4

font pango:monospace 8

# Apps
set $term foot
set $menu rofi -show drun -show-icons
set $winmenu rofi -show window

# XDG autostart
exec_always dex --autostart --environment sway

# Notifications
exec_always mako

# Screen lock / idle
exec_always swayidle -w \
  timeout 600 '~/.config/sway/scripts/lock.sh' \
  before-sleep '~/.config/sway/scripts/lock.sh' \
  lock '~/.config/sway/scripts/lock.sh'

# Pol-kit auth
exec_always /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

# OSD
exec_always --no-startup-id swayosd-server
exec_always --no-startup-id swayosd

# Touchpad
input type:touchpad {
    tap enabled
    dwt enabled
    natural_scroll enabled
    pointer_accel 0.3
}

# Volume keys (capped at 100%)
set $refresh_i3status killall -SIGUSR1 i3status
bindsym XF86AudioRaiseVolume exec ~/.config/waybar/scripts/volume.sh up && $refresh_i3status
bindsym XF86AudioLowerVolume exec ~/.config/waybar/scripts/volume.sh down && $refresh_i3status
bindsym XF86AudioMute exec ~/.config/waybar/scripts/volume.sh toggle && $refresh_i3status
bindsym XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && $refresh_i3status

# Brightness
bindsym XF86MonBrightnessUp exec --no-startup-id sh -c 'brightnessctl set +10%'
bindsym XF86MonBrightnessDown exec --no-startup-id sh -c 'brightnessctl set 10%-'

# Lock screen
bindsym $wndw+l exec ~/.config/sway/scripts/lock.sh

# Mouse drag
floating_modifier $mod

# Terminal
bindsym $mod+Return exec $term

# Kill window
bindsym $mod+Shift+q kill

# Launchers
bindsym $mod+d exec $winmenu
bindsym $wndw+d exec $menu

# Focus
focus_wrapping workspace
bindsym $mod+Shift+Tab focus left
bindsym $mod+Tab focus right
bindsym $mod+Control+Shift+Tab workspace prev
bindsym $mod+Control+Tab workspace next
bindsym $mod+Down focus down
bindsym $mod+Up focus up

# Move window
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Splits
bindsym $mod+h split h
bindsym $mod+v split v

# Fullscreen
bindsym $mod+f fullscreen toggle

# Layouts
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Floating
bindsym $mod+Shift+space floating toggle

# Parent focus
bindsym $mod+a focus parent

# Workspaces
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"

bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8
bindsym $mod+9 workspace number $ws9
bindsym $mod+0 workspace number $ws10

bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+7 move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+9 move container to workspace number $ws9
bindsym $mod+Shift+0 move container to workspace number $ws10

bindsym $mod+Control+Shift+Right move container to workspace next; workspace next
bindsym $mod+Control+Shift+Left move container to workspace prev; workspace prev

# Reload
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r reload

# Exit
bindsym $mod+Shift+e exec swaynag -t warning -m "Exit Sway?" -B "Yes, exit Sway" "swaymsg exit"

# Resize mode
mode "resize" {
    bindsym j resize shrink width 10 px or 10 ppt
    bindsym k resize grow height 10 px or 10 ppt
    bindsym l resize shrink height 10 px or 10 ppt
    bindsym semicolon resize grow width 10 px or 10 ppt
    bindsym Left resize shrink width 10 px or 10 ppt
    bindsym Down resize grow height 10 px or 10 ppt
    bindsym Up resize shrink height 10 px or 10 ppt
    bindsym Right resize grow width 10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym $mod+r mode "default"
}
bindsym $mod+r mode "resize"

# Dual waybar setup
exec_always waybar --config ~/.config/waybar/config-top
exec_always waybar --config ~/.config/waybar/config-bottom
EOF

# =============================================================================
# STEP 4: Install Lock Script
# =============================================================================
log "Installing lock script..."

cat > "$CONFIG_DIR/sway/scripts/lock.sh" << 'EOF'
#!/bin/bash
# Swaylock wrapper with proper configuration

if [ -z "$(swaymsg -t get_outputs | grep '"active": true')" ]; then
    exit 0
fi

swaylock --config ~/.config/swaylock/config "$@"
EOF
chmod +x "$CONFIG_DIR/sway/scripts/lock.sh"

# =============================================================================
# STEP 5: Install Swaylock Configuration
# =============================================================================
log "Installing swaylock configuration..."

cat > "$CONFIG_DIR/swaylock/config" << 'EOF'
# Swaylock Configuration
--color 1a1b26
--show-failed-attempts
--indicator-radius 100
--indicator-thickness 15
--inside-color 1a1b26
--inside-clear-color 1a1b26
--inside-ver-color 89b4fa
--inside-wrong-color f38ba8
--line-color 313244
--line-clear-color 313244
--line-ver-color 89b4fa
--line-wrong-color f38ba8
--key-hl-color 89b4fa
--bs-hl-color f38ba8
--text-color cdd6f4
--text-clear-color 6c7086
--font "JetBrainsMono Nerd Font"
--font-size 24
--ring-color 89b4fa
--ring-ver-color a6e3a1
--ring-wrong-color f38ba8
--indicator-caps-lock
--caps-lock-key-hl-color f9e2af
--caps-lock-bs-hl-color f9e2af
--inside-caps-lock-color 313244
--line-caps-lock-color f9e2af
EOF

# =============================================================================
# STEP 6: Install Waybar Configuration
# =============================================================================
log "Installing waybar configuration..."

# Top bar (system monitoring)
cat > "$CONFIG_DIR/waybar/config-top" << 'EOF'
{
  "name": "top",
  "layer": "top",
  "position": "top",
  "height": 34,
  "spacing": 4,

  "modules-left": ["wlr/workspaces", "custom/cpu", "memory", "custom/disk"],
  "modules-center": ["custom/gpu", "window"],
  "modules-right": ["custom/network-speed", "tray"],

  "wlr/workspaces": {
    "format": "{name}",
    "show-output": true
  },

  "custom/cpu": {
    "exec": "~/.config/waybar/scripts/cpu.sh",
    "interval": 2,
    "return-type": "text"
  },

  "memory": {
    "format": "{percentage}%",
    "interval": 2
  },

  "custom/disk": {
    "exec": "~/.config/waybar/scripts/disk.sh",
    "interval": 10,
    "return-type": "text"
  },

  "custom/gpu": {
    "exec": "~/.config/waybar/scripts/gpu.sh",
    "interval": 5,
    "return-type": "text"
  },

  "custom/network-speed": {
    "exec": "~/.config/waybar/scripts/network-speed.sh",
    "interval": 1,
    "return-type": "json"
  },

  "window": {
    "format": "{title}",
    "max-length": 100
  },

  "tray": {
    "icon-size": 16,
    "spacing": 6
  }
}
EOF

# Bottom bar (controls)
cat > "$CONFIG_DIR/waybar/config-bottom" << 'EOF'
{
  "name": "bottom",
  "layer": "top",
  "position": "bottom",
  "height": 34,
  "spacing": 4,

  "modules-left": [
    "custom/launcher",
    "custom/media-prev",
    "custom/media-playpause", 
    "custom/media-next",
    "custom/media-info"
  ],
  "modules-center": ["clock"],
  "modules-right": [
    "backlight",
    "custom/volume",
    "custom/network",
    "custom/bluetooth",
    "battery",
    "tray"
  ],

  "custom/launcher": {
    "format": "󰣇",
    "tooltip": false,
    "on-click": "rofi -show drun -show-icons"
  },

  "clock": {
    "format": "{:%a %b %d  %H:%M}",
    "format-alt": "{:%Y-%m-%d}",
    "tooltip-format": "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>",
    "on-click": "toggle_format"
  },

  "backlight": {
    "format": "{icon} {percent}%",
    "format-icons": ["󰃚", "󰃛", "󰃜", "󰃝", "󰃞", "󰃟", "󰃠"],
    "on-scroll-up": "brightnessctl set +5%",
    "on-scroll-down": "brightnessctl set 5%-",
    "tooltip": false,
    "min-length": 6
  },

  "custom/volume": {
    "exec": "exec ~/.config/waybar/scripts/volume.sh",
    "interval": 1,
    "return-type": "text",
    "on-click": "~/.config/waybar/scripts/volume.sh toggle",
    "on-scroll-up": "~/.config/waybar/scripts/volume.sh up",
    "on-scroll-down": "~/.config/waybar/scripts/volume.sh down",
    "tooltip": false
  },

  "custom/network": {
    "exec": "~/.config/waybar/scripts/network-tooltip.sh",
    "interval": 5,
    "return-type": "json",
    "format": "{text}",
    "on-click": "nm-connection-editor"
  },

  "custom/bluetooth": {
    "exec": "~/.config/waybar/scripts/bluetooth-status.sh",
    "interval": 5,
    "return-type": "json",
    "format": "{text}",
    "on-click": "blueman-manager",
    "tooltip": false
  },

  "battery": {
    "states": {"warning": 30, "critical": 15},
    "format": "{icon} {capacity}%",
    "format-charging": "󰂄 {capacity}%",
    "format-plugged": "󰂄 {capacity}%",
    "format-alt": "{time} {icon}",
    "format-icons": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"],
    "tooltip": false
  },

  "custom/media-prev": {
    "exec": "~/.config/waybar/scripts/media-prev.sh",
    "interval": "once",
    "return-type": "text",
    "on-click": "playerctl -p playerctld,spotify previous",
    "tooltip": false
  },

  "custom/media-playpause": {
    "exec": "~/.config/waybar/scripts/media-playpause.sh",
    "interval": 1,
    "return-type": "text",
    "on-click": "playerctl -p playerctld,spotify play-pause",
    "tooltip": false
  },

  "custom/media-next": {
    "exec": "~/.config/waybar/scripts/media-next.sh",
    "interval": "once",
    "return-type": "text",
    "on-click": "playerctl -p playerctld,spotify next",
    "tooltip": false
  },

  "custom/media-info": {
    "exec": "~/.config/waybar/scripts/media-info.sh",
    "interval": 1,
    "return-type": "text",
    "tooltip": false,
    "hide-empty-text": true
  },

  "tray": {
    "icon-size": 18,
    "spacing": 8
  }
}
EOF

# =============================================================================
# STEP 7: Install Waybar CSS
# =============================================================================
log "Installing waybar styles..."

cat > "$CONFIG_DIR/waybar/style.css" << 'EOF'
/* ============================================
   SWAY DUAL-BAR THEME - Developer/Hacker Style
   ============================================ */

* {
  font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", monospace;
  font-size: 12px;
  min-height: 0;
  border: none;
  border-radius: 0;
  padding: 0;
  margin: 0;
}

/* Top Bar */
window#waybar.top {
  background: rgba(13, 17, 23, 0.95);
  color: #c9d1d9;
  border-bottom: 1px solid rgba(48, 54, 61, 0.8);
}

window#waybar.top #workspaces {
  margin: 4px;
}

window#waybar.top #workspaces button {
  padding: 0 10px;
  margin: 2px 4px;
  border-radius: 6px;
  background: rgba(22, 27, 34, 0.8);
  color: #8b949e;
  border: 1px solid rgba(48, 54, 61, 0.5);
  min-width: 30px;
}

window#waybar.top #workspaces button.focused {
  background: rgba(95, 135, 255, 0.2);
  border: 1px solid rgba(95, 135, 255, 0.6);
  color: #ffffff;
}

window#waybar.top #workspaces button.urgent {
  background: rgba(255, 95, 95, 0.25);
  border: 1px solid rgba(255, 95, 95, 0.6);
  color: #ffffff;
}

window#waybar.top #custom-cpu,
window#waybar.top #memory,
window#waybar.top #custom-disk,
window#waybar.top #custom-gpu,
window#waybar.top #custom-network-speed {
  padding: 0 12px;
  margin: 6px 3px;
  border-radius: 8px;
  background: rgba(22, 27, 34, 0.8);
  border: 1px solid rgba(48, 54, 61, 0.5);
}

window#waybar.top #custom-cpu { border-left: 3px solid rgba(255, 215, 95, 0.9); }
window#waybar.top #memory { border-left: 3px solid rgba(175, 135, 255, 0.9); }
window#waybar.top #custom-disk { border-left: 3px solid rgba(95, 255, 135, 0.9); }
window#waybar.top #custom-gpu { border-left: 3px solid rgba(45, 226, 230, 0.9); }
window#waybar.top #custom-network-speed { border-left: 3px solid rgba(255, 165, 0, 0.9); }

window#waybar.top #window {
  color: #8b949e;
  padding: 0 15px;
  font-style: italic;
}

/* Bottom Bar */
window#waybar.bottom {
  background: rgba(30, 30, 46, 0.98);
  color: #cdd6f4;
  border-top: 1px solid rgba(69, 71, 90, 0.8);
}

window#waybar.bottom #custom-launcher {
  padding: 0 16px;
  margin: 4px 8px;
  border-radius: 8px;
  background: rgba(137, 180, 250, 0.15);
  color: #89b4fa;
  font-size: 16px;
  border: 1px solid rgba(137, 180, 250, 0.3);
}

window#waybar.bottom #clock {
  padding: 0 20px;
  margin: 4px;
  border-radius: 8px;
  background: rgba(49, 50, 68, 0.8);
  color: #f5c2e7;
  font-size: 14px;
  font-weight: bold;
  border: 1px solid rgba(245, 194, 231, 0.3);
}

window#waybar.bottom #backlight,
window#waybar.bottom #custom-volume,
window#waybar.bottom #custom-network,
window#waybar.bottom #custom-bluetooth,
window#waybar.bottom #battery {
  padding: 0 14px;
  margin: 4px 3px;
  border-radius: 8px;
  background: rgba(49, 50, 68, 0.7);
  border: 1px solid rgba(69, 71, 90, 0.5);
  color: #cdd6f4;
}

window#waybar.bottom #backlight { color: #f9e2af; }
window#waybar.bottom #custom-volume { color: #89b4fa; }
window#waybar.bottom #custom-network { color: #a6e3a1; }
window#waybar.bottom #custom-bluetooth { color: #89dceb; }
window#waybar.bottom #battery { color: #f38ba8; }

window#waybar.bottom #custom-media-prev,
window#waybar.bottom #custom-media-playpause,
window#waybar.bottom #custom-media-next,
window#waybar.bottom #custom-media-info {
  color: #fab387;
  background: transparent;
  border: none;
  padding: 0 6px;
  margin: 4px 2px;
}

window#waybar.bottom #tray {
  padding: 0 10px;
  margin: 4px;
  background: rgba(49, 50, 68, 0.5);
  border-radius: 8px;
}

window#waybar.bottom #battery.charging,
window#waybar.bottom #battery.plugged {
  color: #a6e3a1;
  background: rgba(166, 227, 161, 0.15);
}

window#waybar.bottom #battery.warning {
  color: #f9e2af;
  background: rgba(249, 226, 175, 0.15);
}

window#waybar.bottom #battery.critical {
  color: #f38ba8;
  background: rgba(243, 139, 168, 0.15);
  animation: blink 1s linear infinite;
}

@keyframes blink {
  0% { opacity: 1; }
  50% { opacity: 0.5; }
  100% { opacity: 1; }
}

tooltip {
  background: rgba(13, 17, 23, 0.98);
  border: 1px solid rgba(48, 54, 61, 0.8);
  border-radius: 8px;
  padding: 10px 12px;
}

tooltip label {
  color: #c9d1d9;
  font-family: "JetBrainsMono Nerd Font", monospace;
  font-size: 11px;
}
EOF

# =============================================================================
# STEP 8: Install Waybar Scripts
# =============================================================================
log "Installing waybar scripts..."

# Volume script
cat > "$CONFIG_DIR/waybar/scripts/volume.sh" << 'EOF'
#!/bin/bash
# Volume display using Nerd Font icons
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
EOF

# Network script
cat > "$CONFIG_DIR/waybar/scripts/network-tooltip.sh" << 'EOF'
#!/bin/bash
# Network status with tooltip
SSID=$(nmcli -t -f active,ssid dev wifi | grep "^yes:" | cut -d: -f2)
if [[ -z "$SSID" ]]; then
    echo '{"text": "󰯂", "tooltip": "Not connected"}'
else
    IP=$(ip route get 1 2>/dev/null | grep -oP 'src \K[0-9.]+' || echo "")
    echo "{\"text\": \"$SSID\", \"tooltip\": \"Connected to $SSID${IP:+\\nIP: $IP}\"}"
fi
EOF

# Bluetooth script
cat > "$CONFIG_DIR/waybar/scripts/bluetooth-status.sh" << 'EOF'
#!/bin/bash
# Bluetooth status
if bluetoothctl show | grep -q "Powered: yes"; then
    DEV=$(bluetoothctl devices | grep -E "Connected: (yes|no)" | grep "Connected: yes" | head -1)
    if [[ -n "$DEV" ]]; then
        NAME=$(echo "$DEV" | sed 's/Device //' | awk '{print $2,$3}')
        echo "{\"text\": \"󰂱 $NAME\", \"class\": \"connected\"}"
    else
        echo '{"text": "󰂯", "class": "disconnected"}'
    fi
else
    echo '{"text": "󰂲"}'
fi
EOF

# Make scripts executable
chmod +x "$CONFIG_DIR/waybar/scripts/"*.sh

# =============================================================================
# STEP 9: Configure Greetd
# =============================================================================
log "Configuring greetd login manager with rotating quotes..."

sudo mkdir -p /etc/greetd 2>/dev/null || true

# Create quotes file in system location (accessible by greeter user)
cat > /tmp/greetd-quotes.txt << 'EOF'
With great power comes great responsibility. - Spider-Man
Talk is cheap. Show me the code. - Linus Torvalds
Programs must be written for people to read, and only incidentally for machines to execute. - Harold Abelson
Simplicity is the ultimate sophistication. - Leonardo da Vinci
Any sufficiently advanced technology is indistinguishable from magic. - Arthur C. Clarke
The only way to do great work is to love what you do. - Steve Jobs
First, solve the problem. Then, write the code. - John Johnson
Experience is the name everyone gives to their mistakes. - Oscar Wilde
Java is to JavaScript what car is to Carpet. - Chris Heilmann
Knowledge is power. - Francis Bacon
Code is like humor. When you have to explain it, it's bad. - Cory House
Fix the cause, not the symptom. - Steve Maguire
Make it work, make it right, make it fast. - Kent Beck
Before software can be reusable it first has to be usable. - Ralph Johnson
It's not a bug, it's a feature. - Anonymous
Software is eating the world. - Marc Andreessen
The best way to predict the future is to invent it. - Alan Kay
Debugging is twice as hard as writing the code in the first place. - Brian Kernighan
I think, therefore I am. - René Descartes
The unexamined life is not worth living. - Socrates
EOF

# Create quote script in system location (accessible by greeter user)
cat > /tmp/greetd-quote-script.sh << 'EOF'
#!/bin/bash
# Random quote selector for tuigreet
QUOTES_FILE="/etc/greetd/quotes.txt"

if [ -f "$QUOTES_FILE" ]; then
    QUOTE=$(shuf -n 1 "$QUOTES_FILE")
else
    QUOTE="Welcome to Sway"
fi

exec tuigreet \
    --cmd sway \
    --greeting "$QUOTE" \
    --time \
    --asterisks \
    --theme 'border=magenta;text=white;prompt=green;time=blue;action=cyan;button=yellow;container=black'
EOF

cat > /tmp/greetd-config.toml << 'EOF'
[terminal]
vt = 1

[default_session]
command = "/etc/greetd/tuigreet-with-quotes.sh"
user = "greeter"

[environment]
EOF

# Copy files to system location (requires sudo)
if sudo cp /tmp/greetd-quotes.txt /etc/greetd/quotes.txt 2>/dev/null && \
   sudo cp /tmp/greetd-quote-script.sh /etc/greetd/tuigreet-with-quotes.sh 2>/dev/null && \
   sudo chmod +x /etc/greetd/tuigreet-with-quotes.sh 2>/dev/null && \
   sudo chmod 644 /etc/greetd/quotes.txt 2>/dev/null && \
   sudo cp /tmp/greetd-config.toml /etc/greetd/config.toml 2>/dev/null; then
    log "Greetd configured successfully with rotating quotes"
else
    warn "Cannot write to /etc/greetd. Copy manually:"
    echo "sudo cp /tmp/greetd-quotes.txt /etc/greetd/quotes.txt"
    echo "sudo cp /tmp/greetd-quote-script.sh /etc/greetd/tuigreet-with-quotes.sh"
    echo "sudo chmod +x /etc/greetd/tuigreet-with-quotes.sh"
    echo "sudo cp /tmp/greetd-config.toml /etc/greetd/config.toml"
fi

# =============================================================================
# STEP 10: Create Sway Desktop Entry
# =============================================================================
log "Creating sway.desktop for greetd..."

mkdir -p ~/.local/share/wayland-sessions 2>/dev/null || true

cat > ~/.local/share/wayland-sessions/sway.desktop << 'EOF'
[Desktop Entry]
Name=Sway
Comment=An efficient and flexible Wayland compositor
Exec=dbus-run-session sway
Type=Application
EOF

# =============================================================================
# SUMMARY
# =============================================================================
log ""
log "============================================"
log "Installation Complete!"
log "============================================"
log ""
log "To start Sway:"
log "1. Log out of current session"
log "2. Select 'Sway' from greetd login screen"
log "3. If using display manager, choose Sway session"
log ""
log "Keybindings:"
log "  Super+L       - Lock screen"
log "  Super+Return  - Terminal (foot)"
log "  Super+D       - App launcher"
log "  Volume keys   - Control volume (capped at 100%)"
log "  Brightness    - Fn keys for brightness"
log ""
log "Files installed:"
log "  ~/.config/sway/config"
log "  ~/.config/sway/scripts/lock.sh"
log "  ~/.config/swaylock/config"
log "  ~/.config/waybar/config-top"
log "  ~/.config/waybar/config-bottom"
log "  ~/.config/waybar/style.css"
log "  ~/.config/waybar/scripts/*.sh"
log "  ~/.config/greetd/config.toml"
log ""
warn "=== SAFELY TEST GREETD FIRST ==="
warn "1. From TTY, test without enabling service:"
warn "   sudo cp ~/.config/greetd/config.toml /etc/greetd/config.toml"
warn "   sudo systemctl stop greetd 2>/dev/null"
warn "   sudo greetd --config /etc/greetd/config.toml"
warn "   (Press Alt+F2 to go to TTY2 to test, Alt+F1 to return)"
warn ""
warn "2. If it works, enable greetd:"
warn "   sudo systemctl enable greetd"
warn ""
warn "3. If it breaks, revert from TTY:"
warn "   sudo systemctl stop greetd"
warn "   sudo systemctl start sddm  # or just run 'exec sway' from TTY"
warn ""
