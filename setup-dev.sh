#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Dev Environment Setup
# Installs: WezTerm, Neovim (LazyVim), tmux, fzf, lazygit, git-delta, tig,
#           gh, mise, tldr, direnv + dotfile configs
# Supports: macOS and Debian/Ubuntu Linux
#
# Dotfiles are stored alongside this script (script lives inside the dotfiles repo)
# and symlinked into place. Existing configs are backed up.
# Host this dotfiles directory on git to persist configs.
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
step() { echo -e "\n${BLUE}==>${NC} $1"; }

# Resolve the dotfiles directory relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

# ============================================================
# Detect platform + arch
# ============================================================
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Darwin) PLATFORM="macos" ;;
    Linux)  PLATFORM="linux" ;;
    *)      err "Unsupported OS: $OS" ;;
esac

log "Platform: $PLATFORM ($ARCH)"
log "Dotfiles directory: $DOTFILES_DIR"

# ============================================================
# Symlink helper
#   link_dotfile <dotfiles-relative-source> <link-target>
#
#   - If target is already a symlink pointing to our source: skip
#   - If target exists (file/dir): back it up then symlink
#   - Otherwise: symlink directly
# ============================================================
link_dotfile() {
    local src="$DOTFILES_DIR/$1"
    local dst="$2"

    # Ensure source exists
    if [[ ! -e "$src" ]]; then
        warn "Source not found, skipping: $src"
        return
    fi

    # Already correctly symlinked?
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        log "Already linked: $dst -> $src"
        return
    fi

    # Backup existing file/dir (even if it's a stale/wrong symlink)
    if [[ -e "$dst" || -L "$dst" ]]; then
        local backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
        warn "Backing up existing $dst -> $backup"
        mv "$dst" "$backup"
    fi

    # Create parent dirs if needed
    mkdir -p "$(dirname "$dst")"

    ln -s "$src" "$dst"
    log "Linked: $dst -> $src"
}

# ============================================================
# macOS: Homebrew
# ============================================================
ensure_homebrew() {
    if ! command -v brew &>/dev/null; then
        step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ "$ARCH" == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        log "Homebrew already installed"
    fi
}

# ============================================================
# Install core packages
# ============================================================
install_packages() {
    step "Installing packages..."

    if [[ "$PLATFORM" == "macos" ]]; then
        ensure_homebrew
        brew install neovim tmux git curl unzip zsh starship the_silver_searcher \
            fzf lazygit git-delta gh mise tldr direnv tig
        if brew list --cask wezterm &>/dev/null; then
            log "WezTerm already installed"
        else
            brew install --cask wezterm
        fi

    elif [[ "$PLATFORM" == "linux" ]]; then
        if ! command -v apt-get &>/dev/null; then
            err "Only apt-based Linux distros are supported (Debian/Ubuntu)."
        fi

        sudo apt-get update -qq || warn "apt-get update had errors (possibly a third-party repo); continuing..."
        sudo apt-get install -y git curl unzip build-essential tmux fontconfig zsh \
            silversearcher-ag fzf tldr direnv tig

        install_neovim_linux
        install_wezterm_linux
        install_starship_linux
        install_gh_linux
        install_lazygit_linux
        install_delta_linux
        install_tig_linux
        install_mise
    fi
}

# ============================================================
# Neovim: latest stable from GitHub releases (Linux)
# ============================================================
install_neovim_linux() {
    if command -v nvim &>/dev/null; then
        log "Neovim already installed ($(nvim --version | head -1))"
        return
    fi

    step "Installing Neovim (latest stable)..."
    local tmp_dir
    tmp_dir=$(mktemp -d)

    local archive="nvim-linux-x86_64.tar.gz"
    [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]] && archive="nvim-linux-arm64.tar.gz"

    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${archive}" \
        -o "$tmp_dir/nvim.tar.gz"
    sudo tar -C /usr/local -xzf "$tmp_dir/nvim.tar.gz" --strip-components=1
    rm -rf "$tmp_dir"
    log "Neovim installed to /usr/local/bin/nvim"
}

