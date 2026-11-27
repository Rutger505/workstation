local colors = require("colors")

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,
    col = {
      active_border = colors.active_border,
      inactive_border = colors.inactive_border,
    },
    layout = "dwindle",
  },
  decoration = {
    rounding = 8,
    shadow = { enabled = false },
    blur = { enabled = false },
  },
  dwindle = {
    preserve_split = true,
  },
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    force_default_wallpaper = 0,
    background_color = colors.background,
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
  xwayland = {
    force_zero_scaling = true,
  },
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
})
