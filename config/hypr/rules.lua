-- Hyprland window and layer rules
-- Docs: https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Suppress maximize event for all windows
hl.window_rule({
  match = { class = ".*" },
  suppress_event = "maximize",
})

-- Prevent idle when an app is fullscreen
hl.window_rule({
  match = { class = ".*" },
  idle_inhibit = "fullscreen",
})

-- Floating utilities and settings
hl.window_rule({
  name = "float-pavucontrol",
  match = { class = "^(pavucontrol)$" },
  float = true,
  center = true,
})

hl.window_rule({
  name = "float-nm-connection-editor",
  match = { class = "^(nm-connection-editor)$" },
  float = true,
  center = true,
})

hl.window_rule({
  name = "float-blueman-manager",
  match = { class = "^(blueman-manager)$" },
  float = true,
  center = true,
})

-- Standard File Dialogs
hl.window_rule({
  name = "float-file-dialogs",
  match = { title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)$" },
  float = true,
  center = true,
  size = { 800, 550 },
})

hl.window_rule({
  name = "float-xdg-portal",
  match = { class = "^(xdg-desktop-portal-gtk)$" },
  float = true,
  center = true,
})

-- Media Floating
hl.window_rule({
  name = "float-terminal-dialog",
  match = { class = "^(floating-terminal|org.void.terminal|org.void.terminal)$" },
  float = true,
  center = true,
  size = { 920, 620 },
})

hl.window_rule({
  name = "media-float",
  match = { class = "^(imv|mpv)$" },
  float = true,
  center = true,
  size = { 875, 600 },
  idle_inhibit = "focus",
})

hl.window_rule({
  name = "doc-float",
  match = { class = "^org.pwmt.zathura$" },
  float = true,
  center = true,
  size = { 900, 700 },
})

hl.window_rule({
  name = "thunar-dialogs",
  match = { class = "^(Thunar|thunar)$", title = ".*(Properties|Rename|Preferences|Bulk Rename).*" },
  float = true,
  center = true,
  size = { 700, 500 },
})

-- Screensaver (Fullscreen, Floating, Slide Animation)
hl.window_rule({
  name = "screensaver-fullscreen",
  match = { class = "^(org.void.screensaver|org.void.screensaver)$" },
  fullscreen = true,
  float = true,
  animation = "slide",
})

-- Layer rules for instant Quickshell UI responses
hl.layer_rule({ match = { namespace = "^(void-bar|void-bar)$" }, blur = true, ignore_alpha = 0.3, no_anim = true, animation = "none" })
hl.layer_rule({ match = { namespace = "^(void-menu|void-menu|void-image-selector|void-clipboard|void-osd|void-network-qr)$" }, no_anim = true, animation = "none" })
hl.layer_rule({ match = { namespace = "^(void-background|owe-background)$" }, no_anim = true, animation = "none" })
