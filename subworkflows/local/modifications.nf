/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MODIFICATIONS — RNA modification detection (spec §5.5)

    Two families of detector:
      single-sample : m6anet (m6A; model-based, no control)
      comparative   : Nanocompore, ELIGOS-pair, nanoRMS

    Comparative contrasts are REPLICATE-AWARE: samples are grouped, not paired
    one-by-one. The control group = all samples with control==true (pooled
    background). Each test group = samples with control==false sharing a
    `condition`. Every test condition is contrasted against the control group.
      • Nanocompore (eventalign): pass each side's replicate collapse files as a
        list (native --file_list1/2 replicate support).
      • ELIGOS / nanoRMS (BAM): merge each group's replicate BAMs (SAMTOOLS_MERGE)
        then pair the merged condition BAMs.

    Substrates: eventalign (f5c) → m6anet, Nanocompore; genome BAM → ELIGOS, nanoRMS.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { M6ANET                } from '../../modules/local/m6anet.nf'
include { NANOCOMPORE_COLLAPSE  } from '../../modules/local/nanocompore_collapse.nf'
include { NANOCOMPORE_SAMPCOMP  } from '../../modules/local/nanocompore_sampcomp.nf'
include { SAMTOOLS_MERGE        } from '../../modules/local/samtools_merge.nf'
include { ELIGOS_PAIRDIFF       } from '../../modules/local/eligos_pairdiff.nf'
include { NANORMS               } from '../../modules/local/nanorms.nf'

workflow MODIFICATIONS {
    take:
    ch_eventalign   // [ meta, eventalign.tsv.gz ]  (transcriptome, from f5c)
    ch_bam          // [ meta, genome_bam ]
    ch_bai          // [ meta, genome_bai ]
    ch_fasta        // value: reference FASTA

    main:
    ch_versions   = Channel.empty()
    ch_multiqc_in = Channel.empty()

    // ========================================================================
    // Single-sample: m6anet (m6A)
    // ========================================================================
    M6ANET ( ch_eventalign )
    ch_versions = ch_versions.mix(M6ANET.out.versions.first())

    // ========================================================================
    // Nanocompore — replicate-aware (eventalign substrate)
    // ========================================================================
    NANOCOMPORE_COLLAPSE ( ch_eventalign )
    ch_versions = ch_versions.mix(NANOCOMPORE_COLLAPSE.out.versions.first())

    ch_coll = NANOCOMPORE_COLLAPSE.out.collapsed                 // [ meta, dir ]

    // control group: all collapse dirs from control==true samples (one list)
    ch_coll_ctrl = ch_coll
        .filter { meta, d -> meta.control }
        .map    { meta, d -> [ 'control', d ] }
        .groupTuple()                                           // [ 'control', [dirs] ]

    // test groups: collapse dirs grouped by condition (control==false)
    ch_coll_test = ch_coll
        .filter { meta, d -> !meta.control }
        .map    { meta, d -> [ meta.condition, d ] }
        .groupTuple()                                           // [ condition, [dirs] ]

    ch_ncomp = ch_coll_test
        .combine(ch_coll_ctrl)
        .map { tcond, tdirs, cname, cdirs ->
            [ [ id: "${tcond}_vs_control", test: tcond, control: 'control' ], tdirs, cdirs ]
        }
    NANOCOMPORE_SAMPCOMP ( ch_ncomp, ch_fasta )
    ch_versions = ch_versions.mix(NANOCOMPORE_SAMPCOMP.out.versions.first())

    // ========================================================================
    // BAM-based (ELIGOS, nanoRMS) — merge replicates per group, then pair
    // ========================================================================
    ch_bam_join = ch_bam.join(ch_bai)                           // [ meta, bam, bai ]

    // one channel of groups keyed by [id, is_control]; merge each group's BAMs
    ch_groups = ch_bam_join
        .map { meta, bam, bai ->
            def g = meta.control ? 'control' : meta.condition
            [ [ id: g, is_control: meta.control ], bam ]
        }
        .groupTuple()                                           // [ [id,is_control], [bams] ]
    SAMTOOLS_MERGE ( ch_groups )
    ch_versions = ch_versions.mix(SAMTOOLS_MERGE.out.versions.first())

    ch_merged_ctrl = SAMTOOLS_MERGE.out.bam.filter { meta, bam, bai ->  meta.is_control }
    ch_merged_test = SAMTOOLS_MERGE.out.bam.filter { meta, bam, bai -> !meta.is_control }

    ch_bam_pairs = ch_merged_test
        .combine(ch_merged_ctrl)
        .map { tmeta, tbam, tbai, cmeta, cbam, cbai ->
            [ [ id: "${tmeta.id}_vs_control", test: tmeta.id, control: 'control' ],
              tbam, tbai, cbam, cbai ]
        }

    ELIGOS_PAIRDIFF ( ch_bam_pairs, ch_fasta )
    NANORMS         ( ch_bam_pairs, ch_fasta )
    ch_versions = ch_versions.mix(ELIGOS_PAIRDIFF.out.versions.first(),
                                  NANORMS.out.versions.first())

    emit:
    m6anet_sites  = M6ANET.out.sites
    nanocompore   = NANOCOMPORE_SAMPCOMP.out.results
    eligos        = ELIGOS_PAIRDIFF.out.outdir
    nanorms       = NANORMS.out.stoichiometry
    multiqc_files = ch_multiqc_in
    versions      = ch_versions
}
