-- Custom user overrides for Omarchy Quattro 4.0 keybindings

-- Toggle small centered floating window (Super + T)
o.rebind("SUPER + T", "Toggle floating window", "omarchy-toggle-floating-centered")

-- Music: bind to cliamp TUI instead of Spotify
o.rebind("SUPER + SHIFT + M", "Music", { tui = "cliamp", focus = true })
o.rebind("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })

-- File manager: bind to yazi TUI instead of nautilus
o.rebind("SUPER + SHIFT + F", "File manager", { tui = "yazi", focus = true })
o.rebind("SUPER + ALT + SHIFT + F", "File manager (cwd)", { omarchy = "nautilus-cwd" })

-- Unbind removed apps, calculators, web apps, and dictation
hl.unbind("SUPER + SHIFT + SLASH")       -- 1Password
hl.unbind("SUPER + SHIFT + G")           -- Signal
hl.unbind("SUPER + SHIFT + W")           -- Omawrite
hl.unbind("SUPER + SHIFT + Q")           -- Calculator
hl.unbind("XF86Calculator")              -- Calculator
hl.unbind("SUPER + CTRL + X")            -- Dictation
hl.unbind("F9")                          -- Dictation push-to-talk
hl.unbind("SUPER + SHIFT + A")           -- ChatGPT
hl.unbind("SUPER + SHIFT + ALT + A")     -- Grok
hl.unbind("SUPER + SHIFT + C")           -- Calendar web app
hl.unbind("SUPER + SHIFT + E")           -- Email web app
hl.unbind("SUPER + SHIFT + ALT + E")     -- New email web app
hl.unbind("SUPER + SHIFT + Y")           -- YouTube web app
hl.unbind("SUPER + SHIFT + ALT + G")     -- WhatsApp web app
hl.unbind("SUPER + SHIFT + CTRL + G")    -- Google Messages web app
hl.unbind("SUPER + SHIFT + P")           -- Google Photos web app
hl.unbind("SUPER + SHIFT + S")           -- Google Maps web app
hl.unbind("SUPER + SHIFT + X")           -- X web app
hl.unbind("SUPER + SHIFT + ALT + X")     -- X Post web app

-- Workspaces 1..10
for workspace = 1, 10 do
  local key = tostring(workspace % 10)
  o.rebind("SUPER + " .. key, "Switch to workspace " .. workspace, o.workspaces.focus(workspace))
  o.rebind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, o.workspaces.move_window(workspace))
  o.rebind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. workspace, o.workspaces.move_window(workspace, false))
end
