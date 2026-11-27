require("looknfeel")
require("input")
require("rules")
require("bindings")
local monitors = require("monitors")

local file = io.open("/proc/sys/kernel/hostname")
local hostname = file:read("l")
file:close()
local host = package.searchpath("hosts." .. hostname, package.path)
if host then
  dofile(host)
end

monitors.start()
