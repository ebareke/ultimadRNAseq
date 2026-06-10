/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Main workflow — reference-guided dRNA-seq (Phase 1, in progress)

      INPUT_CHECK  →  QC  →  [Phase 1.2] align  →  [Phase 1.3] quant  →  MultiQC
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { INPUT_CHECK    } from '../subworkflows/local/input_check.nf'
include { SIGNAL         } from '../subworkflows/local/signal.nf'
include { RESQUIGGLE     } from '../subworkflows/local/resquiggle.nf'
include { MODIFICATIONS  } from '../subworkflows/local/modifications.nf'
include { POLYA          } from '../subworkflows/local/polya.nf'
include { DENOVO         } from '../subworkflows/local/denovo.nf'
include { QC             } from '../subworkflows/local/qc.nf'
include { PREPARE_GENOME } from '../subworkflows/local/prepare_genome.nf'
include { ALIGN          } from '../subworkflows/local/align.nf'
include { QUANTIFY       } from '../subworkflows/local/quantify.nf'
include { MULTIQC        } from '../modules/local/multiqc.nf'
include { SUMMARY_REPORT } from '../modules/local/summary_report.nf'

workflow DRNASEQ {

    main:
    ch_versions   = Channel.empty()
    ch_multiqc_in = Channel.empty()
    ch_report     = Channel.empty()   // cross-module files for the summary report

    // ------------------------------------------------------------------------
    // 1. Parse & validate sample sheet
    // ------------------------------------------------------------------------
    INPUT_CHECK ( params.input )
    ch_samples = INPUT_CHECK.out.samples

    ch_samples.view { meta, entry ->
        "✓ ${meta.id}  [${meta.condition}/rep${meta.replicate}, ${meta.kit}, " +
        "control=${meta.control}]  inputs: ${entry.keySet().join(', ')}"
    }

    // ------------------------------------------------------------------------
    // 2. Signal processing & basecalling (spec §5.2)
    //    FAST5→POD5 convert always; Dorado basecalling opt-in (--run_dorado).
    // ------------------------------------------------------------------------
    SIGNAL ( ch_samples )
    ch_versions = ch_versions.mix(SIGNAL.out.versions)

    // Reads feeding QC/align/quant = user-provided FASTQ ∪ Dorado-basecalled FASTQ
    ch_provided_fastq = ch_samples
        .filter { meta, entry -> entry.containsKey('fastq') }
        .map    { meta, entry -> [ meta, entry.fastq ] }
    ch_fastq = ch_provided_fastq.mix(SIGNAL.out.fastq)

    // Sequencing summaries (pycoQC) = user-provided ∪ Dorado-produced
    ch_provided_summary = ch_samples
        .filter { meta, entry -> entry.containsKey('summary') }
        .map    { meta, entry -> [ meta, entry.summary ] }
    ch_summary = ch_provided_summary.mix(SIGNAL.out.summary)

    // ------------------------------------------------------------------------
    // 3. Quality control (spec §5.3)
    // ------------------------------------------------------------------------
    if (!params.skip_qc) {
        QC ( ch_fastq, ch_summary )
        ch_versions   = ch_versions.mix(QC.out.versions)
        ch_multiqc_in = ch_multiqc_in.mix(QC.out.multiqc_files)
    }

    // ------------------------------------------------------------------------
    // 4. Alignment — Minimap2 (spec §5.4).
    //    Runs in BOTH modes whenever a reference is supplied: the genome BAM is
    //    needed by f5c/modifications/poly(A) and by StringTie2 (de novo). The
    //    transcriptome arm self-gates on --transcript_fasta (empty channel).
    // ------------------------------------------------------------------------
    ch_genome_bam = Channel.empty()
    ch_genome_bai = Channel.empty()
    ch_txome_bam  = Channel.empty()
    ch_txome_bai  = Channel.empty()
    ch_txome_fa   = Channel.empty()
    ch_genome_fa  = Channel.empty()
    ch_gtf        = Channel.empty()
    if (!params.skip_alignment && (params.fasta || params.transcript_fasta)) {
        PREPARE_GENOME ( params.fasta, params.gtf, params.transcript_fasta )
        ALIGN ( ch_fastq, PREPARE_GENOME.out.fasta, PREPARE_GENOME.out.txome )

        ch_genome_bam = ALIGN.out.genome_bam
        ch_genome_bai = ALIGN.out.genome_bai
        ch_txome_bam  = ALIGN.out.txome_bam
        ch_txome_bai  = ALIGN.out.txome_bai
        ch_txome_fa   = PREPARE_GENOME.out.txome
        ch_genome_fa  = PREPARE_GENOME.out.fasta
        ch_gtf        = PREPARE_GENOME.out.gtf
        ch_versions   = ch_versions.mix(ALIGN.out.versions)
        ch_multiqc_in = ch_multiqc_in.mix(ALIGN.out.multiqc_files)
    }

    // ------------------------------------------------------------------------
    // 4b. Resquiggle — f5c event alignment (spec §5.2), opt-in (--run_f5c).
    //     Produces transcriptome- AND genome-coordinate eventalign; the
    //     transcriptome one is the correct substrate for m6anet / Nanocompore.
    // ------------------------------------------------------------------------
    ch_eventalign_txome = Channel.empty()
    if (params.run_f5c) {
        RESQUIGGLE ( ch_fastq, SIGNAL.out.pod5,
                     ch_genome_bam, ch_genome_bai, ch_genome_fa,
                     ch_txome_bam,  ch_txome_bai,  ch_txome_fa )
        ch_eventalign_txome = RESQUIGGLE.out.eventalign_txome
        ch_versions         = ch_versions.mix(RESQUIGGLE.out.versions)
    }

    // ------------------------------------------------------------------------
    // 4c. RNA modification detection (spec §5.5), opt-in (!skip_modifications).
    //     m6anet + Nanocompore consume the TRANSCRIPTOME-coordinate eventalign;
    //     ELIGOS/nanoRMS use the genome BAM (error-based / per-read).
    // ------------------------------------------------------------------------
    if (!params.skip_modifications) {
        MODIFICATIONS ( ch_eventalign_txome, ch_genome_bam, ch_genome_bai, ch_genome_fa )
        ch_versions   = ch_versions.mix(MODIFICATIONS.out.versions)
        ch_multiqc_in = ch_multiqc_in.mix(MODIFICATIONS.out.multiqc_files)
        ch_report     = ch_report.mix(
            MODIFICATIONS.out.m6anet_sites.map { meta, f -> f },
            MODIFICATIONS.out.nanocompore.map  { meta, f -> f },
            MODIFICATIONS.out.nanorms.map      { meta, f -> f }
        )
    }

    // ------------------------------------------------------------------------
    // 4d. Poly(A)/poly(U) tail analysis (spec §5.6), opt-in (!skip_polya).
    //     nanopolish polya (alignment-anchored) + tailfindr (raw signal).
    // ------------------------------------------------------------------------
    if (!params.skip_polya) {
        POLYA ( ch_fastq, SIGNAL.out.pod5, ch_genome_bam, ch_genome_bai, ch_genome_fa )
        ch_versions = ch_versions.mix(POLYA.out.versions)
        ch_report   = ch_report.mix(
            POLYA.out.nanopolish.map { meta, f -> f },
            POLYA.out.tailfindr.map  { meta, f -> f }
        )
    }

    // ------------------------------------------------------------------------
    // 5. Quantification — Salmon (spec §5.4), reference mode only
    // ------------------------------------------------------------------------
    if (params.mode == 'reference' && !params.skip_quantification) {
        QUANTIFY ( ch_txome_bam, ch_txome_fa )
        ch_versions   = ch_versions.mix(QUANTIFY.out.versions)
        ch_multiqc_in = ch_multiqc_in.mix(QUANTIFY.out.multiqc_files)
    }

    // ------------------------------------------------------------------------
    // 5b. De novo transcript discovery (spec §5.7), denovo mode only.
    //     RATTLE (reference-free) + StringTie2 (genome-guided, if reference) +
    //     gffcompare characterisation + abundance against the de novo assembly.
    // ------------------------------------------------------------------------
    if (params.mode == 'denovo' && !params.skip_denovo) {
        DENOVO ( ch_fastq, ch_genome_bam, ch_genome_bai, ch_genome_fa, ch_gtf )
        ch_versions = ch_versions.mix(DENOVO.out.versions)
        ch_report   = ch_report.mix(
            DENOVO.out.rattle_transcripts.map { meta, f -> f },
            DENOVO.out.stringtie_gtf.map      { meta, f -> f },
            DENOVO.out.quant.map              { meta, f -> f }
        )
    }

    // ------------------------------------------------------------------------
    // 6. Aggregate report — MultiQC (spec §8) + provenance (spec §11)
    // ------------------------------------------------------------------------
    // Collate all software versions into one provenance file...
    ch_versions_file = ch_versions
        .unique()
        .collectFile(
            name: 'software_versions.yml',
            storeDir: "${params.outdir}/pipeline_info"
        )

    if (!params.skip_multiqc) {
        ch_multiqc_config = Channel.fromPath("${projectDir}/assets/multiqc_config.yml", checkIfExists: true)

        // ...and fold it into the MultiQC inputs alongside tool reports.
        ch_report_files = ch_multiqc_in
            .mix(ch_versions_file)
            .collect()

        MULTIQC ( ch_report_files, ch_multiqc_config.collect() )
        ch_multiqc_in = ch_multiqc_in.mix(MULTIQC.out.report)
    }

    // ------------------------------------------------------------------------
    // 7. Unified summary report — Quarto HTML + PDF (spec §8)
    // ------------------------------------------------------------------------
    if (!params.skip_report) {
        // human-readable run summary (parameters & provenance) for the report
        def summary_text = """\
            pipeline: directRNA ${workflow.manifest.version}
            run_name: ${workflow.runName}
            mode: ${params.mode}
            profile: ${workflow.profile}
            input: ${params.input}
            outdir: ${params.outdir}
            run_dorado: ${params.run_dorado}
            run_f5c: ${params.run_f5c}
            skip_modifications: ${params.skip_modifications}
            skip_polya: ${params.skip_polya}
            skip_denovo: ${params.skip_denovo}
            """.stripIndent()
        ch_run_summary = Channel.of(summary_text).collectFile(name: 'run_summary.yml')

        ch_report_in = ch_report.mix(ch_multiqc_in).collect().ifEmpty([])
        ch_qmd       = Channel.fromPath("${projectDir}/assets/report/report.qmd", checkIfExists: true)

        SUMMARY_REPORT ( ch_report_in, ch_qmd.collect(), ch_versions_file, ch_run_summary )
    }

    emit:
    samples       = ch_samples
    multiqc_files = ch_multiqc_in
    versions      = ch_versions
}
