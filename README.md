# directRNA

Reproducible analysis platform for Oxford Nanopore **Direct RNA Sequencing
(dRNA-seq)** data — built on **Nextflow (DSL2)** with nf-core conventions.

> **Status:** feature-complete against the SRS and validated with `nf-test`
> (6/6) across the reference, signal and de novo paths. Containers (Docker +
> Apptainer) build and are verified on GitHub CI. Remaining work is real-data
> scientific validation on HPC — see [CHANGELOG](CHANGELOG.md) and
> [docs/roadmap.md](docs/roadmap.md).

## What it does

`directRNA` runs a complete ONT dRNA-seq analysis from **raw signal (POD5/FAST5)
or basecalled reads (FASTQ)** through QC, alignment, isoform quantification, RNA
modification detection and poly(A) tail analysis — in both **reference-guided**
and **de novo** modes — and produces aggregated HTML/PDF reports with full
provenance.

## Features

| Stage | Tools |
|-------|-------|
| Signal & basecalling (opt-in) | **Dorado** (GPU), **f5c**, **pod5** (FAST5→POD5) |
| Quality control | **NanoPlot**, **ToulligQC**, **pycoQC**, **MultiQC** |
| Alignment | **Minimap2** (splice-aware genome + `map-ont` transcriptome) |
| Quantification | **Salmon**; **NanoCount** (opt-in, ONT EM estimator) |
| RNA modifications (opt-in) | **m6anet**, **Nanocompore**, **ELIGOS**, **nanoRMS** |
| Poly(A)/(U) (opt-in) | **nanopolish polya**, **tailfindr** |
| De novo discovery | **RATTLE** (reference-free), **StringTie2** + **gffread** + **gffcompare** |
| Reporting | **MultiQC** + unified **Quarto** HTML/PDF report + **Streamlit** GUI |

Inputs: POD5, FAST5 (auto-converted to POD5), FASTQ — local paths or remote
URLs (`http(s)://`, `s3://`). Signal/modification/poly(A) stages are opt-in and
produce no tasks at FASTQ entry.

> Uncalled4 (spec §5.2) is deferred; f5c covers signal-to-reference alignment.

## Quick start

```bash
git clone https://github.com/ebareke/ultimadRNAseq.git && cd ultimadRNAseq

# wiring smoke test — no engine, no real tools
nextflow run . -profile test -stub --outdir results

# reference-guided run on a workstation (Docker)
nextflow run . -profile docker \
    --input samplesheet.csv \
    --fasta genome.fa.gz --gtf annotation.gtf.gz --transcript_fasta transcripts.fa.gz \
    --outdir results

# HPC (SLURM + Apptainer)
nextflow run . -profile hpc --input samplesheet.csv --fasta … --outdir results
```

Curated real-data runs: [SG-NEx (FASTQ)](docs/sgnex_run.md) ·
[Signal + GPU](docs/signal_gpu_run.md).

## Profiles

| Profile | Purpose |
|---------|---------|
| `standard` | local + conda (container-only tools excluded) |
| `docker` | local + Docker |
| `apptainer` / `singularity` | container engine (uses Galaxy-depot SIFs) |
| `slurm` | SLURM executor |
| `hpc` | **SLURM + Apptainer** (primary HPC target) |
| `test` / `test_signal` / `test_denovo` | tiny stub datasets per path |
| `sgnex` | SG-NEx public benchmark (FASTQ, reference-guided) |
| `signal` | full POD5/FAST5 → Dorado → modifications/poly(A) (GPU) |

Combine engine + intent, e.g. `-profile sgnex,hpc` or `-profile signal,hpc`.

## Modes & key options

- `--mode reference` (default) — Minimap2 + Salmon (+ optional NanoCount).
- `--mode denovo` — RATTLE + StringTie2 + gffcompare + de novo quant.
- Opt-in stages: `--run_dorado`, `--run_f5c`, `--run_nanocount`,
  `--skip_modifications false`, `--skip_polya false`.
- Resource caps: `--max_cpus`, `--max_memory`, `--max_time`.

See [docs/usage.md](docs/usage.md) for the full sample-sheet schema, toggles and
outputs.

## Containers & HPC

- Most tools use **biocontainers** (Bioconda) — Docker on workstations,
  Galaxy-depot **Singularity/Apptainer** images on HPC, selected automatically
  by engine.
- Tools without a Bioconda recipe (**tailfindr**, **nanoRMS**, **ELIGOS**) ship
  as custom images, built & pushed by GitHub Actions
  (`.github/workflows/containers.yml`); Apptainer SIFs are built, smoke-tested
  and published to GHCR by `.github/workflows/apptainer.yml`.
- See [docs/hpc.md](docs/hpc.md) and [docs/containers.md](docs/containers.md).

## Documentation

| Guide | |
|-------|--|
| [Usage](docs/usage.md) | sample sheet, modes, toggles, profiles, outputs |
| [Environment](docs/environment.md) | Java/Nextflow bootstrap |
| [HPC & Apptainer](docs/hpc.md) | SLURM + Apptainer, GHCR SIFs, GPU |
| [Containers](docs/containers.md) | build/push the custom images |
| [SG-NEx run](docs/sgnex_run.md) | real-data run (FASTQ) |
| [Signal + GPU run](docs/signal_gpu_run.md) | POD5/FAST5 → modifications/poly(A) |
| [Validation](docs/validation.md) | nf-test, benchmarks |
| [Development](docs/development.md) | architecture, extending |
| [Roadmap](docs/roadmap.md) | phase status |

A full **[GitHub wiki](../../wiki)** mirrors these (Home, Installation, Usage,
Workflow-Modes, Modules-and-Tools, Real-Data-Runs, Containers, Development, FAQ).

## Repository layout

```
ultimadRNAseq/
├── main.nf · nextflow.config · nf-test.config
├── conf/                # base/modules config + profiles (incl. hpc, sgnex, signal)
├── workflows/           # top-level workflow
├── subworkflows/local/  # input_check, signal, qc, align, resquiggle,
│                        # modifications, polya, quantify, denovo
├── modules/local/       # one tool per file (+ stub + versions.yml)
├── assets/              # sample sheets, schema, report template, run scripts
├── containers/          # custom Dockerfiles + build_and_push.sh
├── gui/                 # Streamlit results browser
├── tests/nftest/        # nf-test unit + pipeline tests
├── docs/ · wiki/        # documentation
└── .github/workflows/   # ci, containers, apptainer
```

## Requirements

**Java 17–21** and **Nextflow ≥24.04**, plus a container engine (Docker, or
Apptainer/Singularity on HPC). See [docs/environment.md](docs/environment.md).

## License

MIT © 2026 Eric Bareke. See [LICENSE](LICENSE).
