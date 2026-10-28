# Quattro-Void: Lightweight Omarchy Quattro (4.0) Desktop for Void Linux

A lightweight, bloat-free fork of **Omarchy Quattro (4.0)** engineered specifically for **Void Linux** (`runit` + `xbps` + `pipewire`). It provides the exact appearance, aesthetics, flush 26px edge-to-edge status bar, flyout cards, unified menu, wallpaper transitions, and lockscreen from official Omarchy Quattro while completely stripping out all AI integrations and cloud bloat.

Pre-configured and tested for user **`rajan`** (`/home/rajan`).

---

## Key Highlights & Architectural Differences

| Feature | Upstream Omarchy Quattro | Quattro-Void (This Fork) |
| :--- | :--- | :--- |
| **Shell Engine** | Pure Quickshell (`Qt6` + `QML`) | **Pure Quickshell** (direct code from official upstream) |
| **Visual Aesthetics** | Flush 26px top bar, glassy flyouts, official `omarchy.ttf` icons | **Identical 1:1 aesthetics**, typography, glyphs, and animations |
| **AI Integrations** | Claude, Codex, Fireworks, Grok agents running in background | **100% Stripped Out** (Zero AI bloat, zero background telemetry) |
| **Cloud Services** | Dropbox, Tailscale, Ookla speedtest daemons | **Removed** (Only local hardware & network controls) |
| **App Philosophy** | Relies on GNOME desktop apps (Nautilus, Loupe, etc.) | **TUI-First & Minimal**: `yazi`, `btop`, `lazygit`, `pulsemixer`, `impala`, `bluetuith` |
| **Init & Packages** | Systemd + Arch Linux `pacman` | **Void Linux Runit** + **`xbps`** + **`pipewire`** with drop-in shims |
| **Daily CLI Tools** | Custom Arch-specific CLI commands | Fast productivity tools: `fzf`, `zoxide`, `eza`, `bat`, `starship` |

---

## Features

- **Exact Quattro Status Bar**:
  - **Left Section**: Minimal Omarchy Menu icon button (`omarchy.menu`), 12px spacer, workspace switcher slots (`1..5+` with focused glyph `󱗻`).
  - **Center Box**: Clock (`omarchy.clock`) displaying day and time, surrounded by indicator pills (`omarchy.indicators`) and weather forecast (`omarchy.weather`). Double-clicking bar switches between opaque, glassy, and translucent styles.
  - **Right Section**: Dedicated icon buttons for System Tray (`omarchy.tray`), Keyboard layout (`omarchy.keyboard-layout`), Bluetooth (`omarchy.bluetooth`), Network (`omarchy.network`), Audio (`omarchy.audio`), Monitor / Display (`omarchy.monitor`), and Power (`omarchy.power` with toggleable battery percentage).
- **Authentic Flyout Panels**:
  - Left-clicking any status bar widget smoothly opens its respective card: audio sinks/volume, Wi-Fi networks, Bluetooth devices, brightness/scaling, power profiles/shutdown, and calendar.
- **Unified Menu & Overlays**:
  - Super-fast unified search and action menu (`Super + Space`).
  - Native Quickshell applications grid (`Super + Alt + Space`).
  - Persistent clipboard history manager with image and text preview (`Super + Ctrl + V`).
  - Notification toasts with interactive actions and history drawer (`Super + Shift + Alt + ,`).
  - Wayland layer-shell session lockscreen (`WlSessionLock`).
  - Volume, mic mute, and brightness HUD OSD overlays.

---

## Keybindings Reference

### Shell & Panels
| Shortcut | Action |
| :--- | :--- |
| `SUPER + SPACE` | Unified Omarchy Menu |
| `SUPER + ALT + SPACE` | Applications Launcher Grid |
| `SUPER + CTRL + V` | Clipboard Manager & History Overlay |
| `SUPER + CTRL + A` | Audio Control Panel |
| `SUPER + CTRL + B` | Bluetooth Control Panel |
| `SUPER + CTRL + N` / `SUPER + CTRL + W` | Network & Wi-Fi Panel |
| `SUPER + CTRL + D` | Monitor, Display & Nightlight Panel |
| `SUPER + CTRL + P` / `SUPER + ESCAPE` | Power & Session Panel |
| `SUPER + CTRL + ALT + D` | Calendar & Clock Panel |
| `SUPER + CTRL + L` / `SUPER + L` | Lock Screen (`omarchy-lock`) |
| `SUPER + SHIFT + SPACE` | Toggle Status Bar visibility |
| `SUPER + SHIFT + ALT + ,` | Notification History Drawer |
| `SUPER + SHIFT + R` | Reload Desktop & Restart Quickshell |

### Terminals & TUIs
| Shortcut | Action |
| :--- | :--- |
| `SUPER + ENTER` | Launch Terminal (Alacritty / Foot) |
| `SUPER + E` | File Manager (`yazi` floating) |
| `SUPER + B` | System Activity & Resource Monitor (`btop` floating) |
| `SUPER + G` | Git Interface (`lazygit` floating) |
| `SUPER + ALT + A` | Audio Mixer TUI (`wiremix` or `pulsemixer`) |
| `SUPER + ALT + N` | Wi-Fi Manager TUI (`impala` or `nmtui`) |
| `SUPER + ALT + B` | Bluetooth Manager TUI (`bluetuith`) |
| `SUPER + ALT + X` | Interactive Void Package Manager (`xbps` + `fzf`) |

### Window Management & Workspaces
| Shortcut | Action |
| :--- | :--- |
| `SUPER + Q` / `SUPER + W` | Close focused window |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + SHIFT + SPACE` | Toggle floating mode |
| `SUPER + H / J / K / L` | Move focus (left / down / up / right) |
| `SUPER + SHIFT + H / J / K / L` | Move window |
| `SUPER + 1 .. 9` | Switch to workspace 1 through 9 |
| `SUPER + SHIFT + 1 .. 9` | Move window to workspace 1 through 9 |
| `SUPER + S` | Toggle Special Scratchpad workspace |
| `Print` | Screenshot region (`grim` + `slurp`) |
| `SHIFT + Print` | Screenshot fullscreen |
| `SUPER + SHIFT + C` | Hyprpicker color dropper |

---

## One-Command Setup

To deploy or reinstall on Void Linux:

```bash
cd ~/quattro-void-dotfiles
chmod +x install.sh
./install.sh
```

The installer automatically:
1. Enables the Fastly CDN mirror and Hyprland-Void XBPS repository.
2. Installs required Wayland, Quickshell, PipeWire, TUI, and font packages.
3. Deploys the official `omarchy.ttf` icon font and Tokyo Night / Quattro themes.
4. Installs compatibility shims for Void Linux (`systemd-cat`, `systemctl`, `uwsm`, `pacman`, `magick`, PAM).
5. Configures and starts Void `runit` services (`dbus`, `NetworkManager`, `bluetoothd`, `polkitd`, `seatd`, `upowerd`).
6. Deploys dotfiles to `~/.config` and `~/.local/bin`.

