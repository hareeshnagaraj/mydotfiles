#!/usr/bin/env python3
"""Status line: the model, loud when it is Fable, and how much of the 5-hour and 7-day quota is gone.

It also records the live model per session for ~/.claude/hooks/fable-build-guard.py,
which is not told the model any other way.
"""
import json
import os
import sys
import tempfile

d = json.load(sys.stdin)
m = d.get("model") or {}
model_id = m.get("id") or ""
if model_id and d.get("session_id"):
    try:
        state = os.path.join(tempfile.gettempdir(), "fable-guard")
        os.makedirs(state, exist_ok=True)
        with open(os.path.join(state, f"model-{d['session_id']}"), "w") as f:
            f.write(model_id)
    except OSError:
        pass
model = m.get("display_name") or "?"
if "fable" in model.lower():
    model = f"\033[1;30;43m {model} \033[0m"  # black on yellow: Fable costs the most
limits = d.get("rate_limits") or {}
quota = [f"{label} {round(limits[key]['used_percentage'])}%" for key, label in (("five_hour", "5h"), ("seven_day", "7d"))
         if isinstance(limits.get(key), dict) and limits[key].get("used_percentage") is not None]
print("  ·  ".join([model, *quota]))
