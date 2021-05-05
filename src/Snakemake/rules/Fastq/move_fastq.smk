# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

__author__ = "Jonas Almlöf, Patrik Smeds"
__copyright__ = "Copyright 2021, Patrik Smeds, Jonas Almlöf"
__email__ = "jonas.almlöf@scilifelab.uu.se, patrik.smeds@scilifelab.uu.se"
__license__ = "GPL3"

"""
 Move fastq files
 Input, output and config
 ------------------------------------------------------------------------------
 Input variable:
    move_fastq_input: optional
            Default:
            "fastq_temp/DNA"
 If units is set in the config file that will override any input settings with the
 path stored in that file.

 Output variable:
    move_fastq_input: optional
        Default:
            "fastq/DNA",
 If

 Overriding input and output
 ------------------------------------------------------------------------------

"""

import src.lib.python.utils as utils


_move_fastq_input = "fastq_temp"
try:
    _move_fastq_input = move_fastq_input
except:
    pass


_move_fastq_output = "fastq/DNA/"
try:
    _move_fastq_output = move_fastq_output
except:
    pass

_move_fastq_input_r1 = _move_fastq_input + "/{sample}_R1.fastq.gz"
_move_fastq_input_r2 = _move_fastq_input + "/{sample}_R2.fastq.gz"
_move_fastq_output_r1 = _move_fastq_output + "/{sample}_R1.fastq.gz"
_move_fastq_output_r2 = _move_fastq_output + "/{sample}_R2.fastq.gz"

if "units" in config:
    import src.lib.python.utils as utils

    _move_fastq_input_r1 = lambda wildcards: utils.get_fastq_file(units, wildcards.sample, wildcars.unit, "fq1")
    _move_fastq_input_r2 = lambda wildcards: utils.get_fastq_file(units, wildcards.sample, wildcars.unit, "fq2")
    _move_fastq_output_r1 = _move_fastq_output + "/{sample}_{unit}_R1.fastq.gz"
    _move_fastq_output_r2 = _move_fastq_output + "/{sample}_{unit}_R2.fastq.gz"


rule move_fastq:
    input:
        fastq1=_move_fastq_input_r1,
        fastq2=_move_fastq_input_r2,
    output:
        fastq1=_move_fastq_output_r1,
        fastq2=_move_fastq_output_r2,
    shell:
        "cp {input.fastq1} {output.fastq1} && "
        "cp {input.fastq2} {output.fastq2}"
