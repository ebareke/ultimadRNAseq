#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    directRNA — Oxford Nanopore Direct RNA-seq Analysis Platform
    Entry point
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { DRNASEQ } from './workflows/drnaseq.nf'

// ----------------------------------------------------------------------------
// Functions (top-level declarations are allowed; bare statements are not —
// Nextflow's strict parser requires imperative code inside workflow/process/fn)
// ----------------------------------------------------------------------------
def banner() {
    log.info """
    ============================================================
      directRNA  v${workflow.manifest.version}
      ONT Direct RNA-seq Analysis Platform
    ============================================================
      profile        : ${workflow.profile}
      mode           : ${params.mode}
      input          : ${params.input ?: '<none>'}
      outdir         : ${params.outdir}
    ============================================================
    """.stripIndent()
}

def helpMessage() {
    log.info """
    Usage:
        nextflow run ebareke/directRNA --input samplesheet.csv --outdir results -profile <docker|apptainer|hpc|test>

    Required:
        --input         Path to sample sheet CSV
        --outdir        Output directory

    Mode:
        --mode          'reference' (default) or 'denovo'

    Reference inputs (reference mode):
        --fasta             Genome FASTA
        --gtf               Gene annotation (GTF/GFF3)
        --transcript_fasta  Transcriptome FASTA (for Salmon)

    Module toggles:
        --skip_qc, --skip_alignment, --skip_quantification,
        --skip_modifications, --skip_polya, --skip_denovo, --skip_multiqc

    Signal processing (off by default):
        --run_dorado, --run_f5c, --run_uncalled4

    Profiles:
        -profile test,docker        Smoke test on local Docker
        -profile hpc                SLURM + Apptainer
        -profile standard           Local + conda
    """.stripIndent()
}

def validateParams() {
    if (!params.input) {
        log.error "Missing required parameter --input (sample sheet CSV)"
        System.exit(1)
    }
    if (!(params.mode in ['reference', 'denovo'])) {
        log.error "--mode must be 'reference' or 'denovo' (got: ${params.mode})"
        System.exit(1)
    }
}

// ----------------------------------------------------------------------------
// Entry workflow
// ----------------------------------------------------------------------------
workflow {
    if (params.help) {
        helpMessage()
        return
    }

    banner()
    validateParams()

    DRNASEQ()
}
