# Sway Pastel Environment

A complete, reproducible Sway Wayland compositor setup with dual waybar, fingerprint support, passkeys, and Catppuccin theming.

![Desktop](assets/desktop.png)

## Features

- **Dual Waybar Setup**: Top bar for system monitoring, bottom bar for controls
- **Catppuccin Theming**: Consistent pastel colors throughout
- **Screen Lock**: Official Catppuccin swaylock theme with fingerprint support
- **Fingerprint Auth**: Unlock with password OR fingerprint
- **Passkey Support**: WebAuthn/FIDO2 support for modern authentication
- **Media Controls**: Spotify integration with playerctl
- **Screenshots**: Built-in screenshot tool (Print, Shift+Print, Ctrl+Print)
- **Volume Control**: Capped at 100% with visual indicators
- **Auto-installer**: One-command setup
- **Optional Greetd**: Terminal-based login with 104 rotating quotes (experimental, disabled by default)

## Quick Install

### Option 1: One-liner (curl)
```bash
curl -fsSL https://raw.githubusercontent.com/stateofthehart/sway-pastel/main/install.sh | bash
```

### Option 2: Clone and install
```bash
# Using HTTPS
git clone https://github.com/stateofthehart/sway-pastel.git
cd sway-pastel && ./install.sh

# Using SSH
git clone git@github.com:stateofthehart/sway-pastel.git
cd sway-pastel && ./install.sh
```

## Screenshots

### Desktop with Dual Waybar
The main desktop showing the dual waybar setup with system monitoring (top) and controls (bottom).

![Desktop](assets/desktop.png)

### App Launcher (Rofi)
Press `Super+D` to open the application launcher.

![Rofi](assets/rofi.png)

## Prerequisites

- Arch Linux (or derivatives: CachyOS, Manjaro, EndeavourOS)
- `git` and `curl` installed
- sudo access
- (Optional) Fingerprint reader for biometric unlock

## What Gets Installed

### Core Components
- `sway` - Wayland compositor
- `waybar` - Status bar (dual instance setup)
- `greetd` + `tuigreet` - Login manager with rotating quotes
- `swaylock-effects` - Screen locker with Catppuccin theme
- `swayidle` - Idle management
- `swayosd` - On-screen display

### Applications
- `foot` - Terminal emulator
- `rofi` - Application launcher
- `mako` - Notification daemon
- `waypaper` - Wallpaper setter
- `grim` + `slurp` - Screenshot tools

### System & Security
- `fprintd` - Fingerprint authentication
- `libfido2` - FIDO2/WebAuthn passkey support
- `brightnessctl` - Brightness control
- `wireplumber`/`pipewire` - Audio control
- `playerctl` - Media control
- `NetworkManager` - Networking
- `blueman` - Bluetooth
- `polkit-gnome` - Authentication agent

### Fonts
- `ttf-jetbrains-mono-nerd` - Nerd Font with icons
- `noto-fonts-emoji` - Emoji support

## Configuration Details

### Sway Keybindings

| Key | Action |
|-----|--------|
| `Super+L` | Lock screen (password OR fingerprint) |
| `Super+Return` | Terminal (foot) |
| `Super+D` | App launcher (rofi) |
| `Super+Shift+Q` | Kill window |
| `Fn+F2/F3` | Volume down/up |
| `Fn+F5/F6` | Brightness down/up |
| `Print` | Screenshot (full screen) |
| `Shift+Print` | Screenshot (select area) |
| `Ctrl+Print` | Screenshot (focused window) |

### Greetd Login Screen (Optional/Experimental)

⚠️ **Note:** Greetd login manager is currently experimental and disabled by default. To enable it, edit `install.sh` and uncomment the greetd setup section before running the installer.

When enabled, it features:
- **104 rotating quotes** from famous developers and philosophers
- **Catppuccin pastel theme** with colored borders
- **Time display** with custom format
- **Password feedback** with asterisks
- **Hotkeys**: F2 (change command), F3 (sessions), F12 (power menu)

