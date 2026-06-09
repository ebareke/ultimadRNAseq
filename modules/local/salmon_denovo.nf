process SALMON_DENOVO {
    tag   "$meta.id"
    label 'process_medium'

    conda "bioconda::salmon=1.10.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/salmon:1.10.3--haf24da9_3' :
        'biocontainers/salmon:1.10.3--haf24da9_3' }"

    input:
    // bam + the same per-sample assembled transcripts used as reference
    tuple val(meta), path(bam), path(transcripts)

    output:
    tuple val(meta), path("${meta.id}_denovo/quant.sf"), emit: quant
    tuple val(meta), path("${meta.id}_denovo"),          emit: results
    path  "versions.yml",                                emit: versions

    script:
    def args   = task.ext.args ?: '--ont'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    salmon quant \\
        --threads $task.cpus \\
        --libType A \\
        $args \\
        --targets $transcripts \\
        --alignments $bam \\
        --output ${prefix}_denovo

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salmon: \$(salmon --version | sed 's/^salmon //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_denovo
    printf 'Name\\tLength\\tEffectiveLength\\tTPM\\tNumReads\\ntranscript_1\\t12\\t1\\t0.0\\t0\\n' > ${prefix}_denovo/quant.sf
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salmon: 1.10.3
    END_VERSIONS
    """
}
