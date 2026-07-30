#!/usr/bin/env bash
# install.sh — link mydotfiles's dotfiles into your home dir. Backs up anything it replaces.
# Idempotent: re-run any time. Templates (gitconfig, zshrc.snippets) are NOT auto-applied
# — you copy/merge those by hand so your identity + secrets stay yours.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$REPO/dotfiles"
STAMP="$(date +%Y%m%d-%H%M%S)"

link() { # link <src> <dest>
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    cp "$dest" "$dest.bak-$STAMP"; echo "backed up $dest -> $dest.bak-$STAMP"
  fi
  ln -sfn "$src" "$dest"; echo "linked $dest -> $src"
}

link "$D/tmux.conf"               "$HOME/.tmux.conf"
link "$D/vimrc"                   "$HOME/.vimrc"
link "$D/gitignore_global"        "$HOME/.gitignore_global"
link "$D/config-tmux/git-status.sh" "$HOME/.config/tmux/git-status.sh"
# Ghostty reads the XDG path on every platform (macOS additionally reads
# ~/Library/Application Support/com.mitchellh.ghostty/config; identical keys merge cleanly).
link "$D/ghostty/config"          "$HOME/.config/ghostty/config"
link "$D/ghostty/themes/ayu-dark" "$HOME/.config/ghostty/themes/ayu-dark"

echo
echo "Linked the safe dotfiles. Manual steps (identity/secrets — intentionally not automated):"
echo "  • ~/.gitconfig     : cp $D/gitconfig.template ~/.gitconfig  then fill in name/email"
echo "  • ~/.zshrc         : append the parts you want from $D/zshrc.snippets"
echo "  • tmux plugins     : git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm ; open tmux, prefix + I"
