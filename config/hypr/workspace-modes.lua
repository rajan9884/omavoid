-- Workspace modes for Hyprland: Dwindle, Scrolling, and Floating
-- Supports dynamic switching via void-hyprland-workspace-layout-toggle

o = o or {}

local home = os.getenv("HOME") or "/home/rajan"
local state_home = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")

local FLOATED_TAG = "omarchy-mode-floated"
local WORKSPACE_TAG = "omarchy-floating-workspace"
local OPENED_TAG = "omarchy-mode-opened"
local OPEN_RULE = "omarchy-floating-open-"
local LAST_WORKSPACE = 2147483647
local TITLEBARS = "/usr/lib/omarchy-hyprland-titlebars/titlebars.so"

local M = {}
local modes = {}
local default_mode = nil
local watching = false
local floating_ready = false
local set_up_floating
local cascade = 0
local open_rules = 0

local function set_floating(window, floating)
  hl.dispatch(hl.dsp.window.float({ action = floating and "on" or "off", window = window }))
end

local function set_claimed(window, claimed)
  hl.dispatch(hl.dsp.window.tag({ tag = (claimed and "+" or "-") .. FLOATED_TAG, window = window }))
end

local function set_on_floating_workspace(window, on)
  hl.dispatch(hl.dsp.window.tag({ tag = (on and "+" or "-") .. WORKSPACE_TAG, window = window }))
end

local function claimed()
  local addresses = {}
  for _, window in ipairs(hl.get_windows({ tag = FLOATED_TAG })) do
    addresses[window.address] = true
  end
  return addresses
end

local function floating_workspace(id)
  id = tonumber(id)
  if not id or id < 1 then return false end
  local mode = modes[tostring(id)]
  if mode then return mode == "floating" end
  return default_mode == "floating"
end

local function anything_floats()
  if default_mode == "floating" then return true end
  for _, mode in pairs(modes) do
    if mode == "floating" then return true end
  end
  return false
end

local function place(window)
  local monitor = window.monitor
  if not monitor or not monitor.width then return end

  local width = math.floor(monitor.width / monitor.scale)
  local height = math.floor(monitor.height / monitor.scale)
  if (monitor.transform or 0) % 2 == 1 then
    width, height = height, width
  end

  local reserved = monitor.reserved or {}
  width = width - (reserved.left or 0) - (reserved.right or 0)
  height = height - (reserved.top or 0) - (reserved.bottom or 0)

  hl.dispatch(hl.dsp.window.resize({
    x = math.min(1100, math.floor(width * 0.64)),
    y = math.min(760, math.floor(height * 0.68)),
    relative = false,
    window = window,
  }))
  hl.dispatch(hl.dsp.window.center({ window = window }))

  cascade = (cascade + 1) % 5
  hl.dispatch(hl.dsp.window.move({ x = cascade * 24 - 48, y = cascade * 24 - 48, relative = true, window = window }))
end

local function float_for_mode(windows)
  local claiming = {}
  for _, window in ipairs(windows) do
    set_on_floating_workspace(window, true)
    if not window.floating and (window.fullscreen or 0) == 0 then
      set_claimed(window, true)
      table.insert(claiming, window)
    end
  end
  for _, window in ipairs(claiming) do
    set_floating(window, true)
    place(window)
  end
end

local function tile_for_mode(window, mine)
  set_on_floating_workspace(window, false)
  if not mine[window.address] or window.pinned then return end
  set_claimed(window, false)
  set_floating(window, false)
end

local function floating_ranges()
  local ranges = {}
  if default_mode == "floating" then
    local tiled = {}
    for id, mode in pairs(modes) do
      local n = tonumber(id)
      if n and n >= 1 and mode ~= "floating" then
        table.insert(tiled, n)
      end
    end
    table.sort(tiled)

    local from = 1
    for _, n in ipairs(tiled) do
      if n > from then
        table.insert(ranges, { from, n - 1 })
      end
      from = n + 1
    end
    table.insert(ranges, { from, LAST_WORKSPACE })
  else
    for id, mode in pairs(modes) do
      local n = tonumber(id)
      if n and n >= 1 and mode == "floating" then
        table.insert(ranges, { n, n })
      end
    end
    table.sort(ranges, function(a, b) return a[1] < b[1] end)
  end
  return ranges
end

local OPEN_WIDTH = "min(1100,monitor_w*0.64)"
local OPEN_HEIGHT = "min(760,monitor_h*0.68)"

local function open_position()
  local step = cascade * 24 - 48
  return string.format("(monitor_w-%s)/2+(%d) (monitor_h-%s)/2+(%d)", OPEN_WIDTH, step, OPEN_HEIGHT, step)
end

