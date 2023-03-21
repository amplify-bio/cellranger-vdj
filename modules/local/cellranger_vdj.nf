process CELLRANGER_VDJ {
    tag "${meta.id}"
    label 'cellranger'

    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        exit 1, "CELLRANGER_VDJ module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    container params.docker_cellranger

    input:
    tuple val(meta), path(reads)
    path  reference, stageAs: 'reference'

    output:
    tuple val(meta), path("sample-${meta.id}/outs/*")                  , emit: outs
    tuple val(meta), path("sample-${meta.id}/outs/metrics_summary.csv"), emit: summary_csv
    path "versions.yml"                                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def sample_arg = meta.samples.unique().join(",")
    """
    cellranger \\
        vdj \\
        --id="sample-${meta.id}" \\
        --fastqs=. \\
        --sample=$sample_arg \\
        --reference=reference \\
        --localcores=${task.cpus} \\
        --localmem=${task.memory.toGiga()} \\
        $args
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellranger: \$(echo \$( cellranger --version 2>&1) | sed 's/^.*[^0-9]\\([0-9]*\\.[0-9]*\\.[0-9]*\\).*\$/\\1/' )
    END_VERSIONS
    """

    stub:
    """
    mkdir -p "sample-${meta.id}/outs/"
    touch sample-${meta.id}/outs/fake_file.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellranger: \$(echo \$( cellranger --version 2>&1) | sed 's/^.*[^0-9]\\([0-9]*\\.[0-9]*\\.[0-9]*\\).*\$/\\1/' )
    END_VERSIONS
    """
}
