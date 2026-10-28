# Quattro-Void: Lightweight Omarchy Quattro Desktop for Void Linux

[![Void Linux](https://img.shields.io/badge/Void_Linux-runit_%7C_xbps-black?logo=voidlinux&logoColor=white)](https://voidlinux.org)
[![Compositor](https://img.shields.io/badge/Hyprland-0.56+-58E1E1?logo=hyprland&logoColor=black)](https://hyprland.org)
[![Shell](https://img.shields.io/badge/Quickshell-Qt6_%7C_QML-41CD52?logo=qt&logoColor=white)](https://quickshell.outfoxxed.me)
[![Audio](https://img.shields.io/badge/Audio-PipeWire_+_WirePlumber-blue)](https://pipewire.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

An authentic, bloat-free port of **Omarchy Quattro (4.0)** engineered specifically for **Void Linux** (`runit` + `xbps` + `pipewire`). It brings the exact visual styling, flush 26px edge-to-edge status bar, fluid flyout cards, unified application menu, dynamic multi-theme engine, wallpaper switcher, and Wayland lockscreen to Void Linux—while completely removing systemd dependencies, cloud daemons, and AI telemetry.

Fully reproducible from a clean base install on any standard Void Linux x86_64 system.

---

## Architecture & Differences from Upstream Omarchy

| Component | Upstream Omarchy Quattro | Quattro-Void (This Port) |
| :--- | :--- | :--- |
| **Operating System** | Arch Linux | **Void Linux** (x86_64 glibc) |
| **Init & Services** | systemd + systemd user units | **Void runit** (`dbus`, `elogind`, `seatd`, `NetworkManager`, `greetd`) |
| **Shell Engine** | Quickshell (`Qt6` + `QML`) | **Pure Quickshell** (authentic upstream components) |
| **Package Manager** | `pacman` | **`xbps`** + Fastly CDN mirror & Hyprland-Void repo |
| **Audio Stack** | systemd user pipewire | **PipeWire + WirePlumber** auto-spawned via `context.exec` |
| **Display Manager** | Greetd / Systemd | **`greetd` + `tuigreet`** runit service on VT 1 |
| **AI / Cloud Daemons** | Claude, Codex, Grok, Fireworks, Dropbox | **100% Stripped Out** (Zero AI bloat, zero background telemetry) |
| **App Philosophy** | Heavy GNOME apps (Nautilus, Loupe) | **TUI-First & Minimal**: `yazi`, `btop`, `lazygit`, `pulsemixer`, `impala` |
| **Hardware State** | `systemd-backlight`, `alsa-state` | **`void-backlight`** and **`alsactl`** hooked into `rc.local` / `rc.shutdown` |

---

## Void Linux Compatibility Shims

Because upstream Omarchy Quattro relies heavily on Arch Linux and systemd user services, `quattro-void-dotfiles` provides transparent compatibility shims installed to `/usr/local/bin`:

- **`systemctl`**: Emulates systemctl power commands using `loginctl` with fallback to `sudo -n poweroff`, `sudo -n reboot`, `zzz` (suspend), and `ZZZ` (hibernate).
- **`uwsm` & `uwsm-app`**: Strips wrapping arguments and launches desktop applications directly under Wayland; cleans up sessions on `stop`.
- **`systemd-run`**: Strips systemd unit properties and directly execs target commands.
- **`systemd-cat`**: Drops systemd logging flags and transparently executes commands.
- **`systemd-inhibit`**: Symlinked directly to `/usr/bin/elogind-inhibit`.
- **`pacman`**: Bridges package list requests from Quickshell/menus to `xbps-query -l`.
- **`magick`**: Lightweight dimension extraction via `file` and regex, eliminating large ImageMagick dependencies.
- **`omarchy-lock-password`**: `/etc/pam.d/omarchy-lock-password` configured with `system-auth` for reliable lockscreen authentication.
- **`omarchy-system`**: Void-native power controller handling logout (`hyprctl dispatch exit`), reboot, shutdown, suspend, and display manager transitions.
- **`void-audio-init`**: Detached background daemon that cleans stale sockets and guarantees PipeWire and WirePlumber are active before the desktop shell starts.
- **`void-backlight`**: Saves and restores screen brightness across reboots via `/var/lib/backlight/` and `~/.local/state/omarchy/brightness`.

---

## Prerequisites (Fresh Void Linux Install)

1. **Void Linux x86_64 Base Install** (`glibc`).
2. A non-root user added to the `wheel` group with `sudo` permissions:
   ```bash
   useradd -m -G wheel,video,audio,input -s /bin/bash <username>
   passwd <username>
   ```
3. Network connection active (Ethernet or Wi-Fi configured via `wpa_supplicant` / `nmtui`).
4. Git installed to clone the repository:
   ```bash
   sudo xbps-install -Sy git
   ```

---

## Quick Installation

Clone the repository and run the automated installer:

```bash
git clone https://github.com/Rajan-08/quattro-void-dotfiles.git
cd quattro-void-dotfiles
sudo ./install.sh
```

### What `install.sh` Does Automatically:
1. **Repository Setup**: Configures the Fastly CDN mirror and the Hyprland-Void community binary repository.
2. **Package Installation**: Installs Hyprland 0.56+, Quickshell, Wayland portals, PipeWire, WirePlumber, foot, alacritty, TUI utilities (`yazi`, `btop`, `lazygit`, `neovim`), `greetd`, `tuigreet`, and JetBrains Mono Nerd Fonts.
3. **Asset Deployment**: Deploys the official `omarchy.ttf` icon font (patched with the Void Linux logo), 23 themes, and Quattro wallpapers.
4. **Shims & Hardware Configuration**:
   - Deploys compatibility shims to `/usr/local/bin`.
   - Configures `/etc/udev/rules.d/60-sound.rules` for unprivileged audio group access.
   - Configures `/etc/pipewire/pipewire.conf.d/10-session-manager.conf`.
   - Sets up `/etc/rc.local` and `/etc/rc.shutdown` for backlight and ALSA persistence.
   - Configures `/etc/greetd/config.toml` with `tuigreet` on VT 1.
   - Grants passwordless power commands and browser tinting via `/etc/sudoers.d/`.
5. **Runit Services**: Enables `dbus`, `elogind`, `seatd`, `NetworkManager`, `bluetoothd`, `polkitd`, `acpid`, and `greetd`.
6. **User Configuration**: Deploys Hyprland Lua configs, Quickshell shell, Starship prompt, terminal configs, and sets default login shell to `zsh`.

After installation finishes, simply reboot:
```bash
sudo reboot
```

---

## Keybindings Reference

### Shell & System Controls
| Shortcut | Action |
| :--- | :--- |
| `SUPER + Space` | Unified Omarchy Menu (Search, Apps, Settings) |
| `SUPER + Alt + Space` | Applications Grid Overlay |
| `SUPER + Esc` | Power & Session Menu (Lock, Logout, Suspend, Reboot, Shutdown) |
| `SUPER + Ctrl + Space` | Wallpaper Switcher |
| `SUPER + Shift + Ctrl + Space` | Theme Switcher (23 dynamic themes) |
| `SUPER + Shift + Space` | Toggle Top Status Bar visibility |
| `SUPER + Shift + R` | Reload Hyprland and Quickshell |
| `SUPER + L` / `SUPER + Ctrl + L` | Lock Screen |

### Window Management
| Shortcut | Action |
| :--- | :--- |
| `SUPER + Q` / `SUPER + W` | Close focused window |
| `SUPER + T` | Toggle small centered floating window |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + H / J / K / L` | Move window focus (Left, Down, Up, Right) |
| `SUPER + Shift + H / J / K / L` | Move window position |
| `SUPER + 1 .. 9` | Switch to Workspace 1–9 |
| `SUPER + Shift + 1 .. 9` | Move window to Workspace 1–9 |
| `SUPER + S` | Toggle Special Scratchpad workspace |

### Terminals & TUI Apps
| Shortcut | Action |
| :--- | :--- |
| `SUPER + Enter` | Open Terminal (`foot` / `alacritty`) |
| `SUPER + Shift + F` | File Manager (`yazi` floating) |
| `SUPER + B` | System Monitor (`btop` floating) |
| `SUPER + G` | Git Interface (`lazygit` floating) |
| `SUPER + Shift + M` | Music Player TUI (`cliamp`) |
| `SUPER + Alt + A` | Audio Mixer TUI (`wiremix` / `pulsemixer`) |
| `SUPER + Alt + N` | Wi-Fi Manager TUI (`impala` / `nmtui`) |
| `SUPER + Alt + B` | Bluetooth Manager TUI (`bluetuith`) |
| `SUPER + Alt + X` | Interactive Void Package Manager (`xbps` + `fzf`) |

### Clipboard, Screenshots & Notifications
| Shortcut | Action |
| :--- | :--- |
| `SUPER + Ctrl + V` | Clipboard History Manager Overlay |
| `SUPER + C` / `SUPER + V` | Universal Copy / Paste (smart detection for terminals vs GUI apps) |
| `SUPER + X` / `SUPER + A` | Universal Cut / Select All |
| `Print` | Interactive Region Screenshot (saves to `~/Pictures/Screenshots` & clipboard) |
| `SUPER + Ctrl + Alt + C` | Region Screenshot alternative |
| `SUPER + ,` | Dismiss newest notification toast |
| `SUPER + Shift + ,` | Dismiss all notification toasts |
| `SUPER + Alt + ,` | Invoke / activate notification action |
| `SUPER + Shift + Alt + ,` | Open Notification History Drawer |
| `SUPER + Ctrl + Alt + ,` | Toggle Do-Not-Disturb (mute notifications) |

---

## Dynamic Theme Engine

Quattro-Void includes 23 themes (Tokyo Night, Catppuccin Mocha/Macchiato/Latte, Nord, Gruvbox, Rose Pine, Dracula, Solarized, and more).

Switch themes dynamically via `SUPER + Shift + Ctrl + Space` or through the CLI:
```bash
omarchy-theme-set "Tokyo Night"
omarchy-theme-set "Catppuccin Mocha"
omarchy-theme-set "Nord"
```

When switching themes, the system automatically:
- Updates Quickshell colors, status bar, and menu styling.
- Sends live OSC escape sequences to recolor open `foot` terminal sessions instantly.
- Live-imports colors for `alacritty`.
- Updates `btop` color scheme via `~/.config/btop/themes/current.theme`.
- Sets Neovim colorscheme via `~/.config/nvim/lua/plugins/theme.lua`.
- Tint Chromium/Chrome borders to match the theme accent color.
- Switches desktop wallpaper with a crossfade transition.

---

## Hardware & Power Management

### Screen Brightness Persistence
Void Linux does not have `systemd-backlight`. Quattro-Void uses `void-backlight`:
- Automatically saves brightness on shutdown (`/etc/rc.shutdown`).
- Automatically restores brightness on boot (`/etc/rc.local`) and on user desktop login (`autostart.lua`).
- Saves state instantly whenever changed via brightness keys or status bar slider.

### Audio Routing (Speakers vs Headphones)
Sound is handled by PipeWire and WirePlumber with ALSA UCM / SOF DSP profiles:
- Unprivileged users can access sound hardware through `/etc/udev/rules.d/60-sound.rules`.
- Hardware mixer levels are persisted across reboots via `alsactl store` and `alsactl restore`.
- If earphones or headphones appear silent, launch `wiremix` (`Super + Alt + A`) or run:
  ```bash
  amixer -c 0 sset 'Auto-Mute Mode' 'Disabled'
  alsactl store
  ```

### Touchpad Natural Scrolling
Configured in `~/.config/hypr/input.lua`:
```lua
input = {
  touchpad = {
    natural_scroll = true,
  },
}
```

---

## Troubleshooting

1. **Audio status bar icon shows muted after reboot:**
   PipeWire was likely started after Quickshell. Run `reload-desktop` or press `Super + Shift + R`. The installer ensures `omarchy-launch-shell` starts `void-audio-init` first.
2. **First-run notifications repeatedly appearing:**
   Markers are saved in `~/.local/state/omarchy/done/`. Run:
   ```bash
   omarchy-done mark first-run-user
   omarchy-done mark finalize-user
   omarchy-shell -q ipc notifications.dismissAll
   ```
3. **Display Manager fails to start:**
   Check runit status:
   ```bash
   sv status greetd dbus elogind
   ```
   If needed, switch to TTY2 (`Ctrl + Alt + F2`), log in, and check `/var/log/messages`.

---

## License

This project is open-source under the [MIT License](LICENSE). Assets, icons, and themes originate from [Omarchy Quattro](https://github.com/omacom/omarchy).
