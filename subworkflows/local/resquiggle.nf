/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RESQUIGGLE — signal-to-reference event alignment via f5c (spec §5.2)

    Produces eventalign against TWO references, each joined per sample (by meta)
    with the reads + their POD5 signal:

      • transcriptome  → m6anet / Nanocompore expect transcript-coordinate
                         eventalign (transcript_id + transcript_position)
      • genome (splice) → generic signal-to-reference output / other consumers

    The join restricts each arm to samples that have raw signal; an arm with no
    reference (e.g. no transcriptome supplied) simply yields 0 tasks.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { F5C_EVENTALIGN as F5C_EVENTALIGN_TXOME  } from '../../modules/local/f5c_eventalign.nf'
include { F5C_EVENTALIGN as F5C_EVENTALIGN_GENOME } from '../../modules/local/f5c_eventalign.nf'

workflow RESQUIGGLE {
    take:
    ch_fastq         // [ meta, fastq ]
    ch_pod5          // [ meta, pod5_dir ]
    ch_genome_bam    // [ meta, bam ]
    ch_genome_bai    // [ meta, bai ]
    ch_genome_fa     // value: genome FASTA
    ch_txome_bam     // [ meta, bam ]
    ch_txome_bai     // [ meta, bai ]
    ch_txome_fa      // value: transcriptome FASTA

    main:
    ch_versions = Channel.empty()

    // --- transcriptome eventalign (for modification calling) ---------------
    ch_txome_in = ch_fastq
        .join(ch_pod5)
        .join(ch_txome_bam)
        .join(ch_txome_bai)        // [ meta, fastq, pod5, bam, bai ]
    F5C_EVENTALIGN_TXOME ( ch_txome_in, ch_txome_fa )

    // --- genome eventalign (generic signal-to-reference) -------------------
    ch_genome_in = ch_fastq
        .join(ch_pod5)
        .join(ch_genome_bam)
        .join(ch_genome_bai)
    F5C_EVENTALIGN_GENOME ( ch_genome_in, ch_genome_fa )

    ch_versions = ch_versions.mix(
        F5C_EVENTALIGN_TXOME.out.versions.first(),
        F5C_EVENTALIGN_GENOME.out.versions.first()
    )

    emit:
    eventalign_txome  = F5C_EVENTALIGN_TXOME.out.eventalign    // → m6anet / Nanocompore
    eventalign_genome = F5C_EVENTALIGN_GENOME.out.eventalign
    versions          = ch_versions
}
