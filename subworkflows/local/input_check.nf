/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    INPUT_CHECK — parse and validate the sample sheet
    Emits one [ meta, input ] channel per sample, where `input` carries
    whichever entry point (fastq / pod5_dir / fast5_dir) was provided.

    Validation here is intentionally dependency-free (pure Groovy) so the
    smoke test runs offline. assets/schema_input.json documents the full
    contract and can be enforced with the nf-schema plugin in a later phase.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow INPUT_CHECK {
    take:
    samplesheet   // path to CSV

    main:
    def seen_ids = [] as Set

    ch_samples = Channel
        .fromPath(samplesheet, checkIfExists: true)
        .splitCsv(header: true, strip: true)
        .map { row -> validate_row(row, seen_ids) }

    emit:
    samples  = ch_samples            // [ meta, entrypoint_map ]
}

// ----------------------------------------------------------------------------
// Row-level validation. Throws on contract violations so the run fails fast.
// ----------------------------------------------------------------------------
def validate_row(Map row, Set seen_ids) {
    // --- required: sample id ---
    def id = row.sample?.trim()
    if (!id) {
        error "Sample sheet error: a row is missing the required 'sample' column."
    }
    if (id in seen_ids) {
        error "Sample sheet error: duplicate sample id '${id}'. Sample ids must be unique."
    }
    seen_ids << id

    // --- kit enum ---
    def kit = (row.kit?.trim() ?: 'RNA004').toUpperCase()
    if (!(kit in ['RNA002', 'RNA004'])) {
        error "Sample '${id}': kit must be RNA002 or RNA004 (got '${kit}')."
    }

    // --- at least one entry point ---
    def fastq     = row.fastq?.trim()
    def pod5_dir  = row.pod5_dir?.trim()
    def fast5_dir = row.fast5_dir?.trim()
    if (!fastq && !pod5_dir && !fast5_dir) {
        error "Sample '${id}': provide at least one of fastq, pod5_dir, fast5_dir."
    }

    // --- normalise meta ---
    def meta = [
        id:        id,
        condition: row.condition?.trim() ?: 'none',
        replicate: (row.replicate?.trim() ?: '1'),
        kit:       kit,
        control:   (row.control?.trim()?.toLowerCase() in ['true', '1', 'yes']),
        organism:  row.organism?.trim() ?: 'unknown',
        single_end: true   // dRNA-seq is single-molecule, always single-end
    ]

    // --- resolve entry-point files ---
    // Relative paths resolve against the launch dir first, then fall back to
    // projectDir (so sample sheets shipped with the pipeline / test fixtures
    // work regardless of where Nextflow is launched, e.g. under nf-test).
    def entry = [:]
    if (fastq)     entry.fastq     = resolve_input(fastq)
    if (pod5_dir)  entry.pod5_dir  = resolve_input(pod5_dir)
    if (fast5_dir) entry.fast5_dir = resolve_input(fast5_dir)

    // optional sequencing_summary.txt (enables pycoQC before Phase 2 basecalling)
    def summary = row.summary?.trim()
    if (summary)   entry.summary   = resolve_input(summary)

    return [ meta, entry ]
}

// Resolve an input path. Remote URLs (http/https/s3/...) are passed straight to
// Nextflow's staging; local relative paths resolve against the launch dir first,
// then projectDir (so pipeline-shipped sheets / nf-test isolated dirs work).
def resolve_input(String p) {
    if (p ==~ /(?i)^[a-z][a-z0-9+.-]*:\/\/.*/) return file(p, checkIfExists: true)  // URL/remote
    def f = file(p)
    if (f.exists()) return f
    def alt = file("${projectDir}/${p}")
    if (alt.exists()) return alt
    return file(p, checkIfExists: true)   // not found → throws a clear error
}
