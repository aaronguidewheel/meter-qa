#!/bin/sh
# meter-qa read-only guard (v2.0). PreToolUse hook.
# Blocks browser actions that could change a meter or a backend record: clicks, typing,
# form input, key presses, drags, uploads, and page scripts containing write patterns.
# Reads stay allowed. Exit 2 = block (reason on stderr). Exit 0 = allow.
# Needs python3. If python3 is missing the hook fails open, so check `python3 --version`.
# Tested only on the author's setup against sample inputs, not against every browser tool.
python3 -c '
import sys, json, re
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
name = str(d.get("tool_name", "")).lower()
inp = d.get("tool_input") or {}
def block(why):
    sys.stderr.write("meter-qa guard: blocked (" + why + "). This skill is read-only. Stop and report.\n")
    sys.exit(2)
# 1. Tool names that act on the page
for p in (r"form_input", r"(^|_)click", r"(^|_)type($|_)", r"(^|_)fill", r"press_key", r"(^|_)key($|_)",
          r"drag", r"upload", r"select_option", r"set_value"):
    if re.search(p, name):
        block("browser action tool: " + name)
# 2. Generic "computer" style tools: look at the action field
act = str(inp.get("action", "")).lower()
if act in ("left_click","right_click","double_click","triple_click","type","key","left_click_drag","click","fill","press"):
    block("browser click or typing")
# 3. Page scripts: scan every string in the input for write patterns
if any(k in name for k in ("javascript","evaluate","script","exec")):
    def strings(x):
        if isinstance(x, str): yield x
        elif isinstance(x, dict):
            for v in x.values(): yield from strings(v)
        elif isinstance(x, list):
            for v in x: yield from strings(v)
    t = "\n".join(strings(inp))
    bad = [r"\bsave\s*\(", r"\breset\s*\(", r"\.click\s*\(", r"\.submit\s*\(", r"\.value\s*=(?!=)", r"\.checked\s*=(?!=)",
           r"selectedIndex\s*=(?!=)", r"dispatchEvent", r"\.send\s*\(", r"XMLHttpRequest", r"\bfetch\s*\(",
           r"method\s*:\s*[\x27\"](POST|PUT|DELETE|PATCH)", r"Add Register", r"\.remove\s*\(", r"innerHTML\s*=(?!=)",
           r"document\.write", r"\.dispatch\s*\(", r"location\s*(\.href)?\s*=(?!=)"]
    for p in bad:
        if re.search(p, t, re.I):
            block("page script matches a write pattern")
sys.exit(0)
'
