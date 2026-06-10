# directRNA

A reproducible **Nextflow (DSL2)** platform for **Oxford Nanopore Direct RNA
Sequencing** analysis — reference-guided and de novo, from raw signal or
basecalled reads, through QC, alignment, quantification, RNA-modification
detection and poly(A) tail analysis, with HTML/PDF reporting and a GUI.

## Contents

- **[[Installation]]** — Java, Nextflow, containers
- **[[Usage]]** — sample sheet, modes, toggles, profiles, outputs
- **[[Workflow-Modes]]** — reference-guided vs de novo
- **[[Modules-and-Tools]]** — every tool and what it does
- **[[Real-Data-Runs]]** — SG-NEx (FASTQ) and signal+GPU runbooks
- **[[Containers]]** — building the custom images
- **[[HPC]]** — SLURM + Apptainer, GHCR SIFs, GPU
- **[[Development]]** — architecture & extending the pipeline
- **[[FAQ]]**

## At a glance

| Capability | Tools |
|------------|-------|
| Inputs | POD5, FAST5 (→POD5), FASTQ; local or remote URLs |
| Signal / basecalling | Dorado (GPU), f5c, pod5 |
| QC | NanoPlot, ToulligQC, pycoQC, MultiQC |
| Alignment / quant | Minimap2 (splice + map-ont), Salmon, NanoCount (opt-in) |
| RNA modifications | m6anet, Nanocompore, ELIGOS, nanoRMS |
| Poly(A)/(U) | nanopolish polya, tailfindr |
| De novo | RATTLE, StringTie2, gffcompare |
| Reporting | MultiQC + Quarto HTML/PDF + Streamlit GUI |
| Deploy | Docker, Apptainer/Singularity; local, SLURM, cloud |
| Validation | nf-test (unit + pipeline), CI |

## Quick start

```bash
git clone https://github.com/ebareke/ultimadRNAseq.git && cd ultimadRNAseq
nextflow run . -profile test -stub-run --outdir results   # wiring check
nextflow run . -profile hpc --input samplesheet.csv \
    --fasta genome.fa.gz --gtf anno.gtf.gz --transcript_fasta tx.fa.gz \
    --outdir results
```

> Requires **Java 17** and **Nextflow ≥24.04**. See [[Installation]].
