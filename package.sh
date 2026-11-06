#!/bin/sh
# Package build/lcs/LCSNative for the console into out/lcs/ (BUILD_DIR=<dir>:
# <dir>/lcs/LCSNative into <dir>.out/lcs/, see build.sh; OUT_DIR overrides):
#   LCSNative (stripped, RUNPATH $ORIGIN/lib), lib/ (every library it needs
#   that goodluckOS doesn't have, listed in console-libs.txt), start.sh,
#   config/, lcs.puppy. The game files go in out/lcs/game/ on the console.
set -eu
cd "$(dirname "$0")"
B=${BUILD_DIR:-build}
if [ "$B" = build ]; then OUT=${OUT_DIR:-out}; else OUT=${OUT_DIR:-$B.out}; fi
rm -rf "$OUT" && mkdir -p "$OUT/lcs/lib"
docker run --rm -e B="$B" -e OUT="$OUT" -v "$PWD":/w -w /w lcs-recomp-builder sh -c '
set -eu
dirs="/usr/lib/arm-linux-gnueabihf /lib/arm-linux-gnueabihf"
always_system="libc.so.6 libm.so.6 libdl.so.2 libpthread.so.0 librt.so.1 libresolv.so.2 ld-linux-armhf.so.3"
todo="$B/lcs/LCSNative"; seen=""
while [ -n "$todo" ]; do
    set -- $todo; f=$1; shift; todo="$*"
    for so in $(arm-linux-gnueabihf-readelf -d "$f" | sed -n "s/.*NEEDED.*\[\(.*\)\]/\1/p"); do
        case " $seen " in *" $so "*) continue ;; esac
        seen="$seen $so"
        case " $always_system " in *" $so "*) continue ;; esac
        # goodluckOS has these, but built without parts the Debian libraries
        # need (libcrypto has no ENGINE API), so they are bundled anyway.
        case " libssl.so.3 libcrypto.so.3 " in *" $so "*) ;; *)
            grep -qx "$so" console-libs.txt && continue ;; esac
        for d in $dirs; do
            if [ -e "$d/$so" ]; then
                cp -L "$d/$so" "$OUT/lcs/lib/"
                todo="$todo $OUT/lcs/lib/$so"
                break
            fi
        done
        [ -e "$OUT/lcs/lib/$so" ] || echo "MISSING: $so"
    done
done
arm-linux-gnueabihf-strip -o "$OUT/lcs/LCSNative" "$B/lcs/LCSNative"
arm-linux-gnueabihf-strip "$OUT"/lcs/lib/*.so*
patchelf --set-rpath "\$ORIGIN/lib" "$OUT/lcs/LCSNative"
for l in "$OUT"/lcs/lib/*; do patchelf --set-rpath "\$ORIGIN" "$l"; done
'
cp start.sh lcs.puppy icon.png "$OUT/lcs/"
# glos/: the driver set from goodluckOS-mali-driver (the port runs on a stock
# goodluckOS with nothing installed outside its folder) plus this port's own
# runtime extra, fbpan.so. glos/testing/ is not shipped (goodluckOS-tools/testing-sync.sh
# copies it over when a bench or profile needs it).
GLOS=../goodluckOS-mali-driver/glos
[ -d "$GLOS" ] || { echo "package.sh: $GLOS missing (goodluckOS-mali-driver/assemble-glos.sh); the port needs glos/ next to start.sh" >&2; exit 1; }
rm -rf "$OUT/lcs/glos" && mkdir -p "$OUT/lcs/glos/lib"
cp "$GLOS"/glos-gpu "$GLOS"/glos-gpu-switch "$GLOS"/mali.ko "$GLOS"/glos_fbfix.ko "$OUT/lcs/glos/" && cp "$GLOS"/lib/* "$OUT/lcs/glos/lib/"
cp glos/fbpan.so "$OUT/lcs/glos/"
mkdir -p "$OUT/lcs/config" && cp config/LCSNative.ini "$OUT/lcs/config/"
# Program variants seen so far, with the driver's binaries: made at startup
# (config/shader-cache/<key>.bin, LCS_GLES_SHADER_WARMUP / LCS_GLES_SHADER_CACHE).
if ls config/shader-cache/*.bin >/dev/null 2>&1; then
    mkdir -p "$OUT/lcs/config/shader-cache" && cp config/shader-cache/*.bin "$OUT/lcs/config/shader-cache/"
fi
ls "$OUT/lcs/lib" | wc -l; du -sh "$OUT/lcs" "$OUT/lcs/lib" "$OUT/lcs/LCSNative"
