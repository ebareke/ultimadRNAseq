process SAMTOOLS_FASTQ {
    tag   "$meta.id"
    label 'process_low'

    conda "bioconda::samtools=1.20"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.20--h50ea8bc_0' :
        'biocontainers/samtools:1.20--h50ea8bc_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: fastq
    path  "versions.yml",                emit: versions

    script:
    def args   = task.ext.args ?: '-T "*"'   // carry over tags (e.g. move table) where supported
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools fastq \\
        -@ $task.cpus \\
        $args \\
        $bam \\
        | gzip -c > ${prefix}.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n1 | sed 's/^samtools //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo | gzip -c > ${prefix}.fastq.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: 1.20
    END_VERSIONS
    """
}
