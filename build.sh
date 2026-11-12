#!/bin/sh
# Cross-build LCSNative for goodluckOS (armhf, Cortex-A7) in Docker.
#   ./build.sh            configure (first time) and build into build/
#   PGO=use ./build.sh    profile-guided build with the profile in pgo/
#   PGO=generate ./build.sh   instrumented build; run it (tools/pgo.sh), it
#                         writes its profile to /dev/shm/lcspgo on the console
#   PGO_FILES="ge_renderer.cpp lcs_ge_exec.cpp" ./build.sh
#                         per-file retrain: a PGO=use build in which only the
#                         named host sources are instrumented (one compile and
#                         a link, not a full rebuild); then MERGE=1 tools/pgo.sh
#                         train, then a plain ./build.sh picks the new profile up
# JOBS=<n> parallel compiles (default 8; the instrumented builds of the big
# generated units need ~1 GB each). Changing PGO rebuilds everything. The
# default is PGO=use when the profile directory has a profile, otherwise none.
# BUILD_DIR=<dir> (default build) builds in another directory, so a second
# candidate can compile while the first one is benched; its profile lives in
# <dir>.pgo and its package in <dir>.out (PGO_DIR, OUT_DIR override). The
# profile files carry the build directory in their names, so a profile
# trained in build-b/ is committed to pgo/ by renaming "#w#build-b#" to
# "#w#build#".
# Generated-code fast paths are on: no guest write watch, no dispatch
# counters (debug features only switched on by PSPRECOMP_* variables).
# upstream/ is elmasas/lcs-recomp at $COMMIT with patches/ applied.
set -eu
cd "$(dirname "$0")"
COMMIT=1132a76
if [ ! -d upstream ]; then
    git clone https://github.com/elmasas/lcs-recomp upstream
    git -C upstream checkout -q "$COMMIT"
    # Generated patches over 40 MB are stored xz-compressed (GitHub file size limit).
    for p in patches/[0-9]*; do case $p in *.xz) xz -dc "$p" | git -C upstream apply;; *) git -C upstream apply "../$p";; esac; done
fi
B=${BUILD_DIR:-build}
if [ "$B" = build ]; then PGO_DIR=${PGO_DIR:-pgo}; else PGO_DIR=${PGO_DIR:-$B.pgo}; fi
if [ -z "${PGO:-}" ]; then
    if ls "$PGO_DIR"/*.gcda >/dev/null 2>&1; then PGO=use; else PGO=off; fi
fi
case "$PGO" in
    generate) flags="-fprofile-generate=/dev/shm/lcspgo -DLCS_PGO_GENERATE" ;;
    # Code that changed since the profile was taken just goes unprofiled.
    # -fprofile-correction: the game's threads update shared counters without
    # locking, so some counts come out slightly inconsistent.
    use) flags="-fprofile-use=/w/$PGO_DIR -fprofile-correction -fprofile-partial-training -Wno-missing-profile -Wno-coverage-mismatch" ;;
    off) flags="" ;;
    *) echo "PGO must be generate, use or off"; exit 2 ;;
esac
pgo_files=$(echo "${PGO_FILES:-}" | tr ' ' ';')
# IDENTITY=0 (default 1): without the PSP's memory mapped at its own addresses
# (guest address = host address, see GuestMemory; the executable is then
# linked at 0x10000000, clear of the scratchpad, VRAM and RAM).
link=''
if [ "${IDENTITY:-1}" = 1 ]; then flags="$flags -DPSPRECOMP_FASTMEM_IDENTITY"; link='-Wl,-Ttext-segment=0x10000000'; fi
gen_opt=${GEN_OPT:-3}  # GEN_OPT=2: generated units at -O2 (see lcs/CMakeLists.txt; -O3 measured faster)
[ -n "$pgo_files" ] && [ "$PGO" != use ] && { echo "PGO_FILES needs PGO=use (a profile in $PGO_DIR/)"; exit 2; }
echo "PGO=$PGO${pgo_files:+ PGO_FILES=$pgo_files} BUILD_DIR=$B PGO_DIR=$PGO_DIR"
docker buildx build --load -t lcs-recomp-builder . >/dev/null
# One build at a time: a build left running (e.g. after Ctrl-C) is stopped.
# One build per directory at a time: a build left running (e.g. after Ctrl-C) is stopped.
name="lcs-recomp-build-$(basename "$PWD")-$B"
docker rm -f "$name" >/dev/null 2>&1 || true
docker run --rm --name "$name" -v "$PWD":/w -w /w lcs-recomp-builder sh -c "
    # Setting CMAKE_CXX_FLAGS replaces the toolchain file's *_FLAGS_INIT, so the
    # A33 flags (Cortex-A7, NEON, VFPv4) are passed here too. No fused
    # multiply-add contraction: float results stay as the PSP's (and x86's).
    # Not position-independent: PIE reserved a register for the GOT base in
    # every generated function and loaded the runtime's globals through it.
    A33='-mcpu=cortex-a7 -mtune=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard -ffp-contract=off -fno-pie'
    [ -f $B/build.ninja ] && [ \"\$(cat $B/.pgo 2>/dev/null)\" = '$PGO-a33c-$pgo_files-O$gen_opt-I${IDENTITY:-1}' ] ||
        cmake -S upstream -B $B -G Ninja \
            -DCMAKE_TOOLCHAIN_FILE=/w/toolchain-armhf.cmake \
            -DCMAKE_BUILD_TYPE=Release -DLCS_VULKAN=OFF -DPSPRECOMP_BUILD_TESTS=OFF \
            -DPSPRECOMP_AOT_ASSUME_NO_WRITE_WATCH=ON -DPSPRECOMP_AOT_PRODUCTION_FASTPATHS=ON \
            -DCMAKE_C_FLAGS=\"\$A33 $flags\" -DCMAKE_CXX_FLAGS=\"\$A33 $flags\" -DCMAKE_EXE_LINKER_FLAGS='-no-pie $link $flags' \
            -DLCS_PGO_GENERATE_FILES='$pgo_files' -DLCS_GENERATED_OPT=$gen_opt
    echo '$PGO-a33c-$pgo_files-O$gen_opt-I${IDENTITY:-1}' > $B/.pgo
    ninja -C $B -j${JOBS:-8} LCSNative"
file build/lcs/LCSNative
