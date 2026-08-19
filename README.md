# mydotfiles

My Mac setup: tmux, vim, zsh, and the AI-coding tools I use together. Part
reference-for-future-me, part a guide anyone can hand their local LLM to stand up the
same setup. No secrets live here — every credential is a `<<PLACEHOLDER>>` you supply
yourself.

## New here? (total-beginner path)

Don't read this file — hand it to an AI and let it do the work. On a Mac:

1. Install [Claude Code](https://claude.com/claude-code) (or Cursor, or Codex — any
   agent that can run terminal commands).
2. Paste it this repo's URL and say:

   > Set my machine up from https://github.com/hareeshnagaraj/mydotfiles — go
   > section by section, ask me before each piece, and skip anything I won't
   > need as a beginner.

3. Say yes to Homebrew, the font, and the shell basics; skip whatever sounds like
   overkill. You can rerun this any time and add more.

The guide below is written for the AI to execute, so that's genuinely all there is
to it.

## Layout

```
mydotfiles/
├── README.md            ← this guide (narrated, opt-in, LLM-friendly)
├── dotfiles/            ← the actual scrubbed configs (symlinked into ~ by install.sh)
│   ├── tmux.conf            (multi-agent zoom workflow + Catppuccin)
│   ├── vimrc
│   ├── gitignore_global
│   ├── zshrc.snippets       (curated safe subset — you append what you want)
│   ├── gitconfig.template   (fill in your own name/email)
│   ├── config-tmux/git-status.sh
│   ├── ghostty/             (terminal config + ayu-dark theme)
│   └── yazi/                (file tree + glow + ayu-dark flavor matching Ghostty)
├── scripts/
│   ├── install.sh       ← symlink dotfiles into ~ (backs up existing)
│   ├── sync.sh          ← pull my current configs back in, scrubbed (the periodic update)
│   ├── scrub.sh         ← secret redactor + hard scanner (the safety spine)
│   └── pre-commit       ← blocks any commit that would leak a secret
├── githooks/            ← global AI-attribution guard (commit-msg warn/block)
├── launchd/             ← optional weekly auto-sync agent (never pushes)
└── Makefile             ← make install | sync | scan | hook | githooks | sync-install
```

## Use it

```bash
make install       # link dotfiles into ~ (safe; backs up what it replaces)
make hook          # install the pre-commit secret scanner (do this once)
make githooks      # optional: global hooks that flag AI authorship trailers
make sync          # pull this box's current configs back into the repo, scrubbed + scanned
make sync-install  # optional: weekly launchd agent that runs sync (stages only, never pushes)
```

`sync.sh` is how mydotfiles stays current: it re-copies my live dotfiles through the secret
redactor, regenerates the "skills on this box" appendix (Claude + Codex + Grok + Cursor +
agents), hard-scans for leaks, and stages the diff — commit + push stay manual, always.

---

# My macOS Terminal + AI-Coding Setup — Handoff

> **What this is:** everything I've tuned on my Mac over the years — tmux, vim, zsh,
> key rebindings, the Homebrew stack, and (the good part) the constellation of AI
> coding tools that talk to each other. One file. Hand it to a friend on a Mac,
> tell them to point their local LLM at it, and it walks them through setting the
> whole thing up — piece by piece, so they choose what they want.

---

## FOR THE ASSISTANT READING THIS (Claude Code / Codex / Cursor / whatever)

You are helping a human replicate someone else's Mac setup. **Do not dump everything
at once. Go section by section, opt-in.** Protocol:

1. Run the **Preflight** block first. Tell them what's already installed vs missing.
2. Then, for each `##` section below, in order:
   - Give them the **2-sentence "what & why"** at the top of the section.
   - Ask: *"Want this one? (y / skip / tell me more)"*
   - On **yes**: back up any file you're about to overwrite (`cp x x.bak-YYYYMMDD`),
     then apply the config block exactly as written. Show a one-line diff summary.
   - On **more**: explain the interesting bits (the comments in each block say why).
   - On **skip**: move on. Never apply a skipped section.
3. **Secrets:** every `<<PLACEHOLDER>>` is a secret the human must supply *themselves*.
   Never invent one. The original owner's tokens are NOT in this file on purpose.
4. At the end, run the **Verify** block and report what works.

Keep the tone of a friendly explainer — this is a guided tour, not a silent installer.

---

## Preflight — what's needed

```bash
# Homebrew (the foundation for everything else)
command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# A Nerd Font — REQUIRED for the tmux/prompt glyphs (git pills, powerline arrows) to render
brew list --cask font-caskaydia-cove-nerd-font >/dev/null 2>&1 || brew install --cask font-caskaydia-cove-nerd-font
# Then set your terminal's font to "CaskaydiaCove Nerd Font". Without this you get tofu boxes.

# Report state
for t in brew tmux nvim vim git gh fzf starship zsh; do command -v $t >/dev/null && echo "have $t" || echo "MISSING $t"; done
```

I use **Ghostty** as the terminal (`brew install --cask ghostty`) — config + theme are in
the Ghostty section below. iTerm2 or Terminal.app work too — you just need the Nerd Font set.

---

## Homebrew stack — the CLI toolbox

**What & why:** the command-line tools I reach for daily. Install the ones you want;
none are mandatory for the configs below except where noted.

```bash
# Core dev + shell quality-of-life
brew install git gh tig fzf zsh-autosuggestions zsh-syntax-highlighting starship coreutils gnu-sed gawk

# Terminal / multiplexer
brew install tmux

# Languages & runtimes I keep around
brew install node python@3.11 pipx

# Handy utilities
brew install glow pandoc poppler ffmpeg yt-dlp shellcheck jq yazi fd zoxide

# Networking / infra (skip unless you use them)
brew install cloudflared tailscale flyctl hcloud

# Casks (GUI)
brew install --cask ghostty orbstack swiftbar
```

- `fzf` powers the tmux copy-popup below — **install it if you take the tmux section.**
- `yazi` `fd` `zoxide` — **install these if you take the yazi section.** `glow` is already
  on the handy-utilities line (used as the markdown reader).
- `zsh-autosuggestions` + `zsh-syntax-highlighting` make the shell feel alive (grey
  inline completions + colored validity). Wire-up is in the zsh section.

---

## Ghostty — the terminal itself

**What & why:** Ghostty is a GPU-fast terminal whose entire configuration is one plain
text file — no settings maze. Mine is two lines: the Nerd Font everything below assumes,
and an Ayu Dark theme (a custom port; the palette matches how I like tmux/vim to sit).

