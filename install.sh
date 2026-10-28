#!/usr/bin/env bash
# ==============================================================================
# QUATTRO-VOID: LIGHTWEIGHT OMARCHY QUATTRO 4.0 FORK FOR VOID LINUX
# Target User: rajan (/home/rajan)
# 1. Configures Fastly Void XBPS repos & Hyprland-Void community repo
# 2. Installs Wayland, Quickshell, PipeWire, TUI, and CLI packages
# 3. Synchronizes official Quattro assets (omarchy.ttf, 2-quattro wallpaper, themes, shell)
# 4. Installs Void compatibility shims (uwsm, systemd-cat, systemctl, pacman, magick, PAM)
# 5. Enables Runit services (dbus, NetworkManager, bluetoothd, seatd, polkitd, upowerd)
# 6. Deploys pure Quickshell desktop, Hyprland configs, and TUI shortcuts
# ==============================================================================

set -euo pipefail

TARGET_USER="${SUDO_USER:-rajan}"
TARGET_HOME="/home/${TARGET_USER}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_ok()    { printf "${GREEN}[OK]${NC}   %s\n" "$1"; }
log_warn()  { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }

echo "======================================================================"
echo "  Quattro-Void (Omarchy Quattro 4.0) Setup for Void Linux (${TARGET_USER})"
echo "======================================================================"

# 1. Configure Fastly CDN & Hyprland-Void XBPS Repositories
setup_void_repos() {
    log_info "Configuring fast Void Linux XBPS repositories..."
    sudo mkdir -p /etc/xbps.d
    if [ ! -f /etc/xbps.d/hyprland-void.conf ]; then
        echo "repository=https://github.com/void-land/hyprland-void-packages/releases/latest/download/" | sudo tee /etc/xbps.d/hyprland-void.conf >/dev/null
    fi
    echo "repository=https://repo-fastly.voidlinux.org/current" | sudo tee /etc/xbps.d/00-repository-main.conf >/dev/null
    sudo xbps-install -Suy xbps || true
    sudo xbps-install -Sy
}

# 2. Install Core Packages via XBPS
install_packages() {
    log_info "Installing Wayland, Quickshell, PipeWire, Networking, TUI, and CLI tools..."

    CORE_PKGS=(
        dbus elogind seatd polkit
        wayland wayland-protocols xorg-server-xwayland
        xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
        mesa-dri vulkan-loader
        pipewire wireplumber alsa-pipewire libspa-bluetooth
        pulsemixer alsa-utils playerctl
        NetworkManager bluez upower inotify-tools socat
        foot alacritty
        wl-clipboard cliphist wtype
        grim slurp brightnessctl file
        qt6-wayland qt6-declarative qt6-svg qt6-shadertools qt6-imageformats qt6ct
        python3 fontconfig
        zsh starship fzf zoxide eza bat fd ripgrep jq
        btop yazi lazygit calcurse neovim fastfetch git curl unzip
        nerd-fonts-symbols-ttf font-jetbrains-mono-ttf noto-fonts-ttf noto-fonts-emoji
    )

    for pkg in "${CORE_PKGS[@]}"; do
        sudo xbps-install -y "$pkg" 2>/dev/null || log_warn "Optional package '$pkg' skipped."
    done

    HYPR_PKGS=(hyprland hyprpicker xdg-desktop-portal-hyprland quickshell wiremix impala bluetuith)
    for hpkg in "${HYPR_PKGS[@]}"; do
        sudo xbps-install -y "$hpkg" 2>/dev/null || log_warn "Package '$hpkg' not in binary mirror; skipping."
    done
    log_ok "Core packages installed."
}

