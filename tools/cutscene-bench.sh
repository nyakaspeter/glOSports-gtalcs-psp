#!/bin/sh
# Repeatable LCS benchmark without touching the controls: the intro cutscene
# plays the same way every time, so frames are measured from 40 to 60 s after
# launch. Each run starts below 50 C (the A33 throttles at 75 C).
#   tools/cutscene-bench.sh <binary in ports/gtalcs-psp> [VAR=value ...]
# e.g. tools/cutscene-bench.sh LCSNative PSPRECOMP_GE_DECODE_THREADS=1
set -eu
cd "$(dirname "$0")/../../goodluckOS-tools"
binary=$1
shift
GLOS_TIMEOUT=900 python3 -I console.py "/usr/local/bin/appctl stop-application; sleep 3
while [ \$(cat /sys/class/thermal/thermal_zone0/temp) -gt 50000 ]; do sleep 5; done
cd /home/player/ports/gtalcs-psp
sed 's|\./LCSNative --game|./$binary --game|' start.sh > start.bench.sh; chmod +x start.bench.sh
/usr/local/bin/appctl launch-application \"cd /home/player/ports/gtalcs-psp && env LCS_FPS_LOG=1 $* ./start.bench.sh\"
sleep 40; n0=\$(wc -l < /dev/shm/lcs.log); sleep 20
tail -n +\$((n0 + 1)) /dev/shm/lcs.log | grep 'glos: FPS' | awk '{f+=\$3; d+=\$5; g+=\$7; n++} END {if (n) printf \"fps %.1f  psp draws/frame %.0f  gl draws/frame %.0f  (%d samples)\\n\", f/n, d/n, g/n, n; else print \"no frames logged\"}'
echo \$((\$(cat /sys/class/thermal/thermal_zone0/temp) / 1000)) C
/usr/local/bin/appctl stop-application"
python3 -I console.py "rm -f /home/player/ports/gtalcs-psp/start.bench.sh" >/dev/null 2>&1 || true
