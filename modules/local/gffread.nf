process GFFREAD {
    tag   "$meta.id"
    label 'process_low'

    conda "bioconda::gffread=0.12.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gffread:0.12.7--hdcf5f25_4' :
        'biocontainers/gffread:0.12.7--hdcf5f25_4' }"

    input:
    tuple val(meta), path(gtf)
    path  fasta   // genome FASTA

    output:
    tuple val(meta), path("*.transcripts.fa"), emit: transcripts
    path  "versions.yml",                      emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    gffread -w ${prefix}.transcripts.fa -g $fasta $gtf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gffread: \$(gffread --version 2>&1)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    printf '>STRG.1.1\\nACGTACGTACGT\\n' > ${prefix}.transcripts.fa
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gffread: 0.12.7
    END_VERSIONS
    """
}
