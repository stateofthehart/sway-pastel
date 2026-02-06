#!/bin/bash
# =============================================================================
# Sway Pastel Environment - Auto Installer
# =============================================================================
# Complete Sway + Waybar + Greetd setup with Catppuccin theming,
# fingerprint support, passkeys, and 104 rotating quotes
# 
# Quick install:
#   curl -fsSL https://raw.githubusercontent.com/stateofthehart/sway-pastel/main/install.sh | bash
#   
# Or clone and run:
#   git clone https://github.com/stateofthehart/sway-pastel.git
#   cd sway-pastel && ./install.sh
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running on Arch-based system
if ! command -v pacman &> /dev/null; then
    error "This installer is designed for Arch Linux and derivatives (CachyOS, Manjaro, EndeavourOS, etc.)"
    exit 1
fi

log "Starting Sway Pastel Environment installation..."

# =============================================================================
# STEP 1: Install Required Packages
# =============================================================================
log "Installing packages..."

PACKAGES=(
    # Core
    sway waybar greetd greetd-tuigreet
    swaylock-effects swayidle swayosd
    
    # Applications
    foot rofi mako waypaper grim slurp
    
    # System utilities
    brightnessctl wireplumber pipewire
    playerctl networkmanager network-manager-applet
    blueman dex polkit-gnome
    fprintd libfido2
    
    # Fonts
    ttf-jetbrains-mono-nerd noto-fonts-emoji
    
    # Tools
    jq curl git
)

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# =============================================================================
# STEP 2: Create Directory Structure
# =============================================================================
log "Creating directories..."

CONFIG_DIR="$HOME/.config"
mkdir -p "$CONFIG_DIR"/{sway/scripts,waybar/scripts,swaylock,greetd}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# STEP 3: Copy All Configurations
# =============================================================================
log "Installing configurations..."

cp -r "$SCRIPT_DIR/config/sway"/* "$CONFIG_DIR/sway/"
cp -r "$SCRIPT_DIR/config/waybar"/* "$CONFIG_DIR/waybar/"
cp -r "$SCRIPT_DIR/config/swaylock"/* "$CONFIG_DIR/swaylock/"

# Make scripts executable
chmod +x "$CONFIG_DIR/sway/scripts/"*.sh 2>/dev/null || true
chmod +x "$CONFIG_DIR/waybar/scripts/"*.sh 2>/dev/null || true

# =============================================================================
# STEP 4: Setup Greetd Login Manager (OPTIONAL - Disabled by default)
# =============================================================================
# NOTE: Greetd is currently experimental and disabled by default.
# To enable it, uncomment the lines below and run the installer again.
# 
# log "Setting up greetd login manager with 104 rotating quotes..."
# 
# sudo mkdir -p /etc/greetd
# 
# # Copy quotes file (104 quotes!)
# sudo cp "$SCRIPT_DIR/config/greetd/quotes.txt" /etc/greetd/quotes.txt
# sudo chmod 644 /etc/greetd/quotes.txt
# 
# # Create quote script
# sudo tee /etc/greetd/tuigreet-with-quotes.sh > /dev/null << 'EOF'
# #!/bin/bash
# QUOTES_FILE="/etc/greetd/quotes.txt"
# if [ -f "$QUOTES_FILE" ]; then
#     QUOTE=$(shuf -n 1 "$QUOTES_FILE")
# else
#     QUOTE="Welcome to Sway"
# fi
# exec tuigreet --cmd sway --greeting "$QUOTE" --time --asterisks --theme 'border=magenta;text=white;prompt=green;time=blue;action=cyan;button=yellow;container=black'
# EOF
# sudo chmod +x /etc/greetd/tuigreet-with-quotes.sh
# 
# # Create greetd config
# sudo tee /etc/greetd/config.toml > /dev/null << 'EOF'
# [terminal]
# vt = 1
# [default_session]
# command = "/etc/greetd/tuigreet-with-quotes.sh"
# user = "greeter"
# [environment]
# EOF
#
# sudo systemctl enable greetd

log "Skipping greetd setup (experimental feature, disabled by default)"

# =============================================================================
# STEP 5: Configure Fingerprint Support (Optional)
# =============================================================================
log "Setting up fingerprint authentication..."

# Check if fingerprint reader exists
if lsusb | grep -qi "fprint\|fingerprint\|synaptics.*sensor"; then
    log "Fingerprint reader detected!"
    
    # Install PAM config for swaylock with fingerprint support
    sudo tee /etc/pam.d/swaylock > /dev/null << 'EOF'
#%PAM-1.0
# Swaylock PAM - password OR fingerprint (both work independently)

# Try password first (with likeauth to allow fallback)
auth       sufficient   pam_unix.so try_first_pass likeauth nullok

# Try fingerprint
auth       sufficient   pam_fprintd.so

# Deny if neither worked
auth       required     pam_deny.so

account    required     pam_unix.so
password   required     pam_unix.so try_first_pass nullok shadow
session    required     pam_unix.so
EOF
    
    warn "Fingerprint reader configured for lock screen!"
    warn "To enroll your fingerprint, run: fprintd-enroll"
    warn "To test: Lock screen with Super+L, then:"
    warn "  - Type password + Enter (unlocks immediately)"
    warn "  - OR press Enter (blank), then use your finger"
else
    warn "No fingerprint reader detected. Skipping fingerprint setup."
    
    # Basic PAM config without fingerprint
    sudo tee /etc/pam.d/swaylock > /dev/null << 'EOF'
#%PAM-1.0
auth       required     pam_unix.so nullok
account    required     pam_unix.so
password   required     pam_unix.so nullok
session    required     pam_unix.so
EOF
fi

# =============================================================================
# STEP 6: Create Sway Desktop Entry
# =============================================================================
log "Creating sway desktop entry..."

mkdir -p ~/.local/share/wayland-sessions

cat > ~/.local/share/wayland-sessions/sway.desktop << 'EOF'
[Desktop Entry]
Name=Sway
Comment=An efficient and flexible Wayland compositor
Exec=sway
Type=Application
EOF

# =============================================================================
# STEP 7: Enable Services
# =============================================================================
log "Enabling services..."

# NOTE: greetd is disabled by default (experimental)
# To enable it, uncomment the line below and the greetd setup in STEP 4
# sudo systemctl enable greetd

sudo systemctl enable NetworkManager

# Enable fingerprint service if available
if systemctl list-unit-files | grep -q fprintd; then
    sudo systemctl enable fprintd
fi

# =============================================================================
# STEP 8: Summary
# =============================================================================
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
log "  Super+Return  - Terminal (foot)"
log "  Super+D       - App launcher (rofi)"
log "  Print         - Screenshot (full screen)"
log "  Shift+Print   - Screenshot (select area)"
log "  Ctrl+Print    - Screenshot (focused window)"
log ""
log "Features:"
log "  - 104 rotating quotes in login screen"
log "  - Dual waybar (top: system, bottom: controls)"
log "  - Catppuccin pastel theme throughout"
log "  - Passkey support enabled (libfido2 installed)"
log ""

# Check if fingerprint needs enrollment
if lsusb | grep -qi "fprint\|fingerprint\|synaptics.*sensor"; then
    if ! fprintd-list "$USER" 2>/dev/null | grep -q "fingers enrolled"; then
        warn "ACTION REQUIRED: Enroll your fingerprint:"
        warn "  Run: fprintd-enroll"
        warn ""
    fi
fi

log "Enjoy your Sway Pastel Environment!"
log ""
