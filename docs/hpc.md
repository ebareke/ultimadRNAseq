# HPC & Apptainer

How `directRNA` runs on an HPC cluster with the SLURM scheduler and Apptainer
(or Singularity) containers.

## TL;DR

```bash
nextflow run . -profile hpc --input samplesheet.csv \
    --fasta genome.fa.gz --gtf anno.gtf.gz --transcript_fasta tx.fa.gz \
    --outdir results
```

`-profile hpc` = SLURM executor + Apptainer enabled (`conf` in
`nextflow.config`). The Nextflow head process submits each task as its own
SLURM job; each task runs inside its container.

## How images resolve

- **Bioconda tools** (the large majority) reference, per module, a prebuilt
  **Singularity/Apptainer image** from `depot.galaxyproject.org` *and* a Docker
  fallback. Under `-profile apptainer`/`hpc`, Nextflow reports the engine as
  `apptainer`, and the modules now select the Galaxy-depot Singularity image
  directly (no Docker→SIF conversion at run time).
- **RATTLE** is on Bioconda too → uses the Galaxy-depot Singularity image.
- **Custom tools** without a Bioconda recipe — **tailfindr**, **nanoRMS**,
  **ELIGOS** — reference a Docker image. Apptainer pulls and converts these
  automatically (`docker://…`), or you can pre-seed prebuilt SIFs (below).
- **Dorado** uses the ONT image (`ontresearch/dorado`); pulled the same way.

## Apptainer SIFs built on GitHub

The **`Apptainer images (HPC)`** workflow (`.github/workflows/apptainer.yml`)
builds SIF images for the custom tools, **smoke-tests each under Apptainer**,
and publishes them to **GHCR** as OCI artifacts. A second job proves the
Bioconda Apptainer path by pulling and running a Galaxy-depot image.

Trigger it from **Actions ▸ Apptainer images (HPC) ▸ Run workflow** (needs the
`DOCKERHUB_*` secrets only if your Docker Hub repos are private; GHCR push uses
the built-in `GITHUB_TOKEN`).

Pre-seed an HPC Apptainer cache from GHCR (optional, for offline compute nodes):

```bash
mkdir -p "$APPTAINER_CACHEDIR"
apptainer pull oras://ghcr.io/ebareke/tailfindr-apptainer:1.4
apptainer pull oras://ghcr.io/ebareke/nanorms-apptainer:2.0
apptainer pull oras://ghcr.io/ebareke/eligos2-apptainer:v2.1.0
```

## Recommended cluster settings

In `assets/run_sgnex.slurm` / `assets/run_signal_gpu.slurm` (or your own
submission script):

```bash
export NXF_APPTAINER_CACHEDIR=/shared/scratch/$USER/apptainer_cache   # shared, large
export NXF_OPTS='-Xms1g -Xmx4g'                                       # head-job heap
```

- Put the Apptainer cache and the Nextflow `work/` dir on **shared scratch**
  (not `$HOME`) — images and intermediates are large.
- The first run downloads images and the reference once; `-resume` reuses them.
- Set the SLURM `--account`/`--partition` in the submission script; tune
  `executor.queueSize` and `process.queue` for your site.

## GPU (Dorado)

Dorado basecalling needs a GPU. The `signal` profile requests it
(`conf/signal.config`):

```groovy
withLabel: process_gpu {
    clusterOptions = '--gres=gpu:1'
    queue          = 'gpu'        // your GPU partition
}
apptainer.runOptions = '--nv'     // expose CUDA inside the container
```

Edit the GPU partition and `--gres` syntax to your scheduler. See
[signal_gpu_run.md](signal_gpu_run.md).

## Verifying locally (no cluster)

```bash
# wiring only (no engine, no real tools)
nextflow run . -profile test -stub --outdir results

# real tools on one node with Apptainer (small inputs)
nextflow run . -profile test,apptainer --outdir results
```
