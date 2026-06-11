process SAMTOOLS_MERGE {
    tag   "$meta.id"
    label 'process_medium'

    conda "bioconda::samtools=1.20"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.20--h50ea8bc_0' :
        'biocontainers/samtools:1.20--h50ea8bc_0' }"

    input:
    tuple val(meta), path(bams)   // one or more coordinate-sorted BAMs (a condition's replicates)

    output:
    tuple val(meta), path("*.merged.bam"), path("*.merged.bam.bai"), emit: bam
    path  "versions.yml",                                            emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # merge the group's replicate BAMs (a single-element group is just copied)
    n=\$(ls -1 ${bams} | wc -l)
    if [ "\$n" -eq 1 ]; then
        cp ${bams} ${prefix}.merged.bam
    else
        samtools merge -@ $task.cpus -f ${prefix}.merged.bam ${bams}
    fi
    samtools index -@ $task.cpus ${prefix}.merged.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n1 | sed 's/^samtools //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.merged.bam ${prefix}.merged.bam.bai
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: 1.20
    END_VERSIONS
    """
}
