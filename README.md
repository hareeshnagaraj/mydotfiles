# mydotfiles

My Mac setup: tmux, vim, zsh, and the AI-coding tools I use together. Part
reference-for-future-me, part a guide anyone can hand their local LLM to stand up the
same setup. No secrets live here — every credential is a `<<PLACEHOLDER>>` you supply
yourself.

## Layout

```
mydotfiles/
├── README.md            ← this guide (narrated, opt-in, LLM-friendly)
├── dotfiles/            ← the actual scrubbed configs (symlinked into ~ by install.sh)
│   ├── tmux.conf
│   ├── vimrc
│   ├── gitignore_global
│   ├── zshrc.snippets       (curated safe subset — you append what you want)
│   ├── gitconfig.template   (fill in your own name/email)
│   ├── config-tmux/git-status.sh
│   └── ghostty/             (terminal config + ayu-dark theme)
├── scripts/
│   ├── install.sh       ← symlink dotfiles into ~ (backs up existing)
│   ├── sync.sh          ← pull my current configs back in, scrubbed (the periodic update)
│   ├── scrub.sh         ← secret redactor + hard scanner (the safety spine)
│   └── pre-commit       ← blocks any commit that would leak a secret
├── launchd/             ← optional weekly auto-sync agent (never pushes)
└── Makefile             ← make install | sync | scan | hook | sync-install
```

## Use it

```bash
make install       # link dotfiles into ~ (safe; backs up what it replaces)
make hook          # install the pre-commit secret scanner (do this once)
make sync          # pull this box's current configs back into the repo, scrubbed + scanned
make sync-install  # optional: weekly launchd agent that runs sync (stages only, never pushes)
```

`sync.sh` is how mydotfiles stays current: it re-copies my live dotfiles through the secret
redactor, regenerates the "skills on this box" appendix, hard-scans for leaks, and stages
the diff — commit + push stay manual, always.

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
brew install glow pandoc poppler ffmpeg yt-dlp shellcheck jq

# Networking / infra (skip unless you use them)
brew install cloudflared tailscale flyctl hcloud

# Casks (GUI)
brew install --cask ghostty orbstack swiftbar
```

- `fzf` powers the tmux copy-popup below — **install it if you take the tmux section.**
- `zsh-autosuggestions` + `zsh-syntax-highlighting` make the shell feel alive (grey
  inline completions + colored validity). Wire-up is in the zsh section.

---

## Ghostty — the terminal itself

**What & why:** Ghostty is a GPU-fast terminal whose entire configuration is one plain
text file — no settings maze. Mine is two lines: the Nerd Font everything below assumes,
and an Ayu Dark theme (a custom port; the palette matches how I like tmux/vim to sit).

The whole config — `~/.config/ghostty/config` (on macOS Ghostty also reads
`~/Library/Application Support/com.mitchellh.ghostty/config`; either works):

```
theme = ayu-dark
font-family = CaskaydiaCove Nerd Font Mono
```

The theme is a file dropped at `~/.config/ghostty/themes/ayu-dark` — Ghostty picks up
any file in that dir by name, so `theme = ayu-dark` just works:

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

## zsh — shell config

**What & why:** agnoster prompt with live git branch, a few aliases, PATH for the tool
stack, and two non-obvious tricks (a tmux-safe mouse flag for AI TUIs, and a helper to
run Codex against a Venice-hosted model). Append to `~/.zshrc`.

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

# --- tmux cheat sheet (prefix = Ctrl-a, see ~/.tmux.conf) ---
# Sessions:   tmux new -s name | tmux ls | tmux attach -t name | prefix d (detach)
# Windows:    prefix c (new) | prefix n/p (next/prev) | prefix 0-9 (jump) | prefix , (rename) | prefix w (list)
# Panes:      prefix | / - (split) | prefix h j k l (move) | prefix H J K L (resize) | prefix z (zoom) | prefix x (kill)
# Copy mode:  prefix [ (enter) | v (select) | y (yank to macOS clipboard) | q (quit)
# Block copy: prefix C-p (fzf popup of clean scrollback)
# Misc:       prefix r (reload config) | prefix ? (list all keybinds)

# --- THE non-obvious one ---
# Claude Code (and similar agent TUIs) use the terminal's alternate-screen buffer and
# fight tmux for mouse-scroll, corrupting the display. Hand scroll fully to tmux when
# inside a tmux session. (Outside tmux, full mouse support is preserved.)
[ -n "$TMUX" ] && export CLAUDE_CODE_DISABLE_MOUSE=1
```

