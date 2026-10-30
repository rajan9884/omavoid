[mgr]
cwd = { fg = "{{ cyan }}" }
hovered = { fg = "{{ background }}", bg = "{{ accent }}", bold = true }
preview_hovered = { underline = true }
find_keyword = { fg = "{{ yellow }}", bold = true, italic = true, underline = true }
find_position = { fg = "{{ magenta }}", normal = true }
marker_copied = { fg = "{{ green }}", bg = "{{ green }}" }
marker_cut = { fg = "{{ red }}", bg = "{{ red }}" }
marker_selected = { fg = "{{ blue }}", bg = "{{ blue }}" }
tab_active = { fg = "{{ background }}", bg = "{{ accent }}", bold = true }
tab_inactive = { fg = "{{ foreground }}", bg = "{{ dark_background }}" }
count_copied = { fg = "{{ background }}", bg = "{{ green }}" }
count_cut = { fg = "{{ background }}", bg = "{{ red }}" }
count_selected = { fg = "{{ background }}", bg = "{{ blue }}" }
border_symbol = "│"
border_style = { fg = "{{ muted }}" }

[status]
separator_open = ""
separator_close = ""
separator_style = { fg = "{{ lighter_background }}", bg = "{{ lighter_background }}" }
mode_normal = { fg = "{{ background }}", bg = "{{ blue }}", bold = true }
mode_select = { fg = "{{ background }}", bg = "{{ green }}", bold = true }
mode_unset = { fg = "{{ background }}", bg = "{{ red }}", bold = true }
progress_label = { bold = true }
progress_normal = { fg = "{{ blue }}", bg = "{{ lighter_background }}" }
progress_error = { fg = "{{ red }}", bg = "{{ lighter_background }}" }
permissions_t = { fg = "{{ blue }}" }
permissions_r = { fg = "{{ yellow }}" }
permissions_w = { fg = "{{ red }}" }
permissions_x = { fg = "{{ green }}" }
permissions_s = { fg = "{{ muted }}" }

[input]
border = { fg = "{{ accent }}" }
title = {}
value = {}
selected = { reversed = true }

[select]
border = { fg = "{{ accent }}" }
active = { fg = "{{ magenta }}" }
inactive = {}

[tasks]
border = { fg = "{{ accent }}" }
title = {}
hovered = { underline = true }

[which]
mask = { bg = "{{ darker_background }}" }
cand = { fg = "{{ cyan }}" }
rest = { fg = "{{ muted }}" }
desc = { fg = "{{ magenta }}" }
separator = "  "
separator_style = { fg = "{{ dark_foreground }}" }

[help]
on = { fg = "{{ green }}" }
run = { fg = "{{ magenta }}" }
desc = { fg = "{{ foreground }}" }
hovered = { bg = "{{ lighter_background }}" }
footer = { fg = "{{ foreground }}", bg = "{{ dark_background }}" }
