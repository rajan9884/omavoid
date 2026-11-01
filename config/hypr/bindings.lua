-- Hyprland keybindings for Void Linux

-- Toggle small centered floating window (Super + T)
o.rebind("SUPER + T", "Toggle floating window", "void-toggle-floating-centered")

-- Toggle HDR display mode (Super + Alt + H / Super + Shift + H)
o.rebind("SUPER + ALT + H", "Toggle HDR mode", "void-toggle-hdr")
o.rebind("SUPER + SHIFT + H", "Toggle HDR mode", "void-toggle-hdr")

-- Background switcher (Super + Ctrl + Space / Super + Ctrl + W)
o.rebind("SUPER + CTRL + SPACE", "Background switcher", { menu = "background" })
o.rebind("SUPER + CTRL + W", "Background switcher", { menu = "background" })

-- Music: bind to cliamp TUI
o.rebind("SUPER + SHIFT + M", "Music", { tui = "cliamp", focus = true })
o.rebind("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })

-- File manager: bind to yazi TUI
o.rebind("SUPER + SHIFT + F", "File manager", { tui = "yazi", focus = true })
o.rebind("SUPER + ALT + SHIFT + F", "File manager (cwd)", { void = "nautilus-cwd" })

-- Notifications: Super + Comma dismisses newest, Super + Alt + Comma invokes
o.rebind("SUPER + comma", "Dismiss last notification", { ipc = "notifications.dismissOne" })
o.rebind("SUPER + SHIFT + comma", "Dismiss all notifications", { ipc = "notifications.dismissAll" })
o.rebind("SUPER + CTRL + comma", "Control notifications with keyboard", { ipc = "notifications.keyboard" })
o.rebind("SUPER + ALT + comma", "Dismiss, invoke, or focus last notification", { ipc = "notifications.act" })
o.rebind("SUPER + SHIFT + ALT + comma", "Open notification history", { ipc = "notifications.showHistory" })

-- Workspaces 1..10
for workspace = 1, 10 do
  local key = tostring(workspace % 10)
  o.rebind("SUPER + " .. key, "Switch to workspace " .. workspace, o.workspaces.focus(workspace))
  o.rebind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, o.workspaces.move_window(workspace))
  o.rebind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. workspace, o.workspaces.move_window(workspace, false))
end

-- Group window switches (Alt + 1..10)
for index = 1, 9 do
  hl.unbind("SUPER + ALT + code:" .. tostring(index + 9))
  o.rebind("ALT + code:" .. tostring(index + 9), "Switch to group window " .. index, hl.dsp.group.active({ index = index }))
end
hl.unbind("SUPER + ALT + code:19")
o.rebind("ALT + code:19", "Switch to group window 10", hl.dsp.group.active({ index = 10 }))