**Optional — run Codex against a Venice-hosted model** (I use this to drive `claude-fable-5`
through the Codex CLI). Needs your own OpenRouter/Venice key in the macOS Keychain:

```bash
# store your key once:
#   security add-generic-password -a "$USER" -s my-openrouter-key -w '<<YOUR_OPENROUTER_KEY>>'
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

> **Secrets note:** the original `.zshrc` also exported a couple of service tokens
> (`HCLOUD_TOKEN`, a gbrain bearer). Those are deliberately omitted. If you use Hetzner
> or gbrain, add your own — ideally via Keychain like `venicefable` above, not inline.

---

## tmux — the big one

**What & why:** `Ctrl-a` prefix, vim pane navigation, a self-hiding git pill in the
status bar, Catppuccin Mocha theme, session persistence, and an fzf popup that copies
clean multi-line text without pane-width line breaks. This is the most-tuned config here.

**Install TPM (plugin manager) first, then drop the config:**

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Write `~/.tmux.conf`:

```tmux
# ===== General =====
set -g mouse on
set -g history-limit 20000
set -g renumber-windows on
set -sg escape-time 10
set -g focus-events on
# Agents thrash pane titles (spinners); keep names stable + block OSC title updates.
set -g automatic-rename off
set -g allow-rename off
set -g allow-set-title off
set -g set-titles off

set -g default-terminal "tmux-256color"
set -as terminal-overrides ",xterm-256color:RGB,tmux-256color:RGB"

# Windows/panes start at 1
set -g base-index 1
setw -g pane-base-index 1

# ===== Prefix: Ctrl-a =====
unbind C-b
set -g prefix C-a
bind C-a send-prefix

bind r source-file ~/.tmux.conf \; display-message "tmux config reloaded"

# ===== Splits open in the current pane's dir =====
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"

# ===== Vi mode + vim pane nav/resize =====
setw -g mode-keys vi
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# vi-style copy → macOS clipboard
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi V send -X select-line
bind -T copy-mode-vi y send -X copy-pipe-and-cancel "pbcopy"
bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "pbcopy"

# ===== Plugins (TPM) =====
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'catppuccin/tmux#v2.3.0'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'laktak/extrakto'

set -g @resurrect-capture-pane-contents 'off'
set -g @continuum-restore 'on'
set -g @continuum-save-interval '30'

# ===== Catppuccin =====
set -g @catppuccin_flavor "mocha"
set -g @catppuccin_window_status_style "rounded"
set -g @catppuccin_window_default_text " #{=/18/…:#{b:pane_current_path}}"
set -g @catppuccin_window_current_text " #{=/18/…:#{b:pane_current_path}}"
run '~/.tmux/plugins/tmux/catppuccin.tmux'

# ===== Status bar =====
set -g status-position bottom
set -g status-interval 15
set -g status-right-length 150
set -g status-left-length 60
set -g status-left "#{E:@catppuccin_status_session} "
# git = custom dependency-free segment; dir = blue pill; clock = surface pill
set -g status-right "#(~/.config/tmux/git-status.sh '#{pane_current_path}') "
set -ga status-right "#[fg=#89b4fa,bg=default]#[fg=#11111b,bg=#89b4fa]  #{s|#{HOME}|~|:pane_current_path} #[fg=#89b4fa,bg=default] "
set -ga status-right "#[fg=#585b70,bg=default]#[fg=#cdd6f4,bg=#585b70]  %H:%M #[fg=#585b70,bg=default]"

