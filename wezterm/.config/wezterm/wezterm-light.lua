-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'Catppuccin Latte'
config.colors = {
    cursor_bg = "#f38ba8", -- Matches Catppuccin mocha.red
    cursor_fg = "#ffffff", -- White text for readability
    cursor_border = "#f38ba8", -- Same as cursor_bg
    background = "white"
  }
config.font_size = 10

config.enable_wayland = false
config.front_end = "WebGpu"

config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

config.window_background_opacity = 0.9

config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
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
    -- Change the default click behavior so that it populates
    -- the Clipboard rather the PrimarySelection.
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

-- and finally, return the configuration to wezterm
return config

