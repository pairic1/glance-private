#!/bin/bash
# Re-render the arcade basketball board as a static PNG for a Glance private
# app, then publish it. Private apps are image-only -- the panel just fetches
# a PNG from a URL -- so the "settings" live here instead:
#
#   ./update.sh "MADDIE" 118              # title defaults to POP-A-SHOT
#   ./update.sh "DAD" 41 "SHUFFLEBOARD"
#
# It renders with the same app.star as the catalog version, through gdn itself,
# so the two are pixel-identical by construction rather than by copying.
set -euo pipefail
cd "$(dirname "$0")"

usage="usage: ./update.sh NAME SCORE [TITLE]"
NAME="${1:?$usage}"
SCORE="${2:?$usage}"
TITLE="${3:-POP-A-SHOT}"

# The app draws a "NO SCORE" screen for anything that is not a whole number,
# which is right on a wall and wrong here -- fail loudly instead of publishing it.
if ! [[ "$SCORE" =~ ^[0-9]+$ ]]; then
  echo "score must be a whole number, got: $SCORE" >&2
  exit 1
fi

GDN=../glance-dev-network
APP="$GDN/apps/arcade-basketball-high-score"
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

"$GDN/.venv/bin/gdn" build "$APP" --out "$OUT" \
  --input "name=$NAME" --input "score=$SCORE" --input "label=$TITLE" >/dev/null 2>&1
cp "$OUT/champ.png" arcade-basketball.png

# Private apps must be PNG, exactly 32 tall, at most 192 wide.
"$GDN/.venv/bin/python" -c "
from PIL import Image
im = Image.open('arcade-basketball.png')
assert im.format == 'PNG' and im.size == (64, 32), (im.format, im.size)
print('rendered arcade-basketball.png', im.size)
"

if git remote get-url origin >/dev/null 2>&1; then
  git add arcade-basketball.png
  git commit -q -m "Record: $NAME, $SCORE ($TITLE)"
  git push -q
  echo "published -- the panel picks it up on its next refresh"
fi
