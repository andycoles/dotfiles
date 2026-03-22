local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- ── Font ──────────────────────────────────────────────────
config.font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'Regular' })
config.font_size = 18.0

-- ── Color scheme ──────────────────────────────────────────
config.color_scheme = 'Tokyo Night'

-- ── Window ────────────────────────────────────────────────
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.window_background_opacity = 1.0

wezterm.on('gui-startup', function()
  local _, _, window = wezterm.mux.spawn_window {}
  window:gui_window():maximize()
end)

-- ── Cursor ────────────────────────────────────────────────
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 500

-- ── Tab bar ───────────────────────────────────────────────
config.enable_tab_bar = true
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false

-- ── Keys ──────────────────────────────────────────────────
-- Pass Ctrl-a through to tmux (prefix key)
config.keys = {
    { key = 'a', mods = 'CTRL', action = wezterm.action.SendKey { key = 'a', mods = 'CTRL' } },
}

-- ── Misc ──────────────────────────────────────────────────
config.audible_bell = 'Disabled'
config.scrollback_lines = 10000
config.window_close_confirmation = 'AlwaysPrompt'

return config
