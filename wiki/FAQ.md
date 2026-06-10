# FAQ

**Which inputs are supported?**
POD5, FAST5 (auto-converted to POD5), and FASTQ. At least one per sample. Paths
may be local or remote URLs (`http(s)://`, `s3://`).

**Do I need a GPU?**
Only for Dorado basecalling (`--run_dorado`). FASTQ entry needs no GPU. See
[[Real-Data-Runs]].

**Why do modifications / poly(A) produce no output?**
They need raw signal **and** `--run_f5c` (and `--skip_modifications false` /
`--skip_polya false`). With FASTQ-only input there is no signal, so those stages
yield 0 tasks by design.

**`standard`/conda profile fails for some tools.**
RATTLE, tailfindr, nanoRMS, ELIGOS and Dorado have no Bioconda recipe — they are
container-only. Use `-profile docker` or `apptainer`. See [[Containers]].

**Config parse / Java errors.**
Requires **Nextflow ≥24.04** and **Java 17–21**. Older Java/Nextflow will fail
on the strict parser and `resourceLimits`. See [[Installation]].

**Reference-guided vs de novo?**
`--mode reference` (Minimap2 + Salmon) or `--mode denovo` (RATTLE + StringTie2).
See [[Workflow-Modes]].

**How do I validate scientific correctness?**
The bundled test data is synthetic (CI only). Run real public data (SG-NEx) and
compare outputs to published results — `docs/validation.md`.

**Where are versions / parameters recorded?**
`<outdir>/pipeline_info/` — `software_versions.yml`, execution timeline, trace,
and DAG (spec §11).

**Can I resume a failed run?**
Yes — add `-resume`; completed steps are skipped.

**How do I browse results?**
`streamlit run gui/app.py -- --results <outdir>` (see `gui/README.md`).
