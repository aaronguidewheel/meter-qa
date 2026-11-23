---
name: meter-qa
description: Read-only quality check of eGauge meters and their Panopticon records. For a list of meters it reads each meter's clock, registers, sensors (CTid) and General Settings (Data Sharing, API URL), then the matching Panopticon meter, compares them with the Guidewheel meter guides, and reports one line per meter (OK or needs attention) with its URL. Never edits, saves or resets anything. Use when the user says "QA the meters", "run the quality check on <site>", "check the registers for <site>", "meter QA", or invokes /meter-qa.
disable-model-invocation: true
hooks:
  PreToolUse:
    - matcher: "mcp__.*([Bb]rowser|[Cc]hrome|[Pp]laywright).*"
      hooks:
        - type: command
          command: "~/.claude/skills/meter-qa/guard.sh"
---

# Meter QA (eGauge and Panopticon, read-only, v2.0)

Support: aaron@guidewheel.com. Version 2.0, 2026-11-23. Questions, bugs and ideas go to that address.

A quality pass over meters that are already installed. It walks a list of meters, opens each one's eGauge settings and its Panopticon record, compares them with the written Guidewheel standards, and reports. It checks. It never builds or fixes anything.

A picture of the whole flow, with a definition for every term, is in `how-it-works.html` (same folder). Open it in a browser. Every box expands.

**Use at your own risk.** The skill is provided as is, without warranty.

**Honest status:** built and used on one person's setup. Not tested on yours. If you have a reference meter, calibrate first (step 5) and watch the first run.

## Start-of-session header (always show this first, before any question)

Print this block exactly, then go to step 1 of the flow:

> **⚠️ Meter QA v2.0. Use at your own risk.**
> **What I do in this session:** I read each meter's settings and its Panopticon record, compare them with the Guidewheel guides, and tell you for each meter whether it is OK or needs attention. I only read. I never save, change or type a password, and you sign in yourself.
> **Not tested on live meters in this version.** Check my results before you rely on them.
> **Questions or bugs:** aaron@guidewheel.com

## Ground rules (read-only, always)

- **Enforced, not just written.** `disable-model-invocation: true` means it runs only when the user invokes it. A `PreToolUse` hook (`guard.sh`, same folder) blocks browser clicks, typing, form input and page scripts that save, reset, submit or assign values. A block is a stop condition: report it. The hook covers only browser tools whose names match the pattern in the front matter. If the browser tools are named differently, edit the `matcher` (see README). If a harness ignores skill hooks, the rules below still apply, so the user should watch the browser window.
- Never type into a field that changes data, never call the page's `save()`, never click Save, Reset, Add Register, Add Meter or any button that writes. `select(<section>)` only switches the view. If a prompt asks to discard, reset, overwrite or confirm anything, answer No/Cancel, stop and report.
- **No passwords.** The skill never types, reads or stores a password, and never copies one from a guide. The user signs in to each meter and to Panopticon by hand. A meter still unauthorized is reported "needs sign-in" and skipped.
- Prefer text and page-script reads over screenshots.
- **Verdicts only against a written standard.** Where nothing is written (see Not written yet), print what is observed and say "observed, no standard". Never invent an expected value.
- A failed or hung step is a stop condition for that meter: report what was seen and go to the next one.
- Nothing is written outside the evidence file and the report.
- Register names chosen by hand are trusted. Do not rename or "correct" them. Report oddities (for example a typo in a name) as an observation for the owner.

## The flow (same order as `how-it-works.html`)

