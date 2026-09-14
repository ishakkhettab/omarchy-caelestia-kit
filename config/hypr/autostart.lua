-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Caelestia provides the visual bar/background. Omarchy shell still starts
-- from defaults so Super+Space, Super+K, lock, and menus keep working.
o.launch_on_start(os.getenv("HOME") .. "/.local/bin/omarchy-caelestia-start")
o.launch_on_start(os.getenv("HOME") .. "/.local/bin/omarchy-caelestia-wallpaper-watch")
o.launch_on_start(os.getenv("HOME") .. "/.local/bin/omarchy-os-haptics")
o.launch_on_start("env LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so " .. os.getenv("HOME") .. "/.local/bin/omarchy-workspace-osd")
o.launch_on_start(os.getenv("HOME") .. "/.local/bin/voxtype-cleanupd")
