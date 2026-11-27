-- Left to right; monitor 1 gets workspace 1
require("monitors").set({
  { output = "DP-1", mode = "preferred", position = "auto-right", scale = 1 },
  { output = "DP-2", mode = "preferred", position = "auto-right", scale = 1 },
  { output = "HDMI-A-1", mode = "preferred", position = "auto-right", scale = 1 },
})
