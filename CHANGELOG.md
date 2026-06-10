# Changelog

All notable changes to `directRNA` will be documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added — first real-data run (SG-NEx)
- `sgnex` profile (`conf/sgnex.config`): SG-NEx public direct-RNA benchmark,
  FASTQ entry, reference-guided; GENCODE v44 human references via URL;
  signal stages off
- `assets/samplesheet_sgnex.csv` (SG-NEx FASTQ URLs — verify keys per runbook)
- `assets/run_sgnex.slurm` SLURM head-job submission script
- `docs/sgnex_run.md` runbook (prereqs, sample-key verification, launch,
  outputs, correctness checks)
- `INPUT_CHECK.resolve_input` is now URL-aware — remote sample-sheet paths
  (http/https/s3/…) bypass local-path resolution and stage directly

### Changed — container hardening
- Replaced placeholder/`:latest` container tags with pinned, buildable images:
  - RATTLE → `ebareke/rattle:1.0` (`containers/rattle/Dockerfile`)
  - tailfindr → `ebareke/tailfindr:1.4` (`containers/tailfindr/Dockerfile`)
  - nanoRMS → `ebareke/nanorms:2.0` (`containers/nanorms/Dockerfile`)
  - ELIGOS → `piroonj/eligos2:v2.1.0` (pin to digest in production)
- Added `containers/` with buildable Dockerfiles (pinned upstream `*_REF`) and
  `docs/containers.md` (build/push, Apptainer, digest pinning). These tools are
  container-only (no Bioconda); the `standard`/conda profile cannot run them.
- Removed the gutted ex-SRS `test.txt`.

### Added
- Phase 0 scaffolding: nf-core-style repo layout
- Nextflow configuration with profiles: `standard`, `docker`, `apptainer`,
  `singularity`, `slurm`, `hpc`, `test`, `test_full`
- `main.nf` entry point with help/banner/param validation
- `workflows/drnaseq.nf` + `subworkflows/local/input_check.nf`: parse & validate
  the sample sheet, emit `[meta, entrypoint]` channel
- Sample sheet contract: `assets/samplesheet_test.csv` + `assets/schema_input.json`
  (sample, condition, replicate, kit RNA002/RNA004, fastq/pod5_dir/fast5_dir,
  control flag, organism)
- Resource defaults in `conf/base.config` via native `resourceLimits`
  with `process_low/medium/high/long/gpu` labels
- Tiny test FASTQs under `tests/data/`
- GitHub Actions CI smoke-test scaffold
- `docs/environment.md`: JDK/Nextflow bootstrap (no-sudo path)

### Added — Phase 1 (reference-guided MVP, stub-validated)
- QC subworkflow (`subworkflows/local/qc.nf`): NanoPlot + ToulligQC on FASTQ,
  pycoQC channel-gated on a `sequencing_summary.txt`
- Minimap2 alignment (`modules/local/minimap2_align.nf`) aliased as
  `MINIMAP2_GENOME` (`-ax splice -uf -k14`) and `MINIMAP2_TXOME` (`-ax map-ont`)
- `PREPARE_GENOME` + `ALIGN` subworkflows; empty-channel gating skips alignment
  when no reference is supplied
- Salmon alignment-based quantification (`--ont`) → per-sample `quant.sf`
- MultiQC aggregation (`modules/local/multiqc.nf`) + `assets/multiqc_config.yml`
- Optional `summary` column added to the sample sheet (enables pycoQC pre-Phase 2)
- Tiny reference fixtures under `tests/data/reference/`
- Full pipeline stub-runs green: INPUT_CHECK → QC → ALIGN → QUANTIFY → MULTIQC
  (21 tasks, 0 failures)

### Added — Phase 7 (validation, spec §12)
- **nf-test** harness: `nf-test.config`, `tests/nextflow.config`
- Pipeline/integration tests (`tests/nftest/pipeline.nf.test`) covering all
  three execution paths — reference, signal+modifications+poly(A), de novo —
  asserting `workflow.success` and the expected output tree (stub mode)
