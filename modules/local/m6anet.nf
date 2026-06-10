process M6ANET {
    tag   "$meta.id"
    label 'process_medium'

    conda "bioconda::m6anet=2.1.0"
    container "${ (workflow.containerEngine == 'singularity' || workflow.containerEngine == 'apptainer') && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/m6anet:2.1.0--pyhdfd78af_0' :
        'biocontainers/m6anet:2.1.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(eventalign)   // f5c/nanopolish eventalign (.tsv or .tsv.gz)

    output:
    tuple val(meta), path("${meta.id}/data.site_proba.csv.gz"),  emit: sites
    tuple val(meta), path("${meta.id}/data.indiv_proba.csv.gz"), emit: reads
    tuple val(meta), path("${meta.id}"),                         emit: results
    path  "versions.yml",                                        emit: versions

    script:
    def args_prep = task.ext.args_prep ?: ''
    def args_inf  = task.ext.args      ?: ''
    def prefix    = task.ext.prefix    ?: "${meta.id}"
    // eventalign must be uncompressed for m6anet dataprep
    def ea = eventalign.name.endsWith('.gz') ? eventalign.name[0..-4] : eventalign.name
    def decompress = eventalign.name.endsWith('.gz') ? "zcat ${eventalign} > ${ea}" : ''
    """
    ${decompress}

    m6anet dataprep \\
        --eventalign ${ea} \\
        --out_dir ${prefix}_dataprep \\
        --n_processes $task.cpus \\
        $args_prep

    m6anet inference \\
        --input_dir ${prefix}_dataprep \\
        --out_dir ${prefix} \\
        --n_processes $task.cpus \\
        $args_inf

    gzip -f ${prefix}/data.site_proba.csv ${prefix}/data.indiv_proba.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        m6anet: \$(m6anet --version 2>&1 | sed 's/^.*m6anet //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}
    echo "transcript_id,transcript_position,n_reads,probability_modified,kmer,mod_ratio" | gzip -c > ${prefix}/data.site_proba.csv.gz
    echo "transcript_id,transcript_position,read_index,probability_modified" | gzip -c > ${prefix}/data.indiv_proba.csv.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        m6anet: 2.1.0
    END_VERSIONS
    """
}
