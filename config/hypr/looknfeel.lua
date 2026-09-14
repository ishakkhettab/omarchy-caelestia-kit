-- Change the default Omarchy look'n'feel.

-- Glass windows so Caelestia and Hyprland read as one OS.
hl.config({
  general = {
    gaps_in = 8,
    gaps_out = 18,
  },
  decoration = {
    rounding = 14,
    -- Keep these at 1 so hover/focus/fullscreen do not fight Super+Backspace.
    active_opacity = 1,
    inactive_opacity = 1,
    fullscreen_opacity = 1,
    blur = {
      enabled = true,
      size = 12,
      passes = 3,
      ignore_opacity = true,
      new_optimizations = true,
      xray = false,
      popups = true,
    },
    shadow = {
      enabled = true,
      range = 18,
      render_power = 3,
      color = "rgba(00000066)",
    },
  },
})

-- Workspace title toast: no compositor fade so our own opacity reads clean.
hl.layer_rule({ match = { namespace = "omarchy-workspace-osd" }, no_anim = true, animation = "none" })

-- Cinematic vanish for Super+D (special:vanish).
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.6, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.4, bezier = "easeOutQuint", style = "popin 55%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.2, bezier = "easeOutQuint", style = "popin 78%" })
