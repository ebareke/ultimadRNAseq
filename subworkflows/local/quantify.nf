/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    QUANTIFY — transcript abundance estimation (spec §5.4)

      Salmon    : alignment-based on the coordinate-sorted transcriptome BAM
                  (always, when quantification is enabled).
      NanoCount : ONT-specific EM estimator, opt-in (--run_nanocount). Needs its
                  OWN transcriptome alignment — secondary alignments kept (-N 10)
                  and query-ordered (not coord-sorted) — so it cannot reuse the
                  Salmon BAM. (NanoCount is the SRS "Nexxons" entry.)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SALMON_QUANT       } from '../../modules/local/salmon_quant.nf'
include { MINIMAP2_NANOCOUNT } from '../../modules/local/minimap2_nanocount.nf'
include { NANOCOUNT          } from '../../modules/local/nanocount.nf'

workflow QUANTIFY {
    take:
    ch_txome_bam    // [ meta, transcriptome_bam ]  (coord-sorted, for Salmon)
    ch_txome_fasta  // value: transcriptome FASTA (may be empty)
    ch_fastq        // [ meta, fastq ]  (for the NanoCount-specific alignment)

    main:
    ch_versions   = Channel.empty()
    ch_multiqc_in = Channel.empty()

    // --- Salmon -------------------------------------------------------------
    SALMON_QUANT ( ch_txome_bam, ch_txome_fasta )
    ch_versions   = ch_versions.mix(SALMON_QUANT.out.versions.first())
    ch_multiqc_in = ch_multiqc_in.mix(SALMON_QUANT.out.results.map { meta, d -> d })

    // --- NanoCount (opt-in) -------------------------------------------------
    ch_nanocount = Channel.empty()
    if (params.run_nanocount) {
        MINIMAP2_NANOCOUNT ( ch_fastq, ch_txome_fasta )
        NANOCOUNT ( MINIMAP2_NANOCOUNT.out.bam )
        ch_nanocount = NANOCOUNT.out.counts
        ch_versions  = ch_versions.mix(MINIMAP2_NANOCOUNT.out.versions.first(),
                                       NANOCOUNT.out.versions.first())
    }

    emit:
    quant         = SALMON_QUANT.out.quant
    nanocount     = ch_nanocount
    multiqc_files = ch_multiqc_in
    versions      = ch_versions
}
