/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ALIGN — Minimap2 alignment for dRNA-seq (spec §5.4)

      genome BAM        : splice-aware (-ax splice -uf -k14) — for visualisation
                          and downstream modification/poly(A) tools.
      transcriptome BAM : map-ont — fed to Salmon for quantification.

    Same MINIMAP2_ALIGN module, two aliases with different presets (set by
    withName in conf/modules.config).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MINIMAP2_ALIGN as MINIMAP2_GENOME } from '../../modules/local/minimap2_align.nf'
include { MINIMAP2_ALIGN as MINIMAP2_TXOME  } from '../../modules/local/minimap2_align.nf'

workflow ALIGN {
    take:
    ch_fastq    // [ meta, fastq ]
    ch_fasta    // value: genome FASTA  (may be empty)
    ch_txome    // value: transcriptome FASTA (may be empty)

    main:
    ch_versions   = Channel.empty()
    ch_multiqc_in = Channel.empty()

    // Gating by empty channel: a process stays idle until every input channel
    // has an item, so when the reference channel is empty (FASTA not supplied)
    // the alignment simply produces 0 tasks — no fake/empty reference passed.
    // --- genome alignment (only if a genome FASTA was provided) -------------
    MINIMAP2_GENOME ( ch_fastq, ch_fasta )

    // --- transcriptome alignment (only if a transcriptome FASTA provided) ---
    MINIMAP2_TXOME  ( ch_fastq, ch_txome )

    ch_versions   = ch_versions.mix(MINIMAP2_GENOME.out.versions.first(),
                                    MINIMAP2_TXOME.out.versions.first())
    ch_multiqc_in = ch_multiqc_in.mix(
        MINIMAP2_GENOME.out.flagstat.map { meta, f -> f },
        MINIMAP2_TXOME.out.flagstat.map  { meta, f -> f }
    )

    emit:
    genome_bam    = MINIMAP2_GENOME.out.bam
    genome_bai    = MINIMAP2_GENOME.out.bai
    txome_bam     = MINIMAP2_TXOME.out.bam
    txome_bai     = MINIMAP2_TXOME.out.bai
    multiqc_files = ch_multiqc_in
    versions      = ch_versions
}
