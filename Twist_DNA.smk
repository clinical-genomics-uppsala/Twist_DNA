# vim: syntax=python tabstop=4 expandtab
# coding: utf-8
import pandas as pd

configfile: "Twist_DNA.yaml"

samples = pd.read_table(config["samples"], index_col="sample")

wildcard_constraints:
    unit="[A-Za-z0-9-]+",
    sample="[^.]+",
    chr="chr[0-9XYM]+",

def get_input():
    input_list = []
    '''Demultiplexning'''
    input_list.append(["fastq/DNA/" + s.Index + "_R1.fastq.gz" for s in samples.itertuples()])
    input_list.append(["fastq/DNA/" + s.Index + "_R2.fastq.gz" for s in samples.itertuples()])

    '''Alignment'''
    input_list.append(["Bam/DNA/" + s.Index + "-ready.bam.bai" for s in samples.itertuples()])

    '''Callers'''
    input_list.append(["mutect2/" + s.Index + ".mutect2.normalized.vcf.gz.tbi" for s in samples.itertuples()])
    input_list.append(["mutect2/" + s.Index + ".mutect2.gvcf.gz" for s in samples.itertuples()])
    input_list.append(["freebayes/" + s.Index + ".freebayes.normalized.vcf.gz.tbi" for s in samples.itertuples()])
    input_list.append(["varscan/" + s.Index + ".varscan.normalized.vcf.gz.tbi" for s in samples.itertuples()])
    input_list.append(["vardict/" + s.Index + ".vardict.normalized.vcf.gz.tbi" for s in samples.itertuples()])
    input_list.append(["recall/" + s.Index + ".ensemble.vcf.gz" for s in samples.itertuples()])
    input_list.append(["recall/" + s.Index + ".ensemble.vcf.gz.tbi" for s in samples.itertuples()])
    input_list.append(["recall/" + s.Index + ".ensemble.vep.vcf.gz" for s in samples.itertuples()])
    input_list.append(["recall/" + s.Index + ".ensemble.vep.vcf.gz.tbi" for s in samples.itertuples()])
    #input_list.append(["Results/DNA/" + s.Index + "/vcf/" + s.Index + ".ensemble.vep.exon.soft_filter.vcf.gz" for s in samples.itertuples()])
    input_list.append(["Results/DNA/" + s.Index + "/vcf/" + s.Index + ".ensemble.vep.exon.soft_filter.ffpe.vcf.gz" for s in samples.itertuples()])
    input_list.append(["Results/DNA/" + s.Index + "/vcf/" + s.Index + ".ensemble.vep.exon.soft_filter.multibp.vcf" for s in samples.itertuples()])

    '''CNV'''
    #input_list.append(["CNV_calls/" + sample_id + "-ready.cnr" for sample_id in config["DNA_Samples"]])
    #input_list.append(["CNV_calls/" + sample_id + "-ready.cns" for sample_id in config["DNA_Samples"]])
    input_list.append("Results/DNA/CNV/Reported_cnvs.txt")
    #input_list.append("CNV_calls/cnv_event.txt")
    #input_list.append(["Results/DNA/" + s.Index + "/CNV/" + s.Index + "-ready.png" for s in samples.itertuples()])
    input_list.append(["Results/DNA/CNV/" + s.Index + "_GATK_clean.calledCNVs.modeled.png" for s in samples.itertuples()])

    '''MSI'''
    input_list.append(["Results/DNA/" + s.Index + "/MSI/" + s.Index + ".msi" for s in samples.itertuples()])

    '''Fusion/SV'''
    input_list.append(["Results/DNA/" + s.Index + "/geneFuse/fusions_" + s.Index + ".txt"  for s in samples.itertuples()])

    '''QC'''
    input_list.append(["Results/DNA/" + s.Index + "/QC/Low_coverage_positions.txt" for s in samples.itertuples()])
    input_list.append(["Results/DNA/" + s.Index + "/QC/All_coverage_positions.txt" for s in samples.itertuples()])
    #input_list.append(["qc/" + s.Index + "/" + s.Index + "_Stat_table.csv" for s in samples.itertuples()])
    input_list.append(["qc/" + s.Index + "/" + s.Index + "_R1_fastqc.html" for s in samples.itertuples()])
    input_list.append(["qc/" + s.Index + "/" + s.Index + "_R1_fastqc.zip" for s in samples.itertuples()])
    input_list.append(["qc/" + s.Index + "/" + s.Index + "_R2_fastqc.html" for s in samples.itertuples()])
    input_list.append(["qc/" + s.Index + "/" + s.Index + "_R2_fastqc.zip" for s in samples.itertuples()])
    input_list.append(["qc/" + s.Index + "/" + s.Index + ".samtools-stats.txt" for s in samples.itertuples()])
    input_list.append(["qc/" + s.Index + "/" + s.Index + ".HsMetrics.txt" for s in samples.itertuples()])
    input_list.append(["qc/" + s.Index + "/" + s.Index + "_stats_mqc.csv" for s in samples.itertuples()])
    input_list.append("qc/batchQC_stats_mqc.json")
    input_list.append("qc/batchQC_stats_unsorted.csv")
    input_list.append("Results/DNA/MultiQC.html")

    return input_list

rule all:
    input:
        get_input()


include: "src/Snakemake/workflow/Twist_DNA_workflow.smk"
