process MINIMAP2_DENOVO {
    tag   "$meta.id"
    label 'process_high'

    conda "bioconda::minimap2=2.28 bioconda::samtools=1.20"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' :
        'biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' }"

    input:
    // de novo: reference is the sample's OWN assembled transcripts (per-sample)
    tuple val(meta), path(reads), path(transcripts)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    tuple val(meta), path("*.bai"), emit: bai
    path  "versions.yml",           emit: versions

    script:
    def args   = task.ext.args   ?: '-ax map-ont'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    minimap2 -t $task.cpus $args $transcripts $reads \\
        | samtools sort -@ $task.cpus -o ${prefix}.denovo.bam -
    samtools index -@ $task.cpus ${prefix}.denovo.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
        samtools: \$(samtools --version | head -n1 | sed 's/^samtools //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.denovo.bam ${prefix}.denovo.bam.bai
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: 2.28-r1209
        samtools: 1.20
    END_VERSIONS
    """
}
