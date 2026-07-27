# githooks — no AI attribution

Global git hooks that flag AI authorship-attribution trailers
(`Co-Authored-By: <bot>`, `🤖 Generated with …`) before they reach history.

## Why this exists

A rule stating "never attribute authored work to an AI tool" lived only as prose
in an agent instruction file for months. An audit of the actual git history found
**194 attributed commits out of 2,933** across three repositories — dozens of them
landing *after* an explicit directive to stop, spanning five model generations.

In the one place a deterministic `commit-msg` hook already ran, the rule held
perfectly. Everywhere else it did not. Prose does not enforce an invariant; it
competes with whatever the agent's own tooling tells it to do, and loses often
enough to matter.

So: enforce it mechanically, and let the prose explain *why* rather than carry
the weight.

## Install

```sh
make githooks
```

Copies these into `~/.config/git/hooks` and sets
`git config --global core.hooksPath`. Undo with:

```sh
git config --global --unset core.hooksPath
```

## Modes

`~/.config/git/hooks/mode`, or `$AI_ATTRIBUTION_MODE` which wins.

| mode | behavior |
|---|---|
| `warn` *(default)* | prints to stderr, **allows** the commit |
| `block` | prints and **rejects** the commit |
| `off` | does nothing |

One-time override: `GIT_ALLOW_AI_ATTRIBUTION=1 git commit …`

## Design

**Matches bot identities, not model names.** Every observed bot trailer carries a
machine email domain; every observed human co-author carries an ordinary one.
Keying on the domain separates them exactly, so all of these stay legitimate:

- `feat: add Claude SDK integration`
- `Fixtures generated with Claude SDK mock server, not live API.`
- `Co-Authored-By: Claude Fontaine <claude.fontaine@acme.com>` — a person

A bare token match on `claude` would reject all three. Validated against the full
2,933-commit corpus: **194 flagged, 0 false positives.**

**Never rewrites a message.** A silent edit is a history-integrity failure — the
author never sees it. Reject-with-a-message is recoverable; a silent mutation is
not.

**Chains to repo-local hooks.** `core.hooksPath` *replaces* `.git/hooks` rather
than chaining, so enabling it naively would silently disable every repo-local
hook on the machine. Every hook here delegates through `_delegate.sh` first:

- a repo hook that rejects still rejects, and its exit code propagates
- a repo hook that strips trailers runs first, leaving nothing to report
- a repo hook present but **not executable** is run via `sh` **with a notice**,
  rather than skipped silently the way stock git would

**Not covered:** submodules, GUI clients, `git commit --no-verify`, and
`git -c core.hooksPath=/dev/null commit` — the last one bypasses hooks *without*
`--no-verify`, so blocking that one flag is not a gate. Anything that must not
escape belongs in a server-side CI check, which no local setting can bypass. A
matching GitHub Actions workflow lives alongside this in each repo.

## Drift check

```sh
~/.config/git/hooks/lib/ai-attribution-sweep.sh          # exit 1 if the count grew
~/.config/git/hooks/lib/ai-attribution-sweep.sh --update-baseline
```

Reads repo paths from `~/.config/git/hooks/sweep-repos`, one per line — untracked,
so private repo names stay off a public dotfiles repo. Schedule it with
`make githooks-sweep-install`; a one-shot check at install time cannot see a
regression that only appears as a slowly rising count over weeks.

## Files

| file | role |
|---|---|
| `lib/ai-attribution.sh` | canonical pattern + scanner, also runnable standalone |
| `lib/ai-attribution-sweep.sh` | recurring drift check |
| `commit-msg` | delegates, then scans |
| `_delegate.sh` | repo-local hook pass-through |
| *(other hook names)* | pass-through only, so nothing is silently disabled |
