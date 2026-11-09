#!/bin/sh
# Driving A/B: for each binary given, start the game, let the player drive
# (45 s to get a car), measure 30 s while they keep driving. Each game is
# stopped only after the player has put the pad down for 5 s; the next one
# starts once the console is idle (goodluckOS-tools/console-idle.sh), else the A/B ends.
# Usage: drive-ab.sh LCSNative.a LCSNative.b LCSNative.a LCSNative.b
# (the player drives the same route each time, ~90 s, then lets go).
set -u
R=$(cd "$(dirname "$0")/../.." && pwd)
L=${TMPDIR:-/tmp}/lcs-console.lock
lock() { while ! mkdir "$L" 2>/dev/null; do sleep 20; done; echo "(console lock taken $(date +%H:%M))"; }
unlock() { rmdir "$L"; }
cd "$R"; lock
for b in "$@"; do
    goodluckOS-tools/console-idle.sh >/dev/null || { echo "console not idle: A/B stopped before $b"; unlock; exit 1; }
    echo "== $b $(date +%H:%M)"
    # fps, minimum and seconds under 22 over the 30 s window (drive-profile.sh)
    DRIVE=45 glOSports-gtalcs-psp/tools/drive-profile.sh $b 2>&1 | tr -d '\r' | grep -a "gameplay\|fps\|thread\|pid\|no frames\|measured"
done
unlock; echo ab-done
