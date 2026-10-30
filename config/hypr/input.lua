hl.config({
  input = {
    kb_layout = "us",
    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },
  gestures = {
    workspace_swipe_distance = 300,
    workspace_swipe_invert = true,
    workspace_swipe_min_speed_to_force = 30,
    workspace_swipe_cancel_ratio = 0.5,
    workspace_swipe_create_new = true,
    workspace_swipe_direction_lock = true,
  },
})

-- Touchpad gestures (Hyprland 0.55+ native Lua gesture system)
-- 3-finger horizontal swipe between workspaces
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- 3-finger vertical swipe toggles scratchpad
hl.gesture({ fingers = 3, direction = "up", action = "special", workspace_name = "scratchpad" })
hl.gesture({ fingers = 3, direction = "down", action = "special", workspace_name = "scratchpad" })

-- 4-finger gestures for fullscreen and floating toggle
hl.gesture({ fingers = 4, direction = "up", action = "fullscreen" })
hl.gesture({ fingers = 4, direction = "down", action = "float" })
