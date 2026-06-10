# Usage

## Sample sheet

One row per sample (formal schema: `assets/schema_input.json`):

```csv
sample,condition,replicate,kit,fastq,pod5_dir,fast5_dir,control,organism
WT_rep1,wildtype,1,RNA004,reads/WT_rep1.fastq.gz,,,false,human
KO_rep1,knockout,1,RNA004,,signal/KO_rep1/pod5,,true,human
```

| Column | Required | Notes |
|--------|----------|-------|
| `sample` | ✔ | unique id |
| `condition`, `replicate` | | grouping |
| `kit` | | `RNA002`/`RNA004` → Dorado model |
| `fastq` / `pod5_dir` / `fast5_dir` | one-of | entry point (FAST5 auto-converts to POD5) |
| `control` | | `true` = background for comparative modification calling |
| `summary` | | a `sequencing_summary.txt` (enables pycoQC without basecalling) |

Paths can be local or remote URLs (`http(s)://`, `s3://`) — remote paths stage
automatically.

## Run

```bash
nextflow run . -profile <engine> --input samplesheet.csv \
    --fasta genome.fa.gz --gtf anno.gtf.gz --transcript_fasta tx.fa.gz \
    --outdir results
```

## Modes & toggles

- `--mode reference` (default) | `--mode denovo` — see [[Workflow-Modes]].
- Signal/epitranscriptomics are opt-in: `--run_dorado`, `--run_f5c`,
  `--skip_modifications false`, `--skip_polya false`.
- Skip stages with `--skip_qc/alignment/quantification/denovo/multiqc/report`.

## Profiles

`standard`, `docker`, `apptainer`, `singularity`, `slurm`, `hpc`,
`test`/`test_signal`/`test_denovo`, `sgnex`, `signal`. Combine engine + intent,
e.g. `-profile sgnex,hpc`.

## Outputs

```
<outdir>/
├── qc/  signal/  alignment/  quantification/
├── modifications/  polya/  denovo/
├── multiqc/multiqc_report.html
├── report/directRNA_report.{html,pdf}
└── pipeline_info/   # versions, timeline, trace, DAG (provenance)
```

## GUI

```bash
pip install -r gui/requirements.txt
streamlit run gui/app.py -- --results <outdir>
```

For full detail see `docs/usage.md` in the repo, and [[Real-Data-Runs]].