**Paths (important on macOS):** Ghostty merges keys from both of these if both exist:

1. `~/.config/ghostty/config` (XDG — portable)
2. `~/Library/Application Support/com.mitchellh.ghostty/config` (macOS App Support)

`make install` **symlinks the same repo file into both**, so an empty App Support template
cannot silently override your theme/font. `make sync` prefers App Support, then falls
back to XDG, and strips comment banners so the repo only keeps real settings.

The config content:

```
theme = ayu-dark
font-family = CaskaydiaCove Nerd Font Mono
```

The theme is a file dropped at `~/.config/ghostty/themes/ayu-dark` (and the matching App
Support themes path on macOS) — Ghostty picks up any file in that dir by name, so
`theme = ayu-dark` just works:

```
background = #0b0e14
foreground = #bfbdb6
selection-background = #1b3a5b
selection-foreground = #bfbdb6
cursor-color = #bfbdb6
cursor-text = #0b0e14
palette = 0=#1e232b
palette = 1=#ea6c73
palette = 2=#7fd962
palette = 3=#f9af4f
palette = 4=#53bdfa
palette = 5=#cda1fa
palette = 6=#90e1c6
palette = 7=#c7c7c7
palette = 8=#686868
palette = 9=#f07178
palette = 10=#aad94c
palette = 11=#ffb454
palette = 12=#59c2ff
palette = 13=#d2a6ff
palette = 14=#95e6cb
palette = 15=#ffffff
```

Both files live in `dotfiles/ghostty/` and are linked by `install.sh` / re-absorbed by
`sync.sh`. Reload a running Ghostty with **Cmd+Shift+,** — no restart needed.

---

## Caps Lock → Control (required for the tmux muscle memory)

**What & why:** tmux prefix is `Ctrl-a`. I remap **Caps Lock → Control** in macOS
**System Settings → Keyboard → Modifier Keys** so the prefix is **Caps+A** under my
left pinky — no chord gymnastics. Without this remap, use plain `Ctrl-a` instead.

This is a macOS setting, not a file in the repo. Do it once per machine / keyboard.

---

## zsh — shell config

**What & why:** agnoster prompt with live git branch, a few aliases, PATH for agent
CLIs, the multi-agent tmux cheat sheet, a tmux-safe mouse flag for AI TUIs, and a
helper to run Codex against a Venice-hosted model. Append to `~/.zshrc` (or copy from
`dotfiles/zshrc.snippets`).

```bash
# --- aliases ---
alias g="git"
alias ll="ls -a -l"

# --- prompt: agnoster theme + live git branch in the prompt ---
ZSH_THEME="agnoster"
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '(%b)'
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f %F{yellow}${vcs_info_msg_0_}%f %# '

# --- suggestions + syntax highlighting (installed via brew above) ---
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# --- completions ---
autoload -Uz compinit && compinit -C

# --- agent CLIs on PATH ---
export PATH="$HOME/.grok/bin:$HOME/.local/bin:$PATH"

# --- tmux multi-agent workflow (prefix = Ctrl-a; Caps Lock → Control on this Mac) ---
# Prefix:     Caps+A
# Hop panes:  prefix then arrows  OR  h/j/k/l  OR  click the pane
# Zoom:       prefix then z   (full-screen the active agent; again to leave)
# 2×2 grid:   split into 4 panes, then prefix then Z  (tiled layout)
# Windows:    prefix c (new) | n/p (next/prev) | 0-9 | , (rename)
# Splits:     prefix | (horizontal) | - (vertical)
# Copy:       prefix [  then v/y  |  prefix C-p (fzf clean multi-line copy)
# Misc:       prefix r (reload) | prefix T (name pane) | prefix ? (all binds)

# --- THE non-obvious one ---
# Claude Code (and similar agent TUIs) use the terminal's alternate-screen buffer and
# fight tmux for mouse-scroll, corrupting the display. Hand scroll fully to tmux when
# inside a tmux session. (Outside tmux, full mouse support is preserved.)
[ -n "$TMUX" ] && export CLAUDE_CODE_DISABLE_MOUSE=1
```

**Secrets — always Keychain, never inline in `~/.zshrc`:**

```bash
# store once:
#   security add-generic-password -a "$USER" -s hcloud-token -w '<<YOUR_HCLOUD_TOKEN>>'
#   security add-generic-password -a "$USER" -s my-openrouter-key -w '<<YOUR_OPENROUTER_KEY>>'
export HCLOUD_TOKEN="$(security find-generic-password -a "$USER" -s hcloud-token -w 2>/dev/null)"
```

**Optional — run Codex against a Venice-hosted model** (I use this to drive `claude-fable-5`
through the Codex CLI):

```bash
venicefable() {
  local k; k="$(security find-generic-password -a "$USER" -s my-openrouter-key -w 2>/dev/null)"
  [ -z "$k" ] && { print -u2 "venicefable: missing Keychain item my-openrouter-key"; return 1; }
  OPENROUTER_API_KEY="$k" command codex \
    -c 'model_provider="venice"' -c 'model="claude-fable-5"' \
    -c 'model_providers.venice.name="Venice Fable"' \
    -c 'model_providers.venice.base_url="https://api.venice.ai/api/v1"' \
    -c 'model_providers.venice.env_key="OPENROUTER_API_KEY"' \
    -c 'model_providers.venice.requires_openai_auth=true' "$@"
}
alias vfable=venicefable
```

> **Secrets note:** never commit tokens. `sync.sh` does **not** absorb raw `~/.zshrc` or
> `~/.gitconfig` for this reason. Cloud tokens (Hetzner `hcloud-token`, OpenRouter, etc.)
> live in Keychain only.

---

## tmux — the big one

**What & why:** `Ctrl-a` prefix (Caps+A with the Caps→Control remap), multi-agent zoom
workflow, vim pane navigation, a self-hiding git pill, Catppuccin Mocha, session
persistence, and an fzf popup that copies clean multi-line text. Canonical file:
`dotfiles/tmux.conf` (linked by `make install`).

### Multi-agent zoom workflow (how I actually work)

I run **one Ghostty window → one tmux session → four panes** (e.g. Claude / Grok /
Codex / shell). Agents stay alive in the small panes; I only full-screen the one I'm
driving.