# ============================================================
# WezTerm: official apt repo (Linux)
# ============================================================
install_wezterm_linux() {
    if command -v wezterm &>/dev/null; then
        log "WezTerm already installed"
        return
    fi

    step "Installing WezTerm..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://apt.fury.io/wez/gpg.key \
        | sudo gpg --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
        | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
    sudo apt-get update -qq || warn "apt-get update had errors; continuing..."
    sudo apt-get install -y wezterm
}

# ============================================================
# JetBrainsMono Nerd Font
# ============================================================
install_nerd_font() {
    step "Installing JetBrainsMono Nerd Font..."

    local font_dir
    if [[ "$PLATFORM" == "macos" ]]; then
        font_dir="$HOME/Library/Fonts"
    else
        font_dir="$HOME/.local/share/fonts"
        mkdir -p "$font_dir"
    fi

    if ls "$font_dir"/JetBrainsMonoNerd* &>/dev/null 2>&1; then
        log "JetBrainsMono Nerd Font already installed"
        return
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)

    curl -fsSL \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
        -o "$tmp_dir/JetBrainsMono.zip"
    unzip -q "$tmp_dir/JetBrainsMono.zip" -d "$tmp_dir/JetBrainsMono"

    # Skip Windows-compatible variants
    find "$tmp_dir/JetBrainsMono" -name "*.ttf" ! -name "*Windows*" \
        -exec cp {} "$font_dir/" \;

    rm -rf "$tmp_dir"

    if [[ "$PLATFORM" == "linux" ]]; then
        fc-cache -f "$font_dir"
    fi

    log "JetBrainsMono Nerd Font installed"
}

# ============================================================
# Starship prompt (Linux — official install script)
# ============================================================
install_starship_linux() {
    if command -v starship &>/dev/null; then
        log "Starship already installed"
        return
    fi
    step "Installing Starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
}

# ============================================================
# GitHub CLI: official apt repo (Linux)
# ============================================================
install_gh_linux() {
    if command -v gh &>/dev/null; then
        log "GitHub CLI already installed"
        return
    fi

    step "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update -qq
    sudo apt-get install -y gh
}

# ============================================================
# lazygit: latest release from GitHub (Linux)
# ============================================================
install_lazygit_linux() {
    if command -v lazygit &>/dev/null; then
        log "lazygit already installed"
        return
    fi

    step "Installing lazygit..."
    local tmp_dir
    tmp_dir=$(mktemp -d)

    local version
    version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -Po '"tag_name": "v\K[^"]*')

    local archive="lazygit_${version}_Linux_x86_64.tar.gz"
    [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]] && archive="lazygit_${version}_Linux_arm64.tar.gz"

    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/${archive}" \
        -o "$tmp_dir/lazygit.tar.gz"
    tar -C "$tmp_dir" -xzf "$tmp_dir/lazygit.tar.gz" lazygit
    sudo install "$tmp_dir/lazygit" /usr/local/bin/lazygit
    rm -rf "$tmp_dir"
    log "lazygit installed to /usr/local/bin/lazygit"
}

# ============================================================
# git-delta: latest release from GitHub (Linux)
# ============================================================
install_delta_linux() {
    if command -v delta &>/dev/null; then
        log "git-delta already installed"
        return
    fi

    step "Installing git-delta..."
    local tmp_dir
    tmp_dir=$(mktemp -d)

    local version
    version=$(curl -fsSL "https://api.github.com/repos/dandavison/delta/releases/latest" \
        | grep -Po '"tag_name": "\K[^"]*')

    local deb="git-delta_${version}_amd64.deb"
    [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]] && deb="git-delta_${version}_arm64.deb"

    curl -fsSL "https://github.com/dandavison/delta/releases/latest/download/${deb}" \
        -o "$tmp_dir/delta.deb"
    sudo dpkg -i "$tmp_dir/delta.deb"
    rm -rf "$tmp_dir"
    log "git-delta installed"
}

