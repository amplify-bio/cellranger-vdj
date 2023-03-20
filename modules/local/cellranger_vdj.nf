// Import genetic module functions
include { saveFiles; getSoftwareName; getProcessName; initOptions } from './functions'

params.options = [:]
options        = initOptions(params.options)

process CELLRANGER_VDJ {
    tag "${meta.gem}-${meta.id}"
    label 'cellranger'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName("${task.process}"), meta:meta, publish_by_meta:['id']) }

    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        exit 1, "CELLRANGER_VDJ module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    container params.docker_cellranger 

    input:
    tuple val(meta), (path(reads), stageAs: 'fastqs/*')
    path  reference, stageAs: 'reference'

    output:
    tuple val(meta), path("*${meta.gem}-${meta.id}/outs/*")                  , emit: outs
    tuple val(meta), path("*${meta.gem}-${meta.id}/outs/metrics_summary.csv"), emit: summary_csv
    path "versions.yml"                                                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    //def sample_arg = meta.samples.unique().join(",")
    //def reference_name = reference.name
    """
    cellranger \\
        vdj \\
        --id="${meta.gem}-${meta.id}" \\
        --fastqs=fastqs \\
        --reference=reference \\
        --sample="${meta.id}" \\
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
