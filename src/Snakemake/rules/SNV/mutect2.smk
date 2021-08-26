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


_mutect_output_bam = "Bam/DNA/{sample}-ready.indel.bam"
try:
    _mutect_output_bam = mutect_output_bam
except:
    pass


_mutect_output_vcf = temp("mutect2/{sample}.mutect2.fixAF.vcf")
try:
    _mutect_output_vcf = mutect_output_vcf
except:
    pass


# TODO Maybe add sample name, to handle cases when multiple designs are run in the same analysis?
rule split_bedfile:
    input:
        config["bed"]["bedfile"],
    output:
        temp("mutect2/bedfile.{chr}.bed"),
    log:
        "logs/variantCalling/split_bed.{chr}.log",
    shell:
        "(awk '{{if(/^{wildcards.chr}\t/) print($0)}}' {input}  > {output}) &> {log}"


rule mutect2:
    input:
        map=_mutect_input,
        bai=_mutect_input + ".bai",
        fasta=config["reference"]["ref"],
        bed="mutect2/bedfile.{chr}.bed",
    output:
        bam=temp("mutect2/bam/{sample}.{chr}.indel.bam"),
        bai=temp("mutect2/bam/{sample}.{chr}.indel.bai"),
        stats=temp("mutect2/temp/{sample}.{chr}.mutect2.unfilt.vcf.gz.stats"),
        vcf=temp("mutect2/temp/{sample}.{chr}.mutect2.unfilt.vcf.gz"),
        vcf_tbi=temp("mutect2/temp/{sample}.{chr}.mutect2.unfilt.vcf.gz.tbi"),
        f1r2=temp("mutect2/temp/{sample}.{chr}.mutect2.f1r2.tar.gz"),
    params:
        extra="--intervals mutect2/bedfile.{chr}.bed --f1r2-tar-gz mutect2/temp/{sample}.{chr}.mutect2.f1r2.tar.gz",
    threads: 1
    log:
        "logs/variantCalling/mutect2_{sample}.{chr}.log",
    container:
        config["singularity"].get("mutect2", config["singularity"].get("default", ""))
    wrapper:
        "0.72.0/bio/gatk/mutect"


rule mutect2_gvcf:
    input:
        map=_mutect_input,
        bai=_mutect_input + ".bai",
        fasta=config["reference"]["ref"],
        bed="mutect2/bedfile.{chr}.bed",
    output:
        stats=temp("mutect2/temp/{sample}.{chr}.mutect2.gvcf.gz.stats"),
        vcf=temp("mutect2/temp/{sample}.{chr}.mutect2.gvcf.gz"),
        vcf_tbi=temp("mutect2/temp/{sample}.{chr}.mutect2.gvcf.gz.tbi"),
    params:
        extra="--intervals mutect2/bedfile.{chr}.bed -ERC BP_RESOLUTION ",
    threads: 1
    log:
        "logs/variantCalling/mutect2_gvcf_{sample}.{chr}.log",
    container:
        config["singularity"].get("mutect2", config["singularity"].get("default", ""))
    wrapper:
        "0.72.0/bio/gatk/mutect"


rule Merge_vcf:
    input:
        calls=expand(
            "mutect2/temp/{{sample}}.{chr}.mutect2.unfilt.vcf.gz",
            chr=utils.extract_chr(config['reference']['ref'] + ".fai"),
        ),
    output:
        #temp("mutect2/temp/{sample}.mutect2.SB.vcf"),
        "mutect2/temp/{sample}.mutect2.unfilt.vcf",
    log:
        "logs/variantCalling/mutect2/merge_vcf/{sample}.log",
    container:
        config["singularity"].get("bcftools", config["singularity"].get("default", ""))
    wrapper:
        "0.70.0/bio/bcftools/concat"


rule Merge_stats:
    input:
        stats=expand(
            "mutect2/temp/{{sample}}.{chr}.mutect2.unfilt.vcf.gz.stats",
            chr=utils.extract_chr(config['reference']['ref'] + ".fai"),
        ),
    params:
        stats=' '.join(
            '-stats ' + v
            for v in expand(
                "mutect2/temp/{{sample}}.{chr}.mutect2.unfilt.vcf.gz.stats",
                chr=utils.extract_chr(config['reference']['ref'] + ".fai"),
            )
        ),
    output:
        temp("mutect2/temp/{sample}.mutect2.unfilt.vcf.gz.stats"),
    log:
        "logs/variantCalling/mutect2/merge_stats/{sample}.log",
    container:
        config["singularity"].get("mutect2", config["singularity"].get("default", ""))
    shell:
        "(gatk MergeMutectStats {params.stats} -O {output}) > {log}"


