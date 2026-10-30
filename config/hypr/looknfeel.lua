-- Cursor theme & Look and feel
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")

local paths = require("default.hypr.paths")
local hdr_flag = paths.state_home .. "/void/toggles/hdr-on"
local is_hdr = io.open(hdr_flag, "r") ~= nil

hl.config({
  misc = {
    disable_watchdog_warning = true,
  },
  render = {
    cm_auto_hdr = is_hdr and 1 or 0,
    direct_scanout = 0,
  },
  experimental = {
    wp_cm_1_2 = is_hdr,
  },
})