1. **Ask the user: What kind of meters are we checking?** Offer three choices: a meter with one current transformer (CT) sensor, a pulse meter (trigger and reject: two pulse sensors through a sensor hub), or something else, which the user describes. Only the first two have a written register standard. One box is checked as one type, never both. "Something else" (including more than one CT sensor on a meter) goes to the grill below.
2. **Ask the user: Do the meters share power with their machines?** Yes or no. It decides how an offline meter is reported.
3. **Ask the user for the list of meters, or a starting file.** One row per meter: four-digit meter number, line, Panopticon meter name, box type, and optionally the site's time zone. If a column is missing, ask one question at a time.
4. **Read the Guidewheel guides** (see Standards). Use the live Confluence pages when a Confluence connector is available. Otherwise use the baseline below.
5. **Optional: reference meter.** Ask whether the user has a reference meter (a meter they trust, with known values). If yes, calibrate: run the read scripts on it and compare with the values the user gives. Any mismatch, script error or guard block: stop and report, do not start the site. If no, skip.
6. **For each meter:**
   - **Online?** No: report "offline, expected" (no flag) if the meters share power with their machines, otherwise "offline" with 🚩. Do not infer a wiring fault from a 404 alone. Yes: continue.
   - **Read the meter and Panopticon parameters** (checks below).
   - **Compare with the Guidewheel standards.**
   - **Save the raw output to the evidence file.**
   - **Any red flags?** Yes: "needs attention". No: ✅ ALL GOOD banner.
   - **Show one result for this meter.** Then the next meter.
7. **Final report** when the list is done, with the second table of "observed, no standard" items.

## Browser options (pick one, none is assumed)

- **BrowserOS** (tools named `mcp__BrowserOS*`): use a work profile the user signs in with. After a restart, load the profile, open a window, then open the tab; the window may open in the background. Never use a personal or family profile.
- **Claude in Chrome** extension (`mcp__claude-in-chrome__*`): works, but sessions vanish when the tab group is closed.
- **Built-in browser pane** of the Claude app: on the author's setup it did not work with eGauge meters. Try it only if the others are not available.

Page scripts run through the browser's evaluate or javascript tool as reads only. One page-script call per meter.

## Standards (where they come from)

Standards are global for the team. They are not a per-run file. At the start of each run read the current guides, in this order:

1. **Confluence, Solutions Consulting space:** *General Meter Configuration*, *Pulse Sensor eGauge Configuration for Speed*, *CT Sensor Installation*, *Guidewheel eGauge Hardware*, *Meter Troubleshooting Guide*. (Search by title with the Confluence connector. If a page body comes back empty, say so and use the baseline.) Never copy a password from any guide.
2. **The team's vault notes** on meter configuration and register standards, if the user has one.
3. **The baseline below**, taken from those guides on 2026-11-23, when neither is reachable.

If a live guide and the baseline disagree, the live guide wins and the difference goes in the report.

### Baseline: every meter
- **Clock:** time zone set to the site's zone, not UTC or GMT; North American time server `{0..3}.north-america.pool.ntp.org`. **Factory default:** a fresh meter shows time zone "custom" with the text UTC. If that is what the page shows, report "clock still at factory default" with a 🚩. The meter time should also be within a day of real time in the site's zone. Never change the clock. The site's zone comes from the meter list (optional column) or one question to the user.
- **Data Sharing:** Custom (factory state is Disabled: flag). URI = the meter's API URL from Panopticon (the device id must match). Options `gzip,sec,old_first,totals`. Interval 1 minute. Update frequency 1 Hz.
- **Name:** the meter's Preferences name follows "Customer - Location, Meter number" and resembles the Panopticon name.
- **Wi-Fi / connection (read-only; status page and WLAN list):** record the connection type (Ethernet or Wi-Fi), the network the meter is joined to, the remembered networks and the signal strength. A site or router network is expected. A plant guest network gets a note, not a flag. **Flag only a weak signal: below 50%.** Everything else is observed. Never join, forget or change a network, and never ask for a Wi-Fi password.
- **Fresh meter (never configured):** the Installation table shows only the five factory registers (Unconfigured Register 1, L1 Voltage, L2 Voltage, L3 Voltage, Internal Temperature, "5 of 64 in use") and Data Sharing is Disabled. Report "fresh, not configured yet", read what can be read, give no register verdict, and flag the clock and Data Sharing as above.
- **Registers:** at most 64. No underscores in register names. Frequency register = 60, once per meter. Usage = the first current sensor, not a sum. Generation and Battery stay empty.
- **Sensors:** the sensor model on each port is recognized by CTid and the register points at that port. A factory demo sensor (a three-channel "AE RCT 106mm/4.17, 2775A" entry) on a port that carries a register is flagged. CT rating in the software must match the physical CT.

