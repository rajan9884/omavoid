-- Unified Hyprland keybindings for Void Linux
local mainMod = "SUPER"

-- ── Universal Keys (Copy / Paste / Cut / Select-All) ──
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then return false end
  local class = (window.class or ""):lower()
  if class:find("foot") or class:find("alacritty") or class:find("kitty") or class:find("terminal") then
    return true
  end
  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then return true end
  end
  return false
end

local function universal_clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key)
  return function()
    if active_window_is_terminal() then
      send_shortcut_once(terminal_mods, terminal_key)()
    else
      send_shortcut_once(default_mods, default_key)()
    end
  end
end

hl.bind(mainMod .. " + A", send_shortcut_once("CTRL", "A"), { description = "Select all" })
hl.bind(mainMod .. " + C", universal_clipboard_shortcut("CTRL", "C", "CTRL SHIFT", "C"), { description = "Universal copy" })
hl.bind(mainMod .. " + V", universal_clipboard_shortcut("CTRL", "V", "CTRL SHIFT", "V"), { description = "Universal paste" })
hl.bind(mainMod .. " + X", send_shortcut_once("CTRL", "X"), { description = "Universal cut" })

-- ── Application Launcher & Clipboard ──
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("void-shell shell toggle omarchy.menu"), { description = "Application Launcher" })
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("void-shell shell toggle omarchy.menu"), { description = "Application Launcher" })
hl.bind(mainMod .. " + CTRL + V", hl.dsp.exec_cmd("void-shell shell toggle omarchy.clipboard"), { description = "Clipboard manager" })

-- ── Core Applications ──
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("foot"), { description = "Terminal" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("helium-browser"), { description = "Browser" })
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("helium-browser --incognito"), { description = "Private Browser" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"), { description = "File Manager" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("foot -e yazi"), { description = "Yazi File Manager" })
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("foot -e btop"), { description = "System Monitor" })
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("foot -e cliamp"), { description = "Music Player" })

-- ── Package Menus ──
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("foot -e void-pkg-install"), { description = "Package installer" })
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("foot -e void-pkg-remove"), { description = "Package remover" })

-- ── Keybindings Search ──
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("void-menu-keybindings"), { description = "Keybindings menu" })

-- ── Window Management ──
hl.bind(mainMod .. " + W", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("void-toggle-floating-centered"), { description = "Toggle float" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Toggle fullscreen" })
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Toggle split" })

-- Window Focus Navigation
hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "l" }), { description = "Focus left" })
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "r" }), { description = "Focus right" })
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "u" }), { description = "Focus up" })
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "d" }), { description = "Focus down" })

-- Window Movement
hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.window.move({ direction = "l" }), { description = "Move left" })
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "r" }), { description = "Move right" })
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.window.move({ direction = "u" }), { description = "Move up" })
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.window.move({ direction = "d" }), { description = "Move down" })

-- ── Workspace Layouts (Dwindle, Scrolling, Floating) ──
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("void-hyprland-workspace-layout-toggle"), { description = "Cycle workspace layout forward" })
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("void-hyprland-workspace-layout-toggle back"), { description = "Cycle workspace layout back" })

-- ── Workspaces 1-10 ──
for i = 1, 10 do
  local key = i % 10
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Move to workspace " .. i })
  hl.bind(mainMod .. " + SHIFT + ALT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }), { description = "Move silently to workspace " .. i })
end

-- ── Scratchpad ──
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("scratchpad"), { description = "Toggle scratchpad" })
hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }), { description = "Move window to scratchpad" })

-- ── Quickshell Statusbar Panels ──
hl.bind(mainMod .. " + CTRL + A", hl.dsp.exec_cmd("void-shell shell toggle omarchy.audio"), { description = "Audio panel" })
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd("void-shell shell toggle omarchy.bluetooth"), { description = "Bluetooth panel" })
hl.bind(mainMod .. " + CTRL + D", hl.dsp.exec_cmd("void-shell shell toggle omarchy.monitor"), { description = "Display panel" })
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd("void-shell shell toggle omarchy.network"), { description = "Network panel" })
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd("void-shell shell toggle omarchy.power"), { description = "Power panel" })
hl.bind(mainMod .. " + CTRL + ALT + D", hl.dsp.exec_cmd("void-shell shell toggle omarchy.clock"), { description = "Clock panel" })

-- ── Themes & Wallpapers ──
hl.bind(mainMod .. " + CTRL + Space", hl.dsp.exec_cmd("void-theme-bg-switcher"), { description = "Wallpaper switcher" })
hl.bind(mainMod .. " + CTRL + SHIFT + Space", hl.dsp.exec_cmd("void-theme-switcher"), { description = "Theme switcher" })

-- ── Toggles (HDR, Nightlight, Screensaver, WARP, DND) ──
hl.bind(mainMod .. " + ALT + H", hl.dsp.exec_cmd("void-toggle-hdr"), { description = "Toggle HDR" })
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd("void-toggle-nightlight"), { description = "Toggle nightlight" })
hl.bind(mainMod .. " + CTRL + ALT + S", hl.dsp.exec_cmd("void-toggle-screensaver"), { description = "Screensaver" })
hl.bind(mainMod .. " + CTRL + ALT + N", hl.dsp.exec_cmd("void-toggle-notification-silencing"), { description = "Toggle notification DND" })

-- ── Notifications Control ──
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("void-shell notifications dismissOne"), { description = "Dismiss notification" })
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.exec_cmd("void-shell notifications dismissAll"), { description = "Dismiss all notifications" })
hl.bind(mainMod .. " + SHIFT + ALT + comma", hl.dsp.exec_cmd("void-shell notifications showHistory"), { description = "Notification history" })

-- ── System Lock & Exit ──
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("void-system-lock"), { description = "Lock system" })
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("void-shell shell toggle omarchy.power"), { description = "Power menu" })

-- ── Volume / Brightness / Media Keys ──
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("void-audio-output-volume up"), { repeating = true, locked = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("void-audio-output-volume down"), { repeating = true, locked = true, description = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("void-audio-output-volume mute-toggle"), { locked = true, description = "Mute audio" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("void-audio-input-mute toggle"), { locked = true, description = "Mute mic" })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("void-brightness-display up"), { repeating = true, locked = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("void-brightness-display down"), { repeating = true, locked = true, description = "Brightness down" })
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("void-brightness-keyboard up"), { repeating = true, locked = true, description = "Keyboard backlight up" })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("void-brightness-keyboard down"), { repeating = true, locked = true, description = "Keyboard backlight down" })
hl.bind("XF86KbdLightOnOff", hl.dsp.exec_cmd("void-brightness-keyboard cycle"), { locked = true, description = "Keyboard backlight toggle" })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause" })

-- Screenshot & OCR
hl.bind("Print", hl.dsp.exec_cmd("void-capture-screenshot"), { description = "Screenshot fullscreen" })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("void-capture-region"), { description = "Screenshot region" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("void-capture-region"), { description = "Screenshot region" })
hl.bind(mainMod .. " + CTRL + Print", hl.dsp.exec_cmd("ocr-extract"), { description = "OCR region to clipboard" })
hl.bind(mainMod .. " + ALT + Print", hl.dsp.exec_cmd("ocr-extract"), { description = "OCR region to clipboard" })
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("ocr-extract"), { description = "OCR region to clipboard" })
