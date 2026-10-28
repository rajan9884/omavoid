-- Extra autostart processes for Void Linux
o.launch_on_start("void-audio-init")
o.launch_on_start("void-backlight restore")
o.launch_on_start("wl-paste --type text --watch cliphist store")
o.launch_on_start("wl-paste --type image --watch cliphist store")
o.launch_on_start("hyprsunset")
o.launch_on_start("qs-app-indexer")
