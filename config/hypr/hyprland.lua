-- Hyprland configuration for Void Linux (Pure native Lua)
local user = os.getenv("USER") or "user"
local home = os.getenv("HOME") or ("/home/" .. user)
local current_path = os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin"
local void_path = os.getenv("VOID_PATH") or "/usr/share/void"
local full_path = home .. "/.local/bin:" .. void_path .. "/bin:" .. current_path

hl.env("PATH", full_path)
hl.env("VOID_PATH", void_path)

-- Wayland & environment setup
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Malloc arena memory optimization
hl.env("MALLOC_ARENA_MAX", "2")
hl.env("MALLOC_TRIM_THRESHOLD_", "131072")

hl.config({
  xwayland = {
    enabled = false,
    force_zero_scaling = true,
  },
  ecosystem = {
    no_update_news = true,
  },
})

-- Load modular configurations directly
require("hypr.monitors")
require("hypr.input")
require("hypr.look")
require("hypr.rules")
require("hypr.workspace-modes")
require("hypr.keybinds")
require("hypr.autostart")
