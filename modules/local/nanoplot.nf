process NANOPLOT {
    tag   "$meta.id"
    label 'process_low'

    conda "bioconda::nanoplot=1.42.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanoplot:1.42.0--pyhdfd78af_0' :
        'biocontainers/nanoplot:1.42.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fastq)

    output:
    tuple val(meta), path("*.html")                 , emit: html
    tuple val(meta), path("*.png") , optional: true , emit: png
    tuple val(meta), path("*.txt")                  , emit: txt
    tuple val(meta), path("*.log")                  , emit: log
    path  "versions.yml"                            , emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    NanoPlot \\
        $args \\
        -t $task.cpus \\
        --fastq $fastq \\
        --prefix ${prefix}_ \\
        2> >(tee ${prefix}.log >&2)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: \$(NanoPlot --version | sed 's/^.*NanoPlot //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_NanoPlot-report.html
    touch ${prefix}_NanoStats.txt
    touch ${prefix}.log
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: 1.42.0
    END_VERSIONS
    """
}
