#!/usr/bin/env bash
# Update shelf page with current favorites from Letterboxd and Backloggd.
# Runs daily via cron. Only updates values it can successfully scrape.

set -euo pipefail

SHELF="/home/mhodde/martinhodde.com/shelf/index.html"
LOG="/tmp/update-shelf.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }

log "Starting shelf update"

LB_HTML=$(curl -sf "https://letterboxd.com/krazyklownn/" 2>/dev/null) || LB_HTML=""

# ── Letterboxd favorites ──
LB_FAVS=""
if [ -n "$LB_HTML" ]; then
  LB_FAVS=$(echo "$LB_HTML" | python3 -c "
import sys, re, html as htmlmod
data = sys.stdin.read()
# Favorites live in id='favourites' section; use data-item-name (not data-film-name)
if 'id=\"favourites\"' in data:
    idx = data.index('id=\"favourites\"')
    section = data[idx:idx+10000]
    favs = re.findall(r'data-item-name=\"([^\"]+)\"', section)
    # Strip trailing year like ' (2015)'
    favs = [re.sub(r'\s*\(\d{4}\)\$', '', f) for f in favs]
else:
    favs = []
for f in favs[:4]:
    print(htmlmod.unescape(f))
" 2>/dev/null) || true
fi

# ── Letterboxd film count ──
LB_COUNT=""
if [ -n "$LB_HTML" ]; then
  LB_COUNT=$(echo "$LB_HTML" | python3 -c "
import sys, re
data = sys.stdin.read()
m = re.search(r'([\d,]+)\s*films?', data)
if m:
    val = m.group(1).replace(',','')
    if int(val) > 10:  # sanity check
        print(val)
" 2>/dev/null) || true
fi

# ── Backloggd ──
BG_HTML=$(curl -sf \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
  -H "Accept-Language: en-US,en;q=0.5" \
  -H "Accept-Encoding: identity" \
  -H "Connection: keep-alive" \
  -H "Upgrade-Insecure-Requests: 1" \
  -A "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0" \
  "https://backloggd.com/u/krazyklown/" 2>/dev/null) || BG_HTML=""

BG_FAVS=""
BG_PLAYED=""
BG_BACKLOG=""
if [ -n "$BG_HTML" ]; then
  BG_FAVS=$(echo "$BG_HTML" | python3 -c "
import sys, re, html as htmlmod
data = sys.stdin.read()
favs = []
if 'id=\"profile-favorites\"' in data:
    idx = data.index('id=\"profile-favorites\"')
    section = data[idx:idx+5000]
    favs = re.findall(r'class=\"game-text-centered\">([^<]+)<', section)
for f in favs[:5]:
    print(htmlmod.unescape(f.strip()))
" 2>/dev/null) || true

  BG_PLAYED=$(echo "$BG_HTML" | python3 -c "
import sys, re
data = sys.stdin.read()
if 'id=\"profile-stats\"' in data:
    idx = data.index('id=\"profile-stats\"')
    section = data[idx:idx+1000]
    nums = re.findall(r'<h1>(\d+)</h1>', section)
    if nums and int(nums[0]) > 0:
        print(nums[0])
" 2>/dev/null) || true

  BG_BACKLOG=$(echo "$BG_HTML" | python3 -c "
import sys, re
data = sys.stdin.read()
if 'id=\"profile-stats\"' in data:
    idx = data.index('id=\"profile-stats\"')
    section = data[idx:idx+1000]
    nums = re.findall(r'<h1>(\d+)</h1>', section)
    if len(nums) >= 3 and int(nums[2]) > 0:
        print(nums[2])
" 2>/dev/null) || true
fi

# ── Apply updates via Python ──
python3 - "$SHELF" "$LB_FAVS" "$LB_COUNT" "$BG_FAVS" "$BG_PLAYED" "$BG_BACKLOG" << 'PYEOF'
import sys, re

shelf_path = sys.argv[1]
lb_favs_raw = sys.argv[2].strip()
lb_count = sys.argv[3].strip()
bg_favs_raw = sys.argv[4].strip()
bg_played = sys.argv[5].strip()
bg_backlog = sys.argv[6].strip()

with open(shelf_path) as f:
    html = f.read()

changed = False

# Update Letterboxd favorites
if lb_favs_raw:
    lb_favs = [f for f in lb_favs_raw.split('\n') if f.strip()]
    if len(lb_favs) >= 2:  # sanity: need at least 2 favorites
        lb_li = '\n'.join(f'            <li>{f}</li>' for f in lb_favs)
        pattern = r'(Letterboxd.*?<h4>current favorites</h4>\s*<ul>\s*)(.*?)(</ul>)'
        match = re.search(pattern, html, re.DOTALL)
        if match:
            old_list = match.group(2).strip()
            if old_list != lb_li:
                html = html[:match.start(2)] + '\n' + lb_li + '\n          ' + html[match.end(2):]
                changed = True

# Update Letterboxd count
if lb_count and lb_count.isdigit() and int(lb_count) > 10:
    pattern = r'(Letterboxd.*?<span class="num">)\d+(</span>\s*<span class="label">films)'
    new_html = re.sub(pattern, rf'\g<1>{lb_count}\g<2>', html, flags=re.DOTALL)
    if new_html != html:
        html = new_html
        changed = True

# Update Backloggd favorites
if bg_favs_raw:
    bg_favs = [f for f in bg_favs_raw.split('\n') if f.strip()]
    if len(bg_favs) >= 2:
        bg_li = '\n'.join(f'            <li>{f}</li>' for f in bg_favs)
        pattern = r'(Backloggd.*?<h4>current favorites</h4>\s*<ul>\s*)(.*?)(</ul>)'
        match = re.search(pattern, html, re.DOTALL)
        if match:
            old_list = match.group(2).strip()
            if old_list != bg_li:
                html = html[:match.start(2)] + '\n' + bg_li + '\n          ' + html[match.end(2):]
                changed = True

# Update Backloggd played count
if bg_played and bg_played.isdigit() and int(bg_played) > 0:
    pattern = r'(Backloggd.*?<span class="num">)\d+(</span>\s*<span class="label">played)'
    new_html = re.sub(pattern, rf'\g<1>{bg_played}\g<2>', html, flags=re.DOTALL)
    if new_html != html:
        html = new_html
        changed = True

# Update Backloggd backlog count
if bg_backlog and bg_backlog.isdigit() and int(bg_backlog) > 0:
    pattern = r'(Backloggd.*?<span class="num">)\d+(</span>\s*<span class="label">backlog)'
    new_html = re.sub(pattern, rf'\g<1>{bg_backlog}\g<2>', html, flags=re.DOTALL)
    if new_html != html:
        html = new_html
        changed = True

if changed:
    with open(shelf_path, 'w') as f:
        f.write(html)
    print("Shelf updated")
else:
    print("No changes needed")
PYEOF

log "Shelf update complete"
