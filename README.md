# glOSports-gtalcs-psp — GTA Liberty City Stories, native, on the GA36-MB

[lcs-recomp](https://github.com/elmasas/lcs-recomp) recompiles the PSP game's
MIPS code ahead of time into C++ (no JIT) on top of the psprecomp runtime,
with its own renderer for the PSP's graphics chip. This repo builds it for
goodluckOS on the GA36-MB (Allwinner A33, 4× Cortex-A7 at 1.2 GHz, Mali-400
MP2 on ARM's closed driver), as a self-contained game folder.

Needs the **US v1.05 release (ULUS-10041)**: the code was generated from that
exact binary (the EU v2.00 does not work). `game/EBOOT.ELF` is the disc's
`PSP_GAME/SYSDIR/BOOT.BIN` (the unencrypted `EBOOT.BIN`), plus the disc's
`PSP_GAME/` folder.

Where it stands: 28–29 fps driving with dips to 18–20 in draw bursts,
27.7–28.6 standing on a busy street, about 29.5 in the safehouse; the game's
own cap is 30. It started at 0.5 fps (software rasterizer) and 6.6 (first GLES
2 version). Patches 0042–0043 (2026-11-06: VFPU compile-time forms, cheaper
store bookkeeping) run on a retrained profile: a tie on the street
benchmark, where the draw work sets the pace; not measured while driving,
where the game thread does (no driving A/B was run).

## Game files

From the US v1.05 UMD (ULUS-10041), into `/home/player/ports/gtalcs-psp/game/`:

| Path | From the disc | Needed |
|---|---|---|
| `EBOOT.ELF` | `PSP_GAME/SYSDIR/BOOT.BIN`, renamed (SHA-256 `f57b9ae4fc764a78c5eba8c44b2c8f979e96e9e7c72c095650c493ccc5437e02`) | yes |
| `PSP_GAME/USRDIR/` | the whole folder (811 MB: `ANIM`, `AUDIO`, `CHK`, `DATA`, `ICONS`, `LUASCRIPTS`, `MODELS`, `MOVIES`, `PRX2_0_0`, `TEXT`, `TXD`, `ENTRIES.DAT`) | yes |
| `PSP_GAME/PARAM.SFO`, `ICON0.PNG`, `ICON1.PMF`, `PIC1.PNG`, `SND0.AT3` | the disc's top-level `PSP_GAME/` files | yes, as upstream asks for the whole `PSP_GAME/` |
| `PSP_GAME/SYSDIR/` | `BOOT.BIN`, `EBOOT.BIN`, `UPDATE/` | kept as part of the whole folder; not tested without it (VCS runs without its own) |

`game/PSP/SAVEDATA/` (the saves) is created by the game.

## The game folder on the console (`/home/player/ports/gtalcs-psp/`)

| | |
|---|---|
| `LCSNative` | the game (stripped, RUNPATH `$ORIGIN/lib`) |
| `lib/` | every library it needs that goodluckOS lacks: Debian's FFmpeg with its codec libraries (105 MB) and OpenSSL (goodluckOS's libcrypto has no ENGINE API); `console-libs.txt` is the list of what the console has |
| `config/LCSNative.ini` | the port's configuration (below) |
| `config/shader-cache/` | the GPU driver's binaries of every shader variant seen so far, loaded at startup (20 ms instead of 800 ms of compiling); shipped, so a fresh install starts warm; grows as the game meets new variants |
| `game/` | the game files; `game/PSP/SAVEDATA/` the saves (never touched by tooling) |
| `glos/` | the ARM driver set from `goodluckOS-mali-driver` plus this port's `fbpan.so` |
| `start.sh` | sets the environment and ends with `exec ./glos/glos-gpu run mali ./LCSNative --game game` |
| `icon.png`, `~/.local/share/applications/gtalcs-psp.puppy` | the launcher entry |

## Repo layout

| Path | What |
|---|---|
| `build.sh` | Clones lcs-recomp at `1132a76` into `upstream/`, applies `patches/`, cross-compiles `LCSNative` in Docker (Debian bookworm, GCC 12). `build/` is kept: later builds are incremental. |
| `package.sh` | `out/gtalcs-psp/`: the stripped binary, `lib/`, `start.sh`, `config/`, `gtalcs-psp.puppy`, `glos/` (from `../goodluckOS-mali-driver/glos` + `glos/fbpan.so`). |
| `patches/` | `0001`–`0050`, every change to upstream, applied in order. A kept change is a new patch (`tools/mkpatch.sh NNNN-name <files under upstream>`) and an entry in this README. |
| `config/` | `LCSNative.ini` and the shader cache. |
| `pgo/` | the profile for profile-guided optimisation (trained in the safehouse and on the street). |
| `start.sh`, `gtalcs-psp.puppy`, `icon.png` | as shipped (the icon is a crop of the game's own `PIC1.PNG`). |
| `glos/fbpan.so` | runtime extra, see "Rendering". `glos/testing/`: console-side tools, copied over only when a bench needs them (`../goodluckOS-tools/testing-sync.sh gtalcs-psp`), removed with `testing-clean.sh gtalcs-psp`; never shipped. |
| `tools/` | Mac-side scripts (benches, profiling, training, patch making, the VFPU lowering and its test, the profile ranking) and `tools/src/fbpan.c` (`tools/build-tools.sh` builds `glos/fbpan.so`). The console-side test tools are shared, in `goodluckOS-tools/testing/`. |
| `candidates/` | changes that were built and measured and not kept, as patches, with the numbers in "Tried and dropped". |
| `docs/` | an outside review (2026-10-28) and profile samples. |

## Build, package, deploy

```sh
./build.sh && ./package.sh           # PGO=use by default once pgo/ has a profile
```
Deploy: `python3 ../goodluckOS-tools/mtp_send.py / out/gtalcs-psp/LCSNative`, then over the console
`mv /home/player/LCSNative /home/player/ports/gtalcs-psp/LCSNative` (MTP never
overwrites, hence send-then-move). A first install copies all of `out/gtalcs-psp/`
and the launcher entry, then the game files.

`JOBS=<n>` (default 8; the instrumented builds of the big generated units
need ~1 GB each, `-O3` ~1.5 GB: `JOBS=6` for those). `BUILD_DIR=<dir>` builds
a second candidate in its own directory (profile in `<dir>.pgo`, package in
`<dir>.out`) while the first is benched.

Profile-guided optimisation (about 12% faster; the profile is committed):
- Full retrain (~27 min): `PGO=generate ./build.sh && ./package.sh &&
  tools/pgo.sh train && ./build.sh && ./package.sh`. Training installs the
  instrumented build as `LCSNative.pgo`, plays the intro, 60 s in the
  safehouse and 60 s on the street (`PGO_TELEPORT`, default the benchmark
  spot; `none` for the safehouse only; the street part is worth 1.5 fps
  there), then fetches the profile over MTP.
- Per-file retrain (~10 min) after changing a host source: a changed function
  loses its profile and gets slower (about 3 fps for a GE file), so
  `PGO_FILES="ge_renderer.cpp" ./build.sh && ./package.sh && MERGE=1
  tools/pgo.sh train && ./build.sh && ./package.sh`: only the named files are
  recompiled instrumented and only their profile files replaced.
- `build.sh` passes the A33 flags (`-mcpu=cortex-a7 -mfpu=neon-vfpv4`)
  together with the PGO flags (setting `CMAKE_CXX_FLAGS` replaces the
  toolchain file's), `-ffp-contract=off` (float results as the PSP's), non-PIE
  (PIE reserved a register for the GOT in every generated function), the
  generated units `-O3 -fno-exceptions -fno-unwind-tables`; units 0061–0063
  `-marm` (Thumb-2 branches out of range under PGO).

## Configuration

`config/LCSNative.ini` (changes from upstream): `Backend=GLES2`; internal
resolution 480×360 (the 4:3 view scaled uniformly 1.33× to the 640×480
screen; the PSP's 480×272 was 1.76× vertically; native 640×480 runs at 20,
GPU-bound); fullscreen; widescreen on (the game's view is 4:3, so the frame
fills the screen); `HudScale=1.0`; `ShowFPS=true` (the FPS counter, top left, drawn as the Android ports do); **VSync off** (the render
thread would wait ~8 ms a frame); **`[Timing] FrameRate=60`** with the hook
that unlocks the game's own limiter: that limiter waits two 60 Hz vblanks, so
a 34 ms frame would cost 50 (a 28 fps scene becomes 20).

`start.sh` sets (all read by the game only):

| Variable | Value | Why |
|---|---|---|
| `SDL_GAMECONTROLLERCONFIG` | GA36-MB mapping | Xbox-style positions (A = bottom), as the GTA ports |
| `SDL_VIDEODRIVER=dummy` | | goodluckOS's SDL has only KMSDRM, which would take the display; SDL is used for the controller and audio only (patch 0003) |
| `PSPRECOMP_GE_DECODE_THREADS=0` | | upstream's decode worker cost ~2 fps on 4 cores (hand-offs and spinning) |
| `LCS_GLES_PRETRANSFORM_MAX=0` | | CPU transform of small draws splits the GPU's sequential runs now |
| `LCS_STICK_SCALE=1.5` | | the GA36-MB's sticks reach 43–213 of the 0–255 its gamepad driver declares |
| `LCS_SMOOTH_CLOCK=1` | | the game's timer follows real time (0044; see "Frame pacing") |
| `LCS_GLES_MIN_PIXELS=8` | | meshes under 8 pixels on screen are not drawn (0045; see "Lower detail") |
| `LCS_FPS_CAP=30` | | an even 30 instead of swinging up to 40 in light scenes |
| `LCS_STICK_DEADZONE=0.12` | | radial (keeps the push's angle; a per-axis dead zone made the stick feel like eight directions); the sticks rest up to 9% of full deflection off centre after scaling, so this is about as small as it can be |
| `LD_PRELOAD=glos/fbpan.so` | | asynchronous framebuffer pan, see "Rendering" |

Optional: `LCS_FPS_LOG=1` (per-second line in `/dev/shm/lcs.log`: fps, PSP and
GL draws, KB of vertices/indices/textures, culled draws, merge-loop breaks,
prescan time, the game clock against real time and the game thread's GE
waits); `LCS_FPS_CAP=<n>` (a cap inside the vblank wait, costs nothing, never exceeded after a dip; off:
light streets run up to 40); `LCS_GLES_SCALE=<percent>` (render scale,
diagnostic); `LCS_GLES_SHADER_CACHE=0` / `LCS_GLES_SHADER_WARMUP=0`;
`LCS_GLES_TEXTURE_RECHECK=1` (re-hash textures every frame instead of every
4th); `LCS_SAS_WORKER=0`, `LCS_ATRAC_WORKER=0` (audio back on the game
thread if it ever misbehaves); `LCS_FRAME_LOG=1` (a line per vblank wait in
`/dev/shm/lcs-frames.csv`: real time, guest clock at the wait and at resume,
vblank count, timer offset, display lists, the first value of each timer call
since the last wait, and the game's own clock: `CTimer`'s milliseconds and
time step, guest `0x08B5E02C`/`0x08B5E030`); `LCS_GLES_STRIP_RUNS=0`,
`LCS_GLES_CONST_ATTRIBS=0`, `PSPRECOMP_GE_GPU_RAW=0`, `LCS_GLES_VBO=2`,
`LCS_GLES_TEXTURE_POOL=1`, `LCS_GLES_UPLOAD_THREAD=1`, `LCS_FBPAN_SYNC=1`,
`LCS_GE_LAYOUT_STATS=1` (A/B switches for the mechanisms below).

## Rendering and threads (patches 0005, 0017–0038)

A GLES 2 backend for the PSP's graphics chip (GE), for ARM's driver: EGL on
`/dev/fb0`, one render target (colour texture, depth renderbuffer, FBO) per
PSP framebuffer address, shader variants instead of per-pixel branches,
partial mip chains completed on the CPU. It starts only while `/dev/mali`
exists; otherwise the software rasterizer draws.

Threads: the **game** (the recompiled code, one guest thread at a time; its
display lists are handed to the GE thread and it waits for the previous one),
the **GE thread** (runs the display lists, collects a frame), the **transform
thread** (the merge loop: scissors, state keys, uniform blocks, the comparison
that joins consecutive draws, 16-bit index arrays), the **render thread** (owns
EGL/GL: one vertex upload per frame, merged GL draws, uniforms as two arrays
sent when changed), plus workers for SAS mixing, ATRAC decoding and disc
reads.

The things that made it fast, roughly in order of weight:
- Draws with hardware-transform layouts go to the GPU as the PSP stores them
  (positions, normals, UVs, colours, up to 8 weights, typed attributes with
  the PSP's own stride) and the vertex shader decodes, skins (weighted bone
  rows as 24 vec4 uniforms), lights with the PSP's model and generates UVs;
  per-draw state is one 64-vec4 uniform array. Shader variants are keyed by
  layout, lights and features (the Mali-400 vertex processor holds 512
  instruction words; the general variant with skinning was 706).
- Meshes entirely off screen are dropped before any per-draw work; the NEON
  bounds scan runs once per mesh while its memory is unwritten (every guest
  store bumps a 64 KB page generation, the change detector all caches use).
- Consecutive draws with the same state merge into one GL draw; one
  sequential run draws with `glDrawArrays`, merged strips joined by
  degenerate vertices (GL index copies: 135 → 8 a frame). About 1,100 GL
  draws remain for ~1,600 PSP draws: every GTA object has its own matrix and
  rarely reuses a texture within itself (a matrix palette was measured
  slower).
- Palette checksums cached per display list (GTA uses ~400 palettes a frame)
  and across lists while their pages are unchanged; textures re-hashed every
  4th frame; list words read straight from guest memory; a per-command class
  table in the list executor with revision counters the lighting and
  transform caches compare.
- `glos/fbpan.so`: ARM's EGL issues `FBIOPAN_DISPLAY` once per frame inside
  `eglSwapBuffers`, and sun4i-drm's fbdev pans with a synchronous atomic
  commit that waits for the vblank (8.5 ms a frame at 20 fps, VSync or not).
  The preload hands the pan to a helper thread (the latest pan wins).
  Measured 23.9/24.1 against 22.7/23.4.
- Program binaries: the driver supports `GL_OES_get_program_binary`, so each
  linked program is saved to `config/shader-cache/<key>.bin` (header: magic,
  format, length, hash of both sources plus renderer/version strings) and
  loaded with `glProgramBinaryOES`; the directory is also the warm-up list.
  Startup shader work 780–820 ms → 21 ms, and no first-encounter stalls in
  play. Precompiling every combination is impossible (about twenty
  independent key fields, millions of legal keys at 10–50 ms each); only
  running the game finds the few dozen it uses.

## The recompiled code (patches 0006, 0020–0022, 0028, 0030, 0033–0036)

The game thread runs the game's own traffic, ped and physics code at about
7.7 host instructions per guest instruction, with no block above 1% of the
profile, so the wins came from the generator and the call protocol:
- fastmem: guest RAM, the VRAM mirrors and the scratchpad in one reserved
  512 MB window, so a guest load is `base + (address & 0x1FFFFFFF)` with no
  range check (5 host instructions instead of 10 and a branch; 283,000
  slow-path call sites gone).
- VFPU prefixes folded at generation time (a prefixed `vsub` was 269 host
  instructions, now 14); NEON for the 3-lane vector ops, dot products, matrix
  transforms and the 16-byte loads/stores (163,840-case equivalence test
  against the scalar forms).
- Guest functions as host functions: 1,940 leaf functions and 3,478
  functions that make calls (44% of the game) are emitted as their own host
  functions and called directly from 41,954 `jal` sites, instead of entering
  a 16 KB unit through its entry switch (prologue 8 instructions against
  ~30); inside them the guest registers live in host locals (two dataflow
  passes, verified by an abstract interpreter over all 5,418 functions). The
  rest stays in the units: functions that share code, contain import stubs,
  straddle a unit boundary or are hooked.
- The cross-unit call protocol: one frame-address compare against a stack
  limit instead of a depth counter with a destructor guard, one countdown
  after the call, every unit with a local copy of the memory view so its
  pointers stay in registers across guest stores.
- `sceKernelLibcGettimeofday` and the audio poll without 64-bit divisions
  (GCC on 32-bit ARM calls libgcc for every one; 280,000 a second).
- SAS mixing and ATRAC3+ decoding on their own workers; the guest thread is
  parked in the scheduler when a ring is empty.
- VFPU operations with compile-time forms (0042). The generator passed
  literal registers to vcrsp/vqmul, vhdp, vuc2i/vc2i/vus2i/vs2i, vh2f, vf2h,
  vocp, vmin/vmax and vscmp/vsge/vslt, and emitted vmmul as two generic matrix
  reads, a scalar triple loop and a generic write: lane mapping in loops, every
  prefix through the lane-by-lane decoder and the masking writer, even with no
  prefix set. The PGO profile (`tools/pgo-hot.py`, below) put those generic
  helpers at about a third of the counted blocks of the game code, in the
  per-bone animation update (quaternion to matrix, vmmul with the parent),
  the ray/triangle collision test (five cross products per call) and the
  int16 keyframe decode. Now the registers are template parameters and,
  while no prefix is pending (checked at run time; GTA sets one only for the
  instruction right after it), no prefix work runs; vmmul is NEON. A pending
  prefix takes the generic form. 778 sites in the units (`tools/vfpu-lower.py`
  rewrites committed units, the generator's lowering pass emits the same
  text: a regeneration from the EBOOT matches the committed units in every
  VFPU form). `tools/vfpu-ct-test.py`: 334,400 random-register checks of
  every register combination the units use against the generic forms, bit
  for bit (any NaN equals any NaN: which payload a NaN carries depends on
  the operand order the compiler gives a commutative operation).
- Guest stores mark their 64 KB page in a byte table (0043) instead of
  bumping its generation (a load, an add and a store, a load-use chain on the
  same word for consecutive stores; 62,853 such sites, ~3% of the generated
  instructions). `fold_dirty_pages()` turns the marks into generation bumps
  at each display-list hand-over, where the GE thread is idle; its two caches
  (cull bounds, palette checksums) are the only readers of the generations.
## Frame pacing (0044)

At a similar frame rate the Android port felt less dippy. The guest clock
moves to the next vblank boundary at each vblank wait, and by whole skipped
vblanks when the game runs late, and the game takes its time step from it
(`sceKernelGetSystemTimeWide`, once a frame): measured with `LCS_FRAME_LOG`
standing at a save (25.9 fps), the frames took 38.5 ms ±4.3 but the game
simulated 33 or 50 ms (±8.6), so the world moved up to 30% too far in one
frame and 25% too little in the next. `LCS_SMOOTH_CLOCK=1` adds an offset to
what the game's timer calls return (`sceKernelGetSystemTime`/`Wide`/`Low`,
`sceKernelLibcClock`, the pad sample times), set at each vblank wait so that
the game resumes at the real time; within four vblanks (more is a stall: the
clocks are put level again) and never going back. The scheduler, the thread
delays, the audio and the vblank interrupt keep the guest clock. Same scene,
same fps: each step now equals the real time of the frame before it within
0.4 ms on average, no frame more than 20% off (without it 6.4 ms, 29% of the
frames). On in `start.sh`; in play it was no clear difference.

Does the game run in slow motion when the frames dip? `CTimer::Update`
(around guest `0x0891B654`) lets the game clock advance at most 60 ms a frame
and caps the time step at 3.333 (67 ms), so a frame over 60 ms loses game
time. A 2-minute drive through the streets with the frame log (3,242 frames,
27 fps mean, 17–22 fps for stretches of 2–5 s): the steps add up to the real
time within 0.1%, 43 frames went over 60 ms, and the cap cost 0.29 s of game
time in 120 s (0.24%). No slow motion: what plays as slowing down is the frame
rate itself. Frame times: median 36 ms, 29% over 40, 7.3% over 50, 1.3% over
60, the slowest 79 ms (one 141 ms frame as the save loaded). The game's
millisecond counter runs 2% behind (the game's code adds the frame's time in
whole milliseconds, dropping the fraction); motion uses the time step.
Raising the cap is not worth its physics risk for 0.24%.

## Lower detail (0045)

To hold 30 at some cost in detail (not resolution). Measured 2026-11-06 at
the player's save (night, rain):
- `LCS_GLES_MIN_PIXELS=<n>`: the renderer's off-screen test (the mesh's
  bounding box against the clip planes) also drops a mesh whose box lies
  wholly in front of the camera and projects to less than n pixels (of the
  PSP's 480×272) along both axes; perspective views only, so the HUD is
  untouched. Street benchmark: 26.2 fps at 1,699 PSP draws a frame without,
  30.0 at 1,093 with 4, 28.7 at 1,027 with 8 (more traffic in that run; the
  game thread at 85% now sets the pace). Moving along the street
  (`sweep-bench.sh`): 31.7 without, 33.7 with 4 (minimum 23.7 / 24.5); the
  second pair was cut short. Side by side
  screenshots of the street look the same.
- Ped and traffic limits (dropped): CPopulation's limits (25 and 40 in this
  EBOOT, guest `0x08B564DC`/`0x08B564E0`; AddToPopulation `0x08A9F178` caps
  groups × zone density × `PedDensityMultiplier` `0x08B564D0` at them) and
  CCarCtrl::GenerateRandomCars (`0x089EA1C0`), which compares the traffic
  count (`0x08B4BBD0`) with a literal 30, as switches: on the street and
  moving along it 6–15 peds and 0–7 traffic cars, under both limits, so they
  changed nothing (19 peds and 22 cars: 32.1 against 32.3 and 32.3; same
  draws), and the player sees no more than 5–12 cars at once.
- Dead end: scaling `TheCamera.LODDistMultiplier` (`0x08B83380`, `+224`)
  where CSimpleModelInfo's LOD lookups (`0x08A8C144`, `0x08A8C1D8`,
  `0x08A8C22C`) read it, to 0.5: same draws, same picture; the world's
  draw distance is decided elsewhere. Removed. (Upstream's `ViewDistance`
  only scales the vehicle LOD distances, upwards, in SetRslCamera
  `0x08926F98`.)
