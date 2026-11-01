-- Essential application bindings for Void Linux.
o.bind("SUPER + RETURN", "Terminal", o.launch_terminal())
o.bind("SUPER + SHIFT + RETURN", "Browser", { void = "browser" })
o.bind("SUPER + SHIFT + B", "Browser", { void = "browser" })
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", { void = "browser --private" })
o.bind("SUPER + SHIFT + F", "File manager", { tui = "yazi", focus = true })
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", { void = "nautilus-cwd" })
o.bind("SUPER + SHIFT + N", "Editor", { void = "editor" })
o.bind("SUPER + ALT + RETURN", "Tmux", { void = "terminal-tmux" })
o.bind("SUPER + SHIFT + M", "Music (CLIAMP)", { tui = "cliamp", focus = true })

if o.cmd_present("obsidian") then
  o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
end

if o.cmd_present("lazygit") then
  o.bind("SUPER + SHIFT + L", "Lazygit", { tui = "lazygit", focus = true })
end
