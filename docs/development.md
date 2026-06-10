# Developer guide

How `directRNA` is structured and how to extend it.

## Architecture

Nextflow **DSL2**, nf-core conventions. The entry point validates params and
dispatches to one workflow that chains subworkflows; each subworkflow composes
single-tool process modules.

```
main.nf
└── workflows/drnaseq.nf
    ├── subworkflows/local/input_check.nf      parse + validate sample sheet
    ├── subworkflows/local/signal.nf           POD5 convert · Dorado · summary · fastq
    ├── subworkflows/local/qc.nf               NanoPlot · ToulligQC · pycoQC
    ├── subworkflows/local/prepare_genome.nf   stage references
    ├── subworkflows/local/align.nf            Minimap2 (genome + transcriptome)
    ├── subworkflows/local/resquiggle.nf       f5c eventalign (txome + genome)
    ├── subworkflows/local/modifications.nf    m6anet · Nanocompore · ELIGOS · nanoRMS
    ├── subworkflows/local/polya.nf            nanopolish polya · tailfindr
    ├── subworkflows/local/quantify.nf         Salmon
    ├── subworkflows/local/denovo.nf           RATTLE · StringTie2 · gffcompare · quant
    └── modules/local/multiqc.nf, summary_report.nf
```

Layout: `conf/` (config + profiles), `modules/local/` (one tool per file),
`subworkflows/local/`, `assets/` (sample sheets, schema, report template),
`containers/` (custom Dockerfiles), `tests/nftest/`, `gui/`, `docs/`.

## Conventions (built for the Nextflow strict parser, ≥25)

- **No top-level statements** in scripts — imperative code lives in
  `workflow {}` / functions.
- **No function or variable declarations in config** — use closures for
  dynamic directives. Resource ceilings use `resourceLimits` (a closure, so
  params resolve *after* profile merge).
- Every process emits `versions.yml` keyed by `${task.process}`; these collate
  to `pipeline_info/software_versions.yml`.
- Every process has a `stub:` block producing dummy outputs — this is what the
  test suite and CI exercise.

## Key patterns

- **Empty-channel gating**: a process stays idle until all input channels have
  an item, so an unsupplied reference ⇒ 0 tasks (no `if` needed).
- **Module aliasing**: one module, multiple presets via
  `include { X as X_A }` + `withName` ext.args (e.g. Minimap2 genome/txome,
  f5c txome/genome eventalign).
- **Per-sample references** (de novo) are carried *inside the tuple*
  (`[meta, reads, transcripts]`) and `.join`-ed by `meta`, not paired by order.
- **Control-vs-test contrasts**: `filter { meta.control }` / `!control` +
  `.combine()` pairs each test sample with each control.

## Add a module

1. `modules/local/<tool>.nf` — `tag`, a `process_*` label, `conda` +
   `container` directives, `script:` + a `stub:` block, and `versions.yml`.
2. Wire it into the relevant subworkflow (mix versions; emit outputs).
3. Add a `withName` block in `conf/modules.config` (publishDir, ext.args).
4. Add `tests/nftest/<tool>.nf.test` asserting outputs + versions.
5. If no Bioconda recipe: add `containers/<tool>/Dockerfile` and document in
   [containers.md](containers.md).

## Testing

```bash
nf-test test                              # all
nf-test test tests/nftest/pipeline.nf.test
nextflow run . -profile test -stub-run --outdir results   # quick wiring check
```

CI (`.github/workflows/ci.yml`) runs the smoke test and `nf-test` in stub on
every push. Container images build via `.github/workflows/containers.yml`.

## Releasing

Bump `manifest.version` in `nextflow.config`, update `CHANGELOG.md`, tag.

## Known refinements

Tracked in `CHANGELOG.md` — e.g. replicate-aware contrast grouping, real
benchmark validation of numerical outputs, POD5→slow5 for nanopolish/tailfindr.
