# meter-qa (v2.0): read-only meter quality check

**What it does**
- Walks a list of installed eGauge meters and checks each one's clock, registers, sensors (CTid), General Settings and API URL.
- Compares them with the Guidewheel meter guides and with the matching Panopticon record.
- Reports one line per meter, OK or needs attention, with an evidence file. It only reads: it never edits, saves or resets anything.

**See how it works:** open `how-it-works.html` in a browser. It is one self-contained page. Every box expands to show what the agent does and what each term means.

**Install (about 5 minutes)**
1. Copy the `meter-qa` folder to `~/.claude/skills/meter-qa/` (personal) or `.claude/skills/meter-qa/` in a project.
2. Make the guard executable: `chmod +x ~/.claude/skills/meter-qa/guard.sh`. It needs `python3`.
3. Check the `matcher` line at the top of `SKILL.md`. It must match the names of your browser tools (for example `mcp__BrowserOS...` or `mcp__claude-in-chrome__...`). If the hook path does not suit your install, change the `command` line.
4. Optional: connect Confluence so the agent reads the current Solutions Consulting guides. Without it, the agent uses a built-in copy of the standards (taken 2026-11-23).
5. Start a new Claude Code session and type `/meter-qa`.

**What you need**
- A browser Claude can drive (BrowserOS, Claude in Chrome, or the Claude app's pane) and a work profile you control.
- Your own sign-in to each meter and to Panopticon. The skill never types, reads or stores a password. You sign in by hand.
- A list of meters: number, line, Panopticon name, box type (CT or pulse). A starting sheet or note is fine.
- Optional: one reference meter you trust, for a practice run first.

**Use at your own risk.** This skill is provided as is, without warranty. It shows this notice at the start of every session.

**Honest caveats**
- Built and used on one person's setup. Not tested on yours, and not tested by anyone else yet.
- It was not tested against live meters in the v2.0 build session. The v2.0 changes (the guides-based standards, the extra QA rules, the parameterized registers script and the new guard) are untested on a real meter.
- The guard hook was tested only with sample inputs. Browser tool names differ, so confirm the matcher, then watch the first run.
- Some things are not written in any guide yet (register sets for any meter type other than one CT sensor or two pulse sensors: the agent asks the user and uses the confirmed answers for that run only). The skill says "observed, no standard" instead of guessing.
- The built-in standards are a copy. If a live guide differs, the live guide wins and the difference goes in the report.

**Support:** aaron@guidewheel.com
