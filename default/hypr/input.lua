-- https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
  input = {
    kb_layout = "@layout@",
    kb_variant = "@variant@",
    kb_model = "",
    kb_options = "@options@",
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0,

    touchpad = {
      natural_scroll = false,
    },
  },

  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})
