/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
if (params.transcriptome_reference) { ch_reference_path = file(params.transcriptome_reference) } else { exit 1, 'Transcriptome reference not specified!' }


/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

// Info required for completion email and summary
def multiqc_report      = []
def pass_percent_mapped = [:]
def fail_percent_mapped = [:]

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)


/*
========================================================================================
    CONFIG FILES
========================================================================================
*/

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()


/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

def multiqc_options  = modules['multiqc']
multiqc_options.args += params.multiqc_title ? Utils.joinModuleArgs(["--title \"$params.multiqc_title\""]) : ''

def umitools_extract_options    = modules['umitools_extract']
umitools_extract_options.args  += params.umitools_extract_method ? Utils.joinModuleArgs(["--extract-method=${params.umitools_extract_method}"]) : ''
umitools_extract_options.args  += params.umitools_bc_pattern     ? Utils.joinModuleArgs(["--bc-pattern='${params.umitools_bc_pattern}'"])       : ''
if (params.save_umi_intermeds)  { umitools_extract_options.publish_files.put('fastq.gz','') }

def trimgalore_options    = modules['trimgalore']
trimgalore_options.args  += params.trim_nextseq > 0 ? Utils.joinModuleArgs(["--nextseq ${params.trim_nextseq}"]) : ''
if (params.save_trimmed)  { trimgalore_options.publish_files.put('fq.gz','') }

include { INPUT_CHECK                 } from '../subworkflows/local/input_check'                           addParams( options: [:]                                                                                                          )
include { FASTQC_UMITOOLS_TRIMGALORE  } from '../subworkflows/nf-core/fastqc_umitools_trimgalore'          addParams( fastqc_options: modules['fastqc'], umitools_options: umitools_extract_options, trimgalore_options: trimgalore_options )
include { CELLRANGER_VDJ              } from '../modules/local/cellranger_vdj'                             addParams( cellranger_options: modules['cellranger']                                                                             )
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main' addParams( options: [publish_files : ['_versions.yml':'']]                                                                       )
include { MULTIQC                     } from '../modules/local/multiqc'                                    addParams( options: multiqc_options                                                                                              )


/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

workflow CELLRANGER {

    ch_software_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    .reads
    .set{ ch_reads }
    ch_software_versions = ch_software_versions.mix(INPUT_CHECK.out.versions.ifEmpty(null))

    //
    // SUBWORKFLOW: Read QC, extract UMI and trim adapters
    //
    FASTQC_UMITOOLS_TRIMGALORE (
        ch_reads,
        params.skip_fastqc || params.skip_qc,
        false,
        true
    )
    ch_software_versions = ch_software_versions.mix(FASTQC_UMITOOLS_TRIMGALORE.out.versions.first().ifEmpty(null))

    //
    // SUBWORKFLOW: CellRanger vdj 
    //
    CELLRANGER_VDJ (
        ch_reads,
        ch_reference_path
    )

    ch_cellranger_vdj_metrics = CELLRANGER_VDJ.out.summary_csv
    ch_software_versions = ch_software_versions.mix(CELLRANGER_VDJ.out.versions.ifEmpty(null))


    //
    // MODULE: Pipeline reporting
    //
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_software_versions.unique().collectFile()
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowCellranger.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    MULTIQC (
        ch_multiqc_config,
        ch_multiqc_custom_config.collect().ifEmpty([]),
        CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect(),
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'),
        FASTQC_UMITOOLS_TRIMGALORE.out.fastqc_zip.collect{it[1]}.ifEmpty([]),
        ch_cellranger_vdj_metrics.collect{it[1]}.ifEmpty([])
    )
    multiqc_report = MULTIQC.out.report.toList()
}


/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
========================================================================================
    THE END
========================================================================================
*/
