local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.color_scheme = 'Catppuccin Mocha'
config.colors = {
    cursor_bg = "#f38ba8",
    cursor_fg = "#ffffff",
    cursor_border = "#f38ba8",

    foreground = "#DDDDDD",

    background = "#1e1e2e",
}
config.font_size = 12

config.enable_wayland = false
config.front_end = "WebGpu"

config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

config.window_background_opacity = 0.9

config.window_padding = {
  left = 5,
  right = 5,
  top = 5,
  bottom = 5,
}

wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
  local zoomed = ''
  if tab.active_pane.is_zoomed then
    zoomed = '[Z] '
  end

  local index = ''
  if #tabs > 1 then
    index = string.format('[%d/%d] ', tab.tab_index + 1, #tabs)
  end

  return zoomed .. index .. tab.active_pane.title
end)

config.mouse_bindings = {
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'NONE',
      action = wezterm.action.Multiple {
          wezterm.action.CompleteSelection 'Clipboard',
          wezterm.action.ClearSelection,
        }
    },
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = wezterm.action.OpenLinkAtMouseCursor,
    },
}

return config
