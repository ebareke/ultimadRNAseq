/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PREPARE_GENOME — stage and validate reference files for reference-guided mode.

    Phase 1: validates presence and emits value channels for the genome FASTA,
    annotation GTF, and transcriptome FASTA. Future: derive transcriptome from
    genome+GTF via gffread when transcript_fasta is not supplied; build .mmi.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PREPARE_GENOME {
    take:
    fasta             // path | null  : genome FASTA
    gtf               // path | null  : annotation
    transcript_fasta  // path | null  : transcriptome FASTA

    main:
    if (!fasta && !transcript_fasta) {
        error "Reference-guided mode needs at least --fasta (genome) or --transcript_fasta (transcriptome)."
    }

    ch_fasta = fasta
        ? Channel.value(file(fasta, checkIfExists: true))
        : Channel.empty()

    ch_gtf = gtf
        ? Channel.value(file(gtf, checkIfExists: true))
        : Channel.empty()

    ch_txome = transcript_fasta
        ? Channel.value(file(transcript_fasta, checkIfExists: true))
        : Channel.empty()

    emit:
    fasta = ch_fasta
    gtf   = ch_gtf
    txome = ch_txome
}