rule merge_LearnReadOrientationModel:
    input:
        f1r2=expand(
            "mutect2/temp/{{sample}}.{chr}.mutect2.f1r2.tar.gz",
            chr=utils.extract_chr(config['reference']['ref'] + ".fai"),
        ),
    output:
        f1r2=temp("mutect2/temp/{sample}.mutect2.f1r2.tar.gz"),
    log:
        "logs/variantCalling/mutect2/merge_LearnReadOrientationModel/{sample}.log",
    shell:
        "(cat {input.f1r2} > {output.f1r2}) > {log}"


rule LearnReadOrientationModel:
    input:
        "mutect2/temp/{sample}.mutect2.f1r2.tar.gz",
    output:
        temp("mutect2/temp/{sample}.mutect2.read-orientation-model.tar.gz"),
    log:
        "logs/variantCalling/mutect2/LearnReadOrientationModel/{sample}.log",
    container:
        config["singularity"].get("mutect2", config["singularity"].get("default", ""))
    shell:
        "(gatk LearnReadOrientationModel -I {input} -O {output}) > {log}"


rule GetPileupSummaries:
    input:
        "Bam/DNA/{sample}-ready.bam",
    params:
        "DATA/chr17_small_exac_common_3.vcf.gz",
    output:
        temp("mutect2/temp/{sample}.mutect2.getpileupsummaries.table"),
    log:
        "logs/variantCalling/mutect2/GetPileupSummaries/{sample}.log",
    container:
        config["singularity"].get("mutect2", config["singularity"].get("default", ""))
    shell:
        "(gatk GetPileupSummaries -I {input} -V {params} -L {params} -O {output}) > {log}"


rule CalculateContamination:
    input:
        "mutect2/temp/{sample}.mutect2.getpileupsummaries.table",
    output:
        segments=temp("mutect2/temp/{sample}.mutect2.tumor_segmentation.table"),
        contamination=temp("mutect2/temp/{sample}.mutect2.contamination.table"),
    log:
        "logs/variantCalling/mutect2/CalculateContamination/{sample}.log",
    container:
        config["singularity"].get("mutect2", config["singularity"].get("default", ""))
    shell:
        "(gatk CalculateContamination -I {input} -tumor-segmentation {output.segments} -O {output.contamination}) > {log}"


rule filterMutect2:
    input:
        vcf="mutect2/temp/{sample}.mutect2.unfilt.vcf.gz",
        vcf_tbi="mutect2/temp/{sample}.mutect2.unfilt.vcf.gz.tbi",
        stats="mutect2/temp/{sample}.mutect2.unfilt.vcf.gz.stats",
        segments="mutect2/temp/{sample}.mutect2.tumor_segmentation.table",
        contamination="mutect2/temp/{sample}.mutect2.contamination.table",
        ob_prior="mutect2/temp/{sample}.mutect2.read-orientation-model.tar.gz",
        fasta=config["reference"]["ref"],
    output:
        vcf=temp("mutect2/temp/{sample}.mutect2.SB.vcf"),
        #vcf_tbi=temp("mutect2/temp/{sample}.mutect2.SB.vcf.gz.tbi"),
        #vcf=temp("mutect2/temp/{sample}.{chr}.mutect2.vcf.gz"),
        #vcf_tbi=temp("mutect2/temp/{sample}.{chr}.mutect2.vcf.gz.tbi"),
    params:
        extra=config.get("mutect_vcf_filter", ""),
    log:
        "logs/variantCalling/mutect2/filter_{sample}.log",
    container:
        config["singularity"].get("mutect2", config["singularity"].get("default", ""))
    shell:
        "(gatk --java-options '-Xmx4g' FilterMutectCalls {params.extra} -R {input.fasta} -V {input.vcf} "
        "--tumor-segmentation {input.segments} --contamination-table {input.contamination} --ob-priors {input.ob_prior} "
        "-O {output.vcf}) &> {log}"


rule Merge_gvcf:
    input:
        calls=expand(
            "mutect2/temp/{{sample}}.{chr}.mutect2.gvcf.gz",
            chr=utils.extract_chr(config['reference']['ref'] + ".fai", skip_chroms=config.get("skip_chrs", [])),
        ),
    output:
        "mutect2/{sample}.mutect2.gvcf.gz",
    params:
        "-O z ",
    log:
        "logs/variantCalling/mutect2/merge_gvcf/{sample}.log",
    container:
        config["singularity"].get("bcftools", config["singularity"].get("default", ""))
    wrapper:
        "0.70.0/bio/bcftools/concat"


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
    container:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/hardFilter_PASS_mutect2.py"


rule merge_mutect_bam:
    input:
        expand(
            "mutect2/bam_temp2/{{sample}}-ready.{chr}.indel.bam",
            chr=utils.extract_chr(config['reference']['ref'] + ".fai", skip_chroms=config.get("skip_chrs", [])),
        ),
    output:
        _mutect_output_bam,
    log:
        "logs/variantCalling/merge_bam/{sample}.log",
    container:
        config["singularity"].get("samtools", config["singularity"].get("default", ""))
    wrapper:
        "0.70.0/bio/samtools/merge"
