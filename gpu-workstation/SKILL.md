---
name: gpu-workstation
description: Launch and manage a temporary AWS compute instance for computationally intensive tasks like rayshader rendering, 3D terrain maps, or heavy R/Python workloads. Use this skill whenever the user needs to run something that would be too slow on a laptop — rayshader, rayrender, large raster processing, CPU-intensive computation — or when they mention wanting to offload work to a remote machine. Also trigger when the user mentions gpu-up, gpu-run, gpu-down, or gpu-bake commands.
---

# Render Workstation

A set of CLI tools for spinning up a temporary AWS compute instance (c5.4xlarge — 16 vCPUs, 32GB RAM), running compute-heavy scripts on it, and pulling results back locally. The instance tries spot pricing first (~$0.24/hr) and falls back to on-demand (~$0.68/hr).

Rayshader is CPU-bound (not GPU) — it uses software rendering via rgl/OpenGL. More CPU cores = faster renders. The c5.4xlarge gives 16 cores vs 4 on a laptop, which is roughly a 4x speedup for parallelizable work.

## Available commands

All scripts live in `~/bin/` and are already installed.

| Command | Purpose |
|---------|---------|
| `gpu-up` | Launch the instance (spot with on-demand fallback), wait for SSH |
| `gpu-run` | Upload files, run an R script remotely, download outputs |
| `gpu-down` | Terminate the instance |
| `gpu-bake` | Snapshot the instance as a custom AMI to preserve new packages |

## Typical workflow

### 1. Launch the instance

```bash
gpu-up
```

The default baked AMI has R and all rayshader dependencies pre-installed — the instance is ready to use as soon as SSH is available (about 60 seconds). There is no install step needed.

### 2. Run a script

```bash
# Basic: upload script, run it, auto-download all image/PDF outputs to ./output/
gpu-run render.R

# With data files
gpu-run render.R terrain.tif hillshade.tif

# Explicit output files
gpu-run render.R terrain.tif -- final_map.png

# Interactive SSH session
gpu-run --ssh
```

How `gpu-run` works:
- Uploads the R script (and any extra files) to `/home/ubuntu/work/` on the instance
- Runs the script via `xvfb-run -a Rscript` (headless OpenGL for rgl/rayshader)
- Downloads outputs to a local `./output/` directory
- By default grabs all `*.png *.jpg *.pdf *.tif *.gif` — or specify files after `--`

### 3. Iterate

Run the script multiple times, tweaking parameters locally and re-uploading. The instance stays up between runs.

### 4. Shut down

```bash
gpu-down
```

### 5. (Optional) Re-bake the AMI

If you install additional R packages or system tools on the instance and want to preserve them for future launches:

```bash
gpu-bake
```

This outputs a new AMI ID. Update the default in `~/bin/gpu-up` (the `BAKED_AMI` variable).

## Pre-installed R packages

The baked AMI includes:
- **Rayshader stack**: rayshader, rayrender, rayimage, rgl, terrainmeshr
- **Spatial**: terra, sf, raster, elevatr, stars, rnaturalearth, rnaturalearthdata, geosphere
- **Visualization**: ggplot2, tidyverse, magick, av, reshape2

## System tools

- ffmpeg (for video/animation export)
- pandoc
- xvfb (headless rendering)
- All spatial C libraries (GDAL, GEOS, PROJ, etc.)

## Configuration

The instance type and AMI can be overridden via environment variables:

```bash
GPU_INSTANCE_TYPE=c5.9xlarge gpu-up    # 36 vCPUs for even faster renders
GPU_AMI_ID=ami-xxxxx gpu-up            # custom baked AMI
```

## State tracking

- Instance ID is stored in `~/.gpu-instance`
- `gpu-up` won't double-launch if an instance is already running
- `gpu-down` cleans up the state file

## When helping the user with render tasks

When the user wants to render something heavy (rayshader terrain, 3D maps, animations):

1. Write the R script locally first
2. Run `gpu-up` to launch the instance (baked AMI, ready in ~60s)
3. Use `gpu-run script.R [data files]` to execute
4. Check the outputs in `./output/`
5. If tweaks are needed, edit the script and re-run — no need to restart the instance
6. Run `gpu-down` when done

Important: do NOT wait for or poll `gpu-run --status` in a loop. The baked AMI is pre-configured — once `gpu-up` reports SSH is ready, you can run scripts immediately. Only use `--status` as a one-time sanity check if something seems wrong.

For rayshader scripts, rendering happens headlessly via xvfb, so the script must save output to files (e.g., `save_png()`, `render_snapshot()`, `ggsave()`) rather than relying on interactive display.

## Rayshader tips for remote rendering

- Use `rgl::rgl.useNULL()` at the top of scripts to suppress X11 warnings
- For `render_highquality()`, set `parallel = TRUE` to use all 16 cores
- For animations, `av::av_capture_graphics()` or `magick::image_animate()` work headlessly
- Save with explicit dimensions: `save_png("output.png", width=1200, height=900)`
- For 3D snapshots: `render_snapshot("output.png")` after `plot_3d()`
