#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"
mkdir -p data/ihotdraw
cd data/ihotdraw
curl -sL -X POST "https://www.txl.ca/cgi-bin/txl-nicaddownload.cgi" -d "Platform=linux" -o nicad_response.html
NURL=$(python3 - <<'PY'
import re
text=open('nicad_response.html').read()
m=re.search(r"href=['\"]?\.\./download/([^'\" >]+)", text, flags=re.IGNORECASE)
if not m:
    raise SystemExit('no Nicad URL')
print(m.group(1))
PY
)
if [ -z "$NURL" ]; then
  echo "Failed to extract NiCad URL"
  exit 1
fi
if [ -z "$NURL" ]; then
  echo "Failed to extract NiCad URL"
  exit 1
fi
echo "NiCad URL: $NURL"
curl -sL "https://www.txl.ca/download/${NURL}" -o NiCad.tar.gz
rm -rf nicad
mkdir -p nicad
cd nicad
tar xzf ../NiCad.tar.gz
ls -1
