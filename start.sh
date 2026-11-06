#!/bin/sh
# GTA Liberty City Stories (lcs-recomp) on goodluckOS, drawn with GLES 2 on
# ARM's Mali driver (glos-gpu). Game files (US v1.05, ULUS-10041):
# game/EBOOT.ELF (the disc's PSP_GAME/SYSDIR/BOOT.BIN) and game/PSP_GAME/.
# Logs to /dev/shm/lcs.log.
cd "$(dirname "$0")"
# Xbox-style positions (A = bottom), as in the GTA III/Vice City ports.
export SDL_GAMECONTROLLERCONFIG="1900c621474133362d4d422047616d00,GA36-MB Gamepad,a:b0,b:b1,x:b3,y:b2,back:b8,start:b9,guide:b8,leftshoulder:b4,rightshoulder:b5,lefttrigger:b6,righttrigger:b7,leftstick:b11,rightstick:b12,dpup:b13,dpdown:b14,dpleft:b15,dpright:b16,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux"
export PSPRECOMP_CONFIG="$PWD/config/LCSNative.ini"
export LCS_STICK_SCALE=1.5      # GA36-MB sticks reach only ~2/3 of the declared range
export LCS_STICK_DEADZONE=0.12  # radial; the sticks rest up to 9% off centre after scaling
# The game's timer follows real time: with the guest clock in whole vblanks
# it simulated 33 or 50 ms per frame while the frames took ~38 (uneven motion).
export LCS_SMOOTH_CLOCK=1
# Meshes under 8 pixels on screen are not drawn (4: street 26 -> 30 fps, no
# visible difference), and frames are capped at 30 so the rate stays even.
export LCS_GLES_MIN_PIXELS=8
export LCS_FPS_CAP=30
# The game draws to /dev/fb0 through EGL. goodluckOS's SDL has no dummy video
# driver, so this makes SDL video fail on purpose (KMSDRM would take the
# display); the game then uses SDL for controller input and audio only.
export SDL_VIDEODRIVER=dummy
# No GE decode worker: on 4 cores its job hand-offs and spinning cost more than
# the decoding it takes off the GE thread (21.2 fps against 19.2).
export PSPRECOMP_GE_DECODE_THREADS=0
# No CPU transform of small draws: the GPU does them (about +0.5 fps since the
# off-screen culling left fewer draws to merge).
export LCS_GLES_PRETRANSFORM_MAX=0
# glos/fbpan.so hands the framebuffer pan that ARM's EGL does in
# eglSwapBuffers to a helper thread: on sun4i-drm's fbdev the pan waits for
# the vblank (~8 ms a frame). LCS_FBPAN_SYNC=1 makes it synchronous again.
export LD_PRELOAD=$PWD/glos/fbpan.so
exec ./glos/glos-gpu run mali ./LCSNative --game game "$@" >/dev/shm/lcs.log 2>&1
