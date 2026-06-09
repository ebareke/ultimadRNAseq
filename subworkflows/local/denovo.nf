/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    DENOVO — de novo transcript discovery (spec §5.7, mode='denovo')

    Two complementary strategies:
      reference-free   : RATTLE (cluster/correct/polish) → transcripts.fa
      genome-guided    : StringTie2 (-L) → novel-isoform GTF
                         → gffread (extract FASTA) + gffcompare (characterise)

    Post-assembly: align reads back to the RATTLE de novo transcriptome
    (per-sample reference) and quantify abundance with Salmon.

    StringTie2/gffread/gffcompare run only when a genome alignment + reference
    are available (empty-channel gating); RATTLE always runs.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { RATTLE          } from '../../modules/local/rattle.nf'
include { STRINGTIE2      } from '../../modules/local/stringtie2.nf'
include { GFFREAD         } from '../../modules/local/gffread.nf'
include { GFFCOMPARE      } from '../../modules/local/gffcompare.nf'
include { MINIMAP2_DENOVO } from '../../modules/local/minimap2_denovo.nf'
include { SALMON_DENOVO   } from '../../modules/local/salmon_denovo.nf'

workflow DENOVO {
    take:
    ch_fastq        // [ meta, fastq ]
    ch_genome_bam   // [ meta, bam ]   (may be empty if no genome)
    ch_genome_bai   // [ meta, bai ]
    ch_genome_fa    // value: genome FASTA (may be empty)
    ch_gtf          // value: annotation GTF (may be empty)

    main:
    ch_versions = Channel.empty()

    // ===== reference-free: RATTLE ==========================================
    RATTLE ( ch_fastq )
    ch_versions = ch_versions.mix(RATTLE.out.versions.first())

    // ===== genome-guided: StringTie2 (+ characterisation) ==================
    STRINGTIE2 ( ch_genome_bam.join(ch_genome_bai), ch_gtf )
    GFFREAD    ( STRINGTIE2.out.gtf, ch_genome_fa )
    GFFCOMPARE ( STRINGTIE2.out.gtf, ch_gtf )
    ch_versions = ch_versions.mix(
        STRINGTIE2.out.versions.first(),
        GFFREAD.out.versions.first(),
        GFFCOMPARE.out.versions.first()
    )

    // ===== quantify against the RATTLE de novo transcriptome ===============
    // per-sample reference: join reads with the sample's own assembly
    ch_denovo_align_in = ch_fastq.join(RATTLE.out.transcripts)   // [meta, reads, transcripts]
    MINIMAP2_DENOVO ( ch_denovo_align_in )

    ch_denovo_quant_in = MINIMAP2_DENOVO.out.bam
        .join(RATTLE.out.transcripts)                            // [meta, bam, transcripts]
    SALMON_DENOVO ( ch_denovo_quant_in )

    ch_versions = ch_versions.mix(
        MINIMAP2_DENOVO.out.versions.first(),
        SALMON_DENOVO.out.versions.first()
    )

    emit:
    rattle_transcripts    = RATTLE.out.transcripts
    stringtie_gtf         = STRINGTIE2.out.gtf
    stringtie_transcripts = GFFREAD.out.transcripts
    gffcompare            = GFFCOMPARE.out.results
    quant                 = SALMON_DENOVO.out.quant
    versions              = ch_versions
}
