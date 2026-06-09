process STRINGTIE2 {
    tag   "$meta.id"
    label 'process_medium'

    conda "bioconda::stringtie=2.2.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/stringtie:2.2.3--h43eeafb_0' :
        'biocontainers/stringtie:2.2.3--h43eeafb_0' }"

    input:
    tuple val(meta), path(bam), path(bai)
    path  gtf   // optional guide annotation (may be staged as an empty list)

    output:
    tuple val(meta), path("*.stringtie.gtf"), emit: gtf
    path  "versions.yml",                     emit: versions

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def guide_arg = gtf ? "-G $gtf" : ''
    """
    stringtie \\
        -L \\
        -p $task.cpus \\
        $guide_arg \\
        $args \\
        -o ${prefix}.stringtie.gtf \\
        $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stringtie: \$(stringtie --version 2>&1)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    printf '# stringtie stub\\nchr_test\\tStringTie\\ttranscript\\t1\\t500\\t.\\t+\\t.\\tgene_id "STRG.1"; transcript_id "STRG.1.1";\\n' > ${prefix}.stringtie.gtf
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stringtie: 2.2.3
    END_VERSIONS
    """
}
