#!/bin/bash
# Sway Developer Environment - Auto Installer
# Installs complete Sway + Waybar + Greetd environment with Catppuccin theming

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

if ! command -v pacman &> /dev/null; then
    error "This installer is designed for Arch Linux and derivatives"
    exit 1
fi

log "Starting Sway Developer Environment installation..."

# Install packages
log "Installing packages..."
PACKAGES=(
    sway waybar greetd greetd-tuigreet
    swaylock-effects swayidle swayosd
    foot rofi mako waypaper
    brightnessctl wireplumber pipewire
    playerctl networkmanager network-manager-applet
    blueman dex polkit-gnome
    ttf-jetbrains-mono-nerd noto-fonts-emoji
    jq curl git
)
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# Create directories
log "Creating directories..."
CONFIG_DIR="$HOME/.config"
mkdir -p "$CONFIG_DIR"/{sway/scripts,waybar/scripts,swaylock,greetd}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy all configs
log "Installing configurations..."
cp -r "$SCRIPT_DIR/config/sway"/* "$CONFIG_DIR/sway/"
cp -r "$SCRIPT_DIR/config/waybar"/* "$CONFIG_DIR/waybar/"
cp -r "$SCRIPT_DIR/config/swaylock"/* "$CONFIG_DIR/swaylock/"
chmod +x "$CONFIG_DIR/sway/scripts/"*.sh 2>/dev/null || true
chmod +x "$CONFIG_DIR/waybar/scripts/"*.sh 2>/dev/null || true

# Setup greetd
log "Setting up greetd login manager..."
sudo mkdir -p /etc/greetd

# Copy quotes file (104 quotes!)
sudo cp "$SCRIPT_DIR/config/greetd/quotes.txt" /etc/greetd/quotes.txt
sudo chmod 644 /etc/greetd/quotes.txt

# Create quote script
sudo tee /etc/greetd/tuigreet-with-quotes.sh > /dev/null << 'EOF'
#!/bin/bash
QUOTES_FILE="/etc/greetd/quotes.txt"
if [ -f "$QUOTES_FILE" ]; then
    QUOTE=$(shuf -n 1 "$QUOTES_FILE")
else
    QUOTE="Welcome to Sway"
fi
exec tuigreet --cmd sway --greeting "$QUOTE" --time --asterisks --theme 'border=magenta;text=white;prompt=green;time=blue;action=cyan;button=yellow;container=black'
EOF
sudo chmod +x /etc/greetd/tuigreet-with-quotes.sh

# Create greetd config
sudo tee /etc/greetd/config.toml > /dev/null << 'EOF'
[terminal]
vt = 1
[default_session]
command = "/etc/greetd/tuigreet-with-quotes.sh"
user = "greeter"
[environment]
EOF

# Create desktop entry
log "Creating sway desktop entry..."
mkdir -p ~/.local/share/wayland-sessions
cat > ~/.local/share/wayland-sessions/sway.desktop << 'EOF'
[Desktop Entry]
Name=Sway
Comment=An efficient and flexible Wayland compositor
Exec=sway
Type=Application
EOF

# Enable services
log "Enabling services..."
sudo systemctl enable greetd
sudo systemctl enable NetworkManager

# Summary
log ""
log "============================================"
log "Installation Complete!"
log "============================================"
log ""
log "Next steps:"
log "1. Log out of your current session"
log "2. Select 'Sway' from the login screen"
log "3. Run 'waypaper' to set your wallpaper"
log ""
log "Keybindings:"
log "  Super+L       - Lock screen"
log "  Super+Return  - Terminal"
log "  Super+D       - App launcher"
log ""
log "104 rotating quotes ready in greetd login!"
log ""
