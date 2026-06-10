# Development

Nextflow **DSL2**, nf-core conventions. Full guide: `docs/development.md`.

## Layout

```
main.nf · nextflow.config · nf-test.config
conf/            config + profiles (base, modules, test*, sgnex, signal)
workflows/       drnaseq.nf (top-level)
subworkflows/local/   input_check, signal, qc, prepare_genome, align,
                      resquiggle, modifications, polya, quantify, denovo
modules/local/   one tool per file (+ stub block + versions.yml)
assets/          sample sheets, schema, report template, run scripts
containers/      custom Dockerfiles + build_and_push.sh
tests/nftest/    nf-test unit + pipeline tests
gui/             Streamlit results browser
docs/ · wiki/    documentation
```

## Strict-parser rules (Nextflow ≥25)

- No top-level statements in scripts; imperative code in `workflow {}`/functions.
- No function/variable declarations in config; use closures for dynamic
  directives. `resourceLimits` is a **closure** so params resolve after profile
  merge.
- Every process: a `process_*` label, `conda` + `container`, a `stub:` block,
  and a `versions.yml`.

## Patterns

- **Empty-channel gating** to skip stages without `if`.
- **Module aliasing** (`include { X as X_A }`) + `withName` ext.args for presets.
- **Per-sample references** carried in the tuple and `.join`-ed by `meta`.
- **Contrasts** via `filter`(`control`) + `.combine()`.

## Add a module

1. `modules/local/<tool>.nf` with `stub:` + `versions.yml`.
2. Wire into a subworkflow; mix versions; emit outputs.
3. `withName` block in `conf/modules.config`.
4. `tests/nftest/<tool>.nf.test`.
5. No Bioconda? add `containers/<tool>/Dockerfile`.

## Test

```bash
nf-test test
nextflow run . -profile test -stub-run --outdir results
```

CI runs the smoke test + nf-test (stub) on every push.