- Dead end: scaling the far clip and fog start CTimeCycle::Update
  (`0x089FA4E0`) writes each frame (`0x08B4C0A4`/`0x08B4C0A8`; 873 and 397 m
  at the save, night, rain) to 0.6 and 0.4: the far buildings stayed, the
  draws stayed (1,098 / 1,130 / 1,118), and at 0.4 cars lost their bodies
  (wheels only). Removed. Why: LCS draws its static world from streamed
  sectors, each instance kept by CCamera::IsSphereVisible alone (Android's
  cWorldStream::Render / Render(sGeomInstance) / IsSphereVisible: near and
  far clip, then the four frustum planes), so the far clip is the only
  distance, and on the streets everything in view is well inside even 350 m
  (buildings and fog close the view). A shorter draw distance removes nothing
  that costs time there.

## Benchmarks and profiling

`../goodluckOS-tools/testing-sync.sh gtalcs-psp` first (puts `glos/testing/` on the console); the
scripts assume the save in `game/PSP/SAVEDATA` (Toni standing in the
safehouse) and that the controls are not touched.

- `tools/gameplay-bench.sh [binary] [VAR=value…]`: launches, presses Cross
  (`padpress`, through uinput) until the HUD's money counter shows
  (`fbprobe`), measures 10 s: fps, PSP and GL draws per frame, each thread's
  CPU share. `TELEPORT="x y z heading"` moves Toni first (it writes the
  player ped's matrix and heading; this EBOOT: matrix at guest `0x099476f0`,
  rotation `0x09947bd0`, health `0x09947754`), presses L and waits 10 s for
  streaming. The street benchmark: `TELEPORT="1138.85 -611.62 15.3 270"`
  (south of the Portland hospital, looking west; ~1,600–1,700 PSP draws a
  frame; traffic is random, so its spread is twice the safehouse's ±0.7 fps:
  two A/B pairs per candidate, alternating). `SHOT=x.png`, `PROFILE=dir`.
