process POD5_CONVERT {
    tag   "$meta.id"
    label 'process_medium'

    conda "bioconda::pod5=0.3.10"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pod5:0.3.10--pyhdfd78af_0' :
        'biocontainers/pod5:0.3.10--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fast5_dir)

    output:
    tuple val(meta), path("${meta.id}_pod5"), emit: pod5
    path  "versions.yml",                     emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_pod5
    pod5 convert fast5 \\
        ${fast5_dir}/*.fast5 \\
        --output ${prefix}_pod5/${prefix}.pod5 \\
        --threads $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pod5: \$(pod5 --version 2>&1 | sed 's/^.*version: //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_pod5
    touch ${prefix}_pod5/${prefix}.pod5
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pod5: 0.3.10
    END_VERSIONS
    """
}
