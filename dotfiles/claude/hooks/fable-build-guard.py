#!/usr/bin/env python3
"""Ask once before building on Fable.

Fable plans, Opus builds (my split, 2026-10-09). Plan mode is read-only, so the first Edit, Write,
NotebookEdit or Bash call outside plan mode is the build starting. If the session is still on
Fable at that moment, Claude Code stops and asks, once per plan cycle: entering plan mode again
re-arms it. Any failure stays silent and lets the call through: a reminder must never block work.

Hooks are not told the model, and the transcript lags a turn behind, so the live model comes from
a state file per session: this script writes it on PostModelSwitch (the moment /model runs), and
~/.claude/statusline.py writes it on every status line refresh.

Test it with another model: FABLE_GUARD_MATCH=haiku.
"""
import json
import os
import sys
import tempfile

MATCH = os.environ.get("FABLE_GUARD_MATCH", "fable")
STATE = os.path.join(tempfile.gettempdir(), "fable-guard")


def state_path(event, kind):
    return os.path.join(STATE, f"{kind}-{event.get('session_id', 'none')}")


def main():
    event = json.load(sys.stdin)
    os.makedirs(STATE, exist_ok=True)
    if event.get("hook_event_name") == "PostModelSwitch":
        with open(state_path(event, "model"), "w") as f:
            f.write(str(event.get("to_model") or ""))
        return
    asked = state_path(event, "asked")
    if event.get("permission_mode") == "plan":
        if os.path.exists(asked):
            os.remove(asked)
        return
    try:
        model = open(state_path(event, "model")).read()
    except OSError:
        return
    if os.path.exists(asked) or MATCH not in model.lower():
        return
    open(asked, "w").close()
    reason = ("Still on Fable outside plan mode. Fable is for planning. "
              "Say no, run /model opus, then tell Claude to continue. Say yes to keep building on Fable.")
    print(json.dumps({
        "hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": reason},
        "systemMessage": "Building on Fable? /model opus to build on Opus.",
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
