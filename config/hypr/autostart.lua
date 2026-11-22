-- Autostart processes for Void Linux on Hyprland

hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")
  hl.exec_cmd("void-audio-init")
  hl.exec_cmd("void-backlight restore")
  hl.exec_cmd("udiskie --automount --no-notify --no-tray")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("quickshell -d -n -p /usr/share/void/shell")
  hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
  hl.exec_cmd("dbus-update-activation-environment --systemd GNOME_KEYRING_CONTROL SSH_AUTH_SOCK")
end)
