process NANOCOUNT {
    tag   "$meta.id"
    label 'process_medium'

    conda "bioconda::nanocount=1.0.0.post6"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanocount:1.0.0.post6--pyhdfd78af_0' :
        'biocontainers/nanocount:1.0.0.post6--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(bam)   // transcriptome BAM, query-ordered (from MINIMAP2_NANOCOUNT)

    output:
    tuple val(meta), path("*.nanocount.tsv"), emit: counts
    path  "versions.yml",                     emit: versions

    script:
    def args   = task.ext.args   ?: '--extra_tx_info'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    NanoCount \\
        -i $bam \\
        -o ${prefix}.nanocount.tsv \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanocount: \$(NanoCount --version 2>&1 | sed 's/^.*NanoCount //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    printf 'transcript_name\\traw\\test\\ttpm\\n' > ${prefix}.nanocount.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanocount: 1.0.0.post6
    END_VERSIONS
    """
}
