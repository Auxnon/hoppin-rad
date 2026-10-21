#!/bin/bash
# Run Hoppin' Rad on a hidden headless Hyprland output with a scripted
# playtest (defines TEST_HOOK(dt), called every frame from loop()).
#
#   playtests/run.sh playtests/smoke.lua [seconds] [shots...]
#
# Log: $OUT/game.log, screenshots: $OUT/shot_<sec>.png
set -e
here="$(cd "$(dirname "$0")/.." && pwd)"
test="$1"; secs="${2:-12}"; shift 2 || true
shots="$*"
engine="${CHOR:-$(command -v chor || echo $HOME/petrichor64/target/release/chor)}"
OUT="${OUT:-$(mktemp -d)}"
game="$OUT/game"
rm -rf "$game"; mkdir -p "$game"
cp -r "$here/scripts" "$here/assets" "$game/"
cp "$test" "$game/scripts/zz_test.lua"
printf '#!/bin/bash\nexec "%s" "%s" > "%s/game.log" 2>&1\n' "$engine" "$game" "$OUT" > "$OUT/launch.sh"
chmod +x "$OUT/launch.sh"
hyprctl output create headless TEST >/dev/null
hyprctl eval 'hl.monitor({output="TEST", mode="1280x800@60", position="-4000x0", scale=1})' >/dev/null
sleep 0.5
ws=$(hyprctl monitors -j | python3 -c 'import json,sys; print([m for m in json.load(sys.stdin) if m["name"]=="TEST"][0]["activeWorkspace"]["id"])')
hyprctl eval "hl.exec_cmd(\"[workspace $ws silent] $OUT/launch.sh\")" >/dev/null
t=0
for s in $shots; do
  sleep $((s - t)); t=$s
  timeout 5 grim -o TEST "$OUT/shot_$s.png" || true
done
sleep $((secs > t ? secs - t : 0))
pkill -x chor || true
sleep 0.5
hyprctl output remove TEST >/dev/null || true
echo "$OUT"
