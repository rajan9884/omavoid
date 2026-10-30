{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",

  "logo": {
    "type": "builtin",
    "source": "void",
    "padding": {
      "right": 1
    }
  },

  "display": {
    "separator": " ➜ ",
    "key": {
      "width": 14
    }
  },

  "modules": [
    {
      "type": "title"
    },
    "separator",

    {
      "type": "custom",
      "format": "\u001b[1;38;2;{{ accent_rgb }}m╭─────────────────────── SYSTEM ──────────────────────╮\u001b[0m"
    },
    {
      "type": "os",
      "key": " OS",
      "keyColor": "{{ accent }}"
    },
    {
      "type": "host",
      "key": "󰌢 Host",
      "keyColor": "{{ accent }}"
    },
    {
      "type": "kernel",
      "key": "󰌽 Kernel",
      "keyColor": "{{ accent }}"
    },
    {
      "type": "uptime",
      "key": "󰅐 Uptime",
      "keyColor": "{{ accent }}"
    },
    {
      "type": "packages",
      "key": "󰏖 Packages",
      "keyColor": "{{ accent }}"
    },
    {
      "type": "shell",
      "key": " Shell",
      "keyColor": "{{ accent }}"
    },
    {
      "type": "custom",
      "format": "\u001b[1;38;2;{{ accent_rgb }}m╰─────────────────────────────────────────────────────╯\u001b[0m"
    },

    {
      "type": "custom",
      "format": "\u001b[1;38;2;{{ cyan_rgb }}m╭────────────────────── DESKTOP ──────────────────────╮\u001b[0m"
    },
    {
      "type": "display",
      "key": "󰍹 Display",
      "keyColor": "{{ cyan }}",
      "format": "{width}x{height} @ {refresh-rate} Hz {scale-factor}x {inch}''"
    },
    {
      "type": "de",
      "key": "󰘔 DE",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "wm",
      "key": "󰖲 WM",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "wmtheme",
      "key": "󰋜 WM Theme",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "font",
      "key": "󰛖 Font",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "cursor",
      "key": "󰇀 Cursor",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "terminal",
      "key": " Terminal",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "terminalfont",
      "key": " Term Font",
      "keyColor": "{{ cyan }}"
    },
    {
      "type": "custom",
      "format": "\u001b[1;38;2;{{ cyan_rgb }}m╰─────────────────────────────────────────────────────╯\u001b[0m"
    },

    {
      "type": "custom",
      "format": "\u001b[1;38;2;{{ magenta_rgb }}m╭────────────────────── HARDWARE ─────────────────────╮\u001b[0m"
    },
    {
      "type": "cpu",
      "key": " CPU",
      "keyColor": "{{ magenta }}",
      "format": "{name} ({cores-online})"
    },
    {
      "type": "gpu",
      "key": "󰢮 GPU",
      "keyColor": "{{ magenta }}",
      "format": "{vendor} {name} ({type})"
    },
    {
      "type": "memory",
      "key": "󰍛 Memory",
      "keyColor": "{{ magenta }}"
    },
    {
      "type": "disk",
      "key": "󰋊 Disk",
      "keyColor": "{{ magenta }}"
    },
    {
      "type": "custom",
      "format": "\u001b[1;38;2;{{ magenta_rgb }}m╰─────────────────────────────────────────────────────╯\u001b[0m"
    },

    "separator",
    {
      "type": "colors",
      "symbol": "circle"
    }
  ]
}
