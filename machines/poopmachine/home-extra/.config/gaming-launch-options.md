# Per-Game Steam Launch Options

Paste these into Steam → right-click game → Properties → Launch Options.
These are NOT set globally — opt in per game only.

GE-Proton is selected per game via Properties → Compatibility → Force the use of a specific Steam Play compatibility tool → GE-Proton11-1.
Enable Steam Play for all titles first: Steam → Settings → Compatibility → Enable Steam Play for all other titles.

---

## Baseline (most games)

```
PROTON_ENABLE_NVAPI=1 PROTON_DLSS_UPGRADE=1 gamemoderun mangohud %command%
```

- `PROTON_ENABLE_NVAPI=1` — exposes NVAPI to the game; required for DLSS, Reflex, and RTX features.
- `PROTON_DLSS_UPGRADE=1` — upgrades DLSS 2 calls to DLSS 3/4 (Frame Generation) where supported.
- `gamemoderun` — activates GameMode (CPU governor, scheduler tweaks).
- `mangohud` — overlays FPS/GPU/CPU stats (toggle with F12 in-game).

---

## DX12 with ray tracing

```
PROTON_ENABLE_NVAPI=1 VKD3D_CONFIG=dxr PROTON_DLSS_UPGRADE=1 gamemoderun mangohud %command%
```

- Adds `VKD3D_CONFIG=dxr` — enables DXR ray tracing path in vkd3d-proton.

---

## RTX 4000/5000 performance-regression workaround

If a game underperforms compared to expected benchmarks, append:

```
PROTON_NVIDIA_LIBS_NO_32BIT=1
```

Full example:
```
PROTON_ENABLE_NVAPI=1 PROTON_DLSS_UPGRADE=1 PROTON_NVIDIA_LIBS_NO_32BIT=1 gamemoderun mangohud %command%
```

---

## Disable NTSync (per-game breakage fix)

NTSync is enabled by default in GE-Proton11-1. If a specific game hangs or crashes, add:

```
PROTON_NO_NTSYNC=1
```

---

## OpenGL-heavy games (threading)

```
__GL_THREADED_OPTIMIZATIONS=1
```

Enables multithreaded OpenGL driver calls. Helps CPU-bound OpenGL titles.
**Caution**: can crash some games — use only for titles that are confirmed to benefit.

---

## Explicit-sync crash workaround (rare)

If a game crashes specifically on Wayland with an explicit-sync error in the log:

```
__NV_DISABLE_EXPLICIT_SYNC=1
```

---

## HDR — intentionally NOT enabled

Do NOT add `DXVK_HDR=1`, `PROTON_ENABLE_HDR=1`, or any gamescope `--hdr-enabled` flags.

Reasons:
- niri does not have color management in 2026; HDR passthrough is broken.
- NVIDIA ultrawide HDR under Wayland has known driver bugs as of mid-2026.

If niri adds color management in a future release, revisit at that time.

---

## Notes

- Shader cache is stored in `~/.cache/nvidia/shaders` (set via `environment.d`).
  First launch of a game will compile shaders; subsequent launches are faster.
- MANGOHUD and PROTON_* are intentionally per-game, not global — global settings
  cause overhead in non-gaming workloads and can break non-game apps.