- Module unit tests (`nanoplot`, `minimap2_align`) asserting outputs + versions
- All 5 tests pass on Nextflow 26.04.3 / Temurin 17
- `INPUT_CHECK` now resolves relative sample-sheet paths against `projectDir`
  as a fallback (robust under nf-test's isolated launch dir and for sheets
  shipped with the pipeline)
- CI extended with an `nf-test` job (stub) alongside the smoke test
- `docs/validation.md`: strategy, how-to, benchmark dataset pointers (SG-NEx,
  nf-core test-data, ONT Open Data, IVT controls)

### Added — Phase 6 (UI & reporting, stub-validated)
- `SUMMARY_REPORT` module: Quarto (`assets/report/report.qmd`) → unified
  **HTML + PDF** report aggregating QC, alignment, quant, modifications,
  poly(A), de novo, software versions and run parameters (spec §8)
- Wired into the main workflow (gated by `--skip_report`, default off); a
  `run_summary.yml` of parameters/provenance is generated inline and passed in
- Report inputs staged with `stageAs: "inputs/?/*"` to avoid per-sample
  basename collisions
- Streamlit **GUI scaffold** (`gui/app.py`, `requirements.txt`, `README.md`) —
  standalone results browser over the `--outdir` (spec §7B), outside the DAG
- Stub-runs green across profiles: `test`=22, `test_signal`=34, `test_denovo`=38

### Packaging / known refinements (Phase 6)
- `SUMMARY_REPORT` uses the Quarto container; PDF rendering needs a LaTeX/Typst
  engine present (HTML always; PDF best-effort).

### Added — Phase 5 (de novo transcript discovery, stub-validated)
- `DENOVO` subworkflow (`subworkflows/local/denovo.nf`), mode='denovo'
- Reference-free: `RATTLE` (cluster/correct/polish) → de novo transcripts
- Genome-guided: `STRINGTIE2 -L` → novel-isoform GTF; `GFFREAD` extracts
  transcript FASTA; `GFFCOMPARE` characterises vs the provided annotation
- De novo abundance: `MINIMAP2_DENOVO` + `SALMON_DENOVO` align reads back to
  each sample's own assembly (per-sample reference carried in the tuple)
- `test_denovo` profile; stub-runs green (37 tasks)
- Refactor: genome alignment now runs in BOTH modes whenever a reference FASTA
  is supplied (StringTie2 and f5c need the genome BAM); Salmon stays
  reference-mode-only, DENOVO is denovo-mode-only. No regression: `test`=21,
  `test_signal`=33, DENOVO absent from both.

### Packaging / known refinements (Phase 5)
- `RATTLE` has no Bioconda recipe — container is a placeholder; build from the
  comprehensivegenomics/RATTLE repo before real runs.

### Added — Phase 4 (poly(A)/poly(U) tail analysis, stub-validated)
- `POLYA` subworkflow (`subworkflows/local/polya.nf`), gated by `--skip_polya`
- `NANOPOLISH_POLYA`: `nanopolish index` + `polya` (alignment-anchored), joins
  reads + signal + genome BAM + reference per sample → per-read `polya.tsv.gz`
- `TAILFINDR`: alignment-free poly(A)+poly(U) from raw signal → per-read CSV
- `test_signal` sets `skip_polya=false`; full path stub-runs green (33 tasks).
  Phase 1 `test` profile unchanged (21).

### Packaging / known refinements (Phase 4)
- nanopolish & tailfindr were built for **FAST5/SLOW5**; the pipeline uses POD5.
  Retain FAST5 or convert POD5→slow5 for real runs (f5c `poly-a` is the
  POD5-native alternative to nanopolish).
- `TAILFINDR` has no official image — container is a placeholder; build from the
  adnaniazi/tailfindr R package before real runs.

### Added — Phase 3 (RNA modification detection, stub-validated)
- `MODIFICATIONS` subworkflow (`subworkflows/local/modifications.nf`) covering
  both detector families, gated by `--skip_modifications` (default true)
