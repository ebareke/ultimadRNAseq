# First real-data run — SG-NEx (HPC / SLURM + Apptainer)

A guided first end-to-end run on the public **SG-NEx** direct-RNA benchmark,
entering at **FASTQ** (no basecalling/GPU), in **reference-guided** mode. It
exercises QC → Minimap2 → Salmon → MultiQC + the unified report. Signal-only
stages (modifications, poly(A)) are intentionally off — FASTQ entry has no raw
signal.

## Prerequisites

- HPC with SLURM and **Apptainer** (or Singularity)
- **Java 17** and **Nextflow ≥24.04** (see [environment.md](environment.md))
- Outbound network on the node running Nextflow (it downloads the GENCODE human
  reference, ~3 GB once, and streams the SG-NEx FASTQs)
- Scratch space for the reference, work dir, and Apptainer cache

## 1. Confirm the SG-NEx sample keys

`assets/samplesheet_sgnex.csv` is pre-filled with the SG-NEx naming scheme, but
**verify the exact object keys** (run/replicate numbers differ per sample):

```bash
# requires awscli; no credentials needed (open bucket)
aws s3 ls --no-sign-request s3://sg-nex-data/data/sequencing_data_ont/fastq/ | grep directRNA
```

Data index & docs: <https://github.com/GoekeLab/sg-nex-data>.
Edit the `fastq` column to the verified `https://sg-nex-data.s3.amazonaws.com/...`
URLs (or local copies). Each row is one sample; set `condition`/`replicate`/
`control` to match your comparison.

## 2. (Optional) localise the reference

The `sgnex` profile points `--fasta/--gtf/--transcript_fasta` at GENCODE v44
URLs. To avoid re-downloading across runs, fetch once and override:

```bash
nextflow run . -profile sgnex,hpc --outdir results_sgnex \
    --fasta /shared/ref/GRCh38.primary_assembly.genome.fa.gz \
    --gtf   /shared/ref/gencode.v44.primary_assembly.annotation.gtf.gz \
    --transcript_fasta /shared/ref/gencode.v44.transcripts.fa.gz
```

## 3. Launch

Edit the `#SBATCH --account` / `--partition` lines (and the toolchain section)
in `assets/run_sgnex.slurm`, then:

```bash
sbatch assets/run_sgnex.slurm
```

The head job stays alive and submits each pipeline step as its own SLURM job
(`-profile hpc` ⇒ `executor = slurm` + Apptainer). `-resume` makes re-runs skip
completed steps.

Quick interactive smoke check (no SLURM, no real tools) before the real run:

```bash
nextflow run . -profile sgnex,test --outdir results -stub-run   # wiring only
```

## 4. Outputs

```
results_sgnex/
├── qc/{nanoplot,toulligqc}/<sample>/      # read-level QC
├── alignment/{genome,transcriptome}/      # Minimap2 BAMs + flagstat
├── quantification/salmon/<sample>/        # quant.sf
├── multiqc/multiqc_report.html            # aggregated QC
├── report/directRNA_report.{html,pdf}     # unified summary
└── pipeline_info/                         # versions, timeline, trace, DAG
```

## 5. Validate correctness

This is where stub-green becomes science-green:

- **Quantification**: correlate Salmon TPM against a published SG-NEx
  quantification for the same sample.
- **Alignment**: sanity-check mapping rate in the flagstats / MultiQC.
- **Provenance**: confirm `pipeline_info/software_versions.yml` and the
  execution report capture every tool + parameter (spec §11).

To extend to modifications/poly(A), supply raw signal (POD5/FAST5) and enable
`--run_dorado --run_f5c --skip_modifications false --skip_polya false` on a GPU
partition — see the `test_signal` wiring for the shape of that run.
