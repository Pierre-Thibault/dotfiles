-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'Catppuccin Latte'
--config.color_scheme = 'mytilus-light'
--config.color_scheme = 'Aardvark Blue'
--config.color_scheme = 'Adventure Time (Gogh)'

config.enable_wayland = false
config.front_end = "WebGpu"

config.font_size = 11
config.font =
  wezterm.font('JetBrains Mono Nerd Font Mono', {})
config.hide_tab_bar_if_only_one_tab = true

-- making window titles more distinct
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

-- and finally, return the configuration to wezterm
return config