- Single-sample: `M6ANET` (dataprep + inference) on f5c eventalign → per-site
  (`data.site_proba.csv.gz`) and per-read m6A probabilities
- Comparative (control-vs-test contrasts from the `control` flag, built by
  channel `.filter` + `.combine`):
  - `NANOCOMPORE_COLLAPSE` + `NANOCOMPORE_SAMPCOMP` (eventalign substrate)
  - `ELIGOS_PAIRDIFF` — `eligos2 pair_diff_mod` from genome BAMs + reference
    (whole-contig BED derived from FASTA via awk; basecalling-error signal)
  - `NANORMS` — comparative stoichiometry from BAM pairs
- Outputs under `results/modifications/{m6anet,nanocompore,eligos,nanorms}/`
- `test_signal` sets `skip_modifications=false`; full path stub-runs green
  (29 tasks). Phase 1 `test` profile unchanged (21).

### Packaging / known refinements (Phase 3)
- `ELIGOS_PAIRDIFF` uses `piroonj/eligos2` (no Bioconda); pin a digest.
- `NANORMS` has **no** official image — container is a placeholder; a custom
  image must be built from the nanoRMS repo before real runs.
- m6anet/Nanocompore expect transcriptome-coordinate eventalign; current f5c
  eventalign is genome-based. Refine before real-data runs.
- Comparative pairing is a Cartesian product of test × control; revisit to
  group replicates per condition for real studies.

### Added — Phase 2 (signal & basecalling, stub-validated)
- `SIGNAL` subworkflow (`subworkflows/local/signal.nf`):
  - `POD5_CONVERT` — auto-converts FAST5→POD5 at ingest (unify on POD5)
  - `DORADO_BASECALLER` — opt-in (`--run_dorado`), `process_gpu`, emits uBAM
    with move tables; model via `--dorado_model`
  - `DORADO_SUMMARY` — produces `sequencing_summary.txt` (activates pycoQC)
  - `SAMTOOLS_FASTQ` — uBAM→FASTQ that feeds QC/ALIGN/QUANT
- `RESQUIGGLE` subworkflow (`subworkflows/local/resquiggle.nf`):
  - `F5C_EVENTALIGN` — opt-in (`--run_f5c`), `f5c index` + `f5c eventalign`
    (`--rna`), joins reads+POD5+genome-BAM by sample; emits `eventalign.tsv.gz`
    (substrate for Phases 3–4)
- QC subworkflow refactored to take explicit `(fastq, summary)` channels so
  basecalled reads/summaries integrate transparently
- Reads feeding QC/align/quant = user FASTQ ∪ Dorado-basecalled FASTQ;
  summaries = user-supplied ∪ Dorado-produced
- `ALIGN` now also emits the genome BAI (needed by f5c)
- Signal test fixtures (`tests/data/signal/`) + `test_signal` profile +
  `samplesheet_signal_test.csv`; full signal path stub-runs green (22 tasks)

### Changed
- `resourceLimits` is now a **closure** in `conf/base.config`. A map literal
  evaluates params eagerly at config-parse (before `-profile` merge) and would
  ignore profile-level `max_cpus`/`max_memory` overrides; a closure defers to
  per-task evaluation. (Discovered via the test profile's `max_cpus=2`.)

### Notes
- Requires **Nextflow ≥24.04** and **Java 17–21**. Built against the strict
  config/script parser (Nextflow 25/26): no top-level statements, no config
  function/variable declarations — replaced `check_max()` with `resourceLimits`.
- Phase 0 + Phase 1 verified green on Nextflow 26.04.3 / Temurin 17.
- Verification is via `-stub-run` (no container engine on the dev box); real
  tool execution happens on HPC with Apptainer or `-profile docker`.
- Resolved: spec's **"Nexxons"** quantifier → **NanoCount** (to be added as a
  second quantifier alongside Salmon in a Phase 1.5 increment).
- Sample sheet schema confirmed/locked.
- Licensed **MIT**.