local function not_floating_on_their_own(match)
  local floating = o.floating_apps or { class = {}, title = {}, tags = {}, tagged = {} }
  local excluded = { class = {}, title = {} }
  for _, key in ipairs({ "class", "title" }) do
    for _, pattern in ipairs(floating[key] or {}) do
      table.insert(excluded[key], pattern)
    end
  end
  for tag in pairs(floating.tags or {}) do
    for _, tagged in ipairs((floating.tagged and floating.tagged[tag]) or {}) do
      table.insert(excluded[tagged.key], tagged.pattern)
    end
  end

  for _, key in ipairs({ "class", "title" }) do
    local patterns = excluded[key]
    if patterns and #patterns > 0 then
      local alternatives = {}
      for _, pattern in ipairs(patterns) do
        table.insert(alternatives, "(?:" .. pattern .. ")")
      end
      match[key] = "negative:" .. table.concat(alternatives, "|")
    end
  end
  return match
end

local function sync_open_rules()
  local ranges = floating_ranges()
  for i, range in ipairs(ranges) do
    hl.window_rule({
      name = OPEN_RULE .. i,
      enabled = true,
      match = not_floating_on_their_own({ workspace = string.format("r[%d-%d]", range[1], range[2]), modal = false }),
      float = true,
      size = OPEN_WIDTH .. " " .. OPEN_HEIGHT,
      move = open_position(),
      tag = "+" .. OPENED_TAG,
    })
  end

  for i = #ranges + 1, open_rules do
    hl.window_rule({ name = OPEN_RULE .. i, enabled = false })
  end
  open_rules = math.max(open_rules, #ranges)
end

o.floating_apps_changed = sync_open_rules

local function claim_opened(window)
  for _, tag in ipairs(window.tags or {}) do
    if tag == OPENED_TAG or tag == OPENED_TAG .. "*" then
      set_claimed(window, true)
      cascade = (cascade + 1) % 5
      sync_open_rules()
      return
    end
  end
end

local function unmaximize_others(window)
  local id = window.workspace and window.workspace.id
  if not floating_workspace(id) then return end
  for _, other in ipairs(hl.get_workspace_windows(tostring(id))) do
    if other.address ~= window.address and (other.fullscreen or 0) == 1 then
      hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset", window = other }))
    end
  end
end

local function arrange(windows, workspace)
  local floating = {}
  local mine = claimed()

  for _, window in ipairs(windows) do
    local id = tonumber(workspace and workspace.id or (window.workspace and window.workspace.id))
    if id and id >= 1 then
      if floating_workspace(id) then
        table.insert(floating, window)
      else
        tile_for_mode(window, mine)
      end
    end
  end
  float_for_mode(floating)
end

local input = {}

local function update_input()
  local workspace = hl.get_active_workspace()
  local active = workspace ~= nil and floating_workspace(workspace.id)
  if active == input.floating then return end
  input.floating = active
  hl.config({ input = { follow_mouse = active and 0 or input.follow_mouse } })
end

local function watch()
  if watching then return end
  watching = true
  input.follow_mouse = hl.get_config("input.follow_mouse")

  hl.on("window.open", function(window)
    claim_opened(window)
    unmaximize_others(window)
    arrange({ window })
  end)

  hl.on("window.move_to_workspace", function(window, workspace)
    hl.timer(function()
      arrange({ window }, workspace)
    end, { type = "oneshot", timeout = 1 })
  end)

  hl.on("window.fullscreen", function(window)
    hl.timer(function()
      arrange({ window })
    end, { type = "oneshot", timeout = 1 })
  end)

  hl.on("workspace.active", update_input)
  hl.on("monitor.focused", update_input)
end

set_up_floating = function()
  if floating_ready then return end
  floating_ready = true

  if not hl.get_config("decoration.shadow.enabled") then
    hl.config({ decoration = { shadow = { enabled = true, range = 16, render_power = 3, color = "rgba(00000035)" } } })
    hl.window_rule({ match = { class = ".*" }, no_shadow = true })
    hl.window_rule({ match = { tag = WORKSPACE_TAG }, no_shadow = false })
  end

  hl.window_rule({ match = { tag = WORKSPACE_TAG }, opacity = "1.0 override 1.0 override" })

  local tf = io.open(TITLEBARS, "r")
  if tf then
    tf:close()
    hl.plugin.load(TITLEBARS)
  end
end

function o.workspace_mode(spec)
  watch()

  if spec.default then
    default_mode = spec.default
    if spec.default ~= "floating" then
      hl.config({ general = { layout = spec.default } })
    end
    sync_open_rules()
    if anything_floats() then
      set_up_floating()
    end
    return
  end

  local workspace = tostring(spec.workspace)
  if spec.mode ~= "floating" then
    hl.workspace_rule({ workspace = workspace, layout = spec.mode })
  end

  modes[workspace] = spec.mode
  if anything_floats() then
    set_up_floating()
  end

  arrange(hl.get_workspace_windows(workspace))
  sync_open_rules()
  update_input()
end

-- Restore saved workspace layouts from disk
local layouts_dir = state_home .. "/void/workspace-layouts"
local pipe = io.popen("ls " .. layouts_dir .. "/*.lua 2>/dev/null")
if pipe then
  for file in pipe:lines() do
    if file and file ~= "" then
      pcall(dofile, file)
    end
  end
  pipe:close()
end

if anything_floats() then
  set_up_floating()
end

return M
