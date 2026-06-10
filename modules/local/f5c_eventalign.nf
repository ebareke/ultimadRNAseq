process F5C_EVENTALIGN {
    tag   "$meta.id"
    label 'process_high'
    label 'process_gpu'   // f5c uses GPU when available; falls back to CPU

    conda "bioconda::f5c=1.5"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/f5c:1.5--hd43b18c_0' :
        'biocontainers/f5c:1.5--hd43b18c_0' }"

    input:
    tuple val(meta), path(fastq), path(pod5_dir), path(bam), path(bai)
    path  fasta

    output:
    tuple val(meta), path("*.eventalign.tsv.gz"), emit: eventalign
    tuple val(meta), path("*.summary.txt"),       emit: summary
    path  "versions.yml",                         emit: versions

    script:
    // index links reads↔raw signal; eventalign maps signal to the reference.
    def args_index = task.ext.args_index ?: ''
    def args_event = task.ext.args       ?: '--rna --signal-index --scale-events'
    def prefix     = task.ext.prefix     ?: "${meta.id}"
    """
    # 1. link basecalled reads to their raw signal (POD5)
    f5c index \\
        -t $task.cpus \\
        $args_index \\
        --pod5 $pod5_dir \\
        $fastq

    # 2. event-align signal to the reference (feeds modification/poly(A) tools)
    f5c eventalign \\
        -t $task.cpus \\
        $args_event \\
        --reads $fastq \\
        --bam $bam \\
        --genome $fasta \\
        --summary ${prefix}.summary.txt \\
        | gzip -c > ${prefix}.eventalign.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        f5c: \$(f5c --version 2>&1 | sed 's/^.*f5c //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo | gzip -c > ${prefix}.eventalign.tsv.gz
    touch ${prefix}.summary.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        f5c: 1.5
    END_VERSIONS
    """
}
