# directRNA

Reproducible analysis platform for Oxford Nanopore **Direct RNA Sequencing (dRNA-seq)** data.

> **Status:** all modules wired and stub/nf-test validated across reference,
> signal, and de novo paths. Real-tool/real-data hardening is ongoing (see
> [CHANGELOG](CHANGELOG.md) and [docs/roadmap.md](docs/roadmap.md)).

## Documentation

| Guide | |
|-------|--|
| [Usage](docs/usage.md) | sample sheet, modes, toggles, profiles, outputs |
| [Environment](docs/environment.md) | Java/Nextflow bootstrap |
| [Containers](docs/containers.md) | build/push the custom images |
| [SG-NEx run](docs/sgnex_run.md) | first real-data run (FASTQ) |
| [Signal + GPU run](docs/signal_gpu_run.md) | POD5/FAST5 → modifications/poly(A) |
| [Validation](docs/validation.md) | nf-test, benchmarks |
| [Development](docs/development.md) | architecture, extending |
| [Roadmap](docs/roadmap.md) | phase status |

A full **[GitHub wiki](../../wiki)** mirrors these (Home, Installation, Usage,
Workflow-Modes, Modules-and-Tools, Real-Data-Runs, Containers, Development, FAQ).

## What it does

`directRNA` orchestrates a complete ONT dRNA-seq analysis from raw signal (POD5/FAST5)
or basecalled reads (FASTQ) through QC, alignment, isoform quantification, RNA
modification detection, and poly(A) tail analysis — with both **reference-guided**
and **de novo** workflow modes.

## Architecture

- **Orchestrator**: Nextflow (DSL2), nf-core conventions
- **Containers**: Docker (workstation), Apptainer/Singularity (HPC)
- **Executors**: local, SLURM, AWS Batch, Google Batch, Kubernetes
- **Dependency management**: Conda fallback for environments without containers

## Quick start (once Phase 1 lands)

```bash
# Smoke test on Docker
nextflow run ebareke/directRNA -profile test,docker --outdir results

# Real run on HPC
nextflow run ebareke/directRNA \
    -profile hpc \
    --input samplesheet.csv \
    --fasta genome.fa \
    --gtf annotation.gtf \
    --transcript_fasta transcripts.fa \
    --outdir results
```

## Modules (planned)

| Phase | Module                         | Tools                                          |
|-------|--------------------------------|------------------------------------------------|
| 1     | Quality control                | NanoPlot, pycoQC, ToulligQC, MultiQC           |
| 1     | Alignment + quantification     | Minimap2, Salmon, Nexxons                      |
| 2     | Basecalling + signal           | Dorado, f5c, Uncalled4                         |
| 3     | RNA modifications              | m6anet, Nanocompore, nanoRMS, ELIGOS           |
| 4     | Poly(A) analysis               | nanopolish polya, tailfindr                    |
| 5     | De novo transcript discovery   | RATTLE, StringTie2-LR, gffcompare              |
| 6     | Reporting + UI                 | MultiQC, Quarto (HTML+PDF), Streamlit GUI      |

## Repository layout

```
directRNA/
├── main.nf                  # Entry point
├── nextflow.config          # Top-level config + profiles
├── conf/                    # Resource defaults, test profiles
├── workflows/               # Top-level workflow(s)
├── subworkflows/local/      # Reusable subworkflow blocks
├── modules/local/           # Process modules (one tool per file)
├── bin/                     # Helper scripts (Python/R)
├── assets/                  # Sample sheets, schema, MultiQC config
├── tests/                   # Test data + integration tests
└── docs/                    # User & developer documentation
```

## License

MIT © 2026 Eric Bareke. See [LICENSE](LICENSE).
