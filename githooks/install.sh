#!/usr/bin/env bash
# Install the global git hooks into ~/.config/git/hooks and point git at them.
# Starts in `warn` mode, so it can report but never reject a commit.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/git/hooks"

mkdir -p "$DEST/lib"
for f in "$SRC"/*; do
  b="$(basename "$f")"
  case "$b" in install.sh|README.md|lib) continue ;; esac
  cp "$f" "$DEST/$b"
  chmod +x "$DEST/$b"
done
cp "$SRC"/lib/*.sh "$DEST/lib/"
chmod +x "$DEST"/lib/*.sh

# Preserve an existing mode; default to the non-blocking one.
[ -f "$DEST/mode" ] || echo warn > "$DEST/mode"

# Seed the repo list for the drift sweep. Untracked on purpose: private repo
# names must not reach a public dotfiles repository.
if [ ! -f "$DEST/sweep-repos" ]; then
  cat > "$DEST/sweep-repos" <<'EOF'
# One repo path per line for ai-attribution-sweep.sh. '#' comments are ignored.
# ~ and $HOME expand. This file is intentionally not tracked.
# $HOME/src/example
EOF
fi

git config --global core.hooksPath "$DEST"

echo "installed -> $DEST"
echo "  mode:     $(cat "$DEST/mode")   (echo block > $DEST/mode to enforce)"
echo "  hooksPath: $(git config --global --get core.hooksPath)"
echo "  undo:     git config --global --unset core.hooksPath"
echo
echo "Repo-local hooks still run: every hook here delegates to the repo's own"
echo "first, because core.hooksPath REPLACES .git/hooks rather than chaining."
