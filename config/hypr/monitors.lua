local paths = require("default.hypr.paths")
local hdr_flag = paths.state_home .. "/void/toggles/hdr-on"
local is_hdr = io.open(hdr_flag, "r") ~= nil

-- Custom user monitor scaling overrides for Void Quattro
local void_monitor_scale = 2.0
if is_hdr then
  hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = void_monitor_scale,
    bitdepth = 10,
    cm = "hdr",
    sdrbrightness = 1.3,
    sdrsaturation = 1.0,
  })
else
  hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = void_monitor_scale,
    cm = "srgb",
  })
end

local void_gdk_scale = 2
hl.env("GDK_SCALE", tostring(void_gdk_scale))
