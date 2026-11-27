-- No float rules: dialogs and pop-ups float by Hyprland's own detection, everything else tiles

hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

-- Fullscreen video and games keep the screen awake
hl.window_rule({ name = "idle-inhibit-fullscreen", match = { class = ".*" }, idle_inhibit = "fullscreen" })

-- Invisible XWayland drag helpers would otherwise steal focus
hl.window_rule({
  name = "fix-xwayland-drags",
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})

hl.window_rule({ name = "ghostty-scroll", match = { class = "^(com\\.mitchellh\\.ghostty|org\\.workstation\\..*)$" }, scroll_touchpad = 0.2 })
