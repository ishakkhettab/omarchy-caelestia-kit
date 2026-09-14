-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.
--
-- See current bindings and descriptions:
--   omarchy menu keybindings --print
--
-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false
--
-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Dictation: Right Alt toggle only
-- Note: SUPER+CTRL+X was previously Toggle dictation
hl.unbind("SUPER + CTRL + X")
hl.unbind("F9")
o.bind("ALT_R", "Toggle dictation", "voxtype record toggle")

-- Caelestia is the visible bar. Keep Super+Shift+Space as "toggle top bar"
-- but point it at Caelestia instead of the hidden Omarchy bar.
-- Note: SUPER+SHIFT+SPACE was previously Toggle top bar (Omarchy).
hl.unbind("SUPER + SHIFT + SPACE")
o.bind("SUPER + SHIFT + SPACE", "Toggle top bar", os.getenv("HOME") .. "/.local/bin/omarchy-caelestia-toggle-bar")

-- Super+D: vanish / restore every window on this workspace (slide + popin).
o.bind("SUPER + D", "Vanish workspace windows", os.getenv("HOME") .. "/.local/bin/omarchy-workspace-vanish")

-- Super+Backspace: 100% → 90% → 80% → 70% → 100%, including fullscreen.
-- Note: SUPER+BACKSPACE was previously Toggle window transparency.
hl.unbind("SUPER + BACKSPACE")
local opacity_levels = { "1.0", "0.90", "0.80", "0.70" }
local opacity_index = {}
o.bind("SUPER + BACKSPACE", "Cycle window opacity", function()
  local w = hl.get_active_window()
  if not w then
    return
  end
  local addr = w.address
  local i = ((opacity_index[addr] or 0) % #opacity_levels) + 1
  opacity_index[addr] = i
  local a = opacity_levels[i]
  local val = a .. " override"
  local win = "address:" .. addr
  hl.dispatch(hl.dsp.window.set_prop({ prop = "opacity", value = val, window = win }))
  hl.dispatch(hl.dsp.window.set_prop({ prop = "opacity_inactive", value = val, window = win }))
  hl.dispatch(hl.dsp.window.set_prop({ prop = "opacity_fullscreen", value = val, window = win }))
  hl.dispatch(hl.dsp.window.set_prop({ prop = "opacity_override", value = "1", window = win }))
  hl.dispatch(hl.dsp.window.set_prop({ prop = "opacity_inactive_override", value = "1", window = win }))
  hl.dispatch(hl.dsp.window.set_prop({ prop = "opacity_fullscreen_override", value = "1", window = win }))
end)
