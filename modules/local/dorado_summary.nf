process DORADO_SUMMARY {
    tag   "$meta.id"
    label 'process_low'

    conda "bioconda::dorado=0.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/dorado:0.8.3--h9ee0642_0' :
        'ontresearch/dorado:sha268dcb4cd02093e75cdc58821f8b93719c4255ed' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*sequencing_summary.txt"), emit: summary
    path  "versions.yml",                             emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    dorado summary $bam > ${prefix}.sequencing_summary.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | head -n1)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo -e "filename\\tread_id\\trun_id\\tchannel\\tstart_time\\tduration\\tsequence_length_template\\tmean_qscore_template" > ${prefix}.sequencing_summary.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: 0.8.3
    END_VERSIONS
    """
}
