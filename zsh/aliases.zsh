# ── Navigation ───────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ── Listing ──────────────────────────────────────────────────
alias ll='ls -lah'
alias la='ls -A'

# ── git ──────────────────────────────────────────────────────
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias grb='git rebase'
alias lg='lazygit'
alias tg='tig'
alias tgs='tig status'
alias tgb='tig blame'
alias tgl='tig log'

# ── delta ─────────────────────────────────────────────────────
alias gdd='git diff | delta'
alias gdcs='git diff --cached | delta'

# ── Neovim ───────────────────────────────────────────────────
alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# ── tmux ─────────────────────────────────────────────────────
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux list-sessions'
alias tk='tmux kill-session -t'

# ── Search ───────────────────────────────────────────────────
alias agg='ag --ignore-dir=node_modules --ignore-dir=.git'

# ── mise ─────────────────────────────────────────────────────
alias mr='mise run'
alias mx='mise exec'
alias mi='mise install'

# ── direnv ───────────────────────────────────────────────────
alias da='direnv allow'

# ── Misc ─────────────────────────────────────────────────────
alias reload='source ~/.zshrc'
alias path='echo $PATH | tr ":" "\n"'
alias h='history'
