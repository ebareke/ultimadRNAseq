process TAILFINDR {
    tag   "$meta.id"
    label 'process_high'

    // tailfindr (adnaniazi/tailfindr R package) — no Bioconda recipe. Container-only;
    // build with containers/tailfindr/Dockerfile (pin TAILFINDR_REF). See docs/containers.md.
    // NOTE: tailfindr reads raw FAST5 signal — provide FAST5 (POD5 needs conversion).
    container 'docker.io/ebareke/tailfindr:1.4'

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
        tailfindr: 1.4
    END_VERSIONS
    """
}
