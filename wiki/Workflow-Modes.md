# Workflow modes

## Reference-guided (`--mode reference`, default)

```
reads → QC → Minimap2 (genome, splice-aware) ─┐
                     └ Minimap2 (transcriptome) → Salmon → quant.sf
        (+ optional) f5c eventalign → modifications · poly(A)
```

- Genome alignment: `-ax splice -uf -k14` (direct-RNA forward strand).
- Transcriptome alignment: `-ax map-ont` → Salmon abundance (+ NanoCount with
  `--run_nanocount`, which does its own `-N 10` query-ordered alignment).
- Needs `--fasta` (+ `--gtf`) and/or `--transcript_fasta`.

## De novo (`--mode denovo`)

```
reads → RATTLE (reference-free) ───────────────→ transcripts → quant
      → StringTie2 -L (genome-guided, if --fasta) → GTF → gffread → gffcompare
```

- **RATTLE** assembles transcripts with no reference at all.
- **StringTie2** (long-read mode) discovers novel isoforms from the genome
  alignment; **gffcompare** characterises them against the annotation.
- Abundance is estimated against each sample's own RATTLE assembly.

## What runs when

| Stage | reference | denovo |
|-------|:---------:|:------:|
| QC | ✔ | ✔ |
| Genome alignment | ✔ (if `--fasta`) | ✔ (if `--fasta`) |
| Salmon quant | ✔ | — |
| RATTLE / StringTie2 | — | ✔ |
| Modifications / poly(A) | opt-in (signal) | opt-in (signal) |

Signal-dependent stages require raw signal + `--run_f5c`; with FASTQ-only input
they produce no tasks.