# ===== Per-pane labels — only when a window is split =====
set -g pane-border-format " #{?pane_active,#[fg=#94e2d5#,bold],#[fg=#6c7086]}#P #{pane_current_command}#[default] #[fg=#585b70]#{b:pane_current_path} "
set -g pane-border-style "fg=#313244"
set -g pane-active-border-style "fg=#94e2d5"
set -g pane-border-status off
set-hook -g window-layout-changed 'if -F "#{==:#{window_panes},1}" "set -w pane-border-status off" "set -w pane-border-status top"'

set -g @extrakto_grab_area "window recent"

# Block copy: prefix + C-p → fzf popup of joined scrollback, Enter copies clean to clipboard.
bind C-p display-popup -E -w 90% -h 90% "tmux capture-pane -pJ -S -5000 | fzf --multi --no-sort --tac --bind 'ctrl-a:select-all' | pbcopy"

run '~/.tmux/plugins/tpm/tpm'

# Post-plugin overrides (tmux-sensible resets some of these otherwise).
set -g status-interval 15
set -g history-limit 20000
set -g automatic-rename off
set -g allow-rename off
set -g allow-set-title off

# Keep copy-mode readable and stop wheel-up from scrolling TUI apps.
set -g mode-style "fg=#11111b,bg=#f9e2af,bold"
bind -T root WheelUpPane select-pane -t= \; copy-mode -e -t=
bind -T copy-mode-vi WheelUpPane select-pane -t= \; send-keys -X -t= -N 5 scroll-up
bind -T copy-mode-vi WheelDownPane select-pane -t= \; send-keys -X -t= -N 5 scroll-down
bind -T copy-mode WheelUpPane select-pane -t= \; send-keys -X -t= -N 5 scroll-up
bind -T copy-mode WheelDownPane select-pane -t= \; send-keys -X -t= -N 5 scroll-down
```

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

**What & why:** I don't use one AI tool, I use several, each in a lane, and they
cross-check each other. This section explains the wiring so you can reproduce the *flow*,
not just install binaries.

### The tools & their lanes

| Tool | Install | Lane I use it in |
|------|---------|------------------|
| **Claude Code** | `curl -fsSL https://claude.ai/install.sh \| bash` (or npm) | Primary driver: specs, reviews, orchestration, final judgment |
| **Codex CLI** (OpenAI) | `brew install codex` | Implementation muscle — hand it a well-specified slice, it writes the code |
| **Grok CLI** | grok installer (`~/.grok/bin` on PATH) | Adversary — attacks plans, steelmans the opposite (never agrees by default) |
| **Cursor** (`cursor-agent`) | download from cursor.com | IDE-side edits + a third reviewer voice |
| **Kimi** (`kimi`) | kimi-code installer | Occasional alt model |
| **gbrain** | `bun install -g gbrain` (or the setup skill) | Persistent memory across every tool + session |

### The core idea: lanes + cross-review

The pattern that makes this work (learned the hard way running a two-agent flow):

- **Claude specifies and reviews. Codex implements.** Don't make Claude hand-resolve a
  trivial thing Codex is slow at, and don't make Codex reason about architecture Claude
  already mapped. Right tool, right lane.
- **Grok is the designated skeptic.** Before committing to a plan, send it to Grok framed
  as *"attack this, steelman the opposite, sharpest case against."* A genuine second mind
  poking holes beats one model agreeing with itself.
- **Everything writes to gbrain** so the next session (any tool) has the context.
- **Observability rule:** when you dispatch one agent from another headlessly, stream its
  output to a logfile you can `tail -f` — never pipe through `tail` (buffers till exit),
  and never fire-and-forget without a liveness timeout.

### How they actually talk to each other

Two concrete wiring examples from my setup:

1. **`venicefable` (in the zsh section)** — Claude's Fable model, served by Venice,
   driven through the *Codex* CLI. One shell function bridges provider + model + CLI.

2. **The `/spar` skill (Claude Code → Grok)** — a Claude Code skill that packages the
   current plan and launches a Grok subagent as an adversary, then relays Grok's verdict
   verbatim before Claude reconciles it. This is the "cross-review" pattern as a one-liner.
   The skill body:

   > SPAR / adversarial challenge. Do NOT agree by default. Attack the conclusion below
   > and steelman the opposite. Give the sharpest case AGAINST it.
   > CONTEXT: `<background so Grok can reason without the session>`
   > CONCLUSION TO ATTACK: `<the plan, stated plainly>`
   > CHALLENGE: Where is this wrong? What does it assume? Name failure modes the author
   > is discounting. Sharpest case against, under 400 words.

   You can reproduce the *idea* in any tool: a saved prompt that sends your current
   conclusion to a *different* model with an adversarial frame.

