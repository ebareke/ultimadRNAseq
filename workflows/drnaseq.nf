/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Main workflow — reference-guided dRNA-seq (Phase 1, in progress)

      INPUT_CHECK  →  QC  →  [Phase 1.2] align  →  [Phase 1.3] quant  →  MultiQC
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { INPUT_CHECK    } from '../subworkflows/local/input_check.nf'
include { QC             } from '../subworkflows/local/qc.nf'
include { PREPARE_GENOME } from '../subworkflows/local/prepare_genome.nf'
include { ALIGN          } from '../subworkflows/local/align.nf'
include { QUANTIFY       } from '../subworkflows/local/quantify.nf'
include { MULTIQC        } from '../modules/local/multiqc.nf'

workflow DRNASEQ {

    main:
    ch_versions   = Channel.empty()
    ch_multiqc_in = Channel.empty()

    // ------------------------------------------------------------------------
    // 1. Parse & validate sample sheet
    // ------------------------------------------------------------------------
    INPUT_CHECK ( params.input )
    ch_samples = INPUT_CHECK.out.samples

    ch_samples.view { meta, entry ->
        "✓ ${meta.id}  [${meta.condition}/rep${meta.replicate}, ${meta.kit}, " +
        "control=${meta.control}]  inputs: ${entry.keySet().join(', ')}"
    }

    // FASTQ channel reused by QC and alignment
    ch_fastq = ch_samples
        .filter { meta, entry -> entry.containsKey('fastq') }
        .map    { meta, entry -> [ meta, entry.fastq ] }

    // ------------------------------------------------------------------------
    // 2. Quality control (spec §5.3)
    // ------------------------------------------------------------------------
    if (!params.skip_qc) {
        QC ( ch_samples )
        ch_versions   = ch_versions.mix(QC.out.versions)
        ch_multiqc_in = ch_multiqc_in.mix(QC.out.multiqc_files)
    }

    // ------------------------------------------------------------------------
    // 3. Alignment — Minimap2 (spec §5.4), reference mode only
    // ------------------------------------------------------------------------
    ch_genome_bam = Channel.empty()
    ch_txome_bam  = Channel.empty()
    ch_txome_fa   = Channel.empty()
    if (params.mode == 'reference' && !params.skip_alignment) {
        PREPARE_GENOME ( params.fasta, params.gtf, params.transcript_fasta )
        ALIGN ( ch_fastq, PREPARE_GENOME.out.fasta, PREPARE_GENOME.out.txome )

        ch_genome_bam = ALIGN.out.genome_bam
        ch_txome_bam  = ALIGN.out.txome_bam
        ch_txome_fa   = PREPARE_GENOME.out.txome
        ch_versions   = ch_versions.mix(ALIGN.out.versions)
        ch_multiqc_in = ch_multiqc_in.mix(ALIGN.out.multiqc_files)
    }

    // ------------------------------------------------------------------------
    // 4. Quantification — Salmon (spec §5.4), reference mode only
    // ------------------------------------------------------------------------
    if (params.mode == 'reference' && !params.skip_quantification) {
        QUANTIFY ( ch_txome_bam, ch_txome_fa )
        ch_versions   = ch_versions.mix(QUANTIFY.out.versions)
        ch_multiqc_in = ch_multiqc_in.mix(QUANTIFY.out.multiqc_files)
    }

    // ------------------------------------------------------------------------
    // 5. Aggregate report — MultiQC (spec §8) + provenance (spec §11)
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
    }

    emit:
    samples       = ch_samples
    multiqc_files = ch_multiqc_in
    versions      = ch_versions
}
