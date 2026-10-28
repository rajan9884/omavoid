-- Monitor scaling configured for Samsung OLED 2880x1800 display.
local omarchy_monitor_scale = 2.0
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

local omarchy_gdk_scale = 2
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