- `tools/sweep-bench.sh`: the same with the player moved 40 m along the
  street every 2 s (motion proxy). `tools/drive-profile.sh`: you drive,
  it samples the busiest threads. `tools/drive-ab.sh`: binaries in turn,
  same route, fps, minimum and seconds under 22 over 30 s of driving; each
  game is stopped only once you have put the pad down for 5 s.
- `tools/psample-symbolise.py` names `psample` output against the unstripped
  `build/lcs/LCSNative` and the console's libraries (`docs/profiles/` has
  samples; profile the exact build you deployed).
- The FPS log also prints the game clock against real time: during the
  dips it stays within 1% of real, and the game thread is busy, not
  waiting, so frame skipping would gain nothing (not built).
- Without the console: `tools/pgo-hot.py [n]` ranks functions by the
  committed profile's counters (the training run's intro, safehouse and
  street: arc sums, so looping helpers look bigger than their time; names
  through GCC's CRC of the mangled name). `tools/vfpu-ct-test.py` checks the
  VFPU compile-time forms against the generic ones (native AArch64 in the
  builder image).

## Patches

| | |
|---|---|
| 0001–0004 | build: Vulkan optional, GLES 2 backend built; `file_clock::to_sys` for GCC 12; `LCS_FPS_LOG` and SDL input-only mode; aligned FFmpeg scaler destination (its NEON YUV→RGB needs 16-byte alignment, 32-bit malloc gives 8: the first movie died with an alignment trap) |
| 0005 | the GLES 2 GE backend; `Backend=GLES2` |
| 0006 | guest-memory loads/stores inline for main RAM |
| 0007 | `SIGUSR1` writes the PGO profile |
| 0008 | HUD squeezed for 4:3, palette checksums cached per list |
| 0009–0015 | strips kept as strips; off-screen meshes dropped (early); 32-bit texture hash; direct-mapped palette cache; palette hash over words; list words read from RAM and VRAM |
| 0016 | per-file PGO retrain |
| 0017–0019 | GE thread per-draw cost: transform built once, no backend mutex per draw, no 2.3 KB copies per draw, NEON cull scan, cached target size, per-command class table with revision counters, texture matrix fix, textures re-hashed every 4th frame |
| 0020–0022 | VFPU prefixes folded, `mul.s` without the inf·0 check, 32-bit chain countdown, fastmem |
| 0023 | prescan race fix (BASE/OFFSET read as one atomic pair) |
| 0024–0025 | GE per-draw work shared between consecutive draws; the raw vertex path (GPU decode, skinning, lighting, UV generation) |
| 0026 | the merge loop on the transform thread; keys instead of GL objects; `glDrawArrays` for sequential groups |
| 0027 | generated units at `-O3` |
| 0028 | no 64-bit divisions in the time and audio HLEs |
| 0029 | SAS and ATRAC workers |
| 0030 | cross-unit call protocol, local memory view |
| 0031 | merged strips as sequential runs, constant attributes once per frame |
| 0032 | the game thread's list prescan through one pointer, only with a GE finish callback registered |
| 0033–0035 | guest functions as host functions (leaves, then functions with calls), guest registers in host locals |
| 0036 | NEON for the VFPU |
| 0037 | internal 480×360; shader variants recorded and warmed |
| 0038 | program binary cache |
| 0039 | `LCS_FPS_CAP` inside the vblank wait; radial stick dead zone; game clock and GE waits in the FPS log |
| 0040 | `LCS_STICK_SCALE`, `LCS_STICK_DEADZONE` |
| 0041 | the 4:3 HUD squeeze picks the top or bottom edge by the centre of what the clip rectangle lets through, not the whole element (from `glOSports-gtavcs-psp`: radar tiles are rotated quads far larger than the radar, and by their whole extent some were squeezed towards the top at some camera angles, a strip of the map above the circle) |
| 0042 | VFPU compile-time forms: vcrsp/vqmul, vhdp, vx2i, vh2f, vf2h, vocp, vmin/vmax, vscmp/vsge/vslt with no prefix work while none is pending, vmmul in NEON, matrix moves with constant slots, the prefix-aware vtfm on 0036's NEON form while no prefix is pending, a plain write behind a zero destination prefix; the generator's lowering pass emits them (units rewritten by `tools/vfpu-lower.py`) |
| 0043 | guest stores mark pages in a byte table, folded into the page generations at each display-list hand-over |
| 0044 | `LCS_SMOOTH_CLOCK`: the game's timer reads follow real time, the scheduler keeps the guest clock; `LCS_FRAME_LOG` |
| 0045 | `LCS_GLES_MIN_PIXELS`: meshes smaller than that on screen are not drawn |
| 0046 | the FPS counter as the goodluckOS Android ports draw it: "28 fps", top left, 5×9 font at 2 pixels a dot, off-white with a dark shadow |
| 0047 | `LCS_FPS_CAP`: a frame that ran late starts the 1/n s grid again (it carried over, so after a dip frames ran above the cap to win the time back; with the smooth clock nothing is won back, as on the Android ports' cap) |
| 0048 | the FPS counter counts whole seconds (the log keeps its half seconds): presentation lags the game's frames by a varying few ms, and over half a second a capped 30 read 31 now and then |
| 0049 | `LCS_FPS_CAP` also paces the presents (no frame on screen sooner than 1/n s after the last, the grid restarted by a late one): frames queued in the GE and render threads during a dip reached the screen in a burst, 31–32 on the counter; street run after: no half second over 30.0, average 29.0 as before |
| 0050 | the on-foot follow camera's upward pitch stops at 0.27 rad (both copies of the pitch update, units 0059 and 0060, CCam +188): pushing the right stick up lowers the camera, and past about 0.45 rad it went below the pavement (1.9–2.7 m under the player in a camera log) and the game stopped updating the view for 2–6 s; the view never pitched up more than 0.27–0.30 anyway. The game's limit is 0.785, which only the port's right-stick camera reached |

## Progress (street benchmark unless noted)

| | fps |
|---|---|
| software rasterizer | 0.5 |
| first GLES 2 version | 6.6 (dirt road) |
| render thread, packed vertices decoded on the GPU | 11.5 |
| safehouse: PGO, guest-memory fast paths, palette cache, strips, culling, flags, decode worker off | 13.7 → 21.5 |
| GE thread work (0017–0019), generator (0020–0022) | safehouse 26–27.5 |
| street benchmark with 0023 | 19.4–23.5 |
| raw vertex path, `fbpan.so`, merge loop on the transform thread, `-O3`, audio workers, call protocol, strip runs (0024–0031) | 26–27 |
| profile trained on the street as well | 27.4–27.5; safehouse 29.5 |
| guest functions as host functions, registers in locals, NEON (0032–0036) | 29.1–29.5 (the cap) at 480×272 |
| internal 480×360 (0037) | 27.7–28.6; driving 28–29, dips 18–20 |
| VFPU compile-time forms, store marks (0042–0043), profile retrained | street: a tie (see below); driving: not measured |

Measured with the series of the time, 0042–0045 (its 0044 was the disc-read
worker, since dropped; see "Tried and dropped"), on a retrained profile
(2026-11-06; trained after loading the
player's save, then on the street) against 0041 on its own profile, street
benchmark, alternating: 0041 26.0 / 26.8 fps at 1,654 / 1,664 PSP draws a
frame, 0042–0045 25.0 / 25.5 at 1,749 / 1,694; then 0042–0045 with
`LCS_IO_WORKER=0` against itself: 25.1 / 26.5 at 1,737 / 1,651 off, 25.7 /
24.7 at 1,710 / 1,813 on. On this scene fps follows the traffic's draw count
(−1.05 fps per 100 draws over all eight runs); at equal draws 0042–0045 is
0.28 fps behind 0041, inside the spread (0041's own two runs: 0.8 apart), and
the disc-read worker makes no difference. Standing on the street the game
thread is 70–79% busy and the GE and render threads 82–95%: the draw work
sets the pace, so game-thread savings cannot show there; while driving the
game thread is the busy one, so only a driving A/B can show them
(`tools/drive-ab.sh`; not run).

What limits it now: while driving the game thread is 95% busy, 92% of that in
the generated code (no function above 1%), and every dip to 17–21 fps comes
with a draw burst of 1,700–2,250 a frame; the render thread is 40% ARM's
driver, 30% GPU waits. The GPU costs ~2.5 fps standing (half resolution: 28.6
→ 29.5) and more in bursts. A study of per-function emission estimated 15–17%
of game-thread time from it; stages 1–3 of it are patches 0033–0035.

Where the game thread's time goes by the PGO profile (2026-11-06, off the
console): the hottest generated functions are the per-bone animation
hierarchy update (0x0890D340, with its quaternion-to-matrix leaf 0x0891D0A8),
the ray/triangle test of the collision code (0x088CB680), the int16 keyframe
and vector decodes (vx2i + vi2f) and a few unit bodies of hooked functions
(0145, 0189, 0049): animation and collision grow with peds, traffic and
speed, the work of a driving dip. The generic VFPU helpers those used were
the largest single group (0042). The import calls are not a lever: per the
same profile they come from the intro movie's polling loops. What remains
in the units' bodies (functions with hand-made hooks, shared code or a unit
straddle, ~20% of the counted blocks) keeps its guest registers in memory;
moving those to function form needs the hooks in the generator.

## Tried and dropped

Each measured as an A/B against the build of the time, usually two pairs:
- Disc reads (sce_lbn handles) on a worker thread, the reader parked while
  another guest thread runs, disc files kept open, pread straight into guest
  memory (2026-11-06): on vs off 25.7 / 24.7 vs 25.1 / 26.5 on the street,
  no difference, and a moving-bench run with it froze (a 3 s stall, then the
  world stood still while frames kept coming). Dropped.
- Index buffer objects (`LCS_GLES_VBO=2`): slower, the driver's index-range
  scan of a buffer costs more than its copy of a client array. Packed
  vertices written straight into a mapped GPU buffer (`GL_OES_mapbuffer`):
  the driver copies at unmap, no change. Unrolling every draw into plain
  triangles: 12.8 fps. A matrix palette and draw sorting (30% fewer GL
  draws): 14.4 fps. Reordering effectively-opaque draws across texture
  changes with an exact rule: saves one GL draw a frame (`candidates/`).
- 16-bit texture uploads (half the bytes): slower standing (sampling), no
  effect on the dips (`candidates/`). A texture pool and an upload thread on
  a second EGL context: a wash; the dips are draw bursts, not uploads (in
  the code, opt-in).
- Upstream's GE decode worker: −2 fps; two workers worse. A cull-ahead
  thread, pinning threads to cores, pipeline depth 2, glibc malloc tunables,
  a bigger kernel copy buffer for small ioctls: no change. Handing work to
  another core keeps costing about what it saves here.
- Guest stores without the page-generation bump: the GE caches re-hash and
  re-scan, slower (`candidates/`). An inline fast path for dynamic `jalr`
  chains: slower in the huge unit functions (`candidates/`). Shadowing guest
  registers in locals per straight-line run inside the units: 1.4% fewer
  instructions, nothing to win (`candidates/gpr_cache.py`); GCC already
  keeps registers across a unit's CFG. `__restrict` on the generated
  functions: no better code.
- ATRAC decoded one frame ahead and the audio submit as one copy, on the
  game thread: slower (`candidates/`; the worker version in 0029 won).
  Audio read-ahead on its own thread (first version): slightly slower.
- CPU pretransform of draws up to 24 vertices (upstream's default): splits
  the sequential runs since 0025/0031, slower. Dropping off-screen meshes
  even earlier, VRAM fast paths, cached mesh bounding boxes (first version),
  a draw-state revision for upstream's descriptor cache, branch-free merge
  loops, clip rows cached by transform revision: no change.
- `FrameRate=30` in the ini as a cap: the game's limiter rounds a 34 ms frame
  to 50. A sleep before the display list as a cap: −3 fps (in series with the
  vblank wait); the cap inside the vblank wait costs nothing.
- Frame skipping: the game clock tracks real time within 1% in the dips and
  the game thread is busy, not waiting; nothing to gain.
- PSP through RetroArch's PPSSPP core on ARM's driver: ~4 game fps (see
  `goodluckOS-retroarch-mali`).

## Traps

- A changed host file with a stale profile costs fps; retrain per file.
  `build/` can be stale after a source revert: check `nm` for symbols that
  should be gone. Profile the exact binary you deployed.
- MTP: `pkill -9 -x ptpcamerad` before each transfer; quit Photos. The
  console's shell appends to what `console.py` sends: never end a command
  with `&`. Busybox `find` has no `-delete`. A tar made on the Mac carries
  `._*` files unless made with `COPYFILE_DISABLE=1 tar --no-xattrs`.
- ARM's GLSL preprocessor rejects an undefined macro in an `#if`; a packed
  base vertex must be padded to a whole vertex once raw blocks of other
  strides share the array; tracked attribute-array enables need a "set
  everything" state at frame start.
- Instrumented `-O3` builds of the big units need ~1.5 GB each.

## Licence

The port's own code is MIT (`LICENSE`); `package.sh` puts a copy into the game folder's
`licenses/`. Third-party components and their licences: `licenses/README.md`.
