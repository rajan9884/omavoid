export USER="${USER:-$(id -un)}"
export HOME="${HOME:-$(getent passwd "$USER" 2>/dev/null | cut -d: -f6)}"
[ -z "$HOME" ] && export HOME="/home/$USER"
export OMARCHY_PATH="/usr/share/omarchy"
export PATH="$HOME/.local/bin:/usr/share/omarchy/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin"
export EDITOR="nvim"
export VISUAL="nvim"
export TERMINAL="foot"

if [ -z "${WAYLAND_DISPLAY:-}" ] && [ "${XDG_VTNR:-0}" -eq 1 ]; then
    if command -v start-hyprland >/dev/null 2>&1; then
        exec dbus-run-session start-hyprland -- --config ~/.config/hypr/hyprland.lua
    else
        exec dbus-run-session Hyprland --config ~/.config/hypr/hyprland.lua
    fi
fi
