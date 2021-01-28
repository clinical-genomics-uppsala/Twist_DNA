# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

__author__ = "Patrik Smeds"
__copyright__ = "Copyright 2021, Patrik Smeds"
__email__ = "patrik.smeds@scilifelab.uu.se"
__license__ = "GPL3"

"""
 Rule that index bam files
 Input, output and config
 ------------------------------------------------------------------------------
 Input variable: 
    index_bam_input: optional
        Default:
            "{folder_path}/{bam_file}.bam",

 Output variable:  
    index_bam_output: optional
        Default:
            "{folder_path}/{bam_file}.bam.bai"
    
 Config dict keys: values 
    config["singularity"]["samtools"] or config["singularity"]["default"]': required
 Overriding input and output
 ------------------------------------------------------------------------------
 Required wildcards:
    bam_file
 Override input format
 Ex
  index_bam_input=[
                       "fastq/{sample}.R1.cutadapt.fastq.gz",
                       "fastq/{sample}.R2.cutadapt.fastq.gz"
                       ]
 Override output format
 Ex
   bwa_alignment_output="alignment/{sample}.cutadapt.bam"
"""


_index_bam_input = "{folder_path}/{bam_file}.bam"
try:
    _index_bam_input = index_bam_input
except:
    pass


_index_bam_output = "{folder_path}/{bam_file}.bam.bai"
try:
    _index_bam_output = index_bam_output
except:
    pass


rule samtools_index:
    input:
        _index_bam_input,
    output:
        _index_bam_output,
    singularity:
        config["singularity"].get("samtools", config["singularity"].get("default", ""))
    wrapper:
        "0.70.0/bio/samtools/index"
