process MULTIQC {
    label 'process_low'

    conda "bioconda::multiqc=1.25.1"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.25.1--pyhdfd78af_0' :
        'biocontainers/multiqc:1.25.1--pyhdfd78af_0' }"

    input:
    path  multiqc_files, stageAs: "?/*"
    path(multiqc_config)

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "versions.yml"        , emit: versions

    script:
    def args        = task.ext.args ?: ''
    def config_arg  = multiqc_config ? "--config $multiqc_config" : ''
    """
    multiqc \\
        --force \\
        $config_arg \\
        $args \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed 's/^.*version //')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p multiqc_data
    touch multiqc_report.html
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: 1.25.1
    END_VERSIONS
    """
}
