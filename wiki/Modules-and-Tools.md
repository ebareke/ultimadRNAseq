# Modules & tools

| Stage | Tool | Module | Container |
|-------|------|--------|-----------|
| Signal convert | pod5 | `pod5_convert.nf` | biocontainers |
| Basecalling | Dorado | `dorado_basecaller.nf` | `ontresearch/dorado` |
| Basecall summary | Dorado | `dorado_summary.nf` | `ontresearch/dorado` |
| uBAM→FASTQ | samtools | `samtools_fastq.nf` | biocontainers |
| Resquiggle | f5c | `f5c_eventalign.nf` | biocontainers |
| QC | NanoPlot | `nanoplot.nf` | biocontainers |
| QC | ToulligQC | `toulligqc.nf` | biocontainers |
| QC | pycoQC | `pycoqc.nf` | biocontainers |
| Alignment | Minimap2 (+samtools) | `minimap2_align.nf` | mulled biocontainer |
| Quantification | Salmon | `salmon_quant.nf` | biocontainers |
| Quantification | NanoCount (opt-in) | `nanocount.nf` (+ `minimap2_nanocount.nf`) | biocontainers |
| m6A | m6anet | `m6anet.nf` | biocontainers |
| Comparative mod | Nanocompore | `nanocompore_collapse.nf`, `nanocompore_sampcomp.nf` | biocontainers |
| Error-based mod | ELIGOS | `eligos_pairdiff.nf` | `piroonj/eligos2` |
| Stoichiometry | nanoRMS | `nanorms.nf` | custom (`containers/nanorms`) |
| Poly(A) | nanopolish polya | `nanopolish_polya.nf` | biocontainers |
| Poly(A)/(U) | tailfindr | `tailfindr.nf` | custom (`containers/tailfindr`) |
| De novo | RATTLE | `rattle.nf` | biocontainers |
| De novo | StringTie2 | `stringtie2.nf` | biocontainers |
| De novo | gffread / gffcompare | `gffread.nf`, `gffcompare.nf` | biocontainers |
| Report | MultiQC | `multiqc.nf` | biocontainers |
| Report | Quarto | `summary_report.nf` | `quarto-dev/quarto` |

## Notes

- **Transcriptome vs genome eventalign**: f5c runs against both; m6anet and
  Nanocompore consume the **transcriptome** eventalign (transcript-coordinate
  calls), while ELIGOS/nanoRMS use the genome BAM.
- **Comparative tools** (Nanocompore, ELIGOS, nanoRMS) build contrasts from the
  `control` sample-sheet flag: each `control=false` (test) sample is compared
  against the `control=true` reference.
- **Container-only tools** (RATTLE, tailfindr, nanoRMS, ELIGOS, Dorado) have no
  Bioconda recipe — use a container engine, not the conda `standard` profile.
  See [[Containers]].
