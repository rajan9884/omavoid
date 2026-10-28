-- Custom user overrides for Omarchy Quattro 4.0 keybindings

-- Music: bind to cliamp TUI instead of Spotify
o.rebind("SUPER + SHIFT + M", "Music", { tui = "cliamp", focus = true })
o.rebind("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })

-- File manager: bind to yazi TUI instead of nautilus
o.rebind("SUPER + SHIFT + F", "File manager", { tui = "yazi", focus = true })
o.rebind("SUPER + ALT + SHIFT + F", "File manager (cwd)", { omarchy = "nautilus-cwd" })

-- Explicit keysym aliases for window resizing to ensure Super+=/- always work
o.bind("SUPER + minus", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
o.bind("SUPER + equal", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
o.bind("SUPER + SHIFT + minus", "Shrink window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
o.bind("SUPER + SHIFT + equal", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

o.bind("SUPER + ALT + minus", "Expand window left a little", hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
o.bind("SUPER + ALT + equal", "Shrink window left a little", hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
o.bind("SUPER + SHIFT + ALT + minus", "Shrink window up a little", hl.dsp.window.resize({ x = 0, y = -25, relative = true }))
o.bind("SUPER + SHIFT + ALT + equal", "Expand window down a little", hl.dsp.window.resize({ x = 0, y = 25, relative = true }))

o.bind("SUPER + CTRL + minus", "Expand window left a lot", hl.dsp.window.resize({ x = -300, y = 0, relative = true }))
o.bind("SUPER + CTRL + equal", "Shrink window left a lot", hl.dsp.window.resize({ x = 300, y = 0, relative = true }))
o.bind("SUPER + CTRL + SHIFT + minus", "Shrink window up a lot", hl.dsp.window.resize({ x = 0, y = -300, relative = true }))
o.bind("SUPER + CTRL + SHIFT + equal", "Expand window down a lot", hl.dsp.window.resize({ x = 0, y = 300, relative = true }))
