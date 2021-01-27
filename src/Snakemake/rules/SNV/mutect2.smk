# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

__author__ = "Jonas Almlöf, Patrik Smeds"
__copyright__ = "Copyright 2021, Patrik Smeds, Jonas Almlöf"
__email__ = "jonas.almlöf@scilifelab.uu.se, patrik.smeds@scilifelab.uu.se"
__license__ = "GPL3"

"""
 Collection of rules that calls variants using Mutect2.
 Input, output and config
 ------------------------------------------------------------------------------
 Input variable: 
    mutect2_input_bam: optional
        Default:
            "mutect2/bam_temp/{sample}.{chr}.bam",
    mutect2_input_bai: optional
        Default:
            "mutect2/bam_temp/{sample}.{chr}.bam.bai",
    
 Output variable:  
    bwa_mem_output: optional
        Default:
            "alignment/{sample}.bam"
    bwa_mem_output_bai:
        Default:
            "alignment/{sample}.bai"
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

localrules:
    split_bedfile,
    fixSB,

_mutect_input = "alignment/{sample}.{chr}.bam"
try:
    _mutect_input = mutect_input
except:
    pass


_mutect_output_bam = "DNA_bam/mutect2_bam/{sample}-ready.indel.bam"
try:
    _mutect_output_bam = mutect_output_bam
except:
    pass


_mutect_output_vcf = temp("mutect2/{sample}.mutect2.fixAF.vcf")
try:
    _mutect_output_vcf = mutect_output_vcf
except:
    pass


rule split_bedfile:
    input:
        config["bed"]["bedfile"],
    output:
        temp("mutect2/bedfile.{chr}.bed"),
    log:
        "logs/variantCalling/split_bed.{chr}.log",
    shell:
        "(grep -w {wildcards.chr} {input} || [[ $? == 1 ]] > {output}) &> {log}"


rule mutect2:
    input:
        map=_mutect_input,
        bai=_mutect_input + ".bai",
        fasta=config["reference"]["ref"],
        bed="mutect2/bedfile.{chr}.bed",
    output:
        bam=temp("mutect2/temp/{sample}.{chr}.indel.bam"),
        bai=temp("mutect2/temp/{sample}.{chr}.indel.bai"),
        stats=temp("mutect2/temp/{sample}.{chr}.mutect2.unfilt.vcf.gz.stats"),
        vcf=temp("mutect2/temp/{sample}.{chr}.mutect2.unfilt.vcf.gz"),
        vcf_tbi=temp("mutect2/temp/{sample}.{chr}.mutect2.unfilt.vcf.gz.tbi"),
    params:
        extra=lambda wildcards: "--bam-output mutect2/bam_temp2/{wildcards.sample}-ready.{wildcards.chr}.indel.bam"
    threads:
        10
    log:
        "logs/variantCalling/mutect2_{sample}.{chr}.log",
    singularity:
        config["singularity"].get("mutect2", config["singularity"].get("default", ""))
    wrapper:
        # "(gatk --java-options '-Xmx4g' Mutect2 -R {input.fasta} -I {input.bam} -L {input.bed} --bam-output {output.bam} -O {output.vcf}) &> {log}"
        "0.70.0/bio/gatk/mutect"


rule filterMutect2:
    input:
        vcf="mutect2/temp/{sample}.{chr}.mutect2.unfilt.vcf.gz",
        vcf_tbi="mutect2/temp/{sample}.{chr}.mutect2.unfilt.vcf.gz.tbi",
        stats="mutect2/temp/{sample}.{chr}.mutect2.unfilt.vcf.gz.stats",
        fasta=config["reference"]["ref"],
    output:
        vcf=temp("mutect2/temp/{sample}.{chr}.mutect2.vcf.gz"),
        vcf_tbi=temp("mutect2/temp{sample}.{chr}.mutect2.vcf.gz.tbi"),
    params:
        extra=config.get("mutect_vcf_filter", "")
    log:
        "logs/variantCalling/mutect2/filter_{sample}.{chr}.log",
    singularity:
        config["singularity"].get("mutect2", config["singularity"].get("default", ""))
    shell:
        "(gatk --java-options '-Xmx4g' FilterMutectCalls {params.extra} -R {input.fasta} -V {input.vcf} -O {output.vcf}) &> {log}"


rule Merge_vcf:
    input:
        vcf=expand("mutect2/temp/{{sample}}.{chr}.mutect2.vcf.gz", chr=utils.extract_chr(config['reference']['ref'] + ".fai")),
    output:
        temp("mutect2/temp/{sample}.mutect2.SB.vcf"),
    log:
        "logs/variantCalling/mutect2/merge_vcf/{sample}.log",
    singularity:
        config["singularity"].get("bcftools", config["singularity"].get("default", ""))
    wrapper:
        "0.70.0/bio/gcftools/concat"


rule fixSB:
    input:
        "mutect2/temp/{sample}.mutect2.SB.vcf",
    output:
        temp(touch("mutect2/temp/{sample}.SB.done")),
    log:
        "logs/variantCalling/mutect2/{sample}.fixSB.log",
    shell:
        "(sed -i 's/=SB/=SB_mutect2/g' {input}  && sed -i 's/:SB/:SB_mutect2/g' {input}) &> {log}"


rule mutect2HardFilter:
    input:
        vcf="mutect2/temp/{sample}.mutect2.SB.vcf",
        wait="mutect2/temp/{sample}.SB.done",
    output:
        _mutect_output_vcf,
    log:
        "logs/variantCalling/mutect2/{sample}.hardFilt.log",
    singularity:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    shell:
        "(python src/python/hardFilter_PASS_mutect2.py {input.vcf} {output}) &> {log}"


rule merge_mutect_bam:
    input:
        expand("mutect2/bam_temp2/{{sample}}-ready.{chr}.indel.bam", chr=utils.extract_chr(config['reference']['ref'] + ".fai")),
    output:
        _mutect_output_bam,
    log:
        "logs/variantCalling/merge_bam/{sample}.log",
    singularity:
        config["singularity"].get("samtools", config["singularity"].get("default", ""))
    wrapper:
        "0.70.0/bio/samtools/merge"
