process PYCOQC {
    tag   "$meta.id"
    label 'process_low'

    conda "bioconda::pycoqc=2.5.2"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pycoqc:2.5.2--py_0' :
        'biocontainers/pycoqc:2.5.2--py_0' }"

    input:
    // pycoQC requires a sequencing_summary.txt (produced by basecalling).
    // Optionally an aligned BAM enriches the alignment-based plots.
    tuple val(meta), path(summary), path(bam), path(bai)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.json"), emit: json
    path  "versions.yml"           , emit: versions

    script:
    def args     = task.ext.args   ?: ''
    def prefix   = task.ext.prefix ?: "${meta.id}"
    def bam_arg  = bam ? "-a $bam" : ''
    """
    pycoQC \\
        $args \\
        --summary_file $summary \\
        $bam_arg \\
        --html_outfile ${prefix}.html \\
        --json_outfile ${prefix}.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pycoqc: \$(pycoQC --version 2>&1 | sed 's/^.*pycoQC v//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.html
    touch ${prefix}.json
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pycoqc: 2.5.2
    END_VERSIONS
    """
}