# ============================================================
# tig: text-mode git browser (Linux — via apt)
# ============================================================
install_tig_linux() {
    if command -v tig &>/dev/null; then
        log "tig already installed"
        return
    fi
    step "Installing tig..."
    sudo apt-get install -y tig
    log "tig installed"
}

# ============================================================
# mise: polyglot version manager (cross-platform install script)
# ============================================================
install_mise() {
    if command -v mise &>/dev/null; then
        log "mise already installed"
        return
    fi

    step "Installing mise..."
    curl -fsSL https://mise.run | sh
    log "mise installed"
}

# ============================================================
# Wire mise activate into ~/.zshrc (if not already present)
# ============================================================
setup_mise_zshrc() {
    local zshrc="$HOME/.zshrc"
    local line='eval "$(mise activate zsh)"'
    if [[ -f "$zshrc" ]] && grep -qF 'mise activate zsh' "$zshrc"; then
        log "mise activate already in $zshrc"
    else
        echo "$line" >> "$zshrc"
        log "Added mise activate to $zshrc"
    fi
}

# ============================================================
# Node.js LTS: install via mise
# ============================================================
install_node_lts() {
    step "Installing Node.js LTS via mise..."

    # Ensure mise is on PATH (may have just been installed by install_mise)
    local mise_bin
    if command -v mise &>/dev/null; then
        mise_bin="mise"
    elif [[ -x "$HOME/.local/bin/mise" ]]; then
        mise_bin="$HOME/.local/bin/mise"
    else
        warn "mise not found; skipping Node.js LTS install"
        return
    fi

    if $mise_bin list node 2>/dev/null | grep -q 'lts\|[0-9]'; then
        log "Node.js already managed by mise ($(node --version 2>/dev/null || echo 'not active yet'))"
    else
        $mise_bin use --global node@lts
        log "Node.js LTS installed via mise"
    fi
}

# ============================================================
# Wire Starship into zsh (append to ~/.zshrc if not already there)
# ============================================================
setup_zsh() {
    step "Setting up zsh..."

    # Make zsh the default shell if it isn't already
    local zsh_path
    zsh_path="$(command -v zsh)"
    if [[ "$SHELL" != "$zsh_path" ]]; then
        # Ensure zsh is in /etc/shells
        if ! grep -qF "$zsh_path" /etc/shells; then
            echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        fi
        log "Changing default shell to zsh (you may be prompted for your password)..."
        chsh -s "$zsh_path"
    else
        log "zsh is already the default shell"
    fi

    # ~/.zshrc is managed as a dotfile symlink (handled in link_all)
}

# ============================================================
# tmux plugin manager (tpm)
# ============================================================
install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" ]]; then
        log "tpm already installed"
    else
        step "Installing tpm (tmux plugin manager)..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    fi
}

# ============================================================
# Neovim: clone LazyVim starter into dotfiles/nvim
# (only if it hasn't been set up yet)
# ============================================================
init_nvim_dotfile() {
    local dst="$DOTFILES_DIR/nvim"

    if [[ -f "$dst/init.lua" ]]; then
        log "Neovim dotfile already exists, skipping LazyVim clone"
        return
    fi

    step "Cloning LazyVim starter into dotfiles/nvim..."
    # Clone into a temp location, then move (avoids partial state on failure)
    local tmp_dir
    tmp_dir=$(mktemp -d)

    git clone https://github.com/LazyVim/starter "$tmp_dir/nvim"
    rm -rf "$tmp_dir/nvim/.git"    # don't nest git repos
    cp -r "$tmp_dir/nvim/." "$dst/"
    rm -rf "$tmp_dir"
    log "LazyVim starter placed in $dst"
}

