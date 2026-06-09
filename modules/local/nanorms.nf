process NANORMS {
    tag   "$meta.id"
    label 'process_medium'

    // nanoRMS (novoalab/nanoRMS) — no Bioconda recipe. Container-only; build with
    // containers/nanorms/Dockerfile (pin NANORMS_REF). See docs/containers.md.
    container 'docker.io/ebareke/nanorms:2.0'

    input:
    // meta.id = "<test>_vs_<control>"
    tuple val(meta), path(test_bam), path(test_bai), path(control_bam), path(control_bai)
    path  fasta

    output:
    tuple val(meta), path("${meta.id}/*.tsv"), emit: stoichiometry
    path  "versions.yml",                      emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}
    # Representative invocation — adjust to the chosen nanoRMS entrypoint/version.
    nanoRMS \\
        --test_bam $test_bam \\
        --control_bam $control_bam \\
        --reference $fasta \\
        --output ${prefix}/${prefix}.stoichiometry.tsv \\
        --threads $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoRMS: \$(nanoRMS --version 2>&1 | head -n1 || echo 'unknown')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}
    echo -e "ref\\tpos\\tstrand\\tmod_stoichiometry_test\\tmod_stoichiometry_control\\tdelta" > ${prefix}/${prefix}.stoichiometry.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoRMS: 2.0
    END_VERSIONS
    """
}
