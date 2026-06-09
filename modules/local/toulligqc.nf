process TOULLIGQC {
    tag   "$meta.id"
    label 'process_low'

    conda "bioconda::toulligqc=2.5.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/toulligqc:2.5.6--pyhdfd78af_0' :
        'biocontainers/toulligqc:2.5.6--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fastq)

    output:
    tuple val(meta), path("${meta.id}/*.html")                 , emit: html
    tuple val(meta), path("${meta.id}/*.data") , optional: true, emit: data
    tuple val(meta), path("${meta.id}/images/*"), optional: true, emit: images
    path  "versions.yml"                                       , emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    toulligqc \\
        $args \\
        --report-name ${prefix} \\
        --fastq $fastq \\
        --output-directory ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        toulligqc: \$(toulligqc --version 2>&1 | sed 's/^.*version //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}/images
    touch ${prefix}/${prefix}_report.html
    touch ${prefix}/${prefix}_report.data
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        toulligqc: 2.5.6
    END_VERSIONS
    """
}
