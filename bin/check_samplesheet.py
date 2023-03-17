#!/usr/bin/env python

import os
import sys
import errno
import argparse


def parse_args(args=None):
    Description = "Reformat klkeys/cellranger-vdj samplesheet file and check its contents."
    Epilog = "Example usage: python check_samplesheet.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input samplesheet file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        try:
            os.makedirs(path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise exception


def print_error(error, context="Line", context_str=""):
    error_str = f"ERROR: Please check samplesheet -> {error}"
    if context != "" and context_str != "":
        error_str = f"ERROR: Please check samplesheet -> {error}\n{context.strip()}: '{context_str.strip()}'"
    print(error_str)
    sys.exit(1)


def check_samplesheet(file_in, file_out):
    """
    This function checks that the samplesheet follows the following structure:
    gem,fastq_id,fastqs,feature_types
    gem1,pbmc_1k_v3_mini,s3://ambys-10xgenomics-pipeline/testdata,gex
    """

    sample_mapping_dict = {}
    with open(file_in, "r") as fin:

        ## Check header
        MIN_COLS = 4
        HEADER = ["gem", "fastq_id", "fastqs", "feature_types"]
        header = [x.strip('"') for x in fin.readline().strip().split(",")]
        if header[: len(HEADER)] != HEADER:
            print(
                f"ERROR: Please check samplesheet header -> {','.join(header)} != {','.join(HEADER)}"
            )
            sys.exit(1)

        ## Check sample entries
        for line in fin:
            lspl = [x.strip().strip('"') for x in line.strip().split(",")]

            ## Check valid number of columns per row
            if len(lspl) < len(HEADER):
                print_error(
                    f"Invalid number of columns (minimum = {len(HEADER)})!",
                    "Line",
                    line,
                )

            num_cols = len([x for x in lspl if x])
            if num_cols < MIN_COLS:
                print_error(
                    f"Invalid number of populated columns (minimum = {MIN_COLS})!",
                    "Line",
                    line,
                )

            ## Check sample name entries
            gem, fastq_id, fastqs, feature_types = lspl[: len(HEADER)]
            if not gem:
                print_error("gem entry has not been specified!", "Line", line)
            if not fastq_id:
                print_error("fastq_id entry has not been specified!", "Line", line)
            if not fastqs:
                print_error("fastqs entry has not been specified!", "Line", line)
            if not feature_types:
                print_error("feature_types entry has not been specified!", "Line", line)
            if feature_types not in ["gex", "fb", "vdj_b", "vdj_t"]:
                print_error("invalid feature type, should be gex, fb, vdj_b or vdj_t", "Line", line)

            ## Create list of feature types
            #featuretype_list.append(feature_types)

            sample_info = [gem, fastqs, feature_types]
            ## Create sample mapping dictionary = { sample: [ single_end, fastq_1, fastq_2 ] }
            if fastq_id not in sample_mapping_dict:
                sample_mapping_dict[fastq_id] = [sample_info]
            else:
                if sample_info in sample_mapping_dict[fastq_id]:
                    print_error("Samplesheet contains duplicate rows!", "Line", line)
                else:
                    print_error("Samplesheet contains duplicate fastq_id entries!", "Line", line)

#        # Checking featuretype list
#        ftypes = ["gex", "fb", "vdj_b", "vdj_t"]
#        featuretype_list = set(featuretype_list)
#        exist = list()
#        for ft in ftypes:
#            if ft in featuretype_list:
#                exist.append("true")
#            else:
#                exist.append("false")
#
#        with open(file_out, "w") as fout:
#            fout.write(",".join(ftypes)+"\n")
#            fout.write(",".join(exist)+"\n")
#
#    ## Write validated samplesheet with appropriate columns
#    if len(sample_mapping_dict) > 0:
#        out_dir = os.path.dirname(file_out)
#        make_dir(out_dir)
#        with open(file_out, "w") as fout:
#            fout.write(
#                ",".join(["gem", "Sample", "Lane", "R1", "R2", "I1"])
#                + "\n"
#            )
#            for (sample, lane) in sorted(sample_mapping_dict.keys()):
#
#                ## Check that multiple runs of the same sample are in different lanes
#                if not all(
#                    x[2] == sample_mapping_dict[(sample, lane)][0][2]
#                    for x in sample_mapping_dict[(sample, lane)]
#                ):
#                    print_error(
#                        f"Multiple runs of a sample must sit in different lanes!",
#                        "Sample",
#                        sample,
#                    )
#
#                for idx, val in enumerate(sample_mapping_dict[(sample, lane)]):
#                    #fout.write(",".join([f"{sample}_{lane}_T{idx+1}"] + val) + "\n")
#                    fout.write(",".join(val) + "\n")
#    else:
#        print_error(f"No entries to process!", "Samplesheet: {file_in}")


def main(args=None):
    args = parse_args(args)
    check_samplesheet(args.FILE_IN, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
