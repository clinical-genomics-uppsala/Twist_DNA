# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

__author__ = "Jonas Almlöf, Patrik Smeds"
__copyright__ = "Copyright 2021, Patrik Smeds, Jonas Almlöf"
__email__ = "jonas.almlöf@scilifelab.uu.se, patrik.smeds@scilifelab.uu.se"
__license__ = "GPL3"

"""
 Trims pe reads using fastq.
 Input, output and config
 ------------------------------------------------------------------------------
 Input variable: fastp_trimming_input: optional
     Default:
        "fastq_temp/DNA",
        "fastq_temp/DNA"
 Output variable:
    fastp_trimming_output: optional
        Default:
            "fastq/DNA",
            "fastq/DNA"

 Config dict keys: values
    config["fastp"]["adapters"] optional
    config["fastp"]["extra"] optional
    config["singularity"]["fastp"] required
 Overriding input and output
 ------------------------------------------------------------------------------
 Required wildcards:
    sample
 Override input format
 Ex
  fastp_trimming_input="fastq"
 Override output format
 Ex
   fastp_trimming_output="fastq/trimmed"
"""

import src.lib.python.utils as utils


_fastp_trimming_input = "fastq_temp/DNA"
try:
    _fastp_trimming_input = fastp_trimming_input
except:
    pass

_fastp_trimming_output = "fastq/DNA"
try:
    _fastp_trimming_output = bwa_mem_output
except:
    pass


_fastp_trimming_input_list = [_fastp_trimming_input + "/{sample}_R1.fastq.gz", _fastp_trimming_input + "/{sample}_R2.fastq.gz"]
_fastp_trimming_output_list = [_fastp_trimming_output + "/{sample}_R1.fastq.gz", _fastp_trimming_output + "/{sample}_R2.fastq.gz"]
_fastp_trimming_output_html = "fastq/DNA/{sample}.html"
_fastp_trimming_output_json = "fastq/DNA/{sample}.json"
_fastp_trimming_trimming_log = "logs/trimming/fastp/{sample}.log"
_fastp_trimming_trimming_benchmark = "benchmarks/trimming/fastp/{sample}.tsv"

if "units" in config:
    import src.lib.python.utils as utils

    if config.get("move_umi", True):
        _fastp_trimming_input_list = [
            _fastp_trimming_input + "/{sample}_{unit}_R1.fastq.gz",
            _fastp_trimming_input + "/{sample}_{unit}_R2.fastq.gz",
        ]
    else:
        _fastp_trimming_input_list = lambda wildcards: [
            utils.get_fastq_file(units, wildcards.sample, wildcards.unit, "fq1"),
            utils.get_fastq_file(units, wildcards.sample, wildcards.unit, "fq2"),
        ]

    _fastp_trimming_output_list = [
        _fastp_trimming_output + "/{sample}_{unit}_R1.fastq.gz",
        _fastp_trimming_output + "/{sample}_{unit}_R2.fastq.gz",
    ]
    _fastp_trimming_output_html = "fastq/DNA/{sample}_{unit}.html"
    _fastp_trimming_output_json = "fastq/DNA/{sample}_{unit}.json"
    _fastp_trimming_trimming_log = "logs/trimming/fastp/{sample}_{unit}.log"
    _fastp_trimming_trimming_benchmark = "benchmarks/trimming/fastp/{sample}_{unit}.tsv"


rule fastp:
    input:
        sample=_fastp_trimming_input_list,
    output:
        trimmed=_fastp_trimming_output_list,
        html=_fastp_trimming_output_html,
        json=_fastp_trimming_output_json,
    params:
        adapters=config.get("fastp", {}).get("adapters", ""),
        extra=config.get("fastp", {}).get("extra", ""),
    log:
        _fastp_trimming_trimming_log,
    threads: 5
    benchmark:
        repeat(_fastp_trimming_trimming_benchmark, config.get("benchmark", {}).get("repeats", 1))
    container:
        config["singularity"].get("fastp", config["singularity"].get("default", ""))
    wrapper:
        "v0.69.0/bio/fastp"
