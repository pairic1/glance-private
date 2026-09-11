#!/bin/bash
# Re-render the Deep Freeze 250 Club frames and publish them.
#
#   ./update.sh                                   # members from manifest.yaml
#   ./update.sh "ARIC, JORI, ANDREA, NEW PERSON"  # or pass the full list
#
# To add someone for good, append them to `members` in manifest.yaml (in the
# order they joined) and run ./update.sh with no arguments.
set -euo pipefail
cd "$(dirname "$0")"

GDN=../../glance-dev-network
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

args=()
if [ $# -gt 0 ]; then args=(--input "members=$1"); fi
"$GDN/.venv/bin/gdn" build . --out "$OUT" "${args[@]+"${args[@]}"}" >/dev/null 2>&1
cp "$OUT/club.png" club.png
cp "$OUT/members.png" members.png

# Private apps must be PNG, exactly 32 tall, at most 192 wide.
"$GDN/.venv/bin/python" -c "
from PIL import Image
for f in ('club.png', 'members.png'):
    im = Image.open(f)
    assert im.format == 'PNG' and im.size == (64, 32), (f, im.format, im.size)
print('rendered club.png and members.png (64, 32)')
"

if git remote get-url origin >/dev/null 2>&1; then
  git add club.png members.png manifest.yaml app.star
  git commit -q -m "Deep Freeze 250 Club: re-render" || { echo "nothing changed"; exit 0; }
  git push -q
  echo "published -- the panel picks it up on its next refresh"
fi
