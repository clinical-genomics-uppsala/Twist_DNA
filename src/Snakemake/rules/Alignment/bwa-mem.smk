# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

__author__ = "Jonas Almlöf, Patrik Smeds"
__copyright__ = "Copyright 2021, Patrik Smeds, Jonas Almlöf"
__email__ = "jonas.almlöf@scilifelab.uu.se, patrik.smeds@scilifelab.uu.se"
__license__ = "GPL3"

"""
 Rule that performs alignment of reads using bwa mem.
 Input, output and config
 ------------------------------------------------------------------------------
 Input variable: 
    bwa_alignment_input: optional
        Default:
            "fastq/{sample}.fq1.fastq.gz",
            "fastq/{sample}.fq2.fastq.gz"
 Output variable:  
    bwa_mem_output: optional
        Default:
            "alignment/{sample}.bam"
 Config dict keys: values
    config["reference"]["ref"]': required
    config["singularity"]["bwa"]' or config["singularity"]["default"]'  : required 
    config["singularity"]["samtools"] or config["singularity"]["default"]': required
 Overriding input and output
 ------------------------------------------------------------------------------
 Required wildcards:
    sample
 Override input format
 Ex
  bwa_alignment_input=[
                       "fastq/{sample}.R1.cutadapt.fastq.gz",
                       "fastq/{sample}.R2.cutadapt.fastq.gz"
                       ]
 Override output format
 Ex
   bwa_alignment_output="alignment/{sample}.cutadapt.bam"
"""


def get_now():
    from datetime import datetime

    return datetime.now().strftime("%Y%m%d")


_bwa_mem_input = ["fastq/DNA/{sample}_R1.fastq.gz", "fastq/DNA/{sample}_R2.fastq.gz"]
try:
    _bwa_mem_input = bwa_mem_input
except:
    pass

_bwa_mem_output = "alignment/{sample}.bam"
try:
    _bwa_mem_output = bwa_mem_output
except:
    pass


rule bwa_mem:
    input:
        reads=_bwa_mem_input,
    output:
        bam=_bwa_mem_output,
    log:
        "logs/map/bwa/{sample}.log",
    params:
        index=config["reference"]["ref"],
        extra=r"-R '@RG\tID:{sample}\tSM:{sample}\tPL:illumina\tPU:{sample}' -v 1",
        sort="samtools",
        sort_order="coordinate",
        sort_extra="-@ 10",
    threads: 10
    benchmark:
        repeat("benchmarks/bwa/mem/{sample}.tsv", config.get("benchmark", {}).get("repeats", 1))
    singularity:
        config["singularity"].get("bwa", config["singularity"].get("default", ""))
    wrapper:
        "0.70.0/bio/bwa/mem"
