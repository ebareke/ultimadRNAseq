# Usage

Complete user guide for the `directRNA` pipeline.

## Install

You need **Java 17** and **Nextflow ≥24.04**, plus a container engine
(**Apptainer**/Singularity on HPC, or **Docker** on a workstation). See
[environment.md](environment.md) for a no-sudo bootstrap.

```bash
# fetch the pipeline
git clone https://github.com/ebareke/ultimadRNAseq.git
cd ultimadRNAseq

# smoke test (no real tools, validates wiring)
nextflow run . -profile test -stub-run --outdir results
```

## Quick start

```bash
# reference-guided, FASTQ entry, on a workstation with Docker
nextflow run . \
    -profile docker \
    --input samplesheet.csv \
    --fasta genome.fa.gz \
    --gtf annotation.gtf.gz \
    --transcript_fasta transcripts.fa.gz \
    --outdir results

# on HPC (SLURM + Apptainer)
nextflow run . -profile hpc --input samplesheet.csv ... --outdir results
```

Curated end-to-end runs:
- **SG-NEx benchmark** (FASTQ): [sgnex_run.md](sgnex_run.md)
- **Signal + GPU** (POD5/FAST5 → modifications/poly(A)): [signal_gpu_run.md](signal_gpu_run.md)

## Sample sheet

CSV with one row per sample (`assets/schema_input.json` is the formal schema):

| Column | Required | Notes |
|--------|----------|-------|
| `sample` | yes | unique id |
| `condition` | no | grouping label (default `none`) |
| `replicate` | no | integer (default `1`) |
| `kit` | no | `RNA002` \| `RNA004` (default `RNA004`) — drives the Dorado model |
| `fastq` | one-of | basecalled reads (`.fastq.gz`) |
| `pod5_dir` | one-of | directory of POD5 signal |
| `fast5_dir` | one-of | directory of FAST5 signal (auto-converted to POD5) |
| `control` | no | `true` = background/reference for comparative modification calling |
| `organism` | no | free text |
| `summary` | no | a `sequencing_summary.txt` (enables pycoQC without basecalling) |

At least one of `fastq` / `pod5_dir` / `fast5_dir` must be present. Paths may be
local (absolute, or relative to the launch dir / project dir) or remote URLs
(`http(s)://`, `s3://`, …) — remote paths are staged automatically.

## Workflow modes

- `--mode reference` (default) — Minimap2 (splice-aware genome + transcriptome)
  → Salmon quantification.
- `--mode denovo` — RATTLE (reference-free) + StringTie2 (genome-guided) +
  gffcompare + de novo abundance.

## Module toggles

| Flag | Default | Effect |
|------|---------|--------|
| `--skip_qc` | false | skip NanoPlot/ToulligQC/pycoQC |
| `--skip_alignment` | false | skip Minimap2 |
| `--skip_quantification` | false | skip Salmon (reference mode) |
| `--run_dorado` | false | basecall POD5/FAST5 with Dorado (GPU) |
| `--run_f5c` | false | f5c event alignment (needed by m6anet/Nanocompore) |
| `--skip_modifications` | true | m6anet, Nanocompore, ELIGOS, nanoRMS |
| `--skip_polya` | true | nanopolish polya, tailfindr |
| `--skip_denovo` | true | RATTLE/StringTie2 (denovo mode) |
| `--skip_multiqc` / `--skip_report` | false | aggregate reports |

Modifications and poly(A) need raw signal + `--run_f5c`; with FASTQ-only input
those stages produce no tasks.

## Profiles

| Profile | Purpose |
|---------|---------|
| `standard` | local + conda (no signal/de-novo-only tools — those are container-only) |
| `docker` | local + Docker |
| `apptainer` / `singularity` | container engine for HPC |
| `slurm` / `hpc` | SLURM executor (`hpc` = SLURM + Apptainer) |
| `test` / `test_signal` / `test_denovo` | tiny stub datasets for each path |
| `sgnex` | SG-NEx benchmark (FASTQ, reference) |
| `signal` | full POD5/FAST5 → Dorado → modifications/poly(A) (GPU) |

Combine engine + intent, e.g. `-profile sgnex,hpc` or `-profile signal,hpc`.

## Outputs

```
<outdir>/
├── qc/{nanoplot,toulligqc,pycoqc}/
├── signal/{dorado,fastq,f5c}/          # with --run_dorado/--run_f5c
├── alignment/{genome,transcriptome}/
├── quantification/salmon/
├── modifications/{m6anet,nanocompore,eligos,nanorms}/
├── polya/{nanopolish,tailfindr}/
├── denovo/{rattle,stringtie,gffcompare,quantification}/   # denovo mode
├── multiqc/multiqc_report.html
├── report/directRNA_report.{html,pdf}
└── pipeline_info/                      # versions, timeline, trace, DAG
```

## Reproducibility & resume

- `-resume` skips completed steps on re-run.
- Every tool version, parameter, timeline, trace and DAG is written to
  `pipeline_info/` (spec §11).
- Resource ceilings: `--max_cpus`, `--max_memory`, `--max_time`.

## GUI

After a run, browse results interactively:

```bash
pip install -r gui/requirements.txt
streamlit run gui/app.py -- --results <outdir>
```

## Troubleshooting

- **Java/Nextflow version errors** → see [environment.md](environment.md).
- **Config parse errors on old Nextflow** → requires ≥24.04 (strict parser +
  `resourceLimits`).
- **Container-only tools fail under `standard`** → RATTLE/tailfindr/nanoRMS/
  ELIGOS/Dorado have no Bioconda recipe; use `-profile docker`/`apptainer`.
- **GPU not visible to Dorado** → ensure Apptainer runs with `--nv` (set in
  `conf/signal.config`) and the task lands on a GPU partition.
