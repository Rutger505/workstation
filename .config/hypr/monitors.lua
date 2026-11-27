-- Monitor layout and monitor-bound workspaces.
-- Host files call set() with their monitors in order; monitor 1 gets workspace 1, ..., the last one the rest up to 9.
-- Other monitors are asked about once (workstation-monitors), the answer is kept per monitor in the state file
-- as "<choice> <description>" and reapplied on every connect.

local M = { host = {} }

local state_file = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/workstation/monitors"
local positions = { right = "auto-right", left = "auto-left", above = "auto-up" }
local applied = {}
local workspace_rules = {}
local bound = ""

local function key(monitor)
  return monitor.description ~= "" and monitor.description or monitor.name
end

local function host_index(name)
  for i, spec in ipairs(M.host) do
    if spec.output == name then
      return i
    end
  end
end

local function saved_choices()
  local choices = {}
  local file = io.open(state_file)
  if file then
    for line in file:lines() do
      local choice, monitor = line:match("^(%S+) (.+)$")
      if choice then
        choices[monitor] = choice
      end
    end
    file:close()
  end
  return choices
end

local function ordered(monitors)
  local list = {}
  for _, monitor in ipairs(monitors) do
    list[#list + 1] = monitor
  end
  table.sort(list, function(a, b)
    local ia, ib = host_index(a.name) or math.huge, host_index(b.name) or math.huge
    if ia ~= ib then
      return ia < ib
    end
    if a.x ~= b.x then
      return a.x < b.x
    end
    return a.y < b.y
  end)
  return list
end

-- Rules merge into the previous rule for the output, so every field is always set
local function set_monitor(spec)
  local signature = table.concat({ spec.mode, spec.position, tostring(spec.scale), spec.mirror, tostring(spec.disabled) }, "|")
  if applied[spec.output] ~= signature then
    applied[spec.output] = signature
    hl.monitor(spec)
  end
end

function M.set(specs)
  M.host = specs
  for _, spec in ipairs(specs) do
    hl.monitor(spec)
  end
end

-- removed: the monitor of a monitor.removed event, which is still listed while it fires.
-- FALLBACK is Hyprland's stand-in output while no real one is enabled.
function M.apply(removed)
  local choices = saved_choices()
  local monitors = {}
  for _, monitor in ipairs(ordered(hl.get_monitors({ all = true }))) do
    if monitor.name ~= "FALLBACK" and not (removed and monitor.name == removed.name) then
      monitors[#monitors + 1] = monitor
    end
  end
  local only = false
  for _, monitor in ipairs(monitors) do
    if choices[key(monitor)] == "only" then
      only = true
    end
  end

  local specs, primary = {}, nil
  for _, monitor in ipairs(monitors) do
    local choice = choices[key(monitor)]
    local host = M.host[host_index(monitor.name) or 0] or {}
    local spec = {
      output = monitor.name,
      mode = host.mode or "preferred",
      position = positions[choice] or host.position or "auto",
      scale = host.scale or "auto",
      mirror = "",
      disabled = choice == "disable" or (only and choice ~= "only"),
    }
    if not spec.disabled and choice ~= "mirror" and not primary then
      primary = monitor.name
    end
    specs[#specs + 1] = spec
  end

  -- Never switch off every screen
  if not primary and #specs > 0 then
    specs[1].disabled = false
    primary = specs[1].output
  end

  for i, monitor in ipairs(monitors) do
    if choices[key(monitor)] == "mirror" and not specs[i].disabled and monitor.name ~= primary then
      specs[i].mirror = primary
    end
    set_monitor(specs[i])
  end
end

function M.bind_workspaces()
  local monitors = {}
  for _, monitor in ipairs(hl.get_monitors()) do
    if not monitor.is_mirror then
      monitors[#monitors + 1] = monitor
    end
  end
  if #monitors == 0 then
    return
  end
  monitors = ordered(monitors)

  local names = {}
  for i, monitor in ipairs(monitors) do
    names[i] = monitor.name
  end
  -- Rules can only be disabled, not removed, so they are only replaced when the order changes
  if table.concat(names, " ") ~= bound then
    bound = table.concat(names, " ")
    for _, rule in ipairs(workspace_rules) do
      rule:set_enabled(false)
    end
    workspace_rules = {}
    for id = 1, 9 do
      local index = math.min(id, #monitors)
      workspace_rules[id] = hl.workspace_rule({ workspace = tostring(id), monitor = names[index], default = id == index })
    end
  end

  local focused, changed = hl.get_active_monitor(), false
  for id = 1, 9 do
    local name = names[math.min(id, #monitors)]
    local workspace = hl.get_workspace(tostring(id))
    if workspace and workspace.monitor and workspace.monitor.name ~= name then
      hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(id), monitor = name }))
      changed = true
    end
  end

  -- A monitor left showing a workspace that isn't its own, or a fresh empty one, switches to its first one
  for index, monitor in ipairs(monitors) do
    local last = index == #monitors and 9 or index
    local current = hl.get_active_workspace(monitor.name)
    if not current or not current.id or current.id < index or current.id > last or (current.is_empty and current.id ~= index) then
      hl.dispatch(hl.dsp.focus({ workspace = index }))
      changed = true
    end
  end
  -- Moving the active workspace takes the focus along; it stays on the screen the user is looking at
  if changed and focused then
    hl.dispatch(hl.dsp.focus({ monitor = focused.name }))
  end
end

function M.start()
  hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

  hl.on("monitor.added", function(monitor)
    local others = #hl.get_monitors() > 1
    if others and not host_index(monitor.name) and not saved_choices()[key(monitor)] then
      hl.exec_cmd("workstation-monitors ask " .. monitor.name)
    end
    M.apply()
  end)
  hl.on("monitor.removed", M.apply)
  hl.on("monitor.layout_changed", M.bind_workspaces)

  M.apply()
  M.bind_workspaces()
end

return M
