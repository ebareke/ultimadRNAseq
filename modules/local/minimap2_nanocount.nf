process MINIMAP2_NANOCOUNT {
    tag   "$meta.id"
    label 'process_high'

    conda "bioconda::minimap2=2.28 bioconda::samtools=1.20"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' :
        'biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' }"

    input:
    tuple val(meta), path(reads)
    path  transcriptome

    output:
    tuple val(meta), path("*.bam"), emit: bam   // query-ordered (NOT coord-sorted)
    path  "versions.yml",           emit: versions

    script:
    // NanoCount needs secondary alignments (-N 10) and the BAM grouped by read
    // (query order) — so we do NOT coordinate-sort here.
    def args   = task.ext.args   ?: '-ax map-ont -N 10'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    minimap2 -t $task.cpus $args $transcriptome $reads \\
        | samtools view -@ $task.cpus -bh -o ${prefix}.nanocount.bam -

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
        samtools: \$(samtools --version | head -n1 | sed 's/^samtools //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.nanocount.bam
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: 2.28-r1209
        samtools: 1.20
    END_VERSIONS
    """
}
