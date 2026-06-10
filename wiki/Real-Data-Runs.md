# Real-data runs

Two curated runbooks ship with the pipeline. Full detail is in the repo `docs/`.

## SG-NEx benchmark (FASTQ, reference-guided)

Validate the deterministic core (QC → Minimap2 → Salmon → report) against the
public **SG-NEx** direct-RNA dataset — no GPU.

```bash
# verify SG-NEx sample keys, then:
sbatch assets/run_sgnex.slurm        # -profile sgnex,hpc
```

- Profile: `sgnex` (`conf/sgnex.config`) — GENCODE v44 human references by URL.
- Edit `--account`/`--partition` in the sbatch script; verify FASTQ keys in
  `assets/samplesheet_sgnex.csv` (`aws s3 ls --no-sign-request s3://sg-nex-data/...`).
- Runbook: `docs/sgnex_run.md`.

## Signal + GPU (POD5/FAST5 → modifications & poly(A))

Full epitranscriptomic run: Dorado basecalling on GPU, f5c eventalign, then
modifications and poly(A).

```bash
sbatch assets/run_signal_gpu.slurm   # -profile signal,hpc
```

- Profile: `signal` (`conf/signal.config`) — turns on `run_dorado`, `run_f5c`,
  modifications, poly(A); sets the Dorado model and GPU request.
- Edit the GPU `queue`/partition in `conf/signal.config` and the SLURM
  account/partition in the sbatch script.
- Fill `assets/samplesheet_signal.csv` with your POD5/FAST5 paths; set `control`
  to mark the background sample for comparative modification calling.
- Runbook: `docs/signal_gpu_run.md`.

## Validating correctness

The bundled `tests/data/` fixtures are synthetic (fast CI only). For scientific
validation use public ONT dRNA datasets (SG-NEx, ONT Open Data, IVT/curlcake
controls) and compare, e.g., Salmon TPM vs a published quantification, or m6anet
calls vs known DRACH sites. See `docs/validation.md`.
