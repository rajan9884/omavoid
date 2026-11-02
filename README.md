# Omavoid

[![Void Linux](https://img.shields.io/badge/Void_Linux-runit_%7C_xbps-black?logo=voidlinux&logoColor=white)](https://voidlinux.org)
[![Compositor](https://img.shields.io/badge/Hyprland-0.56+-58E1E1?logo=hyprland&logoColor=black)](https://hyprland.org)
[![Shell](https://img.shields.io/badge/Quickshell-Qt6_%7C_QML-41CD52?logo=qt&logoColor=white)](https://quickshell.outfoxxed.me)
[![Audio](https://img.shields.io/badge/Audio-PipeWire_+_WirePlumber-blue)](https://pipewire.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

A modern, responsive, and keyboard-centric Wayland desktop environment engineered natively for **Void Linux**.

Omavoid pairs the high-performance **Hyprland** Wayland compositor with a custom **Quickshell** (Qt6/QML) shell layer, a rich terminal utility ecosystem, and deep integration with Void's native **runit** service supervisor and **XBPS** package manager.

---

## Highlights

- **Flush Edge-to-Edge Status Bar**: Ultra-sleek 26px top panel hosting workspaces, active window titles, dynamic indicators, system tray, network status, audio volume, power management, and clock.
- **Unified Menu & Launcher**: Fast, searchable application and command launcher with categorized navigation for tools, appearance, hardware, and system actions (`Super + Space`).
- **Interactive Flyout Panels**: Rich modal panels for PipeWire audio routing, NetworkManager Wi-Fi/Ethernet management with QR code sharing, Bluetooth device pairing, display layouts, and battery profiles.
- **Dynamic 23-Palette Theming Engine**: Switch instantly across 23 curated themes (Tokyo Night, Catppuccin, Nord, Gruvbox, Rose Pine, Dracula, and more) with real-time OSC escape terminal recoloring, wallpaper crossfades, and synchronized styling.
- **Media-Aware Smart Idle & Lock**: Integrated Wayland lockscreen and screensaver with intelligent idle inhibition that detects running audio and fullscreen video streams.
- **TUI-First Philosophy**: Preconfigured terminal workflows featuring `foot`, `yazi` file manager, `btop` system monitor, `lazygit`, `pulsemixer`, and `neovim`.
- **Pure Native Engineering**: Zero cloud telemetry, zero background trackers, and 100% native runit services.

---

## Desktop Architecture

| Subsystem | Technology | Purpose |
| :--- | :--- | :--- |
| **Compositor** | [Hyprland](https://hyprland.org) | Wayland display server, window tiling, fluid animations, and gesture handling |
| **Desktop Shell** | [Quickshell](https://quickshell.outfoxxed.me) | Status bar, quick panels, lockscreen, flyouts, and on-screen display (OSD) |
| **Init & Services** | [runit](https://voidlinux.org) | Lightweight, reliable service supervision (`dbus`, `elogind`, `seatd`, `NetworkManager`) |
| **Package Manager**| [XBPS](https://voidlinux.org) | High-speed binary package management with Fastly CDN mirrors |
| **Sound System** | [PipeWire](https://pipewire.org) + [WirePlumber](https://pipewire.org) | Modern audio routing, Bluetooth audio, and screen capture streaming |
| **Display Manager**| [greetd](https://git.sr.ht/~kennylevinsen/greetd) + [tuigreet](https://github.com/apognu/tuigreet) | Console-based graphical display manager on virtual terminal 1 |
| **Terminal** | [foot](https://codeberg.org/dnkl/foot) / [Alacritty](https://alacritty.org) | Fast, GPU-accelerated terminal emulators supporting true color and live OSC reloading |

---

## Prerequisites (Fresh Void Linux Install)

1. **Void Linux x86_64** base installation (glibc).
2. A non-root user with `wheel` permissions and necessary hardware groups:
   ```bash
   sudo useradd -m -G wheel,video,audio,input,storage -s /bin/bash <username>
   sudo passwd <username>
   ```
3. An active network connection (configured via `dhcpcd`, `wpa_supplicant`, or `nmtui`).
4. Git installed to clone the repository:
   ```bash
   sudo xbps-install -Sy git
   ```

---

## Installation

Clone the repository and run the automated installer:

```bash
git clone https://github.com/rajan9884/omavoid.git
cd omavoid
sudo ./install.sh
```

### What `install.sh` Configures Automatically:

1. **XBPS Repositories**: Adds Fastly CDN mirrors and the `hyprland-void` binary package repository.
2. **System Dependencies**: Installs Hyprland, Quickshell, PipeWire, WirePlumber, Wayland portals, foot, JetBrains Mono Nerd Font, and essential TUI tools (`yazi`, `btop`, `lazygit`, `neovim`).
3. **Display Manager**: Configures `greetd` with `tuigreet` on VT 1 to launch the Hyprland session automatically upon login.
4. **Hardware Rules & Daemons**:
   - Deploys `/etc/udev/rules.d/60-sound.rules` for unprivileged audio hardware access.
   - Sets up `/etc/rc.local` and `/etc/rc.shutdown` for backlight state and sound level persistence.
   - Configures `/etc/pam.d/void-lock-password` for secure lockscreen unlocking.
5. **Runit Services**: Enables `dbus`, `elogind`, `seatd`, `NetworkManager`, `bluetoothd`, `polkitd`, and `greetd`.
6. **User Configuration Symlinks**: Creates atomic symlinks from your clone to `~/.config/`, ensuring that dotfile updates are immediately reflected without duplicating files.

Once the installer finishes, reboot your system:

```bash
sudo reboot
```

---

## Keybindings Reference

### System & Shell Controls

| Shortcut | Description |
| :--- | :--- |
| `SUPER + Space` | Open Unified Application & System Menu |
| `SUPER + Esc` | Power Menu (Lock, Logout, Suspend, Reboot, Power Off) |
| `SUPER + K` | Interactive Keybindings Cheatsheet |
| `SUPER + Ctrl + L` / `SUPER + L` | Lock Session |
| `SUPER + Shift + Space` | Toggle Status Bar visibility |
| `SUPER + Ctrl + Space` | Wallpaper Background Selector |
| `SUPER + Shift + Ctrl + Space` | Dynamic Theme Switcher |
| `SUPER + Shift + R` | Restart Desktop Shell & Reload Compositor |

### Window Management & Tiling

| Shortcut | Description |
| :--- | :--- |
| `SUPER + W` | Close focused window |
| `SUPER + F` | Toggle fullscreen mode |
| `SUPER + T` | Toggle floating mode for focused window |
| `SUPER + H / J / K / L` | Move window focus (Left, Down, Up, Right) |
| `SUPER + Shift + H / J / K / L` | Move window position within layout |
| `SUPER + 1 .. 9` | Switch to Workspace 1–9 |
| `SUPER + Shift + 1 .. 9` | Move focused window to Workspace 1–9 |
| `SUPER + S` | Toggle special scratchpad workspace |

### Terminals & Applications

| Shortcut | Description |
| :--- | :--- |
| `SUPER + Enter` | Open Terminal (`foot`) |
| `SUPER + Shift + B` | Web Browser (`helium-browser`) |
| `SUPER + B` | System Monitor (`btop` floating card) |
| `SUPER + Shift + F` | File Manager (`yazi` floating card) |
| `SUPER + G` | Git Interface (`lazygit` floating card) |
| `SUPER + Shift + M` | Music Player (`cliamp`) |
| `SUPER + Alt + A` | Audio Mixer (`wiremix` / `pulsemixer`) |
| `SUPER + Alt + N` | Wi-Fi Connection Manager (`impala` / `nmtui`) |
| `SUPER + Alt + B` | Bluetooth Device Manager (`bluetuith`) |
| `SUPER + Alt + X` | Interactive Void Package Manager (`xbps` + `fzf`) |

### Clipboard, Screenshots & Utilities

| Shortcut | Description |
| :--- | :--- |
| `SUPER + Ctrl + V` | Open Clipboard History Drawer |
| `SUPER + C` / `SUPER + V` | Universal Copy / Paste (smart detection for terminals vs GUI apps) |
| `SUPER + X` / `SUPER + A` | Universal Cut / Select All |
| `Print` | Interactive Region Screenshot (saved to `~/Pictures/Screenshots` & copied) |
| `SUPER + Ctrl + Print` | OCR screen region directly to clipboard (`ocr-extract`) |
| `SUPER + Ctrl + Alt + C` | Alternate Region Screenshot shortcut |
| `SUPER + ,` | Dismiss top notification toast |
| `SUPER + Shift + ,` | Dismiss all notification toasts |
| `SUPER + Ctrl + Alt + ,` | Toggle Do-Not-Disturb mode |

---

## Dynamic Theming Engine

Omavoid features 23 themes that modify the desktop palette simultaneously across GUI and TUI layers:

- **Tokyo Night** (Default)
- **Catppuccin** (Mocha, Macchiato, Frappe, Latte)
- **Nord**
- **Gruvbox** (Dark & Light)
- **Rose Pine** (Main, Moon, Dawn)
- **Dracula**
- **Solarized** (Dark & Light)
- **Everforest**
- **Kanagawa**
- **One Dark** & **One Light**
- **Vantablack**

### Changing Themes:

- **Via GUI**: Press `SUPER + Shift + Ctrl + Space` to launch the visual theme picker.
- **Via CLI**:
  ```bash
  void theme set "Tokyo Night"
  void theme set "Catppuccin Mocha"
  void theme set "Nord"
  ```

### What Happens During Theme Switches:
1. **Quickshell**: Recompiles semantic colors for the status bar, menus, flyouts, and lockscreen.
2. **Terminal Recolor**: Emits live OSC escape sequences to recolor open `foot` windows instantly without restarting shells.
3. **Configuration Templates**: Updates `alacritty.toml`, `btop.theme`, `yazi/theme.toml`, and `neovim` syntax colors.
4. **Wallpaper**: Applies the coordinated high-resolution wallpaper with a smooth crossfade animation.

---

## Hardware & Power Management

### Screen Brightness Persistence
Because Void Linux does not use `systemd-backlight`, Omavoid provides `void-backlight`:
- Saves current display brightness to `/var/lib/backlight/` upon shutdown or suspend.
- Restores saved brightness on boot via `/etc/rc.local` and user session startup.
- Supports fine-grained hardware brightness adjustments via dedicated laptop keys.

### Audio Routing & Smart Media Detection
PipeWire and WirePlumber manage audio streams with auto-detection for headphones, USB audio DACs, and built-in speakers:
- Hardware mixer levels are persisted across reboots via ALSA hooks.
- **Idle Monitor Integration**: The screen locker checks if PipeWire audio sinks are actively playing before initiating idle timeouts. Streaming music or watching video (even in windowed mode) prevents unwanted screen lockouts.

### Touchpad Gestures & Natural Scrolling
Configured in `~/.config/hypr/input.lua`:
- Natural scrolling enabled by default.
- Tap-to-click and 3-finger / 4-finger workspace swipe gestures.

---

## CLI Management (`void` Command)

Omavoid provides a unified `void` command-line helper:

```bash
# General
void --help                  # View available CLI commands
void menu                    # Open unified application menu
void lock                    # Lock session immediately

# Theming & Wallpaper
void theme                   # Open theme picker
void theme set <theme-name>  # Apply specific theme
void bg                      # Open wallpaper picker

# Status Bar & Panels
void bar position top        # Set bar position (top, bottom, left, right)
void bar background glassy   # Set bar styling (opaque, glassy, none)
void shell ping              # Test communication with Quickshell

# Media & Capture
void capture screenshot      # Capture full screen
void capture region          # Interactively pick and capture region
void toggle idle             # Toggle stay-awake mode
```

---

## Troubleshooting

1. **Audio icon shows muted or unavailable:**
   WirePlumber or PipeWire may need a restart. Run:
   ```bash
   void-restart-audio
   ```
   Or press `SUPER + Shift + R` to reload the desktop shell.

2. **Resetting Desktop State:**
   To reinitialize all quickshell widgets and restore default layouts:
   ```bash
   void-bar defaults
   void-restart-shell
   ```

3. **Verifying Runit Services:**
   Check the status of system services:
   ```bash
   sudo sv status greetd dbus elogind NetworkManager
   ```

---

## License

This project is open-source under the [MIT License](LICENSE).
Built with passion for the **Void Linux** community.
