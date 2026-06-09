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
| **7** | Validation: benchmark datasets, end-to-end tests, validation report      | ⚪ planned |

## Foundational decisions (locked)

- **Orchestrator**: Nextflow (DSL2)
- **Conventions**: nf-core (forking/extending `nf-core/nanoseq` patterns)
- **Primary deploy target**: HPC + SLURM + Apptainer; Docker secondary

## Resolved decisions

- **Sample sheet schema** — LOCKED (2026-06-09). Columns: sample, condition,
  replicate, kit, fastq/pod5_dir/fast5_dir, control, organism, summary.
- **"Nexxons"** (spec quantifier, not a real tool) — resolved to **NanoCount**.
  To be added alongside Salmon as a second quantifier in a Phase 1.5 increment.

## Open design questions

- De novo assembler choice — RATTLE vs IsoQuant vs StringTie2-LR
- Optional GUI stack — Streamlit vs Shiny vs no-GUI (MultiQC + nf-core launch only)
- Reporting renderer for PDFs — Quarto vs ReportLab vs LaTeX
