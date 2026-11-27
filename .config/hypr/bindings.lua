-- Super = windows, Super+Shift = apps, Super+Ctrl = system tools; app and tool keys are left-hand only

local function bind(keys, description, action, opts)
  opts = opts or {}
  opts.description = description
  if type(action) == "string" then
    action = hl.dsp.exec_cmd(action)
  end
  hl.bind(keys, action, opts)
end

local function app(command)
  return "uwsm app -- " .. command
end

local function focus_or_launch(class, command)
  return "workstation-launch-or-focus '" .. class .. "' " .. command
end

local function tui(name, command)
  return "workstation-launch-or-focus --tui org.workstation." .. name .. " " .. (command or name)
end

-- Windows and workspaces
bind("SUPER + SPACE", "App launcher", "fuzzel")
bind("SUPER + RETURN", "Terminal", app("ghostty"))
bind("SUPER + W", "Close window", hl.dsp.window.close())
bind("SUPER + F", "Fullscreen", hl.dsp.window.fullscreen({ action = "toggle" }))
bind("SUPER + T", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))

local directions = {
  { keys = { "H", "LEFT" }, direction = "l", name = "left" },
  { keys = { "J", "DOWN" }, direction = "d", name = "down" },
  { keys = { "K", "UP" }, direction = "u", name = "up" },
  { keys = { "L", "RIGHT" }, direction = "r", name = "right" },
}
for _, d in ipairs(directions) do
  for _, key in ipairs(d.keys) do
    bind("SUPER + " .. key, "Focus " .. d.name, hl.dsp.focus({ direction = d.direction }))
    bind("SUPER + SHIFT + " .. key, "Move window " .. d.name, hl.dsp.window.move({ direction = d.direction }))
  end
end

for i = 1, 9 do
  bind("SUPER + " .. i, "Workspace " .. i, hl.dsp.focus({ workspace = i }))
  bind("SUPER + SHIFT + " .. i, "Move window to workspace " .. i, hl.dsp.window.move({ workspace = i }))
end
bind("SUPER + TAB", "Next workspace on this monitor", hl.dsp.focus({ workspace = "m+1" }))
bind("SUPER + SHIFT + TAB", "Previous workspace on this monitor", hl.dsp.focus({ workspace = "m-1" }))

bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

bind("SUPER + ESCAPE", "Power menu", "workstation-power-menu")
bind("SUPER + F1", "Keybindings", "workstation-cheatsheet")

-- Hyprland merges a held Super into the injected keys and runs Super + letter binds, so type after it's released
local function type_clipboard()
  if hl.is_key_down("Super_L") or hl.is_key_down("Super_R") then
    hl.timer(type_clipboard, { timeout = 10, type = "oneshot" })
  else
    -- ydotool indexes its ASCII keymap with signed bytes, so non-ASCII input would press arbitrary keys
    hl.exec_cmd("wl-paste --no-newline --type text | tr -cd '\\t\\n\\40-\\176' | ydotool type --file -")
  end
end
bind("SUPER + V", "Type clipboard", type_clipboard)

-- gsr's own hotkeys don't work: kanata grabs the keyboards and gsr skips kanata's virtual device
bind("SUPER + C", "GSR save replay + share", "gsr-clip-share replay-save")
bind("SUPER + SHIFT + C", "GSR show/hide", "gsr-ui-cli toggle-show")

-- The autoclicker runs on XWayland and can't see global key presses on Wayland
bind("ALT + F6", "Autoclicker toggle", "useful-autoclicker --toggle")

-- Apps
bind("SUPER + SHIFT + T", "Terminal", app("ghostty"))
bind("SUPER + SHIFT + B", "Browser", app("zen-browser"))
bind("SUPER + SHIFT + F", "File manager", app("ghostty -e yazi"))
bind("SUPER + SHIFT + D", "Discord", focus_or_launch("discord", "discord"))
bind("SUPER + SHIFT + S", "Music", tui("spotatui"))
bind("SUPER + SHIFT + W", "Bitwarden", focus_or_launch("Bitwarden", "bitwarden-desktop"))
bind("SUPER + SHIFT + G", "Steam", focus_or_launch("steam", "steam"))

-- System tools
bind("SUPER + CTRL + W", "WiFi", tui("impala"))
bind("SUPER + CTRL + B", "Bluetooth", tui("bluetui"))
bind("SUPER + CTRL + A", "Audio", tui("wiremix"))
bind("SUPER + CTRL + T", "System monitor", tui("btop"))
bind("SUPER + CTRL + D", "Displays", "workstation-monitors")
bind("SUPER + CTRL + I", "Toggle idle inhibit", "workstation-idle-toggle")
bind("SUPER + CTRL + P", "Battery", "workstation-battery-menu")
bind("SUPER + CTRL + S", "Screenshot region", "workstation-screenshot")
bind("PRINT", "Screenshot region", "workstation-screenshot")
bind("SUPER + CTRL + R", "Screen recording", "workstation-record")
bind("SUPER + CTRL + V", "Clipboard history", "workstation-clipboard")
bind("SUPER + CTRL + E", "Emoji picker", "workstation-emoji")
bind("SUPER + CTRL + C", "Webcam photo", "workstation-webcam")

-- Media keys
local media = { locked = true, repeating = true }
bind("XF86AudioRaiseVolume", "Volume up", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", media)
bind("XF86AudioLowerVolume", "Volume down", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", media)
bind("XF86AudioMute", "Mute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true })
bind("XF86AudioMicMute", "Mute microphone", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", { locked = true })
bind("XF86MonBrightnessUp", "Brightness up", "brightnessctl -e4 -n2 set 5%+", media)
bind("XF86MonBrightnessDown", "Brightness down", "brightnessctl -e4 -n2 set 5%-", media)
bind("XF86AudioPlay", "Play/pause", "playerctl play-pause", { locked = true })
bind("XF86AudioPause", "Play/pause", "playerctl play-pause", { locked = true })
bind("XF86AudioNext", "Next track", "playerctl next", { locked = true })
bind("XF86AudioPrev", "Previous track", "playerctl previous", { locked = true })