### The skill library — the actual muscle

A **skill** is just a markdown file with a trigger phrase + a procedure. Any agent
(Claude Code, Codex) reads it and follows it. Most of my leverage is here. Two sources:

- **gstack** — an open skill suite (`/ship`, `/land-and-deploy`, `/review`,
  `/investigate`, `/qa`, `/design-review`, `/spar`, `/careful`, `/freeze`, …). Installs
  into both `~/.claude/skills/` and `~/.codex/skills/`; `/gstack-upgrade` keeps it current.
- **My gbrain-published pack** — the 23 curated skills below, served from the brain so
  every tool/machine shares them. These are the ones I actually reach for.

**The 23 I keep published (name → what it does → when it fires):**

*Orchestration & delegation*
| Skill | Does | Fires on |
|-------|------|----------|
| `arbitrage` | Before writing any code, decides *which tool/lane* each piece of work runs in | auto, at planning time |
| `codex-implement` | Hands a well-specified slice to Codex as a write-access subagent, verifies, opens a PR | "have codex implement/fix this" |
| `grok-delegate-runtime` | Internal contract for calling the Grok bridge from Claude Code | (helper, used by `/spar`) |
| `grok-run-output` | How to present Grok bridge output back verbatim | (helper) |
| `factory` | One prompt → full vertical slice: 10 scoped agents, 3 human checkpoints, self-loops on failure | "factory", "ship feature end-to-end" |
| `goal-prep` | Structured `/goal` intake for broad/stalled/vague work — Scout/Judge/Worker roles, rolling board | long-running or stuck work |
| `conserve-claude` | Claude stays orchestrator/reviewer; heavy authoring + grunt work route to codex/grok subagents | "conserve claude", "don't burn Claude on this" |

*Review & quality*
| Skill | Does | Fires on |
|-------|------|----------|
| `thermo-nuclear-code-quality-review` | Extremely strict maintainability audit — abstraction quality, giant files, spaghetti conditionals | "thermonuclear review", harsh audit |
| `tavisi-audit` | Domain-specific audit/proof-validation (Tavisi-only, but a template for invariant-driven review) | changes touching custody/proof invariants |
| `explain-diff-html` | Rich HTML explanation of a diff/branch/PR | "explain this change" |
| `deploy-preflight` | Proves a web app builds from a *clean clone* and every env var/secret it references exists on the deploy target | before calling a frontend "done", "will this build on Vercel?" |

*Thinking & teaching*
| Skill | Does | Fires on |
|-------|------|----------|
| `council` | Convene multi-persona deliberation (historical thinkers) for hard problems | complex decisions |
| `grilling` | Relentlessly stress-tests your plan/idea | "grill this", "poke holes" |
| `teach-session` | Turns a session/system into a top-down guided lesson with quizzes until you've mastered it | "teach me what we did", "help me understand X" |

*Design & frontend*
| Skill | Does | Fires on |
|-------|------|----------|
| `design-system-forge` | Forge a ratified, handoff-grade design system from real reference sites; anti-AI-slop pass | "design system", "design handoff" |
| `extract-design` | Pull full design language from any URL → 8 files (tokens, Tailwind, shadcn, Figma vars, WCAG score) | "extract design", "design tokens" |
| `frontend-design` | Guidance for distinctive, non-templated visual design | building new UI |
| `frontend-slides` | Animation-rich HTML presentations, or convert a PPT | "build a deck/slides" |
| `prototype` | Throwaway prototype to answer a design/state question | "sanity-check this UI/logic" |
| `grilling-frontend-prototyping` | Converge a look through rounds of live prototypes + verdicts | UI taste iteration |
| `taste-loop-sprint` | One-day design sprint: plan → outside-voice review → orthogonal live variants → verdicts → deck → deploy | "taste loop", "design sprint" |

