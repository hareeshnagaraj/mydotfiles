# tmux cheat sheet

Every binding that actually works in this setup, generated against a live tmux
server (`tmux list-keys`) so nothing is guessed. Config lives in
`/Users/hareeshnagaraj/Development/mydotfiles/dotfiles/tmux.conf`.

**★ = custom to this config.** Everything unmarked is a tmux default or comes
from a plugin, so it'll work on a stock install too.

---

## The one thing to set up first

The prefix is **`Ctrl-a`** (★ — tmux ships with `Ctrl-b`).

On this Mac, **Caps Lock is remapped to Control** in System Settings → Keyboard →
Modifier Keys. So every "prefix" below is physically **Caps+A**, which is why the
whole thing is comfortable to use all day. Without that remap you're doing
pinky gymnastics on `Ctrl-a` and you'll hate it.

> **How to read this:** `prefix c` means *press Caps+A, let go, then press `c`*.
> It's two separate presses, not a chord. `prefix Ctrl-p` means Caps+A, let go,
> then `Ctrl-p`.

To send a literal `Ctrl-a` through to the program inside the pane (e.g. bash
"jump to start of line"): **`prefix Ctrl-a`**.

---

## Panes

| Keys | Does |
|---|---|
| `prefix \|` | ★ Split **left/right**, new pane opens in the same directory |
| `prefix -` | ★ Split **top/bottom**, same directory |
| `prefix %` / `prefix "` | Same two splits, tmux's default keys (also ★ patched to keep the cwd) |
| `prefix ←↑↓→` | Move between panes |
| `prefix h` `j` `k` `l` | ★ Same thing, vim-style |
| *click a pane* | Move there (mouse is on) |
| `prefix o` | Cycle to the next pane |
| `prefix ;` | Jump to the **last** pane (toggle back and forth) |
| `prefix q` | Flash big pane numbers; press one to jump there |
| `prefix z` | ★ **Zoom** the pane full-screen (press again to unzoom) |
| `prefix H` `J` `K` `L` | ★ Resize by 5 columns — hold the key to repeat |
| `prefix Ctrl-←↑↓→` | Resize by 1 — repeatable |
| `prefix Alt-←↑↓→` | Resize by 5 — repeatable |
| `prefix {` / `prefix }` | Swap this pane with the previous / next one |
| `prefix !` | Break the pane out into its own window |
| `prefix x` | Kill the pane (asks y/n first) |
| `prefix T` | ★ **Name** the active pane — shows in yellow on the pane border |
| `prefix >` | Pane menu (split, swap, kill, zoom, copy the word under the mouse) |

**Why `prefix z` is patched:** stock tmux leaves you in copy-mode when you zoom,
so a TUI redraws at the *old* pane width and you get a wall of hard-wrapped
garbage. This config cancels copy-mode first, then zooms.

---

## Layouts

| Keys | Does |
|---|---|
| `prefix Z` | ★ **Tiled** layout — the 2×2 grid. Make 4 panes, hit this |
| `prefix Space` | Cycle through the built-in layouts |
| `prefix Alt-1` … `Alt-5` | even-horizontal, even-vertical, main-horizontal, main-vertical, tiled |
| `prefix E` | Spread panes out evenly |

The daily driver: one window, four panes (Claude / Grok / Codex / shell),
`prefix Z` to tile them, `prefix z` to zoom whichever one you're driving.

---

## Windows (tabs)

| Keys | Does |
|---|---|
| `prefix c` | ★ New window, opens in the current directory |
| `prefix n` / `prefix p` | Next / previous window |
| `prefix 1` … `prefix 9` | Jump straight to that window |
| `prefix a` | Last window (toggle) |
| `prefix ,` | Rename the window |
| `prefix w` | Visual window picker |
| `prefix f` | Search windows by name |
| `prefix &` | Kill the window (asks first) |
| `prefix .` | Renumber/move this window to another index |

Windows start at **1**, not 0 (★), and renumber themselves when you close one (★).

---

## Sessions

| Keys | Does |
|---|---|
| `prefix d` | **Detach** — leaves everything running in the background |
| `prefix s` | Session picker tree |
| `prefix $` | Rename the session |
| `prefix (` / `prefix )` | Previous / next session |
| `prefix D` | Choose which client to detach |

From a plain shell:

```bash
tmux                    # start
tmux new -s work        # start a named session
tmux ls                 # list sessions
tmux attach             # reattach to the last one
tmux attach -t work     # reattach by name
tmux kill-session -t work
```

---

## Copy & paste — the good part

Four different tools, each for a different job.

### 1. Mouse drag → clipboard (easiest)
Just **select text with the mouse**. On release it's on the macOS clipboard (★).
No keys at all.

