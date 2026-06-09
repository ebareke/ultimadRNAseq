process TAILFINDR {
    tag   "$meta.id"
    label 'process_high'

    // tailfindr is an R package distributed via GitHub (adnaniazi/tailfindr) with
    // no Bioconda recipe or official image. Build a custom container (R + tailfindr)
    // and pin it before real runs; the placeholder only satisfies stub wiring.
    // NOTE: tailfindr reads raw FAST5 signal — provide FAST5 (POD5 needs conversion).
    container 'docker.io/ebareke/tailfindr:placeholder'

    input:
    tuple val(meta), path(signal_dir)

    output:
    tuple val(meta), path("*.tails.csv"), emit: tails
    path  "versions.yml",                 emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    // dna/rna mode: RNA enables poly(A) and poly(U) tail estimation
    def mode = task.ext.mode ?: 'rna'
    """
    Rscript -e 'library(tailfindr); \\
        df <- find_tails(fast5_dir="${signal_dir}", \\
                         save_dir=".", \\
                         csv_filename="${prefix}.tails.csv", \\
                         num_cores=${task.cpus}, \\
                         basecall_group="Basecall_1D_000", \\
                         dna_datatype="${mode}")'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tailfindr: \$(Rscript -e 'cat(as.character(packageVersion("tailfindr")))' 2>/dev/null || echo 'unknown')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "read_id,tail_start,tail_end,samples_per_nt,tail_length,file_path" > ${prefix}.tails.csv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tailfindr: placeholder
    END_VERSIONS
    """
}