*Memory & fleet ops*
| Skill | Does | Fires on |
|-------|------|----------|
| `gbrain-recall` | The gbrain operating manual — page/slug/wiki-link conventions, lock recovery, which query tool for which temporal question | gbrain errors, writing new pages, cross-session recall |
| `fleet-drive` | Resumes the attended driver seat for the autonomous fleet: newest checkpoint → live-state verify → bounded monitor loop | "fleet drive" (Tavisi-only, but a template for babysitting any agent fleet) |

**How to replicate the pack on a fresh machine:**

1. Install gstack (covers most of the above + the `/ship`/`/review`/`/spar` workflow skills).
2. For the gbrain-published pack: stand up your own brain (`setup-gbrain`), then publish
   skills from it — any tool with the gbrain MCP registered can then `list_skills` /
   `get_skill` and follow them, machine-independent.

**The transferable principle even with zero of my tooling:** name your repeatable
workflows as skills (trigger + procedure markdown), and keep a `tasks/lessons.md` per
project that every agent reads at session start and appends to after any correction.

### Claude Code settings worth copying

Two harness settings I run (in `~/.claude/settings.json`):

- **Agent teams / parallel subagents on** — `"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"`
  so one session can fan out independent work across subagents.
- **A tight Bash allowlist** so read-only git/gh/ls/cat commands don't prompt every time.
  (Your friend can generate their own from their transcripts rather than copy mine.)

> **gbrain memory:** I run a *remote* gbrain (a hosted brain all my tools query over MCP).
> For a fresh machine, the `setup-gbrain` skill spins up a **local** brain instead — start
> there. Register it as an MCP server in each tool's config; then every session shares
> memory. Don't copy my remote endpoint or bearer token — stand up your own.

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

---

## Secrets you must supply yourself (never in this file)

| What | Where it goes | How |
|------|---------------|-----|
| OpenRouter / Venice key | Keychain item `my-openrouter-key` | `security add-generic-password -a "$USER" -s my-openrouter-key -w '<<KEY>>'` |
| GitHub auth | `gh` credential store | `gh auth login` |
| gbrain (if used) | each tool's MCP config | stand up your own local brain via `setup-gbrain` |
| Any cloud tokens (Hetzner/Fly/etc.) | Keychain or your own env, **not** dotfiles | per-provider |

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
- `factory` — |
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
- `taste-loop-sprint` — One-day taste sprint that converges a surface's design through live prototypes and cross-model review, ending with a public shareable deck. 
- `tavisi-audit` — Tavisi audit, implementation-review, maintainability-review, proof-validation, and test-planning workflow for collateralcore changes. Use wh
- `tavisi-fleet-ops` — Diagnose, explain, repair, and improve Tavisi fleet operations across schedulers, services, locks, queues, workers, reviews, model lanes, op
- `teach-session` — |
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
- `gstack-autoplan` — |
- `gstack-benchmark` — |
- `gstack-browse` — |
- `gstack-canary` — |
- `gstack-careful` — |
- `gstack-checkpoint` — |
- `gstack-connect-chrome` — |
- `gstack-cso` — |
- `gstack-design-consultation` — |
- `gstack-design-html` — |
- `gstack-design-review` — |
- `gstack-design-shotgun` — |
- `gstack-document-release` — |
- `gstack-freeze` — |
- `gstack-guard` — |
- `gstack-health` — |
- `gstack-investigate` — |
- `gstack-land-and-deploy` — |
- `gstack-learn` — |
- `gstack-office-hours` — |
- `gstack-plan-ceo-review` — |
- `gstack-plan-design-review` — |
- `gstack-plan-eng-review` — |
- `gstack-qa-only` — |
- `gstack-qa` — |
- `gstack-retro` — |
- `gstack-review` — |
- `gstack-setup-browser-cookies` — |
- `gstack-setup-deploy` — |
- `gstack-ship` — |
- `gstack-unfreeze` — |
- `gstack-upgrade` — |
- `gstack` — |
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

<!-- SKILLS:END -->
