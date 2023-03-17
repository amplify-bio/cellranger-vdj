// Cribbed from nf-core/rnaseq:
// https://github.com/nf-core/rnaseq/blob/master/modules/local/multiqc.nf

// Import generic module functions
include { initOptions; saveFiles; getSoftwareName; getProcessName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process MULTIQC {
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName("${task.process}"), meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? 'bioconda::multiqc=1.11' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/multiqc:1.11--pyhdfd78af_0"
    } else {
        container "quay.io/biocontainers/multiqc:1.11--pyhdfd78af_0"
    }

    input:
    path multiqc_config
    path multiqc_custom_config
    path software_versions
    path workflow_summary
    path ('fastqc/*')
    path ('cellranger/outs/*')

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "*_plots"             , optional:true, emit: plots
    path "versions.yml"        , emit: versions

    script:
    def custom_config = params.multiqc_config ? "--config $multiqc_custom_config" : ''
    """
    multiqc -f $options.args $custom_config .

    cat <<-END_VERSIONS > versions.yml
    ${getProcessName(task.process)}:
        ${getSoftwareName(task.process)}: \$( multiqc --version | sed -e "s/multiqc, version //g" )
    END_VERSIONS
    """
}
