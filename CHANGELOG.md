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
- Open question: spec lists **"Nexxons"** as a quantifier — not a known ONT
  tool. Implemented Salmon; likely they meant **NanoCount**. Needs clarification.
