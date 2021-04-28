# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

__author__ = "Jonas Almlöf, Patrik Smeds"
__copyright__ = "Copyright 2021, Patrik Smeds, Jonas Almlöf"
__email__ = "jonas.almlöf@scilifelab.uu.se, patrik.smeds@scilifelab.uu.se"
__license__ = "GPL3"

"""
 Demuliplex a Illumina runfolder
 Input, output and config
 ------------------------------------------------------------------------------
 Output variable:
    demultiplex_output: optional
        Default:
            "fastq",

 Config dict keys: values
    config["bcl2fastq_version"] required
    config["runfolder_path"] required
    config["samplesheet"] required
    config["barcode_mismatch"] optional, default 1
    config["threads"] optional, default -r 16 -d 16 -p 16
    config["extra"] optional
    config["lanes"] optional, set this value to a list of lane names if you want
                    to perform lane splitting, ex for a NextSeq
                    lanes:
                      - L001
                      - L002
                      - L003
                      - L004

 Overriding input and output
 ------------------------------------------------------------------------------

"""

import src.lib.python.utils as utils

_demultiplex_output = "fastq"
try:
    _demultiplex_output = demultiplex_output
except:
    pass


sample_dict = utils.generate_sample_list_from_samplesheet(config['samplesheet'])

if config.get('lanes', None) is not None:
    fastq1_files = []
    for sample in sample_dict:
        for lane in config['lanes']:
            fastq1_files.append(
                "".join(
                    [
                        _demultiplex_output,
                        "/",
                        sample_dict[sample]['projectpath'],
                        sample,
                        "_S",
                        str(sample_dict[sample]['counter']),
                        "_",
                        lane,
                        "_R1_001.fastq.gz",
                    ]
                )
            )
    fastq2_files = []
    for sample in sample_dict:
        for lane in config['lanes']:
            fastq2_files.append(
                "".join(
                    [
                        _demultiplex_output,
                        "/",
                        sample_dict[sample]['projectpath'],
                        sample,
                        "_S",
                        str(sample_dict[sample]['counter']),
                        "_",
                        lane,
                        "_R2_001.fastq.gz",
                    ]
                )
            )
else:
    fastq1_files = []
    for sample in sample_dict:
        fastq1_files.append(
            "".join(
                [
                    _demultiplex_output,
                    "/",
                    sample_dict[sample]['projectpath'],
                    sample,
                    "_S",
                    str(sample_dict[sample]['counter']),
                    "_R1_001.fastq.gz",
                ]
            )
        )
    fastq2_files = []
    for sample in sample_dict:
        fastq2_files.append(
            "".join(
                [
                    _demultiplex_output,
                    "/",
                    sample_dict[sample]['projectpath'],
                    sample,
                    "_S",
                    str(sample_dict[sample]['counter']),
                    "_R2_001.fastq.gz",
                ]
            )
        )


rule demultiplex:
    output:
        fastq1=fastq1_files,
        fastq2=fastq2_files,
    params:
        bcl2fastq_version=config["bcl2fastq_version"],
        runfolder=config["runfolder_path"],
        sample_sheet=config["samplesheet"],
        barcode_mismatch=config.get("barcode_mismatch", 1),
        lane_split="--no-lane-splitting" if config.get('lanes', None) is None else "",
        threads=config.get("threads", "-r 16 -d 16 -p 16"),
        extra=config.get("extra", ""),
        output_folder=_demultiplex_output,
    log:
        "logs/demultiplxing.log",
    run:
        shell(
            "module add bcl2fastq/{params.bcl2fastq_version};"
            "bcl2fastq -R {params.runfolder} "
            "-o {params.output_folder} "
            "--sample-sheet {params.sample_sheet} "
            "--barcode-mismatches {params.barcode_mismatch} "
            "{params.lane_split} "
            "{params.threads} "
            "{params.extra} 2> {log}"
        )
