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
Extra params to bwa-mem:
    bwa_params_extra: optional
        Default:
            r"-R '@RG\tID:{sample}\tSM:{sample}\tPL:illumina\tPU:{sample}' -v 1"
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
import src.lib.python.utils as utils

def get_now():
    from datetime import datetime

    return datetime.now().strftime("%Y%m%d")

def get_bam_files(wildcards):
    if "units" in config:
        return ["alignment/" + wildcards.sample + "_" + unit+ ".sort.bam" for unit in utils.get_units(wildcars.sample)]
    else:
        ["alignment/{sample}.sort.bam"]

_bwa_mem_input = ["fastq/DNA/{sample}_R1.fastq.gz", "fastq/DNA/{sample}_R2.fastq.gz"]
_temp_bwa_mem_output = "alignment/{sample}.sort.bam"
_bwa_log = "logs/map/bwa/{sample}.log"
_bwa_benchmark = "benchmarks/bwa/mem/{sample}.tsv"
_pu = "{sample}"
if "units" in config:
    _bwa_mem_input = ["fastq/DNA/{sample}_{unit}_R1.fastq.gz", "fastq/DNA/{sample}_{unit}_R2.fastq.gz"]
    _temp_bwa_mem_output = "alignment/{sample}_{unit}.sort.bam"
    _bwa_log = "logs/map/bwa/{sample}_{unit}.log"
    _bwa_benchmark = "benchmarks/bwa/mem/{sample}_{units}.tsv"
    _pu = "{sample}_{unit}"

try:
    _bwa_mem_input = bwa_mem_input
except:
    pass


_bwa_mem_output = "alignment/{sample}.sort.bam"
_umi_tag_output = "alignment/{sample}.sort.noUMI.bam",
try:
    _bwa_mem_output = bwa_mem_output
except:
    pass


rule bwa_mem:
    input:
        reads=_bwa_mem_input,
    output:
        bam=temp(_temp_bwa_mem_output),
    log:
        _bwa_log,
    params:
        index=config["reference"]["ref"],
        extra=r"-R '@RG\tID:{sample}\tSM:{sample}\tPL:illumina\tPU:" + _pu + ' -v 1 ' + config.get("bam_extra", ""),
        sort="samtools",
        sort_order="coordinate",
        sort_extra="-@ 10",
    threads: 10
    #benchmark:
    #    repeat(_bwa_benchmark, config.get("benchmark", {}).get("repeats", 1))
    singularity:
        config["singularity"].get("bwa", config["singularity"].get("default", ""))
    wrapper:
        "0.70.0/bio/bwa/mem"


rule finilize_alignment_process:
    input:
        lambda wildcards: get_bam_files(wildcards),
    output:
        _bwa_mem_output,
    singularity:
        config["singularity"].get("samtools", config["singularity"].get("default", ""))
    shell:
        """
        if [[ ${{ArrayName[{input}]}} -gt 1 ]]
        then
            samtools merge -c -p {output} {input}
        else
            mv {input} {output}
        fi
        """

# ToDo make it configurable
rule umi_tag:
    input:
        bam="alignment/{sample}.sort.noUMI.bam",
        bai="alignment/{sample}.sort.noUMI.bam.bai",
    output:
        bam="alignment/{sample}.sort.bam",
    log:
        "logs/map/umi_tag/{sample}.log",
    container:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    shell:
        "python src/scripts/python/umi_annotate.py -i {input.bam} -o {output.bam}"
