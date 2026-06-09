/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    POLYA — poly(A)/poly(U) tail-length analysis (spec §5.6)

      nanopolish polya : alignment-anchored; needs reads + signal + genome BAM
                         + reference. Joined per sample (signal samples only).
      tailfindr        : alignment-free; reads raw signal directly, estimates
                         both poly(A) and poly(U).

    Both tools were built around FAST5/SLOW5; the pipeline standardises on POD5,
    so real runs need FAST5 retained or a POD5→slow5 conversion (tracked
    refinement). The wiring/stub uses the unified signal channel.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { NANOPOLISH_POLYA } from '../../modules/local/nanopolish_polya.nf'
include { TAILFINDR        } from '../../modules/local/tailfindr.nf'

workflow POLYA {
    take:
    ch_fastq        // [ meta, fastq ]
    ch_signal       // [ meta, signal_dir ]   (POD5, from SIGNAL)
    ch_genome_bam   // [ meta, bam ]
    ch_genome_bai   // [ meta, bai ]
    ch_fasta        // value: genome FASTA

    main:
    ch_versions = Channel.empty()

    // -- nanopolish polya: join reads + signal + alignment by sample ---------
    ch_np_in = ch_fastq
        .join(ch_signal)
        .join(ch_genome_bam)
        .join(ch_genome_bai)
        // [ meta, fastq, signal_dir, bam, bai ]
    NANOPOLISH_POLYA ( ch_np_in, ch_fasta )
    ch_versions = ch_versions.mix(NANOPOLISH_POLYA.out.versions.first())

    // -- tailfindr: raw signal only -----------------------------------------
    TAILFINDR ( ch_signal )
    ch_versions = ch_versions.mix(TAILFINDR.out.versions.first())

    emit:
    nanopolish = NANOPOLISH_POLYA.out.polya
    tailfindr  = TAILFINDR.out.tails
    versions   = ch_versions
}
