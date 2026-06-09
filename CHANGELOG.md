# Changelog

All notable changes to `directRNA` will be documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
