#!/bin/sh
# Profile-guided optimisation for LCSNative.
#   1. PGO=generate ./build.sh && ./package.sh
#   2. tools/pgo.sh train     installs the instrumented build as LCSNative.pgo,
#      runs the intro cutscenes and ~60 s of gameplay (padpress, as the
#      gameplay benchmark; don't touch the controls), then SIGUSR1 makes it
#      write its profile, which is fetched into pgo/ over MTP
#   3. PGO=use ./build.sh && ./package.sh   (use is the default once pgo/ has a profile)
# Re-train after big code changes; a stale profile still builds, just helps less.
# Per-file retrain (a changed host source loses its profile; everything else
# keeps it): PGO_FILES="ge_renderer.cpp" ./build.sh && ./package.sh, then
# MERGE=1 tools/pgo.sh train (keeps pgo/, overwrites only the files the
# instrumented build wrote), then ./build.sh && ./package.sh. About 10 minutes.
set -eu
HERE=$(cd "$(dirname "$0")/.." && pwd)
ROOT=$(cd "$HERE/../goodluckOS-tools" && pwd)
# BUILD_DIR=<dir> (see build.sh): the package in <dir>.out, the profile in <dir>.pgo.
B=${BUILD_DIR:-build}
if [ "$B" = build ]; then OUT=${OUT_DIR:-out}; PGO_DIR=${PGO_DIR:-pgo}; else OUT=${OUT_DIR:-$B.out}; PGO_DIR=${PGO_DIR:-$B.pgo}; fi
console() { (cd "$ROOT" && GLOS_TIMEOUT=${T:-60} python3 -I console.py "$1"); }

# PGO_TELEPORT="x y z [heading]" adds 60 s on the street after the 60 s in
# the safehouse, so the traffic, ped and streaming code gets a profile too.
# Default: the street benchmark spot (1138.85 -611.62 15.3 270); that profile
# measured 27.5 / 27.4 against 26.0 / 25.9 for the safehouse-only one on
# 2026-10-29. PGO_TELEPORT=none trains in the safehouse only. LCS-specific:
# the player ped's matrix, rotation and health addresses of this EBOOT, as
# in gameplay-bench.sh.
PGO_TELEPORT=${PGO_TELEPORT:-1138.85 -611.62 15.3 270}
[ "$PGO_TELEPORT" = none ] && PGO_TELEPORT=''
street=''
if [ -n "$PGO_TELEPORT" ]; then
    tp=$(python3 -c 'import struct, sys, math
x, y, z = map(float, sys.argv[1:4]); h = math.radians(float(sys.argv[4]) if len(sys.argv) > 4 else 180)
m = (math.cos(h), -math.sin(h), 0, 0, math.sin(h), math.cos(h), 0, 0, 0, 0, 1, 0, x, y, z, 1)
t = math.atan2(-math.sin(h), math.cos(h))
print("".join("\\%03o" % b for b in struct.pack("<16f", *m)), "".join("\\%03o" % b for b in struct.pack("<ff", t, t)))' $PGO_TELEPORT)
    rot=${tp#* }; tp=${tp%% *}
    street="p=\$(pidof LCSNative.pgo); m=\$(grep -m1 psprecomp-vram /proc/\$p/maps | cut -d- -f1); base=\$((0x\$m - 0x04000000)); h=\$(dd if=/proc/\$p/mem bs=4 skip=\$(( (base + 0x09947754) / 4 )) count=1 2>/dev/null | hexdump -v -e '1/4 \"%08x\"'); if [ \"\$h\" = 42c80000 ]; then printf '$tp' | dd of=/proc/\$p/mem bs=1 seek=\$((base + 0x099476f0)) conv=notrunc 2>/dev/null; printf '$rot' | dd of=/proc/\$p/mem bs=1 seek=\$((base + 0x09947bd0)) conv=notrunc 2>/dev/null; echo teleported for training; sleep 5; /home/player/ports/gtalcs-psp/glos/testing/padpress l 600; sleep 55; else echo \"no teleport: health word \$h\"; fi"
fi

case "${1:-}" in
train)
    tmp=$(mktemp -d)
    cp "$HERE/$OUT/gtalcs-psp/LCSNative" "$tmp/LCSNative.pgo"
    console "/usr/local/bin/appctl stop-application; rm -f /home/player/LCSNative.pgo /home/player/lcspgo.tar"
    pkill -9 -x ptpcamerad 2>/dev/null || true  # macOS claims the console's MTP interface after the first transfer
    (cd "$ROOT" && python3 -I mtp_send.py / "$tmp/LCSNative.pgo" | tail -1)
    # MTP fails silently when macOS's ptpcamerad or Photos holds the console; check before training.
    if ! console "ls /home/player/LCSNative.pgo" | grep -q LCSNative.pgo; then
        echo "pgo.sh: LCSNative.pgo did not reach the console (MTP busy? quit Photos / kill ptpcamerad)" >&2; rm -rf "$tmp"; exit 1
    fi
    T=600 console "cd /home/player/ports/gtalcs-psp && mv /home/player/LCSNative.pgo . && chmod +x LCSNative.pgo && rm -rf /dev/shm/lcspgo
sed 's|\./LCSNative --game|./LCSNative.pgo --game|' start.sh > start.bench.sh; chmod +x start.bench.sh
/usr/local/bin/appctl launch-application 'cd /home/player/ports/gtalcs-psp && ./start.bench.sh'
sleep 40; i=0
while [ \$i -lt 120 ]; do set -- \$(/home/player/ports/gtalcs-psp/glos/testing/fbprobe 494 82 126 12); [ \$2 -gt \$((\$1 + 15)) ] && [ \$2 -gt \$((\$3 + 15)) ] && break; /home/player/ports/gtalcs-psp/glos/testing/padpress a 120; sleep 2; i=\$((i + 1)); done
echo \"in gameplay after \$i presses\"; sleep 60
$street
kill -USR1 \$(pidof LCSNative.pgo); sleep 20; pidof LCSNative.pgo && echo 'still running?'
ls /dev/shm/lcspgo | wc -l; du -sh /dev/shm/lcspgo
cd /dev/shm/lcspgo && tar cf /home/player/lcspgo.tar . && ls -la /home/player/lcspgo.tar; rm -f /home/player/ports/gtalcs-psp/LCSNative.pgo /home/player/ports/gtalcs-psp/start.bench.sh"
    pkill -9 -x ptpcamerad 2>/dev/null || true
    (cd "$ROOT" && python3 -I -c "import sys; sys.path.insert(0, '$ROOT'); sys.argv = ['mtp_get.py', 'lcspgo.tar', '$tmp/lcspgo.tar']; import mtp_get; mtp_get.main()" | tail -1)
    if ! [ -s "$tmp/lcspgo.tar" ]; then
        echo "pgo.sh: profile tar did not arrive over MTP; pgo/ left as it was" >&2; rm -rf "$tmp"; exit 1
    fi
    if [ -z "${MERGE:-}" ]; then rm -rf "${HERE:?}/$PGO_DIR"; fi
    mkdir -p "$HERE/$PGO_DIR"
    tar xf "$tmp/lcspgo.tar" -C "$HERE/$PGO_DIR"
    console "rm -f /home/player/lcspgo.tar"
    rm -rf "$tmp"
    echo "$(ls "$HERE/$PGO_DIR" | grep -c gcda) profile files in $PGO_DIR/ ($(du -sh "$HERE/$PGO_DIR" | cut -f1))"
    ;;
*)
    sed -n 2,9p "$0"
    exit 2
    ;;
esac