# 3. Synchronize Official Omarchy Quattro Assets
sync_upstream_omarchy() {
    log_info "Deploying Omarchy Quattro fonts, themes, wallpapers, and shell to /usr/share/omarchy..."
    sudo mkdir -p /usr/share/omarchy /usr/share/fonts/omarchy

    SRC_OMARCHY=""
    if [ -d "${TARGET_HOME}/omarchy/shell" ]; then
        SRC_OMARCHY="${TARGET_HOME}/omarchy"
    elif [ -d "/tmp/quattro-shallow/shell" ]; then
        SRC_OMARCHY="/tmp/quattro-shallow"
    fi

    if [ -n "$SRC_OMARCHY" ]; then
        log_info "Using local source from ${SRC_OMARCHY}..."
        sudo cp -r "$SRC_OMARCHY/shell" /usr/share/omarchy/
        sudo cp -r "$SRC_OMARCHY/themes" /usr/share/omarchy/
        sudo cp -r "$SRC_OMARCHY/default" /usr/share/omarchy/
        sudo cp -r "$SRC_OMARCHY/config" /usr/share/omarchy/
        sudo cp -r "$SRC_OMARCHY/bin" /usr/share/omarchy/
        if [ -f "$SRC_OMARCHY/default/fonts/omarchy/omarchy.ttf" ]; then
            sudo cp "$SRC_OMARCHY/default/fonts/omarchy/omarchy.ttf" /usr/share/fonts/omarchy/
        fi
    elif [ ! -f /usr/share/omarchy/shell/shell.qml ]; then
        log_info "Cloning shallow quattro branch from github.com/omacom/omarchy..."
        TMP_OMARCHY="/tmp/omarchy-quattro-$$"
        git clone --depth 1 -b quattro https://github.com/omacom/omarchy.git "$TMP_OMARCHY" || true
        if [ -d "$TMP_OMARCHY/shell" ]; then
            sudo cp -r "$TMP_OMARCHY/shell" /usr/share/omarchy/
            sudo cp -r "$TMP_OMARCHY/themes" /usr/share/omarchy/
            sudo cp -r "$TMP_OMARCHY/default" /usr/share/omarchy/
            sudo cp -r "$TMP_OMARCHY/config" /usr/share/omarchy/
            sudo cp -r "$TMP_OMARCHY/bin" /usr/share/omarchy/
            if [ -f "$TMP_OMARCHY/default/fonts/omarchy/omarchy.ttf" ]; then
                sudo cp "$TMP_OMARCHY/default/fonts/omarchy/omarchy.ttf" /usr/share/fonts/omarchy/
            fi
            rm -rf "$TMP_OMARCHY"
        fi
    fi

    # Fallback to repo bundled fonts/themes if still missing
    if [ -f "${REPO_DIR}/fonts/omarchy/omarchy.ttf" ] && [ ! -f /usr/share/fonts/omarchy/omarchy.ttf ]; then
        sudo cp "${REPO_DIR}/fonts/omarchy/omarchy.ttf" /usr/share/fonts/omarchy/
    fi

    sudo fc-cache -fv >/dev/null 2>&1 || true
    sudo chmod +x /usr/share/omarchy/bin/* 2>/dev/null || true
    sudo ln -sfn /usr/share/omarchy/shell /usr/share/omarchy/shell/qs

    # Symlink official omarchy helper scripts to /usr/local/bin
    if [ -d /usr/share/omarchy/bin ]; then
        for b in /usr/share/omarchy/bin/*; do
            [ -x "$b" ] && sudo ln -sf "$b" "/usr/local/bin/$(basename "$b")" 2>/dev/null || true
        done
    fi

    # Ensure quickshell binary symlink 'qs' exists
    if command -v quickshell >/dev/null 2>&1 && ! command -v qs >/dev/null 2>&1; then
        sudo ln -sf "$(command -v quickshell)" /usr/local/bin/qs
    fi

    log_ok "Official assets synchronized."
}

# 4. Install Void Linux Compatibility Shims
install_void_shims() {
    log_info "Installing Void Linux compatibility shims and environment variables..."
    sudo mkdir -p /usr/local/bin /etc/pam.d /etc/profile.d

    echo "OMARCHY_PATH=/usr/share/omarchy" | sudo tee /etc/omarchy.conf >/dev/null
    echo "export OMARCHY_PATH=/usr/share/omarchy" | sudo tee /etc/profile.d/omarchy.sh >/dev/null
    sudo chmod +x /etc/profile.d/omarchy.sh

    # PAM service required by Omarchy Quattro lockscreen
    cat <<'PAM' | sudo tee /etc/pam.d/omarchy-lock-password >/dev/null
auth include system-auth
PAM

    # systemd-cat shim
    cat <<'SHIM' | sudo tee /usr/local/bin/systemd-cat >/dev/null
#!/usr/bin/env bash
while [[ "${1:-}" == -* ]]; do
    if [ "$1" = "-t" ] || [ "$1" = "--identifier" ]; then
        shift 2
        continue
    fi
    if [ "$1" = "--" ]; then
        shift
        break
    fi
    shift
done
exec "$@"
SHIM
    sudo chmod +x /usr/local/bin/systemd-cat

    # systemctl shim for suspend/reboot/poweroff
    cat <<'SHIM' | sudo tee /usr/local/bin/systemctl >/dev/null
#!/usr/bin/env bash
cmd="${1:-}"
case "$cmd" in
    poweroff|power-off) exec loginctl poweroff 2>/dev/null || exec sudo poweroff ;;
    reboot) exec loginctl reboot 2>/dev/null || exec sudo reboot ;;
    suspend) exec loginctl suspend 2>/dev/null || exec zzz ;;
    hibernate) exec loginctl hibernate 2>/dev/null || exec ZZZ ;;
    is-active|status) exit 0 ;;
    *) exit 0 ;;
esac
SHIM
    sudo chmod +x /usr/local/bin/systemctl

    # uwsm and uwsm-app shim
    cat <<'SHIM' | sudo tee /usr/local/bin/uwsm >/dev/null
#!/bin/sh
while [ $# -gt 0 ]; do
    case "$1" in
        --) shift; break ;;
        --*) shift ;;
        -*) shift ;;
        *) break ;;
    esac
done
[ $# -gt 0 ] && exec "$@"
SHIM
    sudo chmod +x /usr/local/bin/uwsm
    sudo cp -f /usr/local/bin/uwsm /usr/local/bin/uwsm-app

    # systemd-run shim
    cat <<'SHIM' | sudo tee /usr/local/bin/systemd-run >/dev/null
#!/bin/sh
while [ $# -gt 0 ]; do
    case "$1" in
        --) shift; break ;;
        --unit=*|--property=*|--description=*|--slice=*|-p|--user|--quiet|--collect|--scope) shift ;;
        --*) shift ;;
        -*) shift ;;
        *) break ;;
    esac
done
[ $# -gt 0 ] && exec "$@"
SHIM
    sudo chmod +x /usr/local/bin/systemd-run

    # xdg-terminal-exec fallback shim if not present
    if [ ! -f /usr/local/bin/xdg-terminal-exec ]; then
        curl -sL https://raw.githubusercontent.com/Vladimir-csp/xdg-terminal-exec/refs/heads/master/xdg-terminal-exec | sudo tee /usr/local/bin/xdg-terminal-exec >/dev/null
        sudo chmod +x /usr/local/bin/xdg-terminal-exec
    fi

    # omasnap screenshot shim (grim + slurp)
    cat <<'SHIM' | sudo tee /usr/local/bin/omasnap >/dev/null
#!/bin/bash
for arg in "$@"; do
    if [[ -f "$arg" && "$arg" =~ \.(png|jpg|jpeg|webp)$ ]]; then
        exec imv "$arg"
    fi
done
SCREENSHOT_DIR="${OMASNAP_SCREENSHOT_DIR:-${OMARCHY_SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}}"
mkdir -p "$SCREENSHOT_DIR"
filename="$SCREENSHOT_DIR/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"
is_fullscreen=0
for arg in "$@"; do
    [[ "$arg" == "fullscreen" ]] && { is_fullscreen=1; break; }
done
if (( is_fullscreen )); then
    grim "$filename" || exit 1
else
    geometry=$(slurp 2>/dev/null)
    [ -z "$geometry" ] && exit 0
    grim -g "$geometry" "$filename" || exit 1
fi
if [ -f "$filename" ]; then
    wl-copy < "$filename"
    omarchy-notification-send -i "$filename" "Screenshot captured" "Saved to Pictures/Screenshots and copied to clipboard"
fi
SHIM
    sudo chmod +x /usr/local/bin/omasnap

    # Universal clipboard shortcut helper
    cat <<'SHIM' | sudo tee /usr/local/bin/omarchy-universal-shortcut >/dev/null
#!/bin/bash
action="$1"
active=$(hyprctl activewindow -j 2>/dev/null)
address=$(jq -r '.address // empty' <<< "$active")
class=$(jq -r '.class // empty' <<< "$active")
is_terminal=0
case "${class,,}" in
    foot*|alacritty*|kitty*|ghostty*|wezterm*|xterm*) is_terminal=1 ;;
esac
case "$action" in
    copy)
        if [[ -z "$address" ]]; then wtype -M ctrl -k c -m ctrl
        elif (( is_terminal )); then hyprctl dispatch sendshortcut "CTRL SHIFT,c,address:$address" >/dev/null
        else hyprctl dispatch sendshortcut "CTRL,c,address:$address" >/dev/null; fi ;;
    paste)
        if [[ -z "$address" ]]; then wtype -M ctrl -k v -m ctrl
        elif (( is_terminal )); then hyprctl dispatch sendshortcut "CTRL SHIFT,v,address:$address" >/dev/null
        else hyprctl dispatch sendshortcut "CTRL,v,address:$address" >/dev/null; fi ;;
    cut)
        if [[ -z "$address" ]]; then wtype -M ctrl -k x -m ctrl
        elif (( is_terminal )); then hyprctl dispatch sendshortcut "CTRL SHIFT,x,address:$address" >/dev/null
        else hyprctl dispatch sendshortcut "CTRL,x,address:$address" >/dev/null; fi ;;
    selectall)
        if [[ -z "$address" ]]; then wtype -M ctrl -k a -m ctrl
        else hyprctl dispatch sendshortcut "CTRL,a,address:$address" >/dev/null; fi ;;
esac
SHIM
    sudo chmod +x /usr/local/bin/omarchy-universal-shortcut

    # Passwordless browser policy rule
    if [ -f /home/rajan/omarchy/etc/sudoers.d/omarchy-theme-browser ]; then
        sudo cp /home/rajan/omarchy/etc/sudoers.d/omarchy-theme-browser /etc/sudoers.d/zz-omarchy-theme-browser
        sudo chmod 0440 /etc/sudoers.d/zz-omarchy-theme-browser
        sudo ln -snf /usr/share/omarchy/bin/omarchy-theme-set-browser-policy /usr/bin/omarchy-theme-set-browser-policy
    fi

    # pacman shim for xbps queries
    cat <<'SHIM' | sudo tee /usr/local/bin/pacman >/dev/null
#!/usr/bin/env bash
if [[ "${1:-}" == -Q* ]]; then
    xbps-query -l | awk '{print $2}' | sed -E 's/-[0-9][^ ]*$//'
    exit 0
fi
exit 0
SHIM
    sudo chmod +x /usr/local/bin/pacman

    # magick shim for image dimension probing
    cat <<'SHIM' | sudo tee /usr/local/bin/magick >/dev/null
#!/usr/bin/env bash
last="${@: -1}"
if [ -f "$last" ]; then
    dims=$(file -b "$last" | grep -oE "[0-9]{3,5}x[0-9]{3,5}" | head -n1 | tr "x" " ")
    if [ -n "$dims" ]; then
        echo -n "$dims"
        exit 0
    fi
fi
echo -n "2880 1800"
SHIM
    sudo chmod +x /usr/local/bin/magick

    log_ok "Compatibility shims installed."
}

# 5. Configure Runit Services & User Groups for `rajan`
setup_runit_and_groups() {
    log_info "Configuring user groups & Void runit services for '${TARGET_USER}'..."
    for grp in wheel video audio input _seatd bluetooth network storage; do
        getent group "$grp" >/dev/null 2>&1 && sudo usermod -aG "$grp" "$TARGET_USER" || true
    done

    for conflict_svc in wpa_supplicant dhcpcd; do
        [ -L "/var/service/${conflict_svc}" ] && sudo rm -f "/var/service/${conflict_svc}"
    done

    for svc in dbus elogind seatd NetworkManager bluetoothd polkitd upowerd; do
        if [ -d "/etc/sv/${svc}" ] && [ ! -L "/var/service/${svc}" ]; then
            sudo ln -sf "/etc/sv/${svc}" "/var/service/${svc}"
            log_ok "Enabled runit service: ${svc}"
        fi
    done

    sudo mkdir -p /etc/alsa/conf.d
    [ -f /usr/share/alsa/alsa.conf.d/50-pipewire.conf ] && sudo ln -sf /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d/
    [ -f /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf ] && sudo ln -sf /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/
}

# 6. Deploy Dotfiles to Target User Home
deploy_dotfiles() {
    log_info "Deploying Quattro-Void dotfiles to ${TARGET_HOME}..."
    BACKUP_DIR="${TARGET_HOME}/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "${TARGET_HOME}/.config" "${TARGET_HOME}/.local/bin" "${TARGET_HOME}/.local/state/omarchy/current/theme" "${TARGET_HOME}/Pictures/Screenshots"

    for dir in hypr quickshell omarchy foot alacritty btop yazi lazygit fastfetch; do
        if [ -e "${TARGET_HOME}/.config/${dir}" ]; then
            mkdir -p "$BACKUP_DIR"
            cp -r "${TARGET_HOME}/.config/${dir}" "$BACKUP_DIR/"
        fi
        rm -rf "${TARGET_HOME}/.config/${dir}"
        cp -r "${REPO_DIR}/config/${dir}" "${TARGET_HOME}/.config/${dir}"
    done

    # Ensure internal module symlink exists in user quickshell config
    ln -sfn "${TARGET_HOME}/.config/quickshell" "${TARGET_HOME}/.config/quickshell/qs"

    cp "${REPO_DIR}/config/starship.toml" "${TARGET_HOME}/.config/starship.toml"
    cp -f "${REPO_DIR}/local/bin/"* "${TARGET_HOME}/.local/bin/"
    chmod +x "${TARGET_HOME}/.local/bin/"*

    cp "${REPO_DIR}/zsh/.zshrc" "${TARGET_HOME}/.zshrc"
    cp "${REPO_DIR}/zsh/.zprofile" "${TARGET_HOME}/.zprofile"

    # Stage initial Tokyo Night / Quattro theme state
    THEME_SRC="/usr/share/omarchy/themes/tokyo-night"
    if [ ! -d "$THEME_SRC" ] && [ -d "${REPO_DIR}/themes/tokyo-night" ]; then
        THEME_SRC="${REPO_DIR}/themes/tokyo-night"
    fi

    if [ -d "$THEME_SRC" ]; then
        cp "$THEME_SRC/colors.toml" "${TARGET_HOME}/.local/state/omarchy/current/theme/colors.toml" 2>/dev/null || true
        cp "$THEME_SRC/shell.lock.toml" "${TARGET_HOME}/.local/state/omarchy/current/theme/shell.lock.toml" 2>/dev/null || true
        echo "tokyo-night" > "${TARGET_HOME}/.local/state/omarchy/current/theme.name"
        WP=$(find "$THEME_SRC/backgrounds" -name "2-quattro.webp" -o -name "*.webp" 2>/dev/null | head -n1 || true)
        if [ -n "$WP" ]; then
            ln -sf "$WP" "${TARGET_HOME}/.local/state/omarchy/current/background"
        fi
    fi

    if command -v zsh >/dev/null 2>&1; then
        sudo chsh -s "$(command -v zsh)" "$TARGET_USER" || true
    fi

    sudo chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.config" "${TARGET_HOME}/.local" "${TARGET_HOME}/.zshrc" "${TARGET_HOME}/.zprofile" 2>/dev/null || true
    log_ok "Dotfiles deployed to ${TARGET_HOME}."
}

setup_void_repos
install_packages
sync_upstream_omarchy
install_void_shims
setup_runit_and_groups
deploy_dotfiles

echo ""
echo "======================================================================"
log_ok "Quattro-Void setup complete! Log in on TTY1 as '${TARGET_USER}'."
echo "======================================================================"