### Baseline: CT box (one CT sensor)
`<prefix>-I1` (type S, the sensor's port, Normal value); `<prefix>-Vln1`, `-Vln2`, `-Vln3` (Voltage [V], standard value 277; the Confluence guide also describes line-to-line voltage divided by the square root of 3 for three-phase, so either form is accepted and noted; a single-phase machine has one voltage register); `<prefix>-F` (Frequency [Hz], 60); `<prefix>-Psum` (Power [W]) = `$"<prefix>-I1"*$"<prefix>-Vln1"*3`; Usage = `+ <prefix>-I1`. The same set applies to one CT sensor on a three-phase or a single-phase machine, per the voltage note. Status: written in the Confluence guide, the exact Psum text is still being confirmed by the team, so a difference is reported as "differs from the guide".

### Baseline: pulse box (trigger and reject, two pulse sensors through a sensor hub)
16 of 64 registers; trigger sensor on S1, reject sensor on S6 (a site may differ; the user says so in the meter list).
- Trigger side: `trig-I1` (S, S1, Normal value); `trig-Vln1`, `trig-Vln2`, `trig-Vln3` (Voltage [V], 277); `trig-F` (Frequency [Hz], 60); `trig-Psum` (Power [W]); `trig-PiecesMin`, `trig-SpeedBottlesMin`, `trig-Pulse` (Whole number). The four formula registers use `$"trig-I1"*100000*0.3`.
- Reject side: `rej-I1` (S, S6); `rej-Vln1` (Voltage [V], 277); `rej-F` (Frequency [Hz], 60); `rej-Psum` (Power [W]); `rej-PiecesMin`, `rej-SpeedBottlesMin`, `rej-Pulse` (Whole number), all formulas `$"rej-I1"*100000*0.3`.
- Usage = `+ trig-I1`. Older meters may carry a 14-register version: report it, do not call it a fault.
- Pulse sensors reach the meter through a sensor hub and count up to 600 pulses a second.

### Any other type: grill the user
No register standard is written for any other meter. Do not guess one and do not borrow the CT or pulse set. Ask one question at a time:
1. Which sensors are on the meter, and on which ports?
2. What register names does the user expect (the machine prefix, and any other names)?
3. What are the types and formulas for each register, if any?
4. Is there anything the guides say about this type that the agent should read?
Then read the answers back as a table and ask the user to confirm it. Use that table for this run only, label every verdict against it "user-provided standard", and save it at the top of the evidence file. Anything the user does not know stays "observed, no standard".

### Baseline: Panopticon
External ID = the four-digit meter number; provider `egauge`. **API parameters** (what earlier notes called the Google Cloud Platform parameters): when a new device is created in Panopticon, its card shows an API URL (button "Show API"). The form is `https://api.safisense.com/v2/ingest?device=<digits>&vendor=egauge`. The host, the path `/v2/ingest` and `vendor=egauge` are the same for every meter. Only the `device` number changes, one per meter. That exact URL is entered in the meter's Data Sharing URI. Check: the Panopticon URL has this form, and the meter's URI equals it character for character (same `device` number). A URI that is empty, points elsewhere, or carries another meter's `device` number is flagged. Meter slug is `<company id>_<site handle><number>` and the device id is `<meter slug>_<register prefix>`. The eGauge prefix on the Panopticon meter is `guidewheel` for newer meters or `egauge` for older ones, and it must match the host name the meter answers on (`<prefix><meter number>.egaug.es`). The meter card has the read buttons Show API, Meter configs (eGauge), Meter links and Hourly uptime. Never press Edit meter, Add Device or any other button that changes a record. A grey status dot is normal until data flows.

### Not written yet (print "observed, no standard")
register sets for any other meter type (the agent asks the user, see above); the expected sensor model and amps per line.

## What it checks, per meter

1. **Online.** Settings page loads and the config fetch works (poll `select(...)` until it stops throwing, up to about 20 seconds). A proxy answer of 404 means offline now. A 401 means "needs sign-in". Settings page: `https://<account><meter>.egaug.es/<code>/settings.html` (the short form redirects).
2. **Clock** (`select(DATE)`), not the "recording started" field. Record zone and time.
3. **Registers** (`select(INST)`). Pulse box: the registers script below. CT box: list the registers and compare by eye with the CT baseline. Registers in a different order are fine.
4. **Sensors and CTid.**
   - A sensor on a port other than the usual pattern (for example S15 instead of S1) is fine when CTid recognizes the sensor and the register points at that port. Do not flag the port.
   - Do not compare the sensor's rated amps with the machine's full load. No amp-headroom flag.
   - Trust a previous CTid scan. Slow meters fill the page late: wait 10 to 20 seconds and reload once before calling a CTid page empty. Never report "never scanned" from one read. When the page shows a scan, its sensor model and serial are the truth.
   - Flag a factory demo sensor on a port that carries a register, and a CTid page still empty after the wait.
5. **General Settings** (`select(GENERAL)`): Data Sharing, API URL, options, interval, update frequency, proxy host. **Connection:** the status page and the WLAN list (see the Wi-Fi baseline).
6. **Panopticon** (read-only): find the meter by external id, check name, line and site against the list, note the log, compare the API URL, read the API URL (Show API) and check its form as in the Panopticon baseline.

## Run protocol

1. **Evidence trail.** For every meter append the raw script output (exactly as returned), the meter URL and the time with zone to `meter-qa-evidence/<site>-<YYYY-MM-DD>.md` in the current folder (date from `date`; ask if another folder is preferred). The verdict cites that file. No evidence entry means no verdict.
2. **Checklist per meter:**
   - [ ] online (or offline, or needs sign-in)
   - [ ] clock read
   - [ ] registers read and compared (or observed, no standard)
   - [ ] sensors and CTid read
   - [ ] General Settings read
   - [ ] Panopticon record read
   - [ ] raw output saved to the evidence file
   - [ ] one verdict line written
3. **One meter at a time,** one short result per meter, never two meters in one message.

## Test cases (run by hand when the skill or the guides change)

| Case | Setup | Expected verdict |
|---|---|---|
| Healthy pulse box | all 16 registers, ports as expected | OK |
| Missing register | meter missing one standard register | needs attention, names it |
| Swapped ports | trigger and reject ports swapped | needs attention, names both |
| Offline, shared power | proxy answers 404 | offline, expected, no flag |
| Offline, own power | proxy answers 404 | offline, flagged |
| Not signed in | 401 | needs sign-in, skipped |
| Sensor on an unusual port, CTid recognizes it | register points at that port | not flagged |
| Write attempt | any click or script with `save(` | blocked by guard, run stops |

**Tested on:** not yet run end to end by anyone but the author, on one setup. Not tested on live meters in the v2.0 build session. Record the model name and date here after each run.

## Output

One line per meter: **OK** or **needs attention**, the meter URL and one short phrase. Mark every item that is off the standard, or off what the other meters of the site show, with 🚩. Group by site.

**All good banner.** If every check for a meter passes with no 🚩, start the result with a green check and a short green banner (emoji blocks, not ANSI): the meter line, "ALL GOOD" and what was checked. Any 🚩 means no banner. An offline-expected meter gets no banner and no flag.

## Scripts (reads only, run through the browser's page-script tool)

The tool may block output that mixes `$` and quotes, so the scripts turn them into `#`.

Registers check for a pulse box. Edit the three constants at the top if a site's standard differs. Few live runs so far:

```js
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const sel=async c=>{for(let i=0;i<12;i++){try{select(c);return true}catch(e){await sleep(2000)}}return false};
// EDIT THESE to match your own written standard (examples shown):
const V=V, HZ=HZ, MULT='100000*0.3'; // line voltage, frequency, pulse multiplier
const f=p=>'$"'+p+'-I1"*'+MULT;
const exp={'trig-I1':['S'],'trig-Vln1':['=','Voltage [V]',V],'trig-Vln2':['=','Voltage [V]',V],'trig-Vln3':['=','Voltage [V]',V],'trig-F':['=','Frequency [Hz]',HZ],'trig-Psum':['=','Power [W]',f('trig')],'trig-PiecesMin':['=','Whole number',f('trig')],'trig-SpeedBottlesMin':['=','Whole number',f('trig')],'trig-Pulse':['=','Whole number',f('trig')],'rej-I1':['S'],'rej-Vln1':['=','Voltage [V]',V],'rej-F':['=','Frequency [Hz]',HZ],'rej-Psum':['=','Power [W]',f('rej')],'rej-PiecesMin':['=','Whole number',f('rej')],'rej-SpeedBottlesMin':['=','Whole number',f('rej')],'rej-Pulse':['=','Whole number',f('rej')]};
const ok=await sel(INST); await sleep(2500);
const t=[...document.querySelectorAll('input')].find(i=>/^(trig-I1|rej-I1|L1 Voltage)$/.test(i.value));
if(!t){'NO TABLE (config not loaded, ok='+ok+')'}else{
 const rows=[...t.closest('table').rows].filter(r=>r.querySelector('input[type=text]')); const by={};
 rows.forEach(r=>{const tx=r.querySelectorAll('input[type=text]'),sl=r.querySelectorAll('select'); const op=sl[0].options[sl[0].selectedIndex].text.trim();
  by[tx[0].value]= op==='S'?{op,port:sl[1].options[sl[1].selectedIndex].text.trim()}:{op,type:sl[1]?sl[1].options[sl[1].selectedIndex].text.trim():'',val:tx[1]?tx[1].value:''}});
 const missing=Object.keys(exp).filter(n=>!by[n]), extra=Object.keys(by).filter(n=>!exp[n]);
 const bad=Object.keys(exp).filter(n=>by[n]&&((exp[n][0]!==by[n].op)||(exp[n][1]&&exp[n][1]!==by[n].type)||(exp[n][2]&&exp[n][2]!==by[n].val)));
 location.host.split('.')[0]+': '+rows.length+' rows | trig-I1='+(by['trig-I1']?.port||'-')+' rej-I1='+(by['rej-I1']?.port||'-')+' | missing: '+(missing.join(',')||'none')+' | extra: '+(extra.join(',')||'none')+' | mismatch: '+(bad.join(',')||'none')}
```

General Settings read (URLs are made safe for the output filter by replacing `? = & $ "` with `#` and `/` with `~`):

```js
const san=s=>String(s).replace(/[?=&$"]/g,'#').replace(/\//g,'~').replace(/\s+/g,' ');
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
for(let i=0;i<10;i++){try{select(GENERAL);break}catch(e){await sleep(2000)}} await sleep(2000);
[...document.querySelectorAll('input,select,textarea')].filter(e=>e.offsetParent!==null&&e.type!=='button'&&e.type!=='hidden')
 .map(e=>{const v=e.tagName==='SELECT'?e.options[e.selectedIndex]?.text:(e.type==='checkbox'||e.type==='radio'?(e.checked?'[x]':'[ ]'):e.value);
  const lab=(e.closest('tr')?.innerText||e.parentElement?.innerText||'').trim().slice(0,50); return san(lab)+' => '+san(v)}).slice(0,40).join('\n')
```

Page functions on the settings page: `select(GENERAL | NET | WLAN | BACNET | MODBUS | INST | DATE | ALERT | LCD)`. The `DATE` read has few live runs, so confirm its field names on the first meter.

## Lessons

- The settings page can throw `Cannot read properties of undefined (reading 'send')` until its config fetch is ready. Poll `select(...)` in a try/catch instead of a fixed wait. A meter that was just saved is rebooting for about a minute.
- A `chrome-error://` page on `/settings.html` for a reachable meter usually clears after opening `/ng/` once, then settings again.
- Never close or reuse a tab another run depends on.
- One page-script call per meter returns one short line and keeps the context small.

## Data check

For a report that will be shared, have a second read-only pass re-derive each value from the live pages or the source list and return a discrepancy list. Stamp the report: `Data quality: checked <time with zone>, <N> values, <M> discrepancies`. No stamp means no check.
