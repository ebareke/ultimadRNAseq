# Roadmap

Phased delivery plan for `directRNA`. Each phase is independently demoable.

| Phase | Deliverable                                                              | Status   |
|-------|--------------------------------------------------------------------------|----------|
| **0** | Repo skeleton, Nextflow configs, CI scaffold, sample sheet schema        | 🟢 done (smoke test green) |
| **1** | MVP reference-guided: FASTQ → QC → Minimap2 → Salmon → HTML report       | 🟢 wired (stub-validated) |
| **2** | Signal + basecalling: POD5/FAST5 ingest, Dorado, f5c (Uncalled4 later)   | 🟢 wired (stub-validated) |
| **3** | RNA modifications: m6anet, Nanocompore, ELIGOS, nanoRMS                  | 🟢 wired (stub-validated) |
| **4** | Poly(A) tail: nanopolish polya, tailfindr                                | 🟢 wired (stub-validated) |
| **5** | De novo: RATTLE + StringTie2 + gffcompare + de novo quant                | 🟢 wired (stub-validated) |
| **6** | UI + reporting: Quarto HTML+PDF report + Streamlit GUI scaffold          | 🟢 wired (stub-validated) |
| **7** | Validation: nf-test (unit + pipeline), benchmark pointers, CI, docs      | 🟢 done (6/6 tests pass) |

## Foundational decisions (locked)

- **Orchestrator**: Nextflow (DSL2)
- **Conventions**: nf-core (forking/extending `nf-core/nanoseq` patterns)
- **Primary deploy target**: HPC + SLURM + Apptainer; Docker secondary

> **All 8 phases (0–7) are wired and `nf-test`-validated (6/6).** Post-roadmap
> hardening is also done (below). The platform is functionally complete against
> the SRS; the only remaining work is real-data scientific validation on HPC.

## Post-roadmap hardening (done)

- **NanoCount** quantifier added alongside Salmon (`--run_nanocount`) — resolves
  the SRS "Nexxons".
- **Transcriptome-coordinate eventalign** for m6anet/Nanocompore (f5c runs
  against both transcriptome and genome).
- **Apptainer + HPC**: all modules use Galaxy-depot SIFs under `-profile
  apptainer`/`hpc`; SIFs for the custom tools are built, smoke-tested and
  published to GHCR by CI (`.github/workflows/apptainer.yml`).
- **RATTLE** switched to its Bioconda biocontainer; **tailfindr/nanoRMS/ELIGOS**
  ship as CI-built custom images.
- `sgnex` and `signal` real-data profiles + SLURM submission scripts + runbooks.

## Resolved decisions

- **Sample sheet schema** — LOCKED. Columns: sample, condition, replicate, kit,
  fastq/pod5_dir/fast5_dir, control, organism, summary.
- **"Nexxons"** → **NanoCount** (done; opt-in second quantifier).
- **De novo** — RATTLE (reference-free) + StringTie2 (genome-guided) + gffcompare.
- **GUI** — Streamlit results browser (`gui/`).
- **PDF reporting** — Quarto (single `.qmd` → HTML + PDF).

## Remaining (real-data, on HPC)

- SG-NEx FASTQ run and signal + GPU run (runbooks in `docs/`).
- Numerical validation of outputs against published results.

(Previously-deferred items now done: **Uncalled4** signal-to-reference
alignment, and **replicate-aware** contrast grouping for the comparative
modification tools.)
