/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    QC subworkflow — read-level quality control (spec §5.3)

    Takes explicit fastq and summary channels so it is agnostic to where the
    reads came from (user-provided FASTQ or Dorado basecalling output).

    NanoPlot  + ToulligQC : run on every FASTQ.
    pycoQC                : runs only for samples with a sequencing_summary.txt
                            (user-supplied or produced by Dorado). Skipped
                            cleanly otherwise — no fabricated inputs.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { NANOPLOT  } from '../../modules/local/nanoplot.nf'
include { TOULLIGQC } from '../../modules/local/toulligqc.nf'
include { PYCOQC    } from '../../modules/local/pycoqc.nf'

workflow QC {
    take:
    ch_fastq     // channel: [ meta, fastq ]
    ch_summary   // channel: [ meta, sequencing_summary ]  (may be empty)

    main:
    ch_versions    = Channel.empty()
    ch_multiqc_in  = Channel.empty()

    // --- FASTQ-based QC ------------------------------------------------------
    NANOPLOT  ( ch_fastq )
    TOULLIGQC ( ch_fastq )

    ch_versions   = ch_versions.mix(NANOPLOT.out.versions.first(),
                                    TOULLIGQC.out.versions.first())
    ch_multiqc_in = ch_multiqc_in.mix(NANOPLOT.out.txt.map { meta, f -> f })

    // --- summary-based QC (pycoQC) ------------------------------------------
    // [ meta, summary, bam, bai ]; bam/bai empty until alignment-aware QC.
    ch_pycoqc_in = ch_summary.map { meta, summary -> [ meta, summary, [], [] ] }

    PYCOQC ( ch_pycoqc_in )
    ch_versions   = ch_versions.mix(PYCOQC.out.versions.first())
    ch_multiqc_in = ch_multiqc_in.mix(PYCOQC.out.json.map { meta, f -> f })

    emit:
    nanoplot_txt  = NANOPLOT.out.txt
    multiqc_files = ch_multiqc_in
    versions      = ch_versions
}
