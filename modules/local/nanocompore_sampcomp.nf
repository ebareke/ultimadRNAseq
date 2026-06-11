process NANOCOMPORE_SAMPCOMP {
    tag   "$meta.id"
    label 'process_high'

    conda "bioconda::nanocompore=1.0.4"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanocompore:1.0.4--pyhdfd78af_0' :
        'biocontainers/nanocompore:1.0.4--pyhdfd78af_0' }"

    input:
    // meta describes the contrast: id = "<condition>_vs_control". test_collapse
    // and control_collapse are LISTS of per-replicate collapse dirs, staged into
    // test/ and control/ so each side's replicate files can be globbed.
    tuple val(meta), path(test_collapse, stageAs: 'test/*'), path(control_collapse, stageAs: 'control/*')
    path  fasta   // transcriptome/genome reference the eventalign was made against

    output:
    tuple val(meta), path("${meta.id}/*.tsv"), emit: results
    tuple val(meta), path("${meta.id}"),       emit: outdir
    path  "versions.yml",                      emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    nanocompore sampcomp \\
        --file_list1 \$(ls control/*/*_eventalign_collapse.tsv | paste -sd, -) \\
        --file_list2 \$(ls test/*/*_eventalign_collapse.tsv | paste -sd, -) \\
        --label1 ${meta.control} \\
        --label2 ${meta.test} \\
        --fasta $fasta \\
        --outpath ${prefix} \\
        --nthreads $task.cpus \\
        --overwrite \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanocompore: \$(nanocompore --version 2>&1 | sed 's/^.*nanocompore //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}
    echo -e "chr\\tpos\\tref_id\\tGMM_logit_pvalue\\tKS_dwell_pvalue\\tKS_intensity_pvalue" > ${prefix}/outnanocompore_results.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanocompore: 1.0.4
    END_VERSIONS
    """
}
