# vim: syntax=python tabstop=4 expandtab
# coding: utf-8
import pandas as pd

configfile: "Twist_DNA.yaml"

samples = pd.read_table(config["samples"], index_col="sample")

wildcard_constraints:
    unit="[A-Za-z0-9-]+",
    sample="[^._]+",
    chr="chr[0-9XYM]+",

sample_list = [s.Index  for s in samples.itertuples()]

def get_input():
    input_list = []
    '''Demultiplexning'''
    if "units" not in config:
        input_list.append(["fastq/DNA/" + s + "_R1.fastq.gz" for s in sample_list])
        input_list.append(["fastq/DNA/" + s + "_R2.fastq.gz" for s in sample_list])

    '''Alignment'''
    input_list.append(["Bam/DNA/" + s + "-ready.bam.bai" for s in sample_list])

    '''Callers'''
    input_list.append(["mutect2/" + s + ".mutect2.gvcf.gz" for s in sample_list])
    for caller in config["callers"]["list"]:
        input_list.append([caller + "/" + s + "." + caller + ".normalized.vcf.gz.tbi" for s in sample_list])
    input_list.append(["vardict/" + s + ".vardict.normalized.vcf.gz.tbi" for s in sample_list])
    input_list.append(["recall/" + s + ".ensemble.vcf.gz" for s in sample_list])
    input_list.append(["recall/" + s + ".ensemble.vcf.gz.tbi" for s in sample_list])
    input_list.append(["recall/" + s + ".ensemble.vep.vcf.gz" for s in sample_list])
    input_list.append(["recall/" + s + ".ensemble.vep.vcf.gz.tbi" for s in sample_list])
    #input_list.append(["Results/DNA/" + s + "/vcf/" + s + ".ensemble.vep.exon.soft_filter.vcf.gz" for s in sample_list])
    input_list.append(["Results/DNA/" + s + "/vcf/" + s + ".ensemble.vep.exon.soft_filter.ffpe.vcf.gz" for s in sample_list])
    input_list.append(["Results/DNA/" + s + "/vcf/" + s + ".ensemble.vep.exon.soft_filter.multibp.vcf" for s in sample_list])

    '''CNV'''
    #input_list.append(["CNV_calls/" + sample_id + "-ready.cnr" for sample_id in sample_list])
    #input_list.append(["CNV_calls/" + sample_id + "-ready.cns" for sample_id in sample_list])
    input_list.append("Results/DNA/CNV/Reported_cnvs.txt")
    #input_list.append("CNV_calls/cnv_event.txt")
    #input_list.append(["Results/DNA/" + s + "/CNV/" + s + "-ready.png" for s in sample_list])
    input_list.append(["Results/DNA/CNV/" + s + "_GATK_clean.calledCNVs.modeled.png" for s in sample_list])

    '''MSI'''
    input_list.append(["Results/DNA/" + s + "/MSI/" + s + ".msi" for s in sample_list])

    '''Fusion/SV'''
    input_list.append(["Results/DNA/" + s + "/geneFuse/fusions_" + s + ".txt"  for s in sample_list])

    '''QC'''
    input_list.append(["Results/DNA/" + s + "/QC/Low_coverage_positions.txt" for s in sample_list])
    input_list.append(["Results/DNA/" + s + "/QC/All_coverage_positions.txt" for s in sample_list])
    #input_list.append(["qc/" + s + "/" + s + "_Stat_table.csv" for s in sample_list])
    input_list.append(["qc/" + s + "/" + s + "_R1_fastqc.html" for s in sample_list])
    input_list.append(["qc/" + s + "/" + s + "_R1_fastqc.zip" for s in sample_list])
    input_list.append(["qc/" + s + "/" + s + "_R2_fastqc.html" for s in sample_list])
    input_list.append(["qc/" + s + "/" + s + "_R2_fastqc.zip" for s in sample_list])
    input_list.append(["qc/" + s + "/" + s + ".samtools-stats.txt" for s in sample_list])
    input_list.append(["qc/" + s + "/" + s + ".HsMetrics.txt" for s in sample_list])
    input_list.append(["qc/" + s + "/" + s + "_stats_mqc.csv" for s in sample_list])
    input_list.append("qc/batchQC_stats_mqc.json")
    input_list.append("qc/batchQC_stats_unsorted.csv")
    input_list.append("Results/DNA/MultiQC.html")

    return input_list

rule all:
    input:
        get_input()


include: "src/Snakemake/workflow/Twist_DNA_workflow.smk"