# ============================================================
# Symlink dotfiles into standard locations
# ============================================================
link_all() {
    step "Symlinking dotfiles..."

    # WezTerm: ~/.config/wezterm/wezterm.lua
    link_dotfile "wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"

    # tmux: ~/.tmux.conf
    link_dotfile "tmux/.tmux.conf" "$HOME/.tmux.conf"

    # Neovim: ~/.config/nvim (whole directory)
    link_dotfile "nvim" "$HOME/.config/nvim"

    # Starship: ~/.config/starship/starship.toml
    link_dotfile "starship/starship.toml" "$HOME/.config/starship/starship.toml"

    # zsh: ~/.zshrc
    link_dotfile "zsh/.zshrc" "$HOME/.zshrc"

    # zsh aliases: ~/.config/zsh/aliases.zsh
    link_dotfile "zsh/aliases.zsh" "$HOME/.config/zsh/aliases.zsh"
}

# ============================================================
# Summary
# ============================================================
print_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Setup complete!                        ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BLUE}Dotfiles location:${NC} $DOTFILES_DIR"
    echo -e "  ${BLUE}(this dotfiles repo — commit and push to GitHub to persist your configs)${NC}"
    echo ""
    echo -e "  ${BLUE}To restore a previous config:${NC}"
    echo -e "    rm <symlink-path>"
    echo -e "    mv <path>.bak.<timestamp> <path>"
    echo ""
    echo -e "  ${BLUE}Next steps:${NC}"
    echo ""
    echo -e "  1. ${YELLOW}WezTerm${NC}  — Restart WezTerm to apply config."
    echo -e "               If fonts look wrong, log out/in (Linux font cache)."
    echo ""
    echo -e "  2. ${YELLOW}tmux${NC}     — Start a session, then press ${GREEN}Ctrl-a + I${NC}"
    echo -e "               (capital I) to install plugins via tpm."
    echo ""
    echo -e "  3. ${YELLOW}Neovim${NC}   — Run ${GREEN}nvim${NC}. LazyVim installs plugins on"
    echo -e "               first launch (takes ~1 min)."
    echo ""
    echo -e "  4. ${YELLOW}Starship${NC} — Open a new zsh session to see the prompt."
    echo -e "               Config: ${GREEN}$DOTFILES_DIR/starship/starship.toml${NC}"
    echo ""
    echo -e "  5. ${YELLOW}mise${NC}     — Activated automatically in .zshrc."
    echo ""
    echo -e "  6. ${YELLOW}direnv${NC}   — Add to your .zshrc:"
    echo -e "               ${GREEN}eval \"\$(direnv hook zsh)\"${NC}"
    echo ""
    echo -e "  7. ${YELLOW}fzf${NC}      — Add to your .zshrc:"
    echo -e "               ${GREEN}source <(fzf --zsh)${NC}"
    echo ""
    echo -e "  8. ${YELLOW}lazygit${NC}  — Run ${GREEN}lazygit${NC} inside any git repo."
    echo ""
    echo -e "  9. ${YELLOW}git-delta${NC}— Add to your ~/.gitconfig:"
    echo -e "               ${GREEN}[core] pager = delta${NC}"
    echo -e "               ${GREEN}[delta] navigate = true${NC}"
    echo ""
    echo -e "  10. ${YELLOW}tig${NC}     — Run ${GREEN}tig${NC} inside any git repo to browse history."
    echo -e "               ${GREEN}tig status${NC} for a staging UI, ${GREEN}tig blame <file>${NC} for blame."
    echo ""
    echo -e "  11. ${YELLOW}Node.js${NC} — Installed via mise (LTS). Open a new shell and run"
    echo -e "               ${GREEN}node --version${NC} to confirm."
    echo ""
}

# ============================================================
# Main
# ============================================================
main() {
    echo ""
    echo -e "${BLUE}Dev environment setup — $(date)${NC}"
    echo -e "${BLUE}Platform: $PLATFORM / Arch: $ARCH${NC}"
    echo ""

    install_packages
    [[ "$PLATFORM" == "macos" ]] && install_mise
    install_node_lts
    install_nerd_font
    install_tpm
    init_nvim_dotfile
    link_all
    setup_zsh
    setup_mise_zshrc

    print_summary
}

main "$@"
