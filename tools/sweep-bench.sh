#!/bin/sh
# gameplay-bench.sh with motion: SWEEP="dx dy hops interval" (default
# "-40 0 5 2") moves the player `hops` times by (dx, dy) metres every
# `interval` seconds during the measurement, after the TELEPORT, so the
# streaming, traffic and ped code runs as when driving (a proxy: no vehicle
# physics). Measures 12 s. Everything else as gameplay-bench.sh:
#   TELEPORT="1138.85 -611.62 15.3 270" SWEEP="-40 0 5 2" tools/sweep-bench.sh [binary] [VAR=value ...]
# Below: the benchmark script this is derived from.
# skip the intro cutscenes with injected Cross presses (padpress) until the
# HUD's green money counter shows (fbprobe), then
# measure 10 s with no input. A new game: standing next to the car on the
# dirt road (trees, ~2700 PSP draws per frame). With a save in game/PSP/SAVEDATA
# the presses load it instead (wherever it was saved).
#   tools/gameplay-bench.sh <binary in ports/lcs> [VAR=value ...]   (default LCSNative)
#   SHOT=file.png also saves a screenshot of the scene.
#   START=start.ioctl.sh launches through that script instead of start.sh (the
#   ioctl counter, glos/testing/ioctlcount.so, logs calls and time per kind).
#   TELEPORT="x y z [heading]" writes that world position (and facing
#   direction, compass degrees: 0 = +y, 90 = +x, default 180) into the
#   player's matrix and heading floats (LCS: player ped pool slot, matrix at
#   guest 0x099476f0, rotation cur/dest at 0x09947bd0) once the save is in gameplay, walks him forward for 1.5 s so the camera
#   settles behind him, waits 10 s for the area to stream in, then measures. Outside the Portland hospital looking along the busy street:
#   TELEPORT="1144.3 -588.74 15.4 270".
#   PROFILE=dir samples the 3 busiest threads afterwards (psample, 10 s each,
#   one after another: in parallel one of them came back empty) into
#   dir/thread-<tid>.txt.
# Needs padpress, fbprobe, fbshot and psample in /home/player/ports/lcs/glos/testing/
# on the console
# Don't touch the controls while it runs.
set -eu
cd "$(dirname "$0")/../.."
binary=${1:-LCSNative}
[ $# -gt 0 ] && shift
out=$(mktemp)
tp=''
rot=''
hops=''
if [ -n "${TELEPORT:-}" ]; then
    # (no `set --` here: the script's own arguments are the env assignments for the launch)
    hops=$(python3 -c 'import struct, sys, math
t = sys.argv[1].split(); s = sys.argv[2].split()
sx, sy, sz = map(float, t[:3]); h = math.radians(float(t[3]) if len(t) > 3 else 180)
dx, dy, n = float(s[0]), float(s[1]), int(s[2])
for k in range(1, n + 1):
    x, y = sx + dx * k, sy + dy * k
    m = (math.cos(h), -math.sin(h), 0, 0, math.sin(h), math.cos(h), 0, 0, 0, 0, 1, 0, x, y, sz, 1)
    print("\x27" + "".join("\\%03o" % b for b in struct.pack("<16f", *m)) + "\x27")' "$TELEPORT" "${SWEEP:--40 0 5 2}" | tr '\n' ' ')
    sweep_interval=$(echo "${SWEEP:--40 0 5 2}" | awk '{print $4}')
fi
if [ -n "${TELEPORT:-}" ]; then
    tp=$(python3 -c 'import struct, sys, math
x, y, z = map(float, sys.argv[1:4]); h = math.radians(float(sys.argv[4]) if len(sys.argv) > 4 else 180)
m = (math.cos(h), -math.sin(h), 0, 0, math.sin(h), math.cos(h), 0, 0, 0, 0, 1, 0, x, y, z, 1)
t = math.atan2(-math.sin(h), math.cos(h))
print("".join("\\%03o" % b for b in struct.pack("<16f", *m)), "".join("\\%03o" % b for b in struct.pack("<ff", t, t)))' $TELEPORT)
    rot=${tp#* }; tp=${tp%% *}
fi
GLOS_TIMEOUT=900 python3 -I console.py "/usr/local/bin/appctl stop-application; sleep 3
cd /home/player/ports/lcs
sed 's|\./LCSNative --game|./$binary --game|' ${START:-start.sh} > start.bench.sh; chmod +x start.bench.sh
/usr/local/bin/appctl launch-application \"cd /home/player/ports/lcs && env LCS_FPS_LOG=1 $* ./start.bench.sh\"
sleep 25; i=0
while [ \$i -lt 90 ]; do set -- \$(/home/player/ports/lcs/glos/testing/fbprobe 494 82 126 12); [ \$2 -gt \$((\$1 + 15)) ] && [ \$2 -gt \$((\$3 + 15)) ] && break; /home/player/ports/lcs/glos/testing/padpress a 120; sleep 1.2; i=\$((i + 1)); done
echo \"in gameplay after \$i presses\"; sleep 5
if [ -n \"$tp\" ]; then p=\$(pidof $binary); m=\$(grep -m1 psprecomp-vram /proc/\$p/maps | cut -d- -f1); base=\$((0x\$m - 0x04000000)); h=\$(dd if=/proc/\$p/mem bs=4 skip=\$(( (base + 0x09947754) / 4 )) count=1 2>/dev/null | hexdump -v -e '1/4 \"%08x\"'); if [ \"\$h\" = 42c80000 ]; then a=0; while [ \$a -lt 3 ]; do printf '$tp' | dd of=/proc/\$p/mem bs=1 seek=\$((base + 0x099476f0)) conv=notrunc 2>/dev/null; printf '$rot' | dd of=/proc/\$p/mem bs=1 seek=\$((base + 0x09947bd0)) conv=notrunc 2>/dev/null; echo teleported; sleep 5; k=0; while [ \$k -lt 5 ]; do /home/player/ports/lcs/glos/testing/padpress l 600; sleep 3; cf=\$(dd if=/proc/\$p/mem bs=16 skip=\$(( (base + 0x08b7cab0) / 16 )) count=1 2>/dev/null | hexdump -v -e '3/4 \"%08x \"'); case \$cf in bf7*) break;; esac; k=\$((k + 1)); done; case \$cf in bf7*) break;; esac; a=\$((a + 1)); done; case \$cf in bf7*) echo camera facing street: front \$cf after \$((k + 1)) L presses, attempt \$((a + 1));; *) echo camera NOT facing street: front \$cf;; esac; sleep 3; else echo \"no teleport: player slot health word reads \$h\"; fi; fi
p=\$(pidof $binary)
for t in /proc/\$p/task/*; do echo \"\$(basename \$t) \$(cut -d' ' -f14,15 \$t/stat)\"; done > /dev/shm/bench.a
n0=\$(wc -l < /dev/shm/lcs.log)
if [ -n \"$hops\" ]; then (for m in $hops; do sleep $sweep_interval; printf \"\$m\" | dd of=/proc/\$p/mem bs=1 seek=\$((base + 0x099476f0)) conv=notrunc 2>/dev/null; done) & fi
sleep 12; wait
for t in /proc/\$p/task/*; do echo \"\$(basename \$t) \$(cut -d' ' -f14,15 \$t/stat)\"; done > /dev/shm/bench.b
tail -n +\$((n0 + 1)) /dev/shm/lcs.log | grep 'glos: FPS' | awk '{f+=\$3; d+=\$5; g+=\$7; n++} END {if (n) printf \"fps %.1f  psp draws/frame %.0f  gl draws/frame %.0f  (%d samples)\\n\", f/n, d/n, g/n, n; else print \"no frames logged\"}'
paste /dev/shm/bench.a /dev/shm/bench.b | awk '{u=(\$5+\$6)-(\$2+\$3); if (u > 100) printf \"thread %s %d%%  \", \$1, u/10} END {print \"\"}'
echo \$((\$(cat /sys/class/thermal/thermal_zone0/temp) / 1000)) C
if [ -n \"${PROFILE:-}\" ]; then
    set -- \$(paste /dev/shm/bench.a /dev/shm/bench.b | awk '{print (\$5+\$6)-(\$2+\$3), \$1}' | sort -rn | head -3 | awk '{print \$2}')
    for t in \$1 \$2 \$3; do /home/player/ports/lcs/glos/testing/psample \$t 10 250 1500 > /dev/shm/prof.\$t.txt; done
    for t in \$1 \$2 \$3; do echo PROFILE \$t; cat /dev/shm/prof.\$t.txt; done
fi" > "$out" || true
sed '/PROFILE [0-9]* *$/,$d' "$out"
[ -n "${PROFILE:-}" ] && tr -d '\r' < "$out" | awk -v dir="$PROFILE" '/PROFILE [0-9]+ *$/ {f = dir "/thread-" $NF ".txt"; next} f {print > f}'
rm -f "$out"
if [ -n "${SHOT:-}" ]; then
    GLOS_TIMEOUT=120 python3 -I console.py "echo BEGIN; /home/player/ports/lcs/glos/testing/fbshot 2 | gzip | base64; echo END" |
        sed -n '/^BEGIN/,/^END/p' | sed '1d;$d' | tr -d '\r' | base64 -D | gunzip |
        python3 -I -c 'import sys, zlib, struct
d = sys.stdin.buffer.read(); h = d.split(b"\n", 3); w, ht = map(int, h[1].split()); px = h[3]
raw = b"".join(b"\0" + px[y*w*3:(y+1)*w*3] for y in range(ht))
c = lambda t, b: struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b))
sys.stdout.buffer.write(b"\x89PNG\r\n\x1a\n" + c(b"IHDR", struct.pack(">IIBBBBB", w, ht, 8, 2, 0, 0, 0)) + c(b"IDAT", zlib.compress(raw)) + c(b"IEND", b""))' > "$SHOT"
fi
python3 -I console.py "/usr/local/bin/appctl stop-application" >/dev/null
python3 -I console.py "rm -f /home/player/ports/lcs/start.bench.sh" >/dev/null 2>&1 || true
