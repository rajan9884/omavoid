#!/usr/bin/env bash
# ==============================================================================
# OMAVOID: LIGHTWEIGHT DESKTOP ENVIRONMENT FOR VOID LINUX
# Fully reproducible fresh-install automation for Void Linux (x86_64 runit)
#
# Flags:
#   -m, --minimal  : Installs minimal core environment and essential configs
#   --dry-run      : Previews actions without making changes
#   -h, --help     : Shows usage instructions
#
# Default (full) mode installs all packages defined in package.txt and configures
# complete desktop, utilities, tools, and user workflows.
# ==============================================================================

set -euo pipefail

INSTALL_MODE="full"
DRY_RUN=0

usage() {
    cat <<USAGE
Usage: ./install.sh [OPTIONS]

Options:
  -m, --minimal    Minimal desktop install (installs only [minimal] core packages & configs)
  --dry-run        Print actions without modifying the system
  -h, --help       Show this help message

By default, Omavoid installer runs in full mode, installing all core, utility, and desktop apps
defined in package.txt and skipping any packages already installed.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--minimal)
            INSTALL_MODE="minimal"
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# Determine target non-root user and home directory dynamically
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
elif [ "$(id -un)" != "root" ]; then
    TARGET_USER="$(id -un)"
else
    TARGET_USER="$(logname 2>/dev/null || id -un 1000 2>/dev/null || echo "user")"
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)"
[ -z "$TARGET_HOME" ] && TARGET_HOME="/home/${TARGET_USER}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

