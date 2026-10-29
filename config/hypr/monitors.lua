-- Custom user monitor scaling overrides for Void Quattro
local void_monitor_scale = 2.0
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = void_monitor_scale })

local void_gdk_scale = 2
hl.env("GDK_SCALE", tostring(void_gdk_scale))
