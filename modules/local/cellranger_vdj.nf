// Import genetic module functions
include { saveFiles; getSoftwareName; getProcessName; initOptions } from './functions'

params.options = [:]
options        = initOptions(params.options)

process CELLRANGER_VDJ {
    tag "$meta.gem"
    label 'cellranger'

    container "nfcore/cellranger:7.1.0"

    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        exit 1, "CELLRANGER_VDJ module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    input:
    tuple val(meta), path(reads)
    path  reference

    output:
    tuple val(meta), path("sample-${meta.gem}/outs/*"), emit: outs
    path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def sample_arg = meta.samples.unique().join(",")
    def reference_name = reference.name
    """
    cellranger \\
        vdj \\
        --id='sample-${meta.gem}' \\
        --fastqs=. \\
        --reference=$reference_name \\
        --sample=$sample_arg \\
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
    mkdir -p "sample-${meta.gem}/outs/"
    touch sample-${meta.gem}/outs/fake_file.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellranger: \$(echo \$( cellranger --version 2>&1) | sed 's/^.*[^0-9]\\([0-9]*\\.[0-9]*\\.[0-9]*\\).*\$/\\1/' )
    END_VERSIONS
    """
}
