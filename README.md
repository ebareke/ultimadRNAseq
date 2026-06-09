# directRNA

Reproducible analysis platform for Oxford Nanopore **Direct RNA Sequencing (dRNA-seq)** data.

> **Status:** Phase 0 (scaffolding). Not yet runnable end-to-end.
> See [docs/roadmap.md](docs/roadmap.md) for the phased delivery plan.

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
| 5     | De novo transcript discovery   | RATTLE, IsoQuant, StringTie2-LR (under review) |

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

TBD.
