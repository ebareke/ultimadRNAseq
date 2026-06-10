process MINIMAP2_ALIGN {
    tag   "$meta.id"
    label 'process_high'

    conda "bioconda::minimap2=2.28 bioconda::samtools=1.20"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' :
        'biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' }"

    input:
    tuple val(meta), path(reads)
    path  reference

    output:
    tuple val(meta), path("*.bam"),                  emit: bam
    tuple val(meta), path("*.bai"),  optional: true, emit: bai
    tuple val(meta), path("*.flagstat"),             emit: flagstat
    path  "versions.yml",                            emit: versions

    script:
    // Preset comes from ext.args (e.g. genome: '-ax splice -uf -k14',
    // transcriptome: '-ax map-ont'). Defaults to genome-splice for dRNA.
    def args   = task.ext.args   ?: '-ax splice -uf -k14'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    minimap2 \\
        -t $task.cpus \\
        $args \\
        $reference \\
        $reads \\
        | samtools sort -@ $task.cpus -o ${prefix}.bam -

    samtools index -@ $task.cpus ${prefix}.bam
    samtools flagstat ${prefix}.bam > ${prefix}.flagstat

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
        samtools: \$(samtools --version | head -n1 | sed 's/^samtools //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam
    touch ${prefix}.bam.bai
    echo "0 + 0 mapped (0.00% : N/A)" > ${prefix}.flagstat
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: 2.28-r1209
        samtools: 1.20
    END_VERSIONS
    """
}
