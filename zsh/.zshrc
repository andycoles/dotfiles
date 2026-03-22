# ── Aliases ──────────────────────────────────────────────────
[[ -f "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"

# ── Starship prompt ──────────────────────────────────────────
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# ── mise (version manager: node, python, etc.) ────────────────
command -v mise &>/dev/null && eval "$(mise activate zsh)"
