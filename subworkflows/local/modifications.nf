/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MODIFICATIONS — RNA modification detection (spec §5.5)

    Two families of detector:
      single-sample : m6anet (m6A; model-based, no control)
      comparative   : Nanocompore, ELIGOS-pair, nanoRMS
                      contrasts = control (control==true) vs test (control==false)

    Substrates:
      eventalign (f5c, Phase 2) → m6anet, Nanocompore
      genome BAM + reference    → ELIGOS, nanoRMS

    Contrast pairing is pure channel algebra: split each per-sample channel on
    the `control` flag, then .combine() to pair every test with every control.

    NOTE: m6anet/Nanocompore conventionally expect transcriptome-coordinate
    eventalign; the current f5c eventalign is genome-based — refine before
    real-data runs.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { M6ANET                } from '../../modules/local/m6anet.nf'
include { NANOCOMPORE_COLLAPSE  } from '../../modules/local/nanocompore_collapse.nf'
include { NANOCOMPORE_SAMPCOMP  } from '../../modules/local/nanocompore_sampcomp.nf'
include { ELIGOS_PAIRDIFF       } from '../../modules/local/eligos_pairdiff.nf'
include { NANORMS               } from '../../modules/local/nanorms.nf'

workflow MODIFICATIONS {
    take:
    ch_eventalign   // [ meta, eventalign.tsv.gz ]  (f5c)
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
    // Comparative detectors — build control-vs-test pairs
    // ========================================================================

    // -- Nanocompore: collapse per sample, then pair (eventalign substrate) --
    NANOCOMPORE_COLLAPSE ( ch_eventalign )
    ch_versions = ch_versions.mix(NANOCOMPORE_COLLAPSE.out.versions.first())

    ch_coll      = NANOCOMPORE_COLLAPSE.out.collapsed
    ch_coll_ctrl = ch_coll.filter { meta, d -> meta.control }
    ch_coll_test = ch_coll.filter { meta, d -> !meta.control }

    ch_ncomp_pairs = ch_coll_test
        .combine(ch_coll_ctrl)
        .map { tmeta, tdir, cmeta, cdir ->
            [ [ id: "${tmeta.id}_vs_${cmeta.id}", test: tmeta.id, control: cmeta.id ], tdir, cdir ]
        }
    NANOCOMPORE_SAMPCOMP ( ch_ncomp_pairs, ch_fasta )
    ch_versions = ch_versions.mix(NANOCOMPORE_SAMPCOMP.out.versions.first())

    // -- BAM-based pairs (shared by ELIGOS and nanoRMS) ---------------------
    ch_bam_join = ch_bam.join(ch_bai)            // [ meta, bam, bai ]
    ch_bam_ctrl = ch_bam_join.filter { meta, bam, bai -> meta.control }
    ch_bam_test = ch_bam_join.filter { meta, bam, bai -> !meta.control }

    ch_bam_pairs = ch_bam_test
        .combine(ch_bam_ctrl)
        .map { tmeta, tbam, tbai, cmeta, cbam, cbai ->
            [ [ id: "${tmeta.id}_vs_${cmeta.id}", test: tmeta.id, control: cmeta.id ],
              tbam, tbai, cbam, cbai ]
        }

    // -- ELIGOS: basecalling-error pair_diff_mod ----------------------------
    ELIGOS_PAIRDIFF ( ch_bam_pairs, ch_fasta )
    ch_versions = ch_versions.mix(ELIGOS_PAIRDIFF.out.versions.first())

    // -- nanoRMS: comparative stoichiometry ---------------------------------
    NANORMS ( ch_bam_pairs, ch_fasta )
    ch_versions = ch_versions.mix(NANORMS.out.versions.first())

    emit:
    m6anet_sites  = M6ANET.out.sites
    nanocompore   = NANOCOMPORE_SAMPCOMP.out.results
    eligos        = ELIGOS_PAIRDIFF.out.outdir
    nanorms       = NANORMS.out.stoichiometry
    multiqc_files = ch_multiqc_in
    versions      = ch_versions
}
