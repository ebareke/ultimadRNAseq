process RATTLE {
    tag   "$meta.id"
    label 'process_high'

    conda "bioconda::rattle=1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/rattle:1.0--h5ca1c30_0' :
        'biocontainers/rattle:1.0--h5ca1c30_0' }"

    input:
    tuple val(meta), path(fastq)

    output:
    tuple val(meta), path("${meta.id}.rattle_transcripts.fa"), emit: transcripts
    path  "versions.yml",                                      emit: versions

    script:
    def args   = task.ext.args ?: '--rna'   // direct-RNA mode
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    rattle cluster -i $fastq -t $task.cpus $args -o .
    rattle correct -i $fastq -c clusters.out -t $task.cpus -o .
    rattle polish  -i corrected.fq -t $task.cpus $args -o .

    # RATTLE polish emits transcriptome.fq → convert to FASTA
    awk 'NR%4==1{printf ">%s\\n", substr(\$0,2)} NR%4==2{print}' transcriptome.fq \\
        > ${prefix}.rattle_transcripts.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rattle: \$(rattle --version 2>&1 | head -n1 || echo 'unknown')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    printf '>transcript_1\\nACGTACGTACGT\\n' > ${prefix}.rattle_transcripts.fa
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rattle: 1.0
    END_VERSIONS
    """
}