log_info()  { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_ok()    { printf "${GREEN}[OK]${NC}   %s\n" "$1"; }
log_warn()  { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_mode()  { printf "${CYAN}[MODE]${NC} %s\n" "$1"; }

echo "======================================================================"
echo "  Omavoid Desktop Setup for Void Linux"
echo "  Target User: ${TARGET_USER} (${TARGET_HOME})"
log_mode "Installation Mode: ${INSTALL_MODE^^}"
[ "$DRY_RUN" -eq 1 ] && log_warn "DRY-RUN enabled: No changes will be committed."
echo "======================================================================"

# Ensure sudo credentials upfront if not dry-run
if [ "$(id -u)" -ne 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    log_info "Elevating privileges for system packages and service configuration..."
    sudo -v || { echo "Administrator privileges required to continue." >&2; exit 1; }
    while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_PID=$!
    trap 'kill "$SUDO_PID" 2>/dev/null || true' EXIT
fi

# 1. Configure Fastly CDN & Hyprland XBPS Repositories
setup_void_repos() {
    log_info "Configuring Void Linux XBPS repositories and kernel tracking..."
    if [ "$DRY_RUN" -eq 1 ]; then return 0; fi

    sudo mkdir -p /etc/xbps.d
    # Remove legacy void-land repo if present (outdated; superseded by void.creations.works)
    sudo rm -f /etc/xbps.d/hyprland-void.conf
    if [ ! -f /etc/xbps.d/creations.conf ]; then
        echo "repository=https://void.creations.works" | sudo tee /etc/xbps.d/creations.conf > /dev/null
    fi
    echo "repository=https://repo-fastly.voidlinux.org/current" | sudo tee /etc/xbps.d/00-repository-main.conf > /dev/null

    # Enable nonfree repository for firmware, proprietary drivers, and media utilities
    sudo xbps-install -Sy void-repo-nonfree 2>/dev/null || true

    local vp_dir="${TARGET_HOME}/.local/share/pkg/void-packages"
    if [ ! -d "$vp_dir" ]; then
        log_info "Cloning void-packages (custom branch) for standalone custom builds..."
        sudo -u "$TARGET_USER" mkdir -p "$(dirname "$vp_dir")"
        sudo -u "$TARGET_USER" git clone -b custom https://github.com/rajan9884/void-packages.git "$vp_dir" 2>/dev/null || log_warn "Could not clone void-packages repo; skipping."
    fi

    if [ -d "$vp_dir/hostdir/binpkgs/custom" ]; then
        cat << EOF | sudo tee /etc/xbps.d/10-custom.conf >/dev/null
repository=$vp_dir/hostdir/binpkgs/custom
repository=$vp_dir/hostdir/binpkgs/custom/nonfree
EOF
    fi

    # Route generic kernel packages to upstream mainline series (rolling-release)
    cat << 'EOF' | sudo tee /etc/xbps.d/kernel.conf >/dev/null
# Route generic kernel packages to upstream mainline series
virtualpkg=linux:linux-mainline
virtualpkg=linux-headers:linux-mainline-headers
EOF

    sudo xbps-install -Suy xbps || true
    sudo xbps-install -Sy
}

# Helper to read package list from package.txt
parse_package_file() {
    local pkg_file="$1"
    local mode="$2"
    local in_minimal=0
    local raw_pkgs=()

    if [ ! -f "$pkg_file" ]; then
        log_warn "Package file '$pkg_file' not found!"
        return 0
    fi

    while IFS= read -r line || [ -n "$line" ]; do
        # Strip comments and surrounding whitespace
        line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Section header check
        if [[ "$line" =~ ^\[(.*)\]$ ]]; then
            local section="${BASH_REMATCH[1]}"
            if [ "$section" = "minimal" ]; then
                in_minimal=1
            else
                in_minimal=0
            fi
            continue
        fi

        local pkg
        pkg="$(echo "$line" | awk '{print $1}')"
        [ -z "$pkg" ] && continue

        if [ "$mode" = "minimal" ]; then
            if [ "$in_minimal" -eq 1 ]; then
                raw_pkgs+=("$pkg")
            fi
        else
            raw_pkgs+=("$pkg")
        fi
    done < "$pkg_file"

    # Deduplicate package names preserving order
    printf '%s\n' "${raw_pkgs[@]}" | awk '!seen[$0]++'
}

# 2. Install Packages via XBPS from package.txt
install_packages() {
    local pkg_file="${REPO_DIR}/package.txt"
    log_info "Parsing packages from ${pkg_file} (mode: ${INSTALL_MODE})..."

    local pkgs=()
    mapfile -t pkgs < <(parse_package_file "$pkg_file" "$INSTALL_MODE")

    if [ ${#pkgs[@]} -eq 0 ]; then
        log_warn "No packages found in ${pkg_file} for mode '${INSTALL_MODE}'."
        return 0
    fi

    log_info "Evaluating ${#pkgs[@]} requested packages against system..."

    # Filter out already installed packages to avoid redundant RSA/hash verification & I/O
    local installed_pkgs
    installed_pkgs="$(xbps-query -l 2>/dev/null | awk '{print $2}' | sed -E 's/-[^-]+_[0-9]+$//')"

    local to_install=()
    for pkg in "${pkgs[@]}"; do
        if ! grep -Fxq "$pkg" <<< "$installed_pkgs"; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        log_info "Batch installing ${#to_install[@]} missing packages: ${to_install[*]}"
        if [ "$DRY_RUN" -eq 0 ]; then
            if ! sudo xbps-install -y "${to_install[@]}"; then
                log_warn "Batch install encountered missing/unavailable package; falling back to resilient per-package install..."
                for pkg in "${to_install[@]}"; do
                    sudo xbps-install -y "$pkg" 2>/dev/null || log_warn "Package '$pkg' skipped or unavailable in repositories."
                done
            fi
        fi
    else
        log_ok "All ${#pkgs[@]} requested packages are already installed."
    fi

    if [ "$DRY_RUN" -eq 1 ]; then return 0; fi

    # Standalone Tool: herdr (AI workspace manager)
    if ! command -v herdr >/dev/null 2>&1 && [ ! -x "${TARGET_HOME}/.local/bin/herdr" ] && [ "$INSTALL_MODE" != "minimal" ]; then
        log_info "Installing herdr (AI workspace manager)..."
        sudo -u "$TARGET_USER" sh -c "curl -fsSL https://herdr.dev/install.sh | sh" 2>/dev/null || log_warn "Could not install herdr automatically."
    fi
    if [ -x "${TARGET_HOME}/.local/bin/herdr" ]; then
        sudo ln -sf "${TARGET_HOME}/.local/bin/herdr" /usr/local/bin/herdr 2>/dev/null || true
    fi

    # Standalone Tool: hyprsunset (Night light filter for Hyprland)
    if ! command -v hyprsunset >/dev/null 2>&1; then
        log_info "Building and installing hyprsunset from source..."
        local sunset_dir
        sunset_dir=$(mktemp -d)
        if git clone --depth 1 https://github.com/hyprwm/hyprsunset.git "$sunset_dir" 2>/dev/null && \
           cmake -B "$sunset_dir/build" -S "$sunset_dir" -G Ninja -DCMAKE_BUILD_TYPE=Release 2>/dev/null && \
           cmake --build "$sunset_dir/build" 2>/dev/null && \
           sudo cmake --install "$sunset_dir/build" 2>/dev/null; then
            log_ok "hyprsunset built and installed successfully."
        else
            log_warn "Failed to compile hyprsunset."
        fi
        rm -rf "$sunset_dir"
    fi

    # Purge legacy LTS kernels and clean boot images
    if xbps-query -l 2>/dev/null | grep -q 'linux6.12'; then
        sudo xbps-remove -y -F linux6.12 2>/dev/null || true
    fi
    sudo vkpurge rm all 2>/dev/null || true
    sudo update-grub 2>/dev/null || true
    log_ok "Package installation step finished."
}

# 3. Synchronize Desktop Assets
sync_dotfiles_assets() {
    log_info "Synchronizing Omavoid assets and linking system defaults to dotfiles..."
    if [ "$DRY_RUN" -eq 1 ]; then return 0; fi

    sudo mkdir -p /usr/share/void /usr/local/bin

    # Unify /usr/share/void directly with dotfiles
    sudo rm -rf /usr/share/void/bin \
                /usr/share/void/config \
                /usr/share/void/default \
                /usr/share/void/install \
                /usr/share/void/shell \
                /usr/share/void/themes 2>/dev/null || true

    sudo ln -sfn "${REPO_DIR}/bin" /usr/share/void/bin
    sudo ln -sfn "${REPO_DIR}/config" /usr/share/void/config
    sudo ln -sfn "${REPO_DIR}/config/quickshell" /usr/share/void/shell
    sudo ln -sfn "${REPO_DIR}/themes" /usr/share/void/themes

    # Grant user ownership
    sudo chown -R "${TARGET_USER}:${TARGET_USER}" /usr/share/void "${REPO_DIR}"

    # Deploy JetBrainsMono Nerd Font if present in repo
    if [ -d "${REPO_DIR}/fonts/JetBrainsMono" ]; then
        sudo mkdir -p /usr/share/fonts/JetBrainsMono
        sudo cp -f "${REPO_DIR}/fonts/JetBrainsMono/"*.ttf /usr/share/fonts/JetBrainsMono/ 2>/dev/null || true
    fi
    sudo fc-cache -fv >/dev/null 2>&1 || true
    chmod +x "${REPO_DIR}/bin/"* 2>/dev/null || true

    # Clean dangling symlinks in /usr/local/bin
    sudo find /usr/local/bin -xtype l -delete 2>/dev/null || true

    # Symlink helper scripts to /usr/local/bin
    if [ -d "${REPO_DIR}/bin" ]; then
        for b in "${REPO_DIR}/bin/"*; do
            [ -x "$b" ] && sudo ln -sf "$b" "/usr/local/bin/$(basename "$b")" 2>/dev/null || true
        done
    fi

    # Ensure quickshell binary symlink 'qs' exists
    if command -v quickshell >/dev/null 2>&1 && ! command -v qs >/dev/null 2>&1; then
        sudo ln -sf "$(command -v quickshell)" /usr/local/bin/qs
    fi

    log_ok "Desktop assets synchronized and unified with dotfiles."
}

# 4. Install Void Linux Environment and Shims
install_void_shims() {
    log_info "Configuring Void Linux environment and desktop integration..."
    if [ "$DRY_RUN" -eq 1 ]; then return 0; fi

    sudo mkdir -p /usr/local/bin /etc/pam.d /etc/profile.d /etc/udev/hwdb.d

    echo "export VOID_PATH=/usr/share/void" | sudo tee /etc/profile.d/void.sh >/dev/null
    sudo chmod +x /etc/profile.d/void.sh

    # PAM service for lockscreen
    cat <<'PAM' | sudo tee /etc/pam.d/void-lock-password >/dev/null
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

    # uwsm and uwsm-app shim
    cat <<'SHIM' | sudo tee /usr/local/bin/uwsm >/dev/null
#!/bin/sh
if [ "$1" = "stop" ]; then
    hyprctl dispatch exit >/dev/null 2>&1 || loginctl terminate-user "$USER" 2>/dev/null || true
    exit 0
fi

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

    # systemd-inhibit to elogind-inhibit symlink
    if [ -x /usr/bin/elogind-inhibit ]; then
        sudo ln -sf /usr/bin/elogind-inhibit /usr/local/bin/systemd-inhibit
    fi

    # Configure greetd with tuigreet
    if command -v tuigreet >/dev/null 2>&1; then
        sudo mkdir -p /etc/greetd
        cat <<'GREETD' | sudo tee /etc/greetd/config.toml >/dev/null
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-user-session --sessions /usr/share/wayland-sessions --session-wrapper 'dbus-run-session' --cmd /usr/bin/start-hyprland --power-shutdown 'loginctl poweroff' --power-reboot 'loginctl reboot' --asterisks"
user = "_greeter"
GREETD
        sudo chmod -R go+r /etc/greetd
        getent passwd _greeter >/dev/null 2>&1 && sudo usermod -aG video,input _greeter || true

        # Ensure greetd run script checks for dbus and elogind
        if [ -d /etc/sv/greetd ]; then
            cat <<'RUN' | sudo tee /etc/sv/greetd/run >/dev/null
#!/bin/sh
exec 2>&1
sv check dbus >/dev/null || exit 1
sv check elogind >/dev/null || exit 1
exec greetd
RUN
            sudo chmod +x /etc/sv/greetd/run
        fi
    fi

    # Hardware Fix: Acer Swift Go microphone mute key (scancode 0x8a -> f20)
    cat <<'HWDB' | sudo tee /etc/udev/hwdb.d/99-acer-swift-micmute.hwdb >/dev/null
# Acer Swift laptop mic mute key (F4 bare press scancode 0x8a)
evdev:atkbd:dmi:bvn*:bvr*:bd*:svnAcer*:pn*Swift*:*
evdev:atkbd:dmi:bvn*:bvr*:bd*:svnAcer*:pn*SFG14-71*:*
 KEYBOARD_KEY_8a=f20
HWDB
    sudo systemd-hwdb update 2>/dev/null || sudo udevadm hwdb --update 2>/dev/null || true
    sudo udevadm trigger --subsystem-match=input 2>/dev/null || true

    # Backlight and ALSA save/restore across reboots
    sudo mkdir -p /var/lib/backlight
    sudo chown root:video /var/lib/backlight 2>/dev/null || true
    sudo chmod 775 /var/lib/backlight 2>/dev/null || true
    cat <<'RC' | sudo tee /etc/rc.local >/dev/null
#!/bin/sh
# Ensure sound hardware permissions and ALSA state access for audio group
(
    for i in $(seq 1 50); do
        if [ -e /dev/snd/controlC0 ]; then
            chmod -R 660 /dev/snd/* 2>/dev/null
            chgrp -R audio /dev/snd/* 2>/dev/null
            udevadm trigger --subsystem-match=sound 2>/dev/null
            break
        fi
        sleep 0.2
    done
    if [ -d /var/lib/alsa ]; then
        chgrp -R audio /var/lib/alsa 2>/dev/null
        chmod -R g+rwX /var/lib/alsa 2>/dev/null
    fi
    command -v alsactl >/dev/null 2>&1 && alsactl restore
) &

# Immediate pass for static nodes
chmod -R 660 /dev/snd/* 2>/dev/null
chgrp -R audio /dev/snd/* 2>/dev/null

[ -x /usr/local/bin/void-backlight ] && /usr/local/bin/void-backlight restore &
RC
    sudo chmod +x /etc/rc.local
    cat <<'RC' | sudo tee /etc/rc.shutdown >/dev/null
#!/bin/sh
command -v alsactl >/dev/null 2>&1 && alsactl store
[ -x /usr/local/bin/void-backlight ] && /usr/local/bin/void-backlight save
RC
    sudo chmod +x /etc/rc.shutdown

    # Mark Void first-run as completed
    mkdir -p "${TARGET_HOME}/.local/state/void/done"
    touch "${TARGET_HOME}/.local/state/void/done/first-run-user"
    touch "${TARGET_HOME}/.local/state/void/done/finalize-user"

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

    # xdg-terminal-exec fallback shim if not present or empty
    if [ ! -s /usr/local/bin/xdg-terminal-exec ] || [ ! -x /usr/local/bin/xdg-terminal-exec ]; then
        curl -sL https://raw.githubusercontent.com/Vladimir-csp/xdg-terminal-exec/refs/heads/master/xdg-terminal-exec | sudo tee /usr/local/bin/xdg-terminal-exec >/dev/null
        sudo chmod +x /usr/local/bin/xdg-terminal-exec
    fi
    sudo mkdir -p /etc/xdg
    echo "foot.desktop" | sudo tee /etc/xdg/xdg-terminals.list >/dev/null

    # omasnap screenshot compatibility shim
    cat <<'SHIM' | sudo tee /usr/local/bin/omasnap >/dev/null
#!/usr/bin/env bash
for arg in "$@"; do
    if [[ -f "$arg" && "$arg" =~ \.(png|jpg|jpeg|webp)$ ]]; then
        exec imv "$arg"
    fi
done
exec void-capture-screenshot "$@"
SHIM
    sudo chmod +x /usr/local/bin/omasnap

    # Sudoers rules for passwordless power management & greetd enablement
    cat <<SUDO | sudo tee /etc/sudoers.d/zz-void-power >/dev/null
${TARGET_USER} ALL=(root) NOPASSWD: /usr/bin/reboot, /usr/bin/poweroff, /usr/bin/shutdown, /usr/bin/halt, /usr/bin/zzz, /usr/bin/ZZZ, /usr/local/bin/void-enable-greetd
SUDO
    sudo chmod 0440 /etc/sudoers.d/zz-void-power

    # pacman shim for xbps queries and package operations
    cat <<'SHIM' | sudo tee /usr/local/bin/pacman >/dev/null
#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"
shift || true

case "$cmd" in
    -Q*|-q*)
        xbps-query -l | awk '{print $2}' | sed -E 's/-[0-9][^ ]*$//'
        ;;
    -S*|-s*)
        pkgs=()
        for arg in "$@"; do
            [[ "$arg" == -* ]] && continue
            pkgs+=("$arg")
        done
        if [ ${#pkgs[@]} -gt 0 ]; then
            exec xbps-install -y "${pkgs[@]}"
        fi
        ;;
    -R*|-r*)
        pkgs=()
        for arg in "$@"; do
            [[ "$arg" == -* ]] && continue
            pkgs+=("$arg")
        done
        if [ ${#pkgs[@]} -gt 0 ]; then
            exec xbps-remove -y "${pkgs[@]}"
        fi
        ;;
    *)
        exit 0
        ;;
esac
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

# 5. Configure Runit Services, Hardware Rules, and User Groups
setup_runit_and_groups() {
    log_info "Configuring user groups & Void runit services for '${TARGET_USER}'..."
    if [ "$DRY_RUN" -eq 1 ]; then return 0; fi

    for grp in wheel video audio input _seatd bluetooth network storage; do
        getent group "$grp" >/dev/null 2>&1 && sudo usermod -aG "$grp" "$TARGET_USER" || true
    done

    # Remove conflicting network services if NetworkManager is used
    for conflict_svc in wpa_supplicant dhcpcd; do
        [ -L "/var/service/${conflict_svc}" ] && sudo rm -f "/var/service/${conflict_svc}"
    done

    # Enable essential runit services
    for svc in dbus elogind seatd NetworkManager bluetoothd polkitd acpid power-profiles-daemon; do
        if [ -d "/etc/sv/${svc}" ] && [ ! -L "/var/service/${svc}" ]; then
            sudo ln -sf "/etc/sv/${svc}" "/var/service/${svc}"
            log_ok "Enabled runit service: ${svc}"
        fi
    done

    # Prevent acpid from double-stepping backlight brightness
    if [ -f /etc/acpi/handler.sh ]; then
        sudo sed -i 's/^\([[:space:]]*step_backlight\)/#\1/' /etc/acpi/handler.sh 2>/dev/null || true
    fi

    # Enable bluetoothd experimental flags for modern BLE/LE Audio profiles
    if [ -d /etc/sv/bluetoothd ]; then
        echo 'OPTS="-E"' | sudo tee /etc/sv/bluetoothd/conf >/dev/null
    fi

    # Configure BlueZ main.conf for automatic connection and pairing recovery
    if [ -f /etc/bluetooth/main.conf ]; then
        sudo sed -i 's/^#*Name *=.*/Name = void/' /etc/bluetooth/main.conf 2>/dev/null || true
        sudo sed -i 's/^#*AutoEnable *=.*/AutoEnable = true/' /etc/bluetooth/main.conf 2>/dev/null || true
        sudo sed -i 's/^#*AlwaysPairable *=.*/AlwaysPairable = true/' /etc/bluetooth/main.conf 2>/dev/null || true
        sudo sed -i 's/^#*FastConnectable *=.*/FastConnectable = true/' /etc/bluetooth/main.conf 2>/dev/null || true
        sudo sed -i 's/^#*JustWorksRepairing *=.*/JustWorksRepairing = always/' /etc/bluetooth/main.conf 2>/dev/null || true
        sudo sed -i 's/^#*PairableTimeout *=.*/PairableTimeout = 0/' /etc/bluetooth/main.conf 2>/dev/null || true
        sudo sed -i 's/^#*DiscoverableTimeout *=.*/DiscoverableTimeout = 0/' /etc/bluetooth/main.conf 2>/dev/null || true
        sudo sed -i 's/^#*MultiProfile *=.*/MultiProfile = multiple/' /etc/bluetooth/main.conf 2>/dev/null || true
    fi

    # Optimize glibc memory arenas to prevent memory bloat across multithreaded daemons
    if [ -f /etc/environment ]; then
        grep -q 'MALLOC_ARENA_MAX' /etc/environment || echo 'MALLOC_ARENA_MAX=2' | sudo tee -a /etc/environment >/dev/null
        grep -q 'MALLOC_TRIM_THRESHOLD_' /etc/environment || echo 'MALLOC_TRIM_THRESHOLD_=131072' | sudo tee -a /etc/environment >/dev/null
    fi

    # Enable greetd display manager if installed
    if [ -d /etc/sv/greetd ] && command -v greetd >/dev/null 2>&1; then
        sudo rm -f /var/service/agetty-tty1 2>/dev/null || true
        sudo ln -sf /etc/sv/greetd /var/service/greetd
        log_ok "Enabled greetd display manager on VT 1."
    fi

    # Configure ALSA PipeWire integration
    sudo mkdir -p /etc/alsa/conf.d
    [ -f /usr/share/alsa/alsa.conf.d/50-pipewire.conf ] && sudo ln -sf /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d/
    [ -f /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf ] && sudo ln -sf /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/

    # Ensure Headphones are always available on Intel SOF Realtek ALC256
    if [ -f /usr/share/alsa/ucm2/HDA/HiFi-analog.conf ]; then
        sudo sed -i 's/^[[:space:]]*JackControl "\${var:hpjack}"/# JackControl "\${var:hpjack}"/' /usr/share/alsa/ucm2/HDA/HiFi-analog.conf
    fi

    # Udev sound hardware permissions for audio group
    sudo mkdir -p /etc/udev/rules.d
    cat <<'UDEV' | sudo tee /etc/udev/rules.d/72-sound.rules >/dev/null
SUBSYSTEM=="sound", TAG-="uaccess", GROUP="audio", MODE="0660"
KERNEL=="controlC[0-9]*", SUBSYSTEM=="sound", TAG-="uaccess", GROUP="audio", MODE="0660"
KERNEL=="pcmC[0-9]*", SUBSYSTEM=="sound", TAG-="uaccess", GROUP="audio", MODE="0660"
KERNEL=="hwC[0-9]*", SUBSYSTEM=="sound", TAG-="uaccess", GROUP="audio", MODE="0660"
KERNEL=="midiC[0-9]*", SUBSYSTEM=="sound", TAG-="uaccess", GROUP="audio", MODE="0660"
KERNEL=="timer", SUBSYSTEM=="sound", TAG-="uaccess", GROUP="audio", MODE="0660"
KERNEL=="seq", SUBSYSTEM=="sound", TAG-="uaccess", GROUP="audio", MODE="0660"
UDEV

    cat <<'UDEV' | sudo tee /etc/udev/rules.d/78-sound-card.rules >/dev/null
SUBSYSTEM!="sound", GOTO="sound_end"
ACTION=="add|change", KERNEL=="controlC*", ATTR{../uevent}="change"
KERNEL!="card*", GOTO="sound_end"
ENV{SOUND_INITIALIZED}="1"
IMPORT{builtin}="hwdb"
IMPORT{builtin}="path_id"
SUBSYSTEMS=="usb", IMPORT{builtin}="usb_id"
SUBSYSTEMS=="usb", GOTO="skip_pci"
SUBSYSTEMS=="firewire", ATTRS{guid}=="?*", \
  ENV{ID_BUS}="firewire", ENV{ID_SERIAL}="$attr{guid}", ENV{ID_SERIAL_SHORT}="$attr{guid}", \
  ENV{ID_VENDOR_ID}="$attr{vendor}", ENV{ID_MODEL_ID}="$attr{model}", \
  ENV{ID_VENDOR}="$attr{vendor_name}", ENV{ID_MODEL}="$attr{model_name}"
SUBSYSTEMS=="firewire", GOTO="skip_pci"
SUBSYSTEMS=="pci", ENV{ID_BUS}="pci", ENV{ID_VENDOR_ID}="$attr{vendor}", ENV{ID_MODEL_ID}="$attr{device}"
SUBSYSTEMS=="pci", GOTO="skip_pci"
SUBSYSTEMS=="platform", ENV{SOUND_FORM_FACTOR}="internal", GOTO="sound_end"
LABEL="skip_pci"
ENV{ID_SERIAL}=="?*", ENV{ID_USB_INTERFACE_NUM}=="?*", ENV{ID_ID}="$env{ID_BUS}-$env{ID_SERIAL}-$env{ID_USB_INTERFACE_NUM}"
ENV{ID_SERIAL}=="?*", ENV{ID_USB_INTERFACE_NUM}=="", ENV{ID_ID}="$env{ID_BUS}-$env{ID_SERIAL}"
ATTR{pcmC%nD0p/pcm_class}=="modem", ENV{SOUND_CLASS}="modem", GOTO="sound_end"
SUBSYSTEMS=="pci", DEVPATH=="*/0000:00:??.?/sound/*", ENV{SOUND_FORM_FACTOR}="internal", GOTO="sound_end"
SUBSYSTEMS=="usb", ENV{ID_USB_INTERFACES}=="*:0e????:*", ENV{SOUND_FORM_FACTOR}="webcam", GOTO="sound_end"
ENV{ID_MODEL}=="*[Ss]peaker*", ENV{SOUND_FORM_FACTOR}="speaker", GOTO="sound_end"
ENV{ID_MODEL_FROM_DATABASE}=="*[Ss]peaker*", ENV{SOUND_FORM_FACTOR}="speaker", GOTO="sound_end"
ENV{ID_MODEL}=="*[Hh]eadphone*", ENV{SOUND_FORM_FACTOR}="headphone", GOTO="sound_end"
ENV{ID_MODEL_FROM_DATABASE}=="*[Hh]eadphone*", ENV{SOUND_FORM_FACTOR}="headphone", GOTO="sound_end"
ENV{ID_MODEL}=="*[Hh]eadset*", ENV{SOUND_FORM_FACTOR}="headset", GOTO="sound_end"
ENV{ID_MODEL_FROM_DATABASE}=="*[Hh]eadset*", ENV{SOUND_FORM_FACTOR}="headset", GOTO="sound_end"
ENV{ID_MODEL}=="*[Hh]andset*", ENV{SOUND_FORM_FACTOR}="handset", GOTO="sound_end"
ENV{ID_MODEL_FROM_DATABASE}=="*[Hh]andset*", ENV{SOUND_FORM_FACTOR}="handset", GOTO="sound_end"
ENV{ID_MODEL}=="*[Mm]icrophone*", ENV{SOUND_FORM_FACTOR}="microphone", GOTO="sound_end"
ENV{ID_MODEL_FROM_DATABASE}=="*[Mm]icrophone*", ENV{SOUND_FORM_FACTOR}="microphone", GOTO="sound_end"
LABEL="sound_end"
UDEV
    sudo rm -f /etc/udev/rules.d/60-sound.rules /etc/udev/rules.d/99-sound.rules
    sudo udevadm control --reload 2>/dev/null || true
    sudo udevadm trigger --subsystem-match=sound 2>/dev/null || true

    # Remove redundant snd-perms runit service if present
    sudo rm -f /var/service/snd-perms
    sudo rm -rf /etc/sv/snd-perms

    # PipeWire session manager auto-spawn (WirePlumber + PipeWire-Pulse)
    sudo mkdir -p /etc/pipewire/pipewire.conf.d
    cat <<'CONF' | sudo tee /etc/pipewire/pipewire.conf.d/10-session-manager.conf >/dev/null
context.exec = [
    { path = "/usr/bin/wireplumber" args = "" }
    { path = "/usr/bin/pipewire" args = [ "-c", "pipewire-pulse.conf" ] }
]
CONF

    # Deploy WirePlumber configuration drop-ins
    sudo mkdir -p /etc/wireplumber/wireplumber.conf.d
    sudo rm -f /etc/wireplumber/wireplumber.conf.d/50-acp-auto-profile.conf
    if [ -d "${REPO_DIR}/config/wireplumber/wireplumber.conf.d" ]; then
        sudo cp -r "${REPO_DIR}"/config/wireplumber/wireplumber.conf.d/* /etc/wireplumber/wireplumber.conf.d/
    fi
}

# 6. Deploy Dotfiles and Workflows to Target User Home (via Symlinks)
deploy_dotfiles() {
    log_info "Deploying Omavoid dotfiles and workflows via symlinks to ${TARGET_HOME}..."
    if [ "$DRY_RUN" -eq 1 ]; then return 0; fi

    BACKUP_DIR="${TARGET_HOME}/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "${TARGET_HOME}/.config" "${TARGET_HOME}/.local/bin" "${TARGET_HOME}/.local/state/void/current/theme" "${TARGET_HOME}/Pictures/Screenshots" "${TARGET_HOME}/.ssh"

    # Symlink all configs from REPO_DIR/config to TARGET_HOME/.config
    for item in "${REPO_DIR}"/config/*; do
        [ -e "$item" ] || continue
        base="$(basename "$item")"
        target="${TARGET_HOME}/.config/${base}"

        # If target already points directly to repo item, keep it
        if [ -L "$target" ] && [ "$(readlink -f "$target" 2>/dev/null)" = "$(readlink -f "$item")" ]; then
            continue
        fi

        # Backup existing file or directory if not pointing to repo
        if [ -e "$target" ] || [ -L "$target" ]; then
            mkdir -p "$BACKUP_DIR"
            cp -r "$target" "$BACKUP_DIR/" 2>/dev/null || true
        fi

        # Atomic symlink replacement
        ln -sfn "$item" "${target}.tmp.$$"
        mv -Tf "${target}.tmp.$$" "$target"
        log_ok "Symlinked ~/.config/${base} -> ${item}"
    done

    # Symlink local helper scripts to TARGET_HOME/.local/bin
    if [ -d "${REPO_DIR}/local/bin" ]; then
        for script in "${REPO_DIR}"/local/bin/*; do
            [ -f "$script" ] || continue
            chmod +x "$script"
            sname="$(basename "$script")"
            starget="${TARGET_HOME}/.local/bin/${sname}"

            if [ -L "$starget" ] && [ "$(readlink -f "$starget" 2>/dev/null)" = "$(readlink -f "$script")" ]; then
                continue
            fi
            if [ -e "$starget" ] || [ -L "$starget" ]; then
                mkdir -p "$BACKUP_DIR/local-bin"
                cp -f "$starget" "$BACKUP_DIR/local-bin/" 2>/dev/null || true
            fi
            ln -sf "$script" "${starget}.tmp.$$"
            mv -f "${starget}.tmp.$$" "$starget"
        done
        log_ok "Symlinked ~/.local/bin scripts to repo."
    fi

    # Symlink shell dotfiles (bashrc, zshrc, zprofile, aliases)
    declare -A SHELL_FILES=(
        [".bashrc"]="shell/bashrc"
        [".zshrc"]="shell/zshrc"
        [".zprofile"]="shell/zprofile"
        [".bash_aliases"]="shell/aliases"
    )
    for sf in "${!SHELL_FILES[@]}"; do
        repo_sf="${REPO_DIR}/${SHELL_FILES[$sf]}"
        target_sf="${TARGET_HOME}/${sf}"
        if [ -f "$repo_sf" ]; then
            if [ -L "$target_sf" ] && [ "$(readlink -f "$target_sf" 2>/dev/null)" = "$(readlink -f "$repo_sf")" ]; then
                continue
            fi
            if [ -e "$target_sf" ] || [ -L "$target_sf" ]; then
                mkdir -p "$BACKUP_DIR"
                cp -f "$target_sf" "$BACKUP_DIR/" 2>/dev/null || true
            fi
            ln -sf "$repo_sf" "${target_sf}.tmp.$$"
            mv -f "${target_sf}.tmp.$$" "$target_sf"
            log_ok "Symlinked ~/${sf} -> ${repo_sf}"
        fi
    done

    # Symlink Git Configurations (gitconfig, gitconfig-personal, gitconfig-work)
    declare -A GIT_FILES=(
        [".gitconfig"]="git/gitconfig"
        [".gitconfig-personal"]="git/gitconfig-personal"
        [".gitconfig-work"]="git/gitconfig-work"
    )
    for gf in "${!GIT_FILES[@]}"; do
        repo_gf="${REPO_DIR}/${GIT_FILES[$gf]}"
        target_gf="${TARGET_HOME}/${gf}"
        if [ -f "$repo_gf" ]; then
            if [ -L "$target_gf" ] && [ "$(readlink -f "$target_gf" 2>/dev/null)" = "$(readlink -f "$repo_gf")" ]; then
                continue
            fi
            if [ -e "$target_gf" ] || [ -L "$target_gf" ]; then
                mkdir -p "$BACKUP_DIR"
                cp -f "$target_gf" "$BACKUP_DIR/" 2>/dev/null || true
            fi
            ln -sf "$repo_gf" "${target_gf}.tmp.$$"
            mv -f "${target_gf}.tmp.$$" "$target_gf"
            log_ok "Symlinked ~/${gf} -> ${repo_gf}"
        fi
    done

    # Ensure SSH configuration contains dual-account GitHub entries
    local ssh_conf="${TARGET_HOME}/.ssh/config"
    touch "$ssh_conf"
    if ! grep -q "Host github.com-personal" "$ssh_conf" 2>/dev/null; then
        cat <<'SSH_SNIP' >> "$ssh_conf"

# Personal Account
Host github.com-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal

# Work Account
Host github.com-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
SSH_SNIP
        log_ok "Added dual-account GitHub hosts to ~/.ssh/config"
    fi
    chmod 700 "${TARGET_HOME}/.ssh" 2>/dev/null || true
    chmod 600 "$ssh_conf" 2>/dev/null || true

    # Deploy ~/.asoundrc for ALSA-to-PipeWire routing
    if [ -f "${REPO_DIR}/shell/asoundrc" ]; then
        cp -f "${REPO_DIR}/shell/asoundrc" "${TARGET_HOME}/.asoundrc"
        log_ok "Deployed ~/.asoundrc for PipeWire ALSA routing."
    fi

    # Stage initial Matte Black theme state
    THEME_SRC="${REPO_DIR}/themes/matte-black"
    if [ -d "$THEME_SRC" ]; then
        cp "$THEME_SRC/colors.toml" "${TARGET_HOME}/.local/state/void/current/theme/colors.toml" 2>/dev/null || true
        cp "$THEME_SRC/shell.lock.toml" "${TARGET_HOME}/.local/state/void/current/theme/shell.lock.toml" 2>/dev/null || true
        echo "matte-black" > "${TARGET_HOME}/.local/state/void/current/theme.name"
        WP=$(find "$THEME_SRC/backgrounds" -name "*.webp" -o -name "*.jpg" -o -name "*.png" 2>/dev/null | head -n1 || true)
        if [ -n "$WP" ]; then
            ln -sf "$WP" "${TARGET_HOME}/.local/state/void/current/background"
        fi
    fi

    # Set up theme hooks for btop and neovim in repo (gitignored)
    mkdir -p "${REPO_DIR}/config/btop/themes"
    ln -snf "${TARGET_HOME}/.local/state/void/current/theme/btop.theme" "${REPO_DIR}/config/btop/themes/current.theme"
    mkdir -p "${REPO_DIR}/config/nvim/lua/plugins"
    ln -snf "${TARGET_HOME}/.local/state/void/current/theme/neovim.lua" "${REPO_DIR}/config/nvim/lua/plugins/theme.lua"

    # Set login shell to zsh if installed
    if command -v zsh >/dev/null 2>&1; then
        sudo chsh -s "$(command -v zsh)" "$TARGET_USER" || true
    fi

    # Ensure proper non-root ownership on deployed user symlinks and files
    sudo chown -h "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.config/"* "${TARGET_HOME}/.zshrc" "${TARGET_HOME}/.zprofile" "${TARGET_HOME}/.bashrc" "${TARGET_HOME}/.bash_aliases" "${TARGET_HOME}/.gitconfig"* 2>/dev/null || true
    sudo chown -R "${TARGET_USER}:${TARGET_USER}" "${REPO_DIR}" "${TARGET_HOME}/.local" "${TARGET_HOME}/Pictures" "${TARGET_HOME}/.ssh" 2>/dev/null || true
    log_ok "Dotfiles and workflows deployed to ${TARGET_HOME}."
}

setup_void_repos
install_packages
sync_dotfiles_assets
install_void_shims
setup_runit_and_groups
deploy_dotfiles

echo ""
echo "======================================================================"
log_ok "Omavoid setup complete! (Mode: ${INSTALL_MODE^^})"
echo "Log in on VT 1 as '${TARGET_USER}'."
echo "======================================================================"
