# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

__author__ = "Jonas Almlöf, Patrik Smeds"
__copyright__ = "Copyright 2021, Patrik Smeds, Jonas Almlöf"
__email__ = "jonas.almlöf@scilifelab.uu.se, patrik.smeds@scilifelab.uu.se"
__license__ = "GPL3"

"""
 Collection of rules that calls variants using Vardict.
 Input, output and config
 ------------------------------------------------------------------------------
 Input variable:
    _vardict_input: optional
        Default:
            "alignment/temp/{sample}.{chr}.bam",
    _vardict_input_bed: optional
        Default:
            "mutect2/bedfile.{chr}.bed"

 Output variable:
    _vardict_output: optional
        Default:
            temp("vardict/{sample}.vardict.okAF.vcf")

 Config dict keys: values
    config["reference"]["ref"]': required
    config["singularity"]["vardict"] or config["singularity"]["default"]'  : required
    config["singularity"]["bcftools"]' or config["singularity"]["default"]'  : required
 Overriding input and output
 ------------------------------------------------------------------------------
 Required wildcards:
    sample
    chr
 Override input format
 Ex
  vardict_input="alignment/{sample}.{chr}.bam"
  vardict_input_bed="bedfile/bedfile.{chr}.bed"

 Override output format
 Ex
   vardict_output="vardict/{sample}.vardict.vcf"
"""


_vardict_input = "alignment/{sample}.{chr}.bam"
try:
    _vardict_input = vardict_input
except:
    pass


_vardict_input_bed = "mutect2/bedfile.{chr}.bed"
try:
    _vardict_input_bed = vardict_input_bed
except:
    pass


_vardict_output = temp("vardict/{sample}.vardict.okAF.vcf")
try:
    _vardict_output = vardict_output
except:
    pass


rule vardict:
    input:
        bam=_vardict_input,
        bai=_vardict_input + ".bai",
        reference=config["reference"]["ref"],
        regions="mutect2/bedfile.{chr}.bed",
    output:
        vcf="vardict/temp/{sample}.{chr}.unsort.vcf",
    params:
        extra="-I 200 -Q 10 -F 0x700",
        sample_name=lambda wildcards: wildcards.sample,
        af_th="0.01",
    threads: 5
    container:
        config["singularity"].get("vardict", config["singularity"].get("default", ""))
    wrapper:
        "0.72.0/bio/vardict"


rule filter_vardict:
    input:
        "vardict/temp/{sample}.{chr}.unsort.vcf",
    output:
        temp("vardict/temp/{sample}.{chr}.unsort.filtered.vcf"),
    params:
        filter="-i 'QUAL >= 0'",
    log:
        "logs/variantCalling/vardict/{sample}.{chr}.filter.log",
    container:
        config["singularity"].get("bcftools", config["singularity"].get("default", ""))
    wrapper:
        "0.72.0/bio/bcftools/filter"


rule filter_iupac_codes_vardict:
    input:
        "vardict/temp/{sample}.{chr}.unsort.filtered.vcf",
    output:
        temp("vardict/temp/{sample}.{chr}.unsort.filtered.mod_iupac.vcf"),
    log:
        "logs/variantCalling/vardict/{sample}.{chr}.iupac_replace.log",
    shell:
        "(cat  {input} | "
        " awk -F$'\t' -v OFS='\t' '{{if ($0 !~ /^#/) gsub(/[KMRYSWBVHDXkmryswbvhdx]/, \"N\", $4) }} {{print}}' |"
        " awk -F$'\t' -v OFS='\t' '{{if ($0 !~ /^#/) gsub(/[KMRYSWBVHDXkmryswbvhdx]/, \"N\", $5) }} {{print}}' "
        " > {output}) &> {log}"


rule remove_duplicates_vardict:
    input:
        "vardict/temp/{sample}.{chr}.unsort.filtered.mod_iupac.vcf",
    output:
        temp("vardict/temp/{sample}.{chr}.unsort.filtered.mod_iupac.dup_removed.fixChr.vcf"),
    log:
        "logs/variantCalling/vardict/{sample}.{chr}.iupac_replace.removed_dup.log",
    shell:
        "(cat  {input} | "
        " awk -F$'\t' -v OFS='\t' '$1!~/^#/ && $4 == $5 {{next}} {{print}}'"
        " > {output}) &> {log}"


rule merge_vcf_vardict:
    input:
        calls=expand(
            "vardict/temp/{{sample}}.{chr}.unsort.filtered.mod_iupac.dup_removed.chrAdded.vcf",
            chr=utils.extract_chr(config['reference']['ref'] + ".fai", filter_out=config.get("skip_chrs", [])),
        ),
    output:
        temp("vardict/temp/{sample}.unsort.filtered.mod.vcf"),
    log:
        "logs/variantCalling/vardict/merge_vcf/{sample}.log",
    container:
        config["singularity"].get("bcftools", config["singularity"].get("default", ""))
    wrapper:
        "0.70.0/bio/bcftools/concat"


rule sortVardict:
    input:
        gz="vardict/temp/{sample}.unsort.filtered.mod.vcf.gz",
        tbi="vardict/temp/{sample}.unsort.filtered.mod.vcf.gz.tbi",
    output:
        _vardict_output,
    container:
        config["singularity"].get("bcftools", config["singularity"].get("default", ""))
    log:
        "logs/variantCalling/vardict/{sample}.sort.log",
    shell:
        "bcftools sort -o {output} -O v {input.gz} &> {log}"