**Example quotes:**
> "Talk is cheap. Show me the code." - Linus Torvalds

> "Any sufficiently advanced technology is indistinguishable from magic." - Arthur C. Clarke

### Lock Screen Authentication

The lock screen supports **both password and fingerprint**:

- **Password**: Type your password and press Enter
- **Fingerprint**: Press Enter (blank), then use your finger

**To enroll your fingerprint:**
```bash
fprintd-enroll
# Follow the prompts to scan your finger
```

**To test:**
```bash
# Lock screen
Super+L

# Then try either:
# 1. Type password + Enter
# 2. Press Enter (blank), then use fingerprint
```

### Passkey Support

This setup includes `libfido2` for modern WebAuthn/FIDO2 authentication:

- Works with Chrome/Chromium for passkey login
- Supports hardware security keys (YubiKey, etc.)
- Enables passwordless authentication on supported websites

**To use passkeys in Chrome:**
1. Install should have added `libfido2` automatically
2. Restart Chrome
3. Visit a site that supports passkeys (Google, GitHub, etc.)
4. Set up passkey authentication in your account settings

## File Structure

```
.
├── install.sh              # Main installer script
├── README.md               # This file
├── config/
│   ├── sway/              # Window manager config
│   ├── waybar/            # Status bar configs
│   ├── swaylock/          # Lock screen config (Catppuccin theme)
│   └── greetd/            # Login manager config (104 quotes)
└── assets/                # Screenshots
    ├── desktop.png        # Desktop screenshot
    └── rofi.png           # App launcher screenshot
```

## Post-Installation

1. **Set wallpaper**: Run `waypaper` and choose your wallpaper
2. **Enroll fingerprint** (if you have a reader): `fprintd-enroll`
3. **Customize quotes**: Edit `/etc/greetd/quotes.txt`
4. **Add more keybindings**: Edit `~/.config/sway/config`

## Troubleshooting

### Greetd not working

From TTY, run:
```bash
sudo systemctl stop greetd
sudo greetd --config /etc/greetd/config.toml
```

### Waybar not showing

Check logs:
```bash
waybar --config ~/.config/waybar/config-bottom -l debug
```

### Fingerprint not working

Check if enrolled:
```bash
fprintd-list $USER
```

If not enrolled:
```bash
fprintd-enroll
```

### Passkeys not working in Chrome

Ensure libfido2 is installed:
```bash
sudo pacman -S libfido2
# Restart Chrome after installation
```

## Customization

### Change Login Quotes

Edit `/etc/greetd/quotes.txt` and add your own quotes (one per line). The file is picked randomly on each login.

### Change Colors

All colors use Catppuccin palette. Edit respective config files:
- Sway: `~/.config/sway/config`
- Waybar: `~/.config/waybar/style.css`
- Swaylock: `~/.config/swaylock/config`

### Disable Fingerprint

If you want to disable fingerprint and use password only:
```bash
sudo tee /etc/pam.d/swaylock << 'EOF'
#%PAM-1.0
auth       required     pam_unix.so nullok
account    required     pam_unix.so
password   required     pam_unix.so nullok
session    required     pam_unix.so
EOF
```

## Repository

- **GitHub**: https://github.com/stateofthehart/sway-pastel
- **SSH**: `git@github.com:stateofthehart/sway-pastel.git`
- **HTTPS**: `https://github.com/stateofthehart/sway-pastel.git`

## Credits

- [Catppuccin](https://github.com/catppuccin) - Color scheme
- [Sway](https://github.com/swaywm/sway) - Window manager
- [Waybar](https://github.com/Alexays/Waybar) - Status bar
- [Tuigreet](https://github.com/apognu/tuigreet) - Login greeter
- [Fprintd](https://github.com/fprint/fprintd) - Fingerprint authentication

## License

MIT - Feel free to use and modify!

---

**Enjoy your Sway Pastel Environment!** 🚀
