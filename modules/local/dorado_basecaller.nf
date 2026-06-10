process DORADO_BASECALLER {
    tag   "$meta.id"
    label 'process_gpu'

    // Dorado is distributed by ONT. Pin a concrete tag on your target system;
    // the container below is a placeholder for the ONT-published image.
    conda "bioconda::dorado=0.8.3"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/dorado:0.8.3--h9ee0642_0' :
        'ontresearch/dorado:sha268dcb4cd02093e75cdc58821f8b93719c4255ed' }"

    input:
    tuple val(meta), path(pod5_dir)

    output:
    tuple val(meta), path("*.bam"), emit: bam     // unaligned BAM w/ move tables
    path  "versions.yml",           emit: versions

    script:
    // `--device cuda:all` requested implicitly via process_gpu allocation.
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def model  = params.dorado_model
    """
    dorado basecaller \\
        $args \\
        $model \\
        $pod5_dir \\
        > ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | head -n1)
        model: ${model}
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: 0.8.3
        model: ${params.dorado_model}
    END_VERSIONS
    """
}