| Action | Keys |
|--------|------|
| Prefix | **Caps+A** (or `Ctrl-a`) |
| Hop panes | prefix then **arrows** or **h/j/k/l**, or **click** a pane |
| Zoom / unzoom | prefix then **z** — yellow **Z** appears in the status bar while zoomed |
| Even 2×2 layout | create four panes, then prefix then **Z** (`select-layout tiled`) |
| Name a pane | prefix then **T** |
| Reload config | prefix then **r** |

Why this works: four agent TUIs visible at once is noisy but high-bandwidth; zoom
gives full attention without killing the other sessions. Continuum/resurrect keep the
layout across reboots.

**Install TPM (plugin manager) first, then drop the config:**

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Prefer `make install` (symlinks `dotfiles/tmux.conf`). If you must paste by hand, write
`~/.tmux.conf` from that file. Highlights of the live config:

```tmux
# Prefix Ctrl-a  ·  Caps+A when Caps Lock → Control
# Zoom: prefix z   ·  tiled 2×2: prefix Z   ·  hop: arrows or hjkl
unbind C-b
set -g prefix C-a
bind C-a send-prefix
bind z resize-pane -Z
bind Z select-layout tiled \; display-message "layout: tiled (2x2-friendly)"
# status left shows yellow Z while zoomed:
# set -g status-left "#{E:@catppuccin_status_session}#{?window_zoomed_flag, #[fg=#f9e2af bold]Z#[default],} "
```

Full file also has: mouse on, 20k history, Catppuccin Mocha, continuum/resurrect,
pane labels only when split, `prefix+T` pane naming, fzf block-copy (`prefix C-p`),
and wheel → tmux copy-mode so agent TUIs don't steal scroll.

**The custom git segment** (dependency-free; shows branch + clean/dirty + ahead/behind,
and renders *nothing* outside a repo). Write `~/.config/tmux/git-status.sh` and
`chmod +x` it:

```bash
#!/usr/bin/env bash
# Self-contained git segment for the tmux status bar (Catppuccin Mocha).
# ✔ clean · ● dirty · ⇡ahead ⇣behind ⇕diverged. 15s cache. Fail-soft (never errors the bar).
set +e; set +o pipefail
CRUST="#11111b"; TEAL="#94e2d5"; PEACH="#fab387"; CACHE_TTL_SEC=15
dir="${1:-$PWD}"; cd "$dir" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
toplevel="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cache_dir="${TMPDIR:-/tmp}/tmux-git-status-cache"; mkdir -p "$cache_dir" 2>/dev/null
cache_key="$(printf '%s' "$toplevel" | tr -c 'A-Za-z0-9._-' '_')"; cache_file="$cache_dir/$cache_key"
if [ -f "$cache_file" ]; then
  now="$(date +%s 2>/dev/null)" || now=0; mtime="$(stat -f %m "$cache_file" 2>/dev/null)" || mtime=0
  age=$(( now - mtime ))
  if [ "$age" -ge 0 ] && [ "$age" -lt "$CACHE_TTL_SEC" ]; then cat "$cache_file" 2>/dev/null; exit 0; fi
fi
branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)"
if [ -z "$branch" ]; then
  branch="$(git rev-parse --short HEAD 2>/dev/null)"; [ -z "$branch" ] && exit 0; branch=":${branch}"
fi
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then symbol="●"; accent="$PEACH"; else symbol="✔"; accent="$TEAL"; fi
sync=""; counts="$(git rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)"
if [ -n "$counts" ]; then
  behind="$(printf '%s' "$counts" | awk '{print $1}')"; ahead="$(printf '%s' "$counts" | awk '{print $2}')"
  if [ "${ahead:-0}" -gt 0 ] && [ "${behind:-0}" -gt 0 ]; then sync=" ⇕${ahead}/${behind}"
  elif [ "${ahead:-0}" -gt 0 ]; then sync=" ⇡${ahead}"
  elif [ "${behind:-0}" -gt 0 ]; then sync=" ⇣${behind}"; fi
fi
out="$(printf '#[fg=%s,bg=default]#[fg=%s,bg=%s] 󰊢 %s %s%s #[fg=%s,bg=default,nobold]' \
  "$accent" "$CRUST" "$accent" "$branch" "$symbol" "$sync" "$accent")"
printf '%s' "$out" >"$cache_file" 2>/dev/null; printf '%s' "$out"; exit 0
```

**After writing both:** open tmux and hit `Ctrl-a` then `I` (capital i) to have TPM
install the plugins. First launch pulls catppuccin/resurrect/etc.

---

## vim — minimal readable defaults

**What & why:** sane defaults, visual-line movement on wrapped lines, and clean markdown
rendering. Tiny. Write `~/.vimrc`:

```vim
" Minimal readable defaults
syntax on
set nocompatible
set wrap linebreak breakindent
set number
set scrolloff=4
set incsearch hlsearch ignorecase smartcase
set backspace=indent,eol,start

" Move by visual line when wrapped
nnoremap j gj
nnoremap k gk

" Markdown: hide syntax clutter (**bold** renders bold, links show label only)
autocmd FileType markdown setlocal conceallevel=2 textwidth=0 colorcolumn=0
let g:markdown_folding = 0
```

---

## yazi — how I read files without VS Code

