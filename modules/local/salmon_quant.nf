process SALMON_QUANT {
    tag   "$meta.id"
    label 'process_medium'

    conda "bioconda::salmon=1.10.3"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/salmon:1.10.3--haf24da9_3' :
        'biocontainers/salmon:1.10.3--haf24da9_3' }"

    input:
    tuple val(meta), path(bam)   // transcriptome-aligned BAM (from minimap2 -ax map-ont)
    path  transcript_fasta

    output:
    tuple val(meta), path("${meta.id}"),             emit: results
    tuple val(meta), path("${meta.id}/quant.sf"),    emit: quant
    path  "versions.yml",                            emit: versions

    script:
    // `--ont` tunes Salmon's model for nanopore long reads in alignment mode.
    def args   = task.ext.args   ?: '--ont'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    salmon quant \\
        --threads $task.cpus \\
        --libType A \\
        $args \\
        --targets $transcript_fasta \\
        --alignments $bam \\
        --output ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salmon: \$(salmon --version | sed 's/^salmon //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}/aux_info ${prefix}/logs
    printf 'Name\\tLength\\tEffectiveLength\\tTPM\\tNumReads\\ntx1\\t500\\t450\\t0.0\\t0\\n' > ${prefix}/quant.sf
    touch ${prefix}/cmd_info.json
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salmon: 1.10.3
    END_VERSIONS
    """
}
