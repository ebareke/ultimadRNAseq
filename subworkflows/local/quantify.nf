/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    QUANTIFY — transcript abundance estimation (spec §5.4)

    Salmon in alignment-based mode on the transcriptome BAM produced by
    Minimap2 (-ax map-ont). Emits per-sample quant.sf (standardised output).

    NOTE: the spec also lists "Nexxons" — not a recognised ONT tool; likely
    means NanoCount. Pending clarification before adding a second quantifier.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SALMON_QUANT } from '../../modules/local/salmon_quant.nf'

workflow QUANTIFY {
    take:
    ch_txome_bam   // [ meta, transcriptome_bam ]
    ch_txome_fasta // value: transcriptome FASTA (may be empty)

    main:
    ch_versions   = Channel.empty()
    ch_multiqc_in = Channel.empty()

    SALMON_QUANT ( ch_txome_bam, ch_txome_fasta )

    ch_versions   = ch_versions.mix(SALMON_QUANT.out.versions.first())
    ch_multiqc_in = ch_multiqc_in.mix(SALMON_QUANT.out.results.map { meta, d -> d })

    emit:
    quant         = SALMON_QUANT.out.quant
    multiqc_files = ch_multiqc_in
    versions      = ch_versions
}