**What & why:** Ghostty is the terminal. tmux is the session (one window, four
agent panes). [yazi](https://yazi-rs.github.io/) is the file tree in a pane.
[glow](https://github.com/charmbracelet/glow) is the markdown reader. vim is the
editor. I do not open VS Code to look at a plan or a doc.

### The stack

```
Ghostty (ayu-dark)
  └── tmux  (prefix = Caps+A / Ctrl-a)
        ├── agent panes (Claude / Grok / Codex / …)
        └── a shell pane
              └── y   → yazi tree
                    ├── i      → glow (read)
                    └── Enter  → vim  (edit)
```

Configs: `dotfiles/yazi/{yazi,keymap,package,theme}.toml` (symlinked by
`make install`). Flavor is **ayu-dark** so yazi matches Ghostty, not the mocha
tmux bar. Piper (md preview) and the flavor are **not** vendored:

```bash
brew install yazi fd zoxide   # glow is already in the handy-utilities line
# after make install:
ya pkg add yazi-rs/plugins:piper kmlupreti/ayu-dark
```

Append the yazi block in `dotfiles/zshrc.snippets` to `~/.zshrc`: `EDITOR`/`VISUAL=vim`,
the official `y` cwd-file wrapper, `eval "$(zoxide init zsh)"`, and `alias plans=…`.

### Daily keys (all inside tmux)

| Want | Do |
|------|----|
| Open the tree here | `y` |
| Open Claude's plan folder | `plans`  (`y ~/.claude/plans`, newest first) |
| Read markdown | hover the file, **`i`** (glow). `q` back to yazi |
| Edit | **Enter** (vim). `:q` back to yazi |
| Newest / dates | default is newest-modified first with the date column on. `,` `M` if you turned it off |
| Leave yazi | `q` (shell cds to last dir) or `Q` (stay put) |
| Copy text | `Caps+A` `[` then `v`/`y`  — or `Caps+A` `C-p` for unwrapped agent output. Paste: Cmd-v |
| Zoom one agent | `Caps+A` `z` (not copy) |

`hjkl` moves. `z` in yazi is fzf jump. `Z` is zoxide. `s` is fd name search.

### Do not

- **Click the path** under a Claude plan (`ctrl+g to edit in VS Code` /
  `~/.claude/plans/….md`). Ghostty hands that click to macOS, which opens
  VS Code. Hop to a shell pane and run `plans`, then `i`.
- Scroll the skinny yazi preview with `J`/`K` to *read*. That's a glance.
  `i` is the reader.
- Use tmux copy-mode and Ghostty-native select as two competing habits.
  Copy is tmux-only.

### Files

| File | Role |
|------|------|
| `dotfiles/yazi/yazi.toml` | newest-first, mtime column, wider preview, glow via piper |
| `dotfiles/yazi/keymap.toml` | `i` → `glow -t` |
| `dotfiles/yazi/theme.toml` | `dark = "ayu-dark"` |
| `dotfiles/yazi/package.toml` | pins piper + ayu-dark (`ya pkg`) |
| `dotfiles/zshrc.snippets` | `y()`, `plans`, `EDITOR=vim`, zoxide |

---

## git — config

**What & why:** identity, `gh` as the GitHub credential helper, a global ignore for
local-only agent files. **Change the name/email to yours.** Write `~/.gitconfig`:

```ini
[user]
	name = <<YOUR NAME>>
	email = <<you@example.com>>
[core]
	excludesfile = ~/.gitignore_global
[credential "https://github.com"]
	helper =
	helper = !gh auth git-credential
[credential "https://gist.github.com"]
	helper =
	helper = !gh auth git-credential
```

And `~/.gitignore_global` — keeps per-machine agent scratch out of every repo:

```gitignore
CLAUDE.local.md
.claude.local/
**/.claude/settings.local.json
```

Run `gh auth login` once so the credential helper works.

---

## The AI-coding constellation — the actually-interesting part

**What & why:** I don't use one AI tool. I run several in **lanes**, often **side by
side in tmux panes**, and they cross-check each other. Reproduce the *flow*, not just
the binaries.

### The tools & their lanes (current)

| Tool | Install | Lane I use it in |
|------|---------|------------------|
| **Claude Code** | `curl -fsSL https://claude.ai/install.sh \| bash` | Primary orchestrator: specs, fleet, reviews, final judgment; agent teams on |
| **Grok CLI** | grok installer (`~/.grok/bin` on PATH) | Default dual-loop partner; frames, awards, verifies; designated skeptic |
| **Cursor** (`cursor-agent`) | cursor.com | **SPAR implementer** — writes the accepted edits (often driven as Grok-4.5) |
| **Codex CLI** (OpenAI) | `brew install codex` | Implementation muscle for well-specified slices; alternate full runtime |
| **gbrain** | `bun install -g gbrain` / `setup-gbrain` | Persistent memory across every tool + session (MCP) |
| **gstack** | gstack install / `/gstack-upgrade` | Large shared skill suite on Claude (+ Codex mirrors) |
| **Kimi / OpenCode** | optional installers | Occasional alt models / Pencil MCP experiments |

### Physical layout

Four panes in one terminal is normal: Claude · Grok · Codex · shell. Hop with
**Caps+A + arrows**, zoom with **Caps+A z**. See the multi-agent zoom section above.

### Two different things both called "SPAR"

Do not conflate them — same name, different contracts:

| | **Grok SPAR** (default implement loop) | **Claude `/spar`** (adversarial spar) |
|--|----------------------------------------|--------------------------------------|
| Where | `~/.grok/skills/spar` + `~/.grok/AGENTS.md` | `~/.claude/skills/spar` |
| Meaning | **S**cope · **P**unch · **A**ward · **R**ealize | Send a plan to Grok to **attack** it |
| Who writes code | **Cursor** implements accepted items only | Nobody — review only |
| Who decides | Grok ACCEPT / REJECT / DEFER | Claude reconciles Grok's attack |
| When | Multi-file implement, refactor, PR-bound work | "Poke holes in this plan" |

Grok SPAR hard defaults: **PR base = `develop`** unless you name another; one writer
per file-set; skip for pure Q&A / one-line typos.

### Lanes + cross-review (the pattern)

- **Claude orchestrates** (and still implements when that's the right tool). Prefer
  `/conserve-claude` when grunt work can go to Codex/Grok/Cursor.
- **Grok × Cursor SPAR** is the default dual loop for non-trivial coding on the Grok
  side: Grok frames → Cursor punches (review/plan) → Grok awards → Cursor implements →
  Grok verifies.
- **Codex** gets well-specified implementation slices; don't make it re-derive architecture
  Claude already mapped.
- **gbrain** holds cross-session memory — every tool with the MCP registered can recall.
- **No AI authorship attribution** in commits/PRs — enforced by global `githooks`
  (`make githooks`) plus prose in `~/.claude/CLAUDE.md` / `~/.grok/AGENTS.md` /
  `~/.codex/AGENTS.md`.
- **Observability:** headless dispatches stream to a logfile you can `tail -f` — never
  pipe through `tail` (buffers till exit), never fire-and-forget without a liveness timeout.

### Wiring examples

1. **`venicefable` (zsh)** — Venice-hosted model driven through the Codex CLI; key in
   Keychain (`my-openrouter-key`).
2. **Claude `/spar` → Grok** — packages the conclusion, launches the Grok bridge as
   adversary, relays the attack verbatim. Prompt frame:

   > SPAR / adversarial challenge. Do NOT agree by default. Attack the conclusion below
   > and steelman the opposite. Give the sharpest case AGAINST it.

3. **Grok SPAR → Cursor** — Grok's global default for multi-file work; Cursor is the
   writer, Grok the adjudicator.

### The skill library — the actual muscle

A **skill** is markdown with a trigger + procedure. Most leverage lives here.

| Source | Where it lands | What it is |
|--------|----------------|------------|
| **gstack** | `~/.claude/skills`, `~/.codex/skills` | `/ship`, `/review`, `/investigate`, `/qa`, `/design-review`, `/careful`, `/freeze`, … |
| **Grok skills** | `~/.grok/skills` | SPAR, ponytail family, cursor bridge, design pack (`better-ui`, `apple-design`, …), first-share, imagine |
| **gbrain-published** | brain + any MCP client | Cross-machine curated pack (orchestration, audit, design, fleet) |
| **Cursor / agents** | `~/.cursor/skills*`, `~/.agents/skills` | IDE helpers, remotion, etc. |

**Reach-for skills (illustrative — full live list is the appendix below, auto-synced):**

*Orchestration:* `arbitrage`, `codex-implement`, `conserve-claude`, `factory`, `goalbuddy`, Grok `spar`, Grok `cursor`  
*Quality:* `thermo-nuclear-code-quality-review`, `tavisi-audit`, `deploy-preflight`, Grok `ponytail` / `ponytail-review`  
*Design:* `design-system-forge`, `extract-design`, `taste-loop-sprint`, Grok `better-ui` / `first-share`  
*Memory / ops:* `gbrain-recall`, `fleet-drive`

**Fresh machine:**

1. Install the CLIs you want (Claude, Grok, Codex, Cursor).
2. Install gstack; run `/gstack-upgrade` periodically.
3. Stand up your own gbrain (`setup-gbrain`) — never copy someone else's DB URL or keys.
4. `make install` + Caps→Control + TPM for the terminal half.

**Transferable principle with zero of my tooling:** name repeatable workflows as skills
(trigger + procedure), and keep project memory the agents actually read.

### Claude Code settings worth copying

In `~/.claude/settings.json`:

- **Agent teams** — `"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"`
- **Bash allowlist** for low-risk git/gh/ls so you aren't prompted constantly (generate
  your own from transcripts; don't copy a foreign allowlist blindly)
- **grok-build plugin** enabled when you want Claude → Grok bridge skills

### Grok settings worth knowing

In `~/.grok/config.toml` (yours will differ): vim mode, fullscreen TUI, SPAR as default
via `AGENTS.md`. Disable/ignore skills you don't want (crypto audit packs, remotion, …)
so the router stays sharp.

> **gbrain:** stand up **your own** local brain via `setup-gbrain`. Register it as MCP in
> each tool. Never copy another machine's database URL, API keys, or bearer tokens into
> this repo — `sync.sh` is built to keep those out.

---

## Verify

```bash
# shell
source ~/.zshrc && echo "zsh ok"
# tmux (reload + confirm plugins dir)
tmux source-file ~/.tmux.conf 2>&1 && ls ~/.tmux/plugins/ && echo "tmux ok"
# git identity
git config --get user.name && git config --get user.email
# git status pill renders inside a repo
~/.config/tmux/git-status.sh "$PWD"; echo
# AI tools present
for t in claude codex grok cursor-agent gbrain; do command -v $t >/dev/null && echo "have $t" || echo "no $t (optional)"; done
```

If the tmux status bar shows tofu boxes instead of glyphs → the terminal font isn't a
Nerd Font. Fix that first; everything else is cosmetic-independent.

Multi-agent zoom smoke test: split into four panes (`prefix |` / `prefix -`), hit
`prefix Z` (tiled), hop with `prefix` + arrows, `prefix z` to zoom — status bar should
show a yellow **Z** while zoomed.

---

## Secrets you must supply yourself (never in this file)

| What | Where it goes | How |
|------|---------------|-----|
| OpenRouter / Venice key | Keychain item `my-openrouter-key` | `security add-generic-password -a "$USER" -s my-openrouter-key -w '<<KEY>>'` |
| Hetzner Cloud token | Keychain item `hcloud-token` | `security add-generic-password -a "$USER" -s hcloud-token -w '<<KEY>>'` then `export HCLOUD_TOKEN="$(security find-generic-password -a "$USER" -s hcloud-token -w)"` |
| GitHub auth | `gh` credential store | `gh auth login` |
| gbrain (if used) | each tool's MCP config | stand up your own local brain via `setup-gbrain` |
| Any other cloud tokens | Keychain or your own env, **not** dotfiles | per-provider |

That's the whole setup. Take the sections you want, skip the rest — it's designed to be
à la carte.

---

## Appendix — skills currently on this box (auto-synced)

<!-- SKILLS:BEGIN (auto-generated by scripts/sync.sh — do not edit by hand) -->

Skills currently installed on this box (name — one-line description):

**`~/.claude/skills`**

- `_gstack-command` — Router for the gstack skill suite. (gstack)
- `arbitrage` — Always active when coding in a Claude (Fable) session. Triggers whenever implementation work is being planned, scoped, or about to start — b
- `autoplan` — Auto-review pipeline — reads the full CEO, design, eng, and DX review skills from disk and runs them sequentially with auto-decisions using 
- `benchmark-models` — Cross-model benchmark for gstack skills. (gstack)
- `benchmark` — Performance regression detection using the browse daemon. (gstack)
- `browse` — Fast headless browser for QA testing and site dogfooding. (gstack)
- `canary` — Post-deploy canary monitoring. (gstack)
- `careful` — Safety guardrails for destructive commands. (gstack)
- `codex-first` — Claude Code-only work routing: delegate implementation, fixing, exploratory subagents, rebasing, and PR merging/landing to Codex CLI while C
- `codex-implement` — Delegate a well-specified implementation to OpenAI Codex as a write-access subagent, then verify and open a PR. Use when the user wants Code
- `codex` — OpenAI Codex CLI wrapper — three modes. (gstack)
- `connect-chrome` — Launch GStack Browser — AI-controlled Chromium with the sidebar extension baked in.
- `conserve-claude` — Stay as orchestrator/reviewer while routing heavy authoring and grunt work to codex/grok subagents, to conserve Claude usage without losing 
- `context-restore` — Restore working context saved earlier by /context-save. (gstack)
- `context-save` — Save working context. (gstack)
- `council` — Convene the Council of High Intelligence — multi-persona deliberation with historical thinkers for deeper analysis of complex problems.
- `cso` — Chief Security Officer mode. (gstack)
- `deploy-preflight` — Pre-deploy verification for web apps: proves the build works from a clean clone with no sibling directories, and that every env var and secr
- `design-consultation` — Design consultation: understands your product, researches the landscape, proposes a complete design system (aesthetic, typography, color, la
- `design-html` — Design finalization: generates production-quality Pretext-native HTML/CSS. (gstack)
- `design-review` — Designer's eye QA: finds visual inconsistency, spacing issues, hierarchy problems, AI slop patterns, and slow interactions — then fixes them
- `design-shotgun` — Design shotgun: generate multiple AI design variants, open a comparison board, collect structured feedback, and iterate. (gstack)
- `design-system-forge` — Forge a ratified, handoff-grade design system from real reference sites - extract design language, cluster into token-backed archetypes, bui
- `devex-review` — Live developer experience audit. (gstack)
- `diagram-design` — Create technical and product diagrams — architecture, IT current-state, flowchart, sequence, state machine, ER / data model, timeline, swiml
- `diagram` — Turn an English description (or mermaid source) into a diagram triplet: the source, an editable .excalidraw file you can open (gstack)
- `dispatch-loop` — Compatibility trigger for exactly one installed Tavisi durable-scheduler pass.
- `document-generate` — Generate missing documentation from scratch for a feature, module, or entire project. (gstack)
- `document-release` — Post-ship documentation update. (gstack)
- `explain-diff-html` — Use when the user asks for a rich explanation of a code change, diff, branch, or PR. Produces HTML output.
- `extract-design` — Extract the full design language from any website URL. Produces 8 output files including AI-optimized markdown, visual HTML preview, Tailwin
- `factory` — Software factory — one prompt ships a vertical slice. Spawns 10 specialized
- `fleet-drive` — Resume the attended fleet-driver seat for the Tavisi autonomous fleet on VM hareesh2. Reads the newest checkpoint, verifies live VM state, a
- `freeze` — Restrict file edits to a specific directory for the session. (gstack)
- `frontend-slides` — Create stunning, animation-rich HTML presentations from scratch or by converting PowerPoint files. Use when the user wants to build a presen
- `gbrain-recall` — How to read from and write to gbrain, the cross-project memory. Use when a gbrain call fails with a lock or 'database is locked' or PGLite e
- `goalbuddy` — Goal Prep for GoalBuddy. Use for broad, long-running, stalled, vague, detailed, planned, or unhealthy Codex or Claude Code work that needs a
- `grilling-frontend-prototyping` — Converge on a frontend look through rounds of prototypes and grilling verdicts. Use when the user wants to iterate on UI/visual taste agains
- `grilling` — Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trig
- `gstack-upgrade` — Upgrade gstack to the latest version.
- `gstack` — Router for the gstack skill suite. (gstack)
- `guard` — Full safety mode: destructive command warnings + directory-scoped edits. (gstack)
- `health` — Code quality dashboard. (gstack)
- `investigate` — Systematic debugging with root cause investigation. (gstack)
- `ios-clean` — Remove the DebugBridge SPM package and all #if DEBUG wiring from an iOS app. (gstack)
- `ios-design-review` — Visual design audit for iOS apps on real hardware. (gstack)
- `ios-fix` — Autonomous iOS bug fixer. (gstack)
- `ios-qa` — Live-device iOS QA for SwiftUI apps. (gstack)
- `ios-sync` — Regenerate the iOS debug bridge against the latest upstream gstack templates. (gstack)
- `land-and-deploy` — Land and deploy workflow. (gstack)
- `landing-report` — Read-only queue dashboard for workspace-aware ship. (gstack)
- `learn` — Manage project learnings.
- `make-pdf` — Turn any markdown file into a publication-quality PDF. (gstack)
- `office-hours` — YC Office Hours — two modes. (gstack)
- `open-gstack-browser` — Launch GStack Browser — AI-controlled Chromium with the sidebar extension baked in.
- `pair-agent` — Pair a remote AI agent with your browser. (gstack)
- `plan-ceo-review` — CEO/founder-mode plan review. (gstack)
- `plan-design-review` — Designer's eye plan review — interactive, like CEO and Eng review. (gstack)
- `plan-devex-review` — Interactive developer experience plan review. (gstack)
- `plan-eng-review` — Eng manager-mode plan review. (gstack)
- `plan-tune` — Self-tuning question sensitivity + developer psychographic for gstack (v1: observational). (gstack)
- `prototype` — Build a throwaway prototype to answer a design question. Use when the user wants to sanity-check whether a state model or logic feels right,
- `qa-only` — Report-only QA testing. (gstack)
- `qa` — Systematically QA test a web application and fix bugs found. (gstack)
- `retro` — Weekly engineering retrospective. (gstack)
- `review` — Pre-landing PR review. (gstack)
- `scrape` — Pull data from a web page. (gstack)
- `setup-browser-cookies` — Import cookies from your real Chromium browser into the headless browse session. (gstack)
- `setup-deploy` — Configure deployment settings for /land-and-deploy.
- `setup-gbrain` — Set up gbrain for this coding agent: install the CLI, initialize a local PGLite or Supabase brain, register MCP, capture per-remote trust po
- `ship` — Ship workflow: detect + merge base branch, run tests, review diff, bump VERSION, update CHANGELOG, commit, push, create PR. (gstack)
- `skillify` — Codify the most recent successful /scrape flow into a permanent browser-skill on disk. (gstack)
- `spar` — Adversarial spar: send a plan/decision/conclusion to Grok to be attacked, not validated. Grok steelmans the opposite and returns the sharpes
- `spec` — Turn vague intent into a precise, executable spec in five phases. (gstack)
- `sync-gbrain` — Keep gbrain current with this repo's code and refresh agent search guidance in CLAUDE.md. Wraps the gstack-gbrain-sync orchestrator with sta
- `taste-loop-sprint` — Taste sprint that converges a surface's design through live prototypes and cross-model review, ending with a public link you walk a stakehol
- `tavisi-audit` — Tavisi audit, implementation-review, maintainability-review, proof-validation, and test-planning workflow for collateralcore changes. Use wh
- `tavisi-fleet-ops` — Diagnose, explain, repair, and improve Tavisi fleet operations across schedulers, services, locks, queues, workers, reviews, model lanes, op
- `teach-session` — Become a wise, patient, ruthlessly effective teacher who makes sure the human
- `technical-brief` — Produce a technical/architectural brief as a clean mobile HTML page (plus .md source) that Hareesh can read on a phone and act on. Use when 
- `thermo-nuclear-code-quality-review` — Run an extremely strict maintainability review for abstraction quality, giant files, and spaghetti-condition growth. Use for a thermo-nuclea
- `unfreeze` — Clear the freeze boundary set by /freeze, allowing edits to all directories again. (gstack)

**`~/.codex/skills`**

- `code-judo-quality-review` — Run a native Codex extremely strict maintainability review for abstraction quality, giant files, spaghetti-condition growth, and dramatic st
- `codex-primary-runtime`
- `council` — Convene the Council of High Intelligence in Codex when the user asks for /council, council deliberation, triads, duo debates, or multi-persp
- `dispatch-loop` — Compatibility trigger for exactly one installed Tavisi durable-scheduler pass.
- `entry-point-analyzer` — Analyzes smart contract codebases to identify state-changing entry points for security auditing. Detects externally callable functions that 
- `ethskills` — Use when a request involves Ethereum, the EVM, or blockchain systems. Applies to building, auditing, deploying, or interacting with smart co
- `foundry-poc` — Generates foundry PoC for smart contracts to scientifically from no special privileges to funds lost. Focused on proof of concept for EVM us
- `grok` — Use the locally installed xAI Grok CLI for a focused second opinion, read-only repository review, brainstorming pass, or adversarial critiqu
- `gstack-autoplan` — Auto-review pipeline — reads the full CEO, design, and eng review skills from disk
- `gstack-benchmark` — Performance regression detection using the browse daemon. Establishes
- `gstack-browse` — Fast headless browser for QA testing and site dogfooding. Navigate any URL, interact with
- `gstack-canary` — Post-deploy canary monitoring. Watches the live app for console errors,
- `gstack-careful` — Safety guardrails for destructive commands. Warns before rm -rf, DROP TABLE,
- `gstack-checkpoint` — Save and resume working state checkpoints. Captures git state, decisions made,
- `gstack-connect-chrome` — Launch real Chrome controlled by gstack with the Side Panel extension auto-loaded.
- `gstack-cso` — Chief Security Officer mode. Infrastructure-first security audit: secrets archaeology,
- `gstack-design-consultation` — Design consultation: understands your product, researches the landscape, proposes a
- `gstack-design-html` — Design finalization: generates production-quality Pretext-native HTML/CSS.
- `gstack-design-review` — Designer's eye QA: finds visual inconsistency, spacing issues, hierarchy problems,
- `gstack-design-shotgun` — Design shotgun: generate multiple AI design variants, open a comparison board,
- `gstack-document-release` — Post-ship documentation update. Reads all project docs, cross-references the
- `gstack-freeze` — Restrict file edits to a specific directory for the session. Blocks Edit and
- `gstack-guard` — Full safety mode: destructive command warnings + directory-scoped edits.
- `gstack-health` — Code quality dashboard. Wraps existing project tools (type checker, linter,
- `gstack-investigate` — Systematic debugging with root cause investigation. Four phases: investigate,
- `gstack-land-and-deploy` — Land and deploy workflow. Merges the PR, waits for CI and deploy,
- `gstack-learn` — Manage project learnings. Review, search, prune, and export what gstack
- `gstack-office-hours` — YC Office Hours — two modes. Startup mode: six forcing questions that expose
- `gstack-plan-ceo-review` — CEO/founder-mode plan review. Rethink the problem, find the 10-star product,
- `gstack-plan-design-review` — Designer's eye plan review — interactive, like CEO and Eng review.
- `gstack-plan-eng-review` — Eng manager-mode plan review. Lock in the execution plan — architecture,
- `gstack-qa-only` — Report-only QA testing. Systematically tests a web application and produces a
- `gstack-qa` — Systematically QA test a web application and fix bugs found. Runs QA testing,
- `gstack-retro` — Weekly engineering retrospective. Analyzes commit history, work patterns,
- `gstack-review` — Pre-landing PR review. Analyzes diff against the base branch for SQL safety, LLM trust
- `gstack-setup-browser-cookies` — Import cookies from your real Chromium browser into the headless browse session.
- `gstack-setup-deploy` — Configure deployment settings for /land-and-deploy. Detects your deploy
- `gstack-ship` — Ship workflow: detect + merge base branch, run tests, review diff, bump VERSION,
- `gstack-unfreeze` — Clear the freeze boundary set by /freeze, allowing edits to all directories
- `gstack-upgrade` — Upgrade gstack to the latest version. Detects global vs vendored install,
- `gstack` — Fast headless browser for QA testing and site dogfooding. Navigate pages, interact with
- `guidelines-advisor` — Smart contract development advisor based on Trail of Bits' best practices. Analyzes codebase to generate documentation/specifications, revie
- `mediabunny` — Multimedia handling with the Mediabunny library
- `remotion-best-practices` — Best practices for Remotion
- `remotion-captions` — Dealing with captions in Remotion
- `remotion-create` — Creating a new Remotion video
- `remotion-docs` — Search and fetch Remotion documentation pages
- `remotion-interactivity` — Best practices for writing Remotion animations that stay intuitive for agents and editable in Remotion Studio Visual Mode.
- `remotion-markup` — Best practices for writing Remotion React Markup
- `remotion-render` — Best practices for rendering videos
- `remotion-saas` — Building video apps with Remotion - framework, rendering and Player advice
- `secure-workflow-guide` — Guides through Trail of Bits' 5-step secure development workflow. Runs Slither scans, checks special features (upgradeability/ERC conformanc
- `smart-contract-audit` — Comprehensive smart contract security audit framework with multi-expert analysis. Use for full audits of Ethereum / EVM Solidity and Vyper, 
- `tavisi-audit` — Tavisi-specific audit, implementation-review, maintainability-review, proof-validation, and test-planning workflow for collateralcore change
- `tavisi-dispatcher-codex` — Run the Tavisi fleet dispatcher from Codex. Codex is primary-eligible — it runs the FULL dispatcher pass when it holds the orchestrator chai
- `tavisi-fleet-ops` — Diagnose, explain, repair, and improve Tavisi fleet operations across schedulers, services, locks, queues, workers, reviews, model lanes, op
- `teach-session` — Become a wise, patient, ruthlessly effective teacher for a coding session so the human deeply understands the problem, solution, design deci
- `thermo-nuclear-code-quality-review` — Run Codex-native extremely strict maintainability audit for current branches, PRs, and local diffs. Use when asked for thermo-nuclear review
- `thermonuclear-code-quality-review` — Run a Codex-native extremely strict maintainability audit for current branches, PRs, or local diffs. Use when asked for thermonuclear code q
- `tiny-auditor` — Audit codebase to uncover critical issues explicitly and certainly leading to loss of funds without false positives
- `token-integration-analyzer` — Token integration and implementation analyzer based on Trail of Bits' token integration checklist. Analyzes token implementations for ERC20/

**`~/.grok/skills`**

- `animation-vocabulary` — Reverse-lookup glossary that turns a vague description of a web animation or motion effect into its exact term ("the bouncy thing when a pop
- `apple-design` — Apple's approach to interface design and fluid, physical motion, translated for the web. Use when building or reviewing gesture-driven UI, s
- `better-colors` — OKLCH color space for web projects. Convert hex/rgb/hsl to oklch, generate palettes, check contrast, handle gamut boundaries, and theme with
- `better-typography` — Web typography from choosing fonts to spacing, wrapping and accessibility. Use when picking or pairing typefaces, configuring variable fonts
- `better-ui` — Design engineering principles for making interfaces feel polished. Use when building UI components, reviewing frontend code, implementing an
- `brand-site` — Build production-quality brand websites from live URLs, Instagram/screenshots,
- `brandup-product-lead`
- `check-work` — Check your work with a verification subagent that reviews diffs, runs builds
- `code-judo-quality-review` — Run a native Codex extremely strict maintainability review for abstraction quality, giant files, spaghetti-condition growth, and dramatic st
- `code-review` — Run an extremely strict maintainability review for abstraction quality, giant files, and spaghetti-condition growth. Use for a deep code qua
- `create-skill` — Interactively create a new Grok skill (SKILL.md + optional scripts/references).
- `cursor` — Headlessly invoke Cursor Agent from Grok for a second opinion, plan, or
- `design-system-forge` — Forge a ratified, handoff-grade design system from real reference sites. Extract design language, cluster into token-backed archetypes, buil
- `emil-design-eng` — This skill encodes Emil Kowalski's philosophy on UI polish, component design, animation decisions, and the invisible details that make softw
- `ethskills` — Use when a request involves Ethereum, the EVM, or blockchain systems. Applies to building, auditing, deploying, or interacting with smart co
- `extract-design` — Extract the full design language from any website URL. Produces 8 output files including AI-optimized markdown, visual HTML preview, Tailwin
- `find-animation-opportunities` — Search a codebase or UI for places that don't animate but should, and reject everything that shouldn't. Read-only; it proposes motion with e
- `first-share` — Artifact-first stakeholder ship loop: name the one human URL, walk the journey,
- `foundry-poc` — Generates foundry PoC for smart contracts to scientifically from no special privileges to funds lost. Focused on proof of concept for EVM us
- `help` — Grok documentation and configuration help. Use when users ask about
- `hermes-runtime-research` — Run a Hermes ecosystem research loop against the Tavisi hermes-aleph runtime
- `imagine` — How to use the image_gen and image_edit tool calls in Grok Build: when to
- `improve-animations` — Survey a codebase's animation and motion code as a senior motion advisor, then produce a prioritized audit and self-contained implementation
- `pick-ui-library` — Pick the right library for a given frontend task from a curated, opinionated list — numbers, OTP inputs, charts, command menus, virtualizati
- `ponytail-audit` — Whole-repo audit for over-engineering. Like ponytail-review, but scans the
- `ponytail-debt` — Harvest every `ponytail:` comment in the codebase into a debt ledger, so the
- `ponytail-gain` — Show ponytail's measured impact as a compact scoreboard: less code, less
- `ponytail-help` — Quick-reference card for all ponytail modes, skills, and commands.
- `ponytail-review` — Code review focused exclusively on over-engineering. Finds what to delete:
- `ponytail` — Forces the laziest solution that actually works, simplest, shortest, most
- `review-animations` — Reviews animation and motion code against a high craft bar derived from Emil Kowalski's design engineering philosophy. Default to flagging; 
- `smart-contract-audit` — Comprehensive smart contract security audit framework with multi-expert analysis. Use for full audits of Ethereum / EVM Solidity and Vyper, 
- `spar` — SPAR — Grok×Cursor adversarial default. Scope·Punch·Award·Realize. Auto-use for
- `tavisi-audit` — Tavisi-specific audit, implementation-review, maintainability-review, proof-validation, and test-planning workflow for collateralcore change
- `tavisi-design` — Use this skill to generate well-branded interfaces and assets for Tavisi, either for production or throwaway prototypes/mocks/etc. Contains 
- `thermo-nuclear-code-quality-review` — Run Codex-native extremely strict maintainability audit for current branches, PRs, and local diffs. Use when asked for thermo-nuclear review
- `tiny-auditor` — Audit codebase to uncover critical issues explicitly and certainly leading to loss of funds without false positives

**`~/.cursor/skills`**

- `mediabunny` — Multimedia handling with the Mediabunny library
- `remotion-best-practices` — Best practices for Remotion
- `remotion-captions` — Dealing with captions in Remotion
- `remotion-create` — Creating a new Remotion video
- `remotion-docs` — Search and fetch Remotion documentation pages
- `remotion-interactivity` — Best practices for writing Remotion animations that stay intuitive for agents and editable in Remotion Studio Visual Mode.
- `remotion-markup` — Best practices for writing Remotion React Markup
- `remotion-render` — Best practices for rendering videos
- `remotion-saas` — Building video apps with Remotion - framework, rendering and Player advice

**`~/.agents/skills`**

- `diagram-design` — Create technical and product diagrams — architecture, IT current-state, flowchart, sequence, state machine, ER / data model, timeline, swiml
- `find-skills` — Helps users discover and install agent skills when they ask questions like "how do I do X", "find a skill for X", "is there a skill that can
- `mediabunny` — Multimedia handling with the Mediabunny library
- `remotion-best-practices` — Best practices for Remotion
- `remotion-captions` — Dealing with captions in Remotion
- `remotion-create` — Creating a new Remotion video
- `remotion-docs` — Search and fetch Remotion documentation pages
- `remotion-interactivity` — Best practices for writing Remotion animations that stay intuitive for agents and editable in Remotion Studio Visual Mode.
- `remotion-markup` — Best practices for writing Remotion React Markup
- `remotion-render` — Best practices for rendering videos
- `remotion-saas` — Building video apps with Remotion - framework, rendering and Player advice

<!-- SKILLS:END -->
