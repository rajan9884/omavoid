-- Void bootstrap keeps path setup out of this user config.
local user = os.getenv("USER") or "user"
local home = os.getenv("HOME") or ("/home/" .. user)
local current_path = os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin"
local void_path = os.getenv("VOID_PATH") or os.getenv("OMARCHY_PATH") or "/usr/share/void"
local full_path = home .. "/.local/bin:" .. void_path .. "/bin:" .. current_path
hl.env("PATH", full_path)
hl.env("VOID_PATH", void_path)
hl.env("OMARCHY_PATH", void_path)

dofile(void_path .. "/default/hypr/bootstrap.lua")

-- Load Void defaults.
require("default.hypr.void")

-- Personal overrides loaded after Void defaults.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")
