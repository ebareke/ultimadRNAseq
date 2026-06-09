process NANOPOLISH_POLYA {
    tag   "$meta.id"
    label 'process_high'

    conda "bioconda::nanopolish=0.14.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanopolish:0.14.0--ha9c7c1a_3' :
        'biocontainers/nanopolish:0.14.0--ha9c7c1a_3' }"

    input:
    // signal_dir is the raw signal. NOTE: nanopolish indexes FAST5/SLOW5;
    // POD5 is not natively supported — retain FAST5 or convert POD5→slow5
    // (slow5tools/blue-crab) for real runs. f5c poly-a is the POD5-native option.
    tuple val(meta), path(fastq), path(signal_dir), path(bam), path(bai)
    path  fasta

    output:
    tuple val(meta), path("*.polya.tsv.gz"), emit: polya
    path  "versions.yml",                    emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    nanopolish index -d $signal_dir $fastq

    nanopolish polya \\
        -t $task.cpus \\
        $args \\
        --reads $fastq \\
        --bam $bam \\
        --genome $fasta \\
        | gzip -c > ${prefix}.polya.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanopolish: \$(nanopolish --version 2>&1 | head -n1 | sed 's/^nanopolish version //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo -e "readname\\tcontig\\tposition\\tpolya_length\\tqc_tag" | gzip -c > ${prefix}.polya.tsv.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanopolish: 0.14.0
    END_VERSIONS
    """
}
