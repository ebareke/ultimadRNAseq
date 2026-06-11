process UNCALLED4_ALIGN {
    tag   "$meta.id"
    label 'process_high'

    // uncalled4 (skovaka/uncalled4) is a PyPI package, no Bioconda recipe.
    // Container-only; build with containers/uncalled4/Dockerfile. See docs/containers.md.
    container 'docker.io/ebareke/uncalled4:4.1.0'

    input:
    // signal-to-reference alignment (spec §5.2): reads + POD5 + a basecalled BAM
    // aligned to the same reference (with move tags) + the reference itself.
    tuple val(meta), path(fastq), path(pod5_dir), path(bam), path(bai)
    path  fasta

    output:
    tuple val(meta), path("*.uncalled4.bam"),            emit: bam
    tuple val(meta), path("*.uncalled4.eventalign.tsv.gz"), optional: true, emit: eventalign
    path  "versions.yml",                                emit: versions

    script:
    // Confirm flags against the installed uncalled4 version; overridable via ext.args.
    def args   = task.ext.args   ?: '--rna'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    uncalled4 align \\
        -p $task.cpus \\
        $args \\
        --ref $fasta \\
        --reads $pod5_dir \\
        --bam-in $bam \\
        --bam-out ${prefix}.uncalled4.bam \\
        --eventalign-out ${prefix}.uncalled4.eventalign.tsv || \\
        uncalled4 align $args -p $task.cpus --ref $fasta --reads $pod5_dir \\
            --bam-in $bam --bam-out ${prefix}.uncalled4.bam
    [ -f ${prefix}.uncalled4.eventalign.tsv ] && gzip -f ${prefix}.uncalled4.eventalign.tsv || true

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        uncalled4: \$(uncalled4 --version 2>&1 | head -n1 | sed 's/^.*uncalled4 //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.uncalled4.bam
    echo | gzip -c > ${prefix}.uncalled4.eventalign.tsv.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        uncalled4: 4.1.0
    END_VERSIONS
    """
}
