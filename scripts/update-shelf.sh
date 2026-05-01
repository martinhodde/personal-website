#!/usr/bin/env bash
# Update shelf page with current favorites from Letterboxd and Backloggd.
# Runs daily via cron. Only updates values it can successfully scrape.

set -euo pipefail

SHELF="/home/mhodde/personal-website/shelf/index.html"
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

# ── Goodreads ──
GR_HTML=$(curl -sf \
  -A "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0" \
  "https://www.goodreads.com/user/show/200749596-martin-hodde" 2>/dev/null) || GR_HTML=""

GR_FAVORITES=""
GR_READ=""
GR_TOREAD=""

GR_RSS=$(curl -sf "https://www.goodreads.com/review/list_rss/200749596?shelf=favorites" 2>/dev/null) || GR_RSS=""
if [ -n "$GR_RSS" ]; then
  GR_FAVORITES=$(echo "$GR_RSS" | python3 -c "
import sys, re, html as htmlmod
data = sys.stdin.read()
# Extract only item titles (inside <item> blocks)
items = re.findall(r'<item>.*?</item>', data, re.DOTALL)
for item in items:
    m = re.search(r'<title>([^<]+)</title>', item)
    if m:
        print(htmlmod.unescape(m.group(1).strip()))
" 2>/dev/null) || true
fi

if [ -n "$GR_HTML" ]; then
  GR_READ=$(echo "$GR_HTML" | python3 -c "
import sys, re
data = sys.stdin.read()
m = re.search(r'(?<![a-z-])read&lrm;[^(]*\((\d+)\)', data)
if m: print(m.group(1))
" 2>/dev/null) || true

  GR_TOREAD=$(echo "$GR_HTML" | python3 -c "
import sys, re
data = sys.stdin.read()
m = re.search(r'to-read&lrm;[^(]*\((\d+)\)', data)
if m: print(m.group(1))
" 2>/dev/null) || true
fi

# ── Spotify top artists ──
SPOTIFY_CREDS="${HOME}/.spotify_credentials"
SP_ARTISTS=""

if [ -f "$SPOTIFY_CREDS" ]; then
  # shellcheck source=/dev/null
  source "$SPOTIFY_CREDS"

  TOKEN_RESPONSE=$(curl -sf -X POST "https://accounts.spotify.com/api/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=refresh_token&refresh_token=${SPOTIFY_REFRESH_TOKEN}&client_id=${SPOTIFY_CLIENT_ID}&client_secret=${SPOTIFY_CLIENT_SECRET}" \
    2>/dev/null) || TOKEN_RESPONSE=""

  if [ -n "$TOKEN_RESPONSE" ]; then
    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('access_token', ''))
" 2>/dev/null) || ACCESS_TOKEN=""

    if [ -n "$ACCESS_TOKEN" ]; then
      SP_RESPONSE=$(curl -sf \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        "https://api.spotify.com/v1/me/top/artists?time_range=short_term&limit=5" \
        2>/dev/null) || SP_RESPONSE=""

      if [ -n "$SP_RESPONSE" ]; then
        SP_ARTISTS=$(echo "$SP_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for item in data.get('items', []):
    print(item['name'])
" 2>/dev/null) || SP_ARTISTS=""
      fi
    fi
  fi
else
  log "Spotify credentials not found at ${SPOTIFY_CREDS}, skipping"
fi

# ── Apply updates via Python ──
python3 - "$SHELF" "$LB_FAVS" "$LB_COUNT" "$BG_FAVS" "$BG_PLAYED" "$BG_BACKLOG" "$SP_ARTISTS" "$GR_FAVORITES" "$GR_READ" "$GR_TOREAD" << 'PYEOF'
import sys, re

shelf_path = sys.argv[1]
lb_favs_raw = sys.argv[2].strip()
lb_count = sys.argv[3].strip()
bg_favs_raw = sys.argv[4].strip()
bg_played = sys.argv[5].strip()
bg_backlog = sys.argv[6].strip()
sp_artists_raw = sys.argv[7].strip()
gr_favorites_raw = sys.argv[8].strip()
gr_read = sys.argv[9].strip()
gr_toread = sys.argv[10].strip()

with open(shelf_path) as f:
    html = f.read()

changed = False

# Update Letterboxd favorites
if lb_favs_raw:
    lb_favs = [f for f in lb_favs_raw.split('\n') if f.strip()]
    if len(lb_favs) >= 2:  # sanity: need at least 2 favorites
        lb_li = '\n'.join(f'            <li>{f}</li>' for f in lb_favs)
        pattern = r'(Letterboxd.*?<h4>favorites</h4>\s*<ul>\s*)(.*?)(</ul>)'
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
        pattern = r'(Backloggd.*?<h4>favorites</h4>\s*<ul>\s*)(.*?)(</ul>)'
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

# Update Goodreads favorites
if gr_favorites_raw:
    gr_books = [b for b in gr_favorites_raw.split('\n') if b.strip()]
    if len(gr_books) >= 1:
        gr_li = '\n'.join(f'            <li>{b}</li>' for b in gr_books)
        pattern = r'(Goodreads.*?<h4>favorites</h4>\s*<ul>\s*)(.*?)(</ul>)'
        match = re.search(pattern, html, re.DOTALL)
        if match:
            old_list = match.group(2).strip()
            if old_list != gr_li:
                html = html[:match.start(2)] + '\n' + gr_li + '\n          ' + html[match.end(2):]
                changed = True

# Update Goodreads read count
if gr_read and gr_read.isdigit() and int(gr_read) > 0:
    pattern = r'(Goodreads.*?<span class="num">)\d+(</span>\s*<span class="label">read)'
    new_html = re.sub(pattern, rf'\g<1>{gr_read}\g<2>', html, flags=re.DOTALL)
    if new_html != html:
        html = new_html
        changed = True

# Update Goodreads to-read count
if gr_toread and gr_toread.isdigit() and int(gr_toread) >= 0:
    pattern = r'(Goodreads.*?<span class="num">)\d+(</span>\s*<span class="label">to read)'
    new_html = re.sub(pattern, rf'\g<1>{gr_toread}\g<2>', html, flags=re.DOTALL)
    if new_html != html:
        html = new_html
        changed = True

# Update Spotify top artists
if sp_artists_raw:
    sp_artists = [a for a in sp_artists_raw.split('\n') if a.strip()]
    if len(sp_artists) >= 3:
        sp_li = '\n'.join(f'            <li>{a}</li>' for a in sp_artists)
        pattern = r'(Spotify.*?<h4>top artists.*?</h4>\s*<ul>\s*)(.*?)(</ul>)'
        match = re.search(pattern, html, re.DOTALL)
        if match:
            old_list = match.group(2).strip()
            if old_list != sp_li:
                html = html[:match.start(2)] + '\n' + sp_li + '\n          ' + html[match.end(2):]
                changed = True

if changed:
    with open(shelf_path, 'w') as f:
        f.write(html)
    print("Shelf updated")
else:
    print("No changes needed")
PYEOF

log "Shelf update complete"
