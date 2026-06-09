process NANOCOMPORE_COLLAPSE {
    tag   "$meta.id"
    label 'process_medium'

    conda "bioconda::nanocompore=1.0.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanocompore:1.0.4--pyhdfd78af_0' :
        'biocontainers/nanocompore:1.0.4--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(eventalign)   // f5c/nanopolish eventalign (.tsv[.gz])

    output:
    tuple val(meta), path("${meta.id}_collapse"), emit: collapsed
    path  "versions.yml",                         emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def ea = eventalign.name.endsWith('.gz') ? eventalign.name[0..-4] : eventalign.name
    def decompress = eventalign.name.endsWith('.gz') ? "zcat ${eventalign} > ${ea}" : ''
    """
    ${decompress}
    mkdir -p ${prefix}_collapse

    nanocompore eventalign_collapse \\
        -t $task.cpus \\
        $args \\
        -i ${ea} \\
        -o ${prefix}_collapse \\
        -p ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanocompore: \$(nanocompore --version 2>&1 | sed 's/^.*nanocompore //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_collapse
    touch ${prefix}_collapse/${prefix}_eventalign_collapse.tsv
    touch ${prefix}_collapse/${prefix}_eventalign_collapse.tsv.idx
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanocompore: 1.0.4
    END_VERSIONS
    """
}