### 2. Copy mode, vim-style
| Keys | Does |
|---|---|
| `prefix [` | Enter copy mode (also: just scroll up with the wheel) |
| `v` | ★ Start selecting |
| `V` | ★ Select the whole line |
| `y` | ★ Yank to the **macOS clipboard** and exit |
| `/` then text | Search **forward** |
| `?` then text | Search **backward** |
| `n` / `N` | Next / previous match |
| `g` / `G` | Top / bottom of scrollback |
| `q` or `Esc` | Leave copy mode |
| `prefix ]` | Paste the tmux buffer |

### 3. `prefix Ctrl-p` — multi-line copy that isn't broken ★
The one worth telling people about. Opens a **fzf popup of the last 5000 lines,
already unwrapped** (`capture-pane -pJ`), so copying a long path or a stack
trace doesn't come out chopped at the pane width.

- Type to filter · `Tab` to mark lines · `Ctrl-a` marks **everything** · `Enter` copies clean.

### 4. `prefix Tab` — extrakto
Fuzzy-grab just the **tokens** on screen: paths, URLs, git SHAs, IPs. Faster than
selecting by hand when you want one word out of a wall of output.

### Also
| Keys | Does |
|---|---|
| `prefix y` | Copy the current **command line** to the clipboard (tmux-yank) |
| `prefix Y` | Copy the pane's **working directory** |
| `prefix =` | Browse every copy buffer |
| `prefix #` | List buffers |

---

## Scrolling

**Just use the mouse wheel.** Scrolling up drops the pane into copy mode
automatically and moves 5 lines per notch (★).

The subtlety: agent TUIs (Claude Code, etc.) take over the alternate screen and
fight tmux for the wheel, which corrupts the display. This config hands scroll
**entirely** to tmux, and the shell sets `CLAUDE_CODE_DISABLE_MOUSE=1` inside
tmux to stop the tug-of-war. Trade-off: TUI frames don't reflow while you scroll
back — you're reading tmux's buffer, not the app's.

`prefix PageUp` also enters copy mode scrolled up one page.

---

## The custom extras ★

| Keys | Does |
|---|---|
| `prefix e` | **Broadcast typing to every pane** in the window. Toggle. Status bar shows a yellow `SYNC` |
| `prefix S` | **Screenshot picker** popup — fzf your screenshots, `Enter` copies the real paths to the clipboard (runs `snapview`) |
| `prefix T` | Name the active pane |
| `prefix Z` | Force the tiled 2×2 grid |
| `prefix r` | Reload the config |

`prefix e` from **outside** tmux (a script or an agent harness):

```bash
tmux-sync on | off | toggle
```

---

## Plugins

| Keys | Does |
|---|---|
| `prefix I` | **Install** plugins listed in the config |
| `prefix U` | Update plugins |
| `prefix Alt-u` | Remove plugins no longer in the config |
| `prefix Ctrl-s` | Save the session by hand (resurrect) |
| `prefix Ctrl-r` | **Restore** a saved session (resurrect) |

Installed: `tpm` · `catppuccin` (mocha theme) · `tmux-sensible` · `tmux-yank` ·
`tmux-resurrect` · `tmux-continuum` · `extrakto`.

**Sessions survive a reboot.** continuum auto-saves every 30 min and restores on
start, so panes and layouts come back. It does *not* save scrollback contents
(deliberately off — too expensive with agent panes flooding output).

First-time setup on a new box:
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# start tmux, then: prefix + I
```

---

## Reading the status bar

**Left:** session name · a yellow **`Z`** while a pane is zoomed · a yellow
**`SYNC`** while broadcast typing is on.

**Right:** git status pill · current directory · clock.

The git pill is a dependency-free script
(`/Users/hareeshnagaraj/Development/mydotfiles/dotfiles/config-tmux/git-status.sh`),
cached 15s, and it hides itself outside a repo:

- `✔` clean · `●` dirty · `⇡` ahead · `⇣` behind · `⇕` diverged

**Pane borders** only appear when a window is actually split. Active pane is
teal and bold, the rest are dimmed. A pane named with `prefix T` shows that name
in yellow.

---

## Getting unstuck

| Keys | Does |
|---|---|
| `prefix ?` | **List every binding** — the real source of truth |
| `prefix /` then a key | "What does this key do?" |
| `prefix :` | tmux command prompt |
| `prefix ~` | Show recent tmux messages (what did that error say?) |
| `prefix t` | Big clock, for some reason |
| `prefix C` | Interactive options browser |

Things that look broken but aren't:

- **Boxes/tofu instead of icons** → you need a Nerd Font. Install
  `font-caskaydia-cove-nerd-font` and set it as the terminal font.
- **`prefix` does nothing** → Caps Lock isn't remapped to Control yet, or another
  app is eating `Ctrl-a`.
- **Colors look washed out** → the terminal isn't advertising truecolor.
- **Scrollback won't reflow in an agent pane** → expected, see *Scrolling* above.
