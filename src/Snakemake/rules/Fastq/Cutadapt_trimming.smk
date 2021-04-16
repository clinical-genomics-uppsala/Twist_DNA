# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

__author__ = "Jonas Almlöf, Patrik Smeds"
__copyright__ = "Copyright 2021, Patrik Smeds, Jonas Almlöf"
__email__ = "jonas.almlöf@scilifelab.uu.se, patrik.smeds@scilifelab.uu.se"
__license__ = "GPL3"

"""
 Run cutadapt on fastq files
 Input, output and config
 ------------------------------------------------------------------------------
 Input variable:
    cutadapt_trimming_input: optional
            Default:
            "fastq_temp/DNA"
 If units is set in the config file that will override any input settings with the
 path stored in that file.

 Output variable:
    cutadapt_trimming_input: optional
        Default:
            "fastq",
 If
 Config dict keys: values
    config["cutadapt"]["adapters"]: optional, default: -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT
    config["cutadapt"]["extra"]: optional, default: --minimum-length 2 -q 20

 Overriding input and output
 ------------------------------------------------------------------------------

"""

import src.lib.python.utils as utils


_cutadapt_trimming_input = "fastq_temp"
try:
    _cutadapt_trimming_input = cutadapt_trimming_input
except:
    pass


_cutadapt_trimming_output = "fastq/DNA/"
try:
    _cutadapt_trimming_output = cutadapt_trimming_output
except:
    pass

_cutadapt_trimming_input_r1 = _cutadapt_trimming_input + "/{sample}_R1.fastq.gz",
_cutadapt_trimming_input_r2 = _cutadapt_trimming_input + "/{sample}_R2.fastq.gz",
_cutadapt_trimming_output_r1 = _cutadapt_trimming_output + "/{sample}_R1.fastq.gz"
_cutadapt_trimming_output_r2 = _cutadapt_trimming_output + "/{sample}_R2.fastq.gz"
_cutadapt_trimming_output_qc = _cutadapt_trimming_output + "/{sample}.qc.txt"
_cutadapt_trimming_log = "logs/trimming/cutadapt/{sample}.log",

if "units" in config:
    import src.lib.python.utils as utils
    _cutadapt_trimming_input_r1 = lambda wildcards: utils.get_fastq_file(units, wildcards.sample, wildcars.unit, "fq1")
    _cutadapt_trimming_input_r2 = lambda wildcards: utils.get_fastq_file(units, wildcards.sample, wildcars.unit, "fq2")
    _cutadapt_trimming_output_r1 = _cutadapt_trimming_output + "/{sample}_{unit}_R1.fastq.gz"
    _cutadapt_trimming_output_r2 = _cutadapt_trimming_output + "/{sample}_{unit}_R2.fastq.gz"
    _cutadapt_trimming_output_qc = _cutadapt_trimming_output + "/{sample}_{unit}.qc.txt"
    _cutadapt_trimming_log = "logs/trimming/cutadapt/{sample}.{unit}.log"


_adapters = config.get("cutadapt",{}).get("adapters", "-a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT")
_extra = config.get("cutadapt",{}).get("extra", "--minimum-length 2 -q 20")


rule cutadapt:
    input:
        fastq1=_cutadapt_trimming_input_r1,
        fastq2=_cutadapt_trimming_input_r2,
    output:
        fastq1=_cutadapt_trimming_output_r1,
        fastq2=_cutadapt_trimming_output_r2,
        qc=_cutadapt_trimming_output_qc,
    params:
        # https://cutadapt.readthedocs.io/en/stable/guide.html#adapter-types
        adapters=_adapters
        # https://cutadapt.readthedocs.io/en/stable/guide.html#
        extra=_extra,
    log:
        _cutadapt_trimming_log,
    threads: 10
    singularity:
        config["singularity"].get("cutadapt", config["singularity"].get("default", ""))
    wrapper:
        "0.73.0/bio/cutadapt/pe"
