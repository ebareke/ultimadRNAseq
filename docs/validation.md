# Validation

This document describes how `directRNA` is validated (spec §12) and how to
reproduce the checks.

## Strategy

Validation has three layers, all driven by [nf-test](https://www.nf-test.com):

| Layer | What it proves | Where |
|-------|----------------|-------|
| **Module unit tests** | each process declares the right inputs/outputs and emits `versions.yml` | `tests/nftest/*.nf.test` (e.g. `nanoplot`, `minimap2_align`) |
| **Pipeline / integration tests** | the three execution paths wire up and complete, producing the expected output tree | `tests/nftest/pipeline.nf.test` |
| **End-to-end (real tools)** | tools run on real data and produce scientifically valid results | run on HPC with containers (see below) |

The unit and pipeline tests run in **stub mode** (`-stub`): they execute each
process's `stub:` block instead of the real tool, so they validate *wiring,
channel topology, contracts and output structure* without needing containers,
GPUs, or large data. This is what CI runs on every push.

End-to-end validation with the real tools is performed on an HPC/container
environment against benchmark datasets (below) — this is where numerical
correctness is established.

## Running the tests

```bash
# all tests
nf-test test

# just the pipeline (integration) tests
nf-test test tests/nftest/pipeline.nf.test

# a single module
nf-test test tests/nftest/nanoplot.nf.test
```

Requires Nextflow ≥24.04 and Java 17 (see [environment.md](environment.md)).

### Current status

| Test | Result |
|------|--------|
| `pipeline.nf.test` — reference-guided mode | ✅ pass |
| `pipeline.nf.test` — signal + modifications + poly(A) | ✅ pass |
| `pipeline.nf.test` — de novo mode | ✅ pass |
| `nanoplot.nf.test` | ✅ pass |
| `minimap2_align.nf.test` | ✅ pass |

All stub-level tests pass on Nextflow 26.04.3 / Temurin 17.

## Benchmark datasets (for real-tool end-to-end validation)

The bundled `tests/data/` fixtures are tiny synthetic files for fast CI; they
are **not** biologically meaningful. For scientific validation use public ONT
direct-RNA datasets:

- **SG-NEx** (Singapore Nanopore Expression) — direct-RNA cell-line data with
  replicates; the de-facto dRNA benchmark. <https://github.com/GoekeLab/sg-nex-data>
- **nf-core/test-datasets** (`nanoseq` branch) — small ONT test data.
- **ONT Open Data** — RNA002/RNA004 runs, incl. basecalling models.
- **IVT / curlcake controls** — unmodified in-vitro-transcribed references for
  validating RNA-modification calls (the `control` sample-sheet flag).

Recommended validation targets:

- Quantification: correlation of Salmon TPM vs. a reference quantification.
- m6A (m6anet): recovery of known DRACH sites / METTL3-KO depletion.
- Poly(A): agreement of nanopolish/tailfindr length distributions with
  published values for spike-in controls.
- De novo: gffcompare sensitivity/precision of RATTLE/StringTie2 vs. annotation.

## Adding tests

New modules should ship a `tests/nftest/<module>.nf.test` asserting
`process.success`, the expected output channels, and `versions.yml`. New
features should extend `pipeline.nf.test` with a focused assertion on the new
output path.
