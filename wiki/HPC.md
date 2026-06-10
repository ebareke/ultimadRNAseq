# HPC & Apptainer

Running directRNA on an HPC cluster with **SLURM** + **Apptainer** (or
Singularity). Full guide: `docs/hpc.md`.

## Run

```bash
nextflow run . -profile hpc --input samplesheet.csv \
    --fasta genome.fa.gz --gtf anno.gtf.gz --transcript_fasta tx.fa.gz \
    --outdir results
```

`-profile hpc` = SLURM executor + Apptainer. The Nextflow head process submits
each task as its own SLURM job; each task runs in its container. Ready-made
submission scripts: `assets/run_sgnex.slurm`, `assets/run_signal_gpu.slurm`.

## How images resolve

- **Bioconda tools** (incl. RATTLE) use the **Galaxy-depot Singularity** image
  directly under `-profile apptainer`/`hpc` — no Docker→SIF conversion at run
  time (the modules recognise the `apptainer` engine, not only `singularity`).
- **Custom tools** without a Bioconda recipe — **tailfindr**, **nanoRMS**,
  **ELIGOS** — use a Docker image that Apptainer pulls/converts automatically,
  or you can pre-seed prebuilt SIFs from GHCR.
- **Dorado** uses the ONT image; pulled the same way.

## Apptainer SIFs built on GitHub

`.github/workflows/apptainer.yml` builds SIFs for the custom tools, smoke-tests
each under Apptainer, and publishes them to **GHCR**. A second job verifies the
Bioconda path (pull + exec a Galaxy-depot image). Pre-seed an HPC cache:

```bash
apptainer pull oras://ghcr.io/ebareke/tailfindr-apptainer:1.4
apptainer pull oras://ghcr.io/ebareke/nanorms-apptainer:2.0
apptainer pull oras://ghcr.io/ebareke/eligos2-apptainer:v2.1.0
```

## Cluster settings

```bash
export NXF_APPTAINER_CACHEDIR=/shared/scratch/$USER/apptainer_cache   # shared, large
export NXF_OPTS='-Xms1g -Xmx4g'                                       # head-job heap
```

- Keep the Apptainer cache and Nextflow `work/` on **shared scratch**, not `$HOME`.
- First run downloads images + reference once; `-resume` reuses them.
- Set SLURM `--account`/`--partition` in the submission script.

## GPU (Dorado)

The `signal` profile requests a GPU (`conf/signal.config`):

```groovy
withLabel: process_gpu {
    clusterOptions = '--gres=gpu:1'
    queue          = 'gpu'        // your GPU partition
}
apptainer.runOptions = '--nv'     // expose CUDA in the container
```

See [[Real-Data-Runs]] and `docs/signal_gpu_run.md`.
