/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RESQUIGGLE — signal-to-reference event alignment via f5c (spec §5.2)

    Joins, per sample (by meta), the basecalled reads + their POD5 signal +
    the splice-aware genome BAM, then runs `f5c index` + `f5c eventalign`.
    The join naturally restricts this to samples that have raw signal — a
    FASTQ-only sample has no POD5 and is dropped before f5c.

    The eventalign output is the substrate for Phase 3 (m6anet/Nanocompore)
    and Phase 4 (nanopolish polya).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { F5C_EVENTALIGN } from '../../modules/local/f5c_eventalign.nf'

workflow RESQUIGGLE {
    take:
    ch_fastq        // [ meta, fastq ]
    ch_pod5         // [ meta, pod5_dir ]
    ch_genome_bam   // [ meta, bam ]
    ch_genome_bai   // [ meta, bai ]
    ch_fasta        // value: genome FASTA

    main:
    ch_versions = Channel.empty()

    // inner-join by meta → only samples with reads + signal + alignment proceed
    ch_f5c_in = ch_fastq
        .join(ch_pod5)
        .join(ch_genome_bam)
        .join(ch_genome_bai)
        // [ meta, fastq, pod5_dir, bam, bai ]

    F5C_EVENTALIGN ( ch_f5c_in, ch_fasta )
    ch_versions = ch_versions.mix(F5C_EVENTALIGN.out.versions.first())

    emit:
    eventalign = F5C_EVENTALIGN.out.eventalign
    versions   = ch_versions
}
