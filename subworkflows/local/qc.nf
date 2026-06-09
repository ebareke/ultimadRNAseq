/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    QC subworkflow — read-level quality control (spec §5.3)

    NanoPlot  + ToulligQC : run on FASTQ (always available at any entry point
                            once basecalled reads exist).
    pycoQC                : requires a sequencing_summary.txt; runs only for
                            samples that provide one (the `summary` column, or
                            Phase 2 basecalling output). Silently skipped
                            otherwise — no fabricated inputs.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { NANOPLOT  } from '../../modules/local/nanoplot.nf'
include { TOULLIGQC } from '../../modules/local/toulligqc.nf'
include { PYCOQC    } from '../../modules/local/pycoqc.nf'

workflow QC {
    take:
    ch_samples   // channel: [ meta, entry_map ]

    main:
    ch_versions    = Channel.empty()
    ch_multiqc_in  = Channel.empty()

    // --- FASTQ-based QC ------------------------------------------------------
    ch_fastq = ch_samples
        .filter { meta, entry -> entry.containsKey('fastq') }
        .map    { meta, entry -> [ meta, entry.fastq ] }

    NANOPLOT  ( ch_fastq )
    TOULLIGQC ( ch_fastq )

    ch_versions   = ch_versions.mix(NANOPLOT.out.versions.first(),
                                    TOULLIGQC.out.versions.first())
    ch_multiqc_in = ch_multiqc_in.mix(NANOPLOT.out.txt.map { meta, f -> f })

    // --- summary-based QC (pycoQC) ------------------------------------------
    // Build [ meta, summary, bam, bai ]; bam/bai empty for now (Phase 1).
    ch_summary = ch_samples
        .filter { meta, entry -> entry.containsKey('summary') }
        .map    { meta, entry -> [ meta, entry.summary, [], [] ] }

    PYCOQC ( ch_summary )
    ch_versions   = ch_versions.mix(PYCOQC.out.versions.first())
    ch_multiqc_in = ch_multiqc_in.mix(PYCOQC.out.json.map { meta, f -> f })

    emit:
    nanoplot_txt  = NANOPLOT.out.txt        // for downstream summaries
    multiqc_files = ch_multiqc_in           // files to feed MultiQC
    versions      = ch_versions
}
