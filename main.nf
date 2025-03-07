#!/usr/bin/env nextflow
/*
========================================================================================
                        klkeys/cellranger-vdj
========================================================================================
    Analysis Pipeline for 10X Cell Ranger vdj
    #### Homepage / Documentation
    https://github.com/klkeys/cellranger-vdj
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2


/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/

WorkflowMain.initialise(workflow, params, log)


/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

include { CELLRANGER } from './workflows/cellranger'

//
// WORKFLOW: Run main cellranger analysis pipeline
//
workflow RUN_CELLRANGER {
    CELLRANGER ()
}

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
//
workflow {
    RUN_CELLRANGER ()
}

/*
========================================================================================
    THE END
========================================================================================
*/
