-- Omarchy's bootstrap keeps path setup out of this user config.
local user = os.getenv("USER") or "user"
local home = os.getenv("HOME") or ("/home/" .. user)
local current_path = os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin"
local full_path = home .. "/.local/bin:/usr/share/omarchy/bin:" .. current_path
hl.env("PATH", full_path)
hl.env("OMARCHY_PATH", "/usr/share/omarchy")

dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Personal overrides loaded after Omarchy's defaults.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")
