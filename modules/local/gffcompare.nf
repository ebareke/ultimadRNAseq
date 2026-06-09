process GFFCOMPARE {
    tag   "$meta.id"
    label 'process_low'

    conda "bioconda::gffcompare=0.12.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gffcompare:0.12.6--h9f5acd7_0' :
        'biocontainers/gffcompare:0.12.6--h9f5acd7_0' }"

    input:
    tuple val(meta), path(query_gtf)
    path  reference_gtf

    output:
    tuple val(meta), path("${meta.id}.gffcompare.*"), emit: results
    path  "versions.yml",                             emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    gffcompare \\
        -r $reference_gtf \\
        -o ${prefix}.gffcompare \\
        $query_gtf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gffcompare: \$(gffcompare --version 2>&1 | sed 's/^gffcompare v//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.gffcompare.stats ${prefix}.gffcompare.tracking ${prefix}.gffcompare.loci
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gffcompare: 0.12.6
    END_VERSIONS
    """
}
