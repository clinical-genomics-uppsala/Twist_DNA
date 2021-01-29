
configfile: "Twist_DNA.yaml"

wildcard_constraints:
    unit="[A-Za-z0-9-]+",
    sample="[^.]+",

def get_input():
    input_list = []
    '''Demultiplexning'''
    input_list.append(["fastq/DNA/" + s + "_R1.fastq.gz" for s in config["DNA_Samples"]])
    input_list.append(["fastq/DNA/" + s + "_R2.fastq.gz" for s in config["DNA_Samples"]])

    '''Alignment'''
    input_list.append(["DNA_bam/" + s + "-ready.bam.bai" for s in config["DNA_Samples"]])

    '''Callers'''
    input_list.append(["mutect2/" + s + ".mutect2.normalized.vcf.gz.tbi" for s in config["DNA_Samples"]])
    input_list.append(["freebayes/" + s + ".freebayes.normalized.vcf.gz.tbi" for s in config["DNA_Samples"]])
    input_list.append(["varscan/" + s + ".varscan.normalized.vcf.gz.tbi" for s in config["DNA_Samples"]])
    input_list.append(["vardict/" + s + ".vardict.normalized.vcf.gz.tbi" for s in config["DNA_Samples"]])
    #input_list.append(["DNA_bam/mutect2_bam/" + s + "-ready.indel.bam.bai" for s in config["DNA_Samples"]])
    input_list.append(["recall/" + s + ".ensemble.vcf.gz" for s in config["DNA_Samples"]])
    input_list.append(["recall/" + s + ".ensemble.vcf.gz.tbi" for s in config["DNA_Samples"]])
    input_list.append(["recall/" + s + ".ensemble.vep.vcf.gz" for s in config["DNA_Samples"]])
    input_list.append(["recall/" + s + ".ensemble.vep.vcf.gz.tbi" for s in config["DNA_Samples"]])

    '''Variant filtering'''
    #input_list.append(["Results/DNA/" + s + "/vcf/" + s + "-ensemble.final.no.introns.vcf.gz" for s in config["DNA_Samples"]])
    #input_list.append(["Results/DNA/" + s + "/vcf/" + s + "-ensemble.final.no.introns.AD20.vcf.gz" for s in config["DNA_Samples"]])
    #input_list.append(["Results/DNA/" + s + "/vcf/" + s + "-ensemble.final.no.introns.AD20.ffpe.tsv.gz" for s in config["DNA_Samples"]])

    '''CNV'''
    #input_list.append(["CNV_calls/" + sample_id + "-ready.cnr" for sample_id in config["DNA_Samples"]])
    #input_list.append(["CNV_calls/" + sample_id + "-ready.cns" for sample_id in config["DNA_Samples"]])
    input_list.append("CNV/CNV_calls/relevant_cnv.txt")
    #input_list.append("CNV_calls/cnv_event.txt")
    #input_list.append(["Results/DNA/" + s + "/CNV/" + s + "-ready.png" for s in config["DNA_Samples"]])
    input_list.append(["CNV/CNV_GATK/" + s + "_clean.calledCNVs.modeled.png" for s in config["DNA_Samples"]])

    '''MSI'''
    input_list.append(["MSI/" + s + ".msi" for s in config["DNA_Samples"]])

    '''Fusion/SV'''
    input_list.append(["gridss/" + s + ".vcf.gz" for s in config["DNA_Samples"]])

    '''QC'''
    #input_list.append(["Results/DNA/" + s + "/QC/Low_coverage_positions.txt" for s in config["DNA_Samples"]])
    #input_list.append(["Results/DNA/" + s + "/QC/All_coverage_positions.txt" for s in config["DNA_Samples"]])
    #input_list.append(["qc/" + s + "/" + s + "_Stat_table.csv" for s in config["DNA_Samples"]])
    input_list.append(["qc/" + s + "/" + s + "_R1_fastqc.html" for s in config["DNA_Samples"]])
    input_list.append(["qc/" + s + "/" + s + "_R1_fastqc.zip" for s in config["DNA_Samples"]])
    input_list.append(["qc/" + s + "/" + s + "_R2_fastqc.html" for s in config["DNA_Samples"]])
    input_list.append(["qc/" + s + "/" + s + "_R2_fastqc.zip" for s in config["DNA_Samples"]])
    input_list.append(["qc/" + s + "/" + s + ".samtools-stats.txt" for s in config["DNA_Samples"]])
    input_list.append(["qc/" + s + "/" + s + ".HsMetrics.txt" for s in config["DNA_Samples"]])
    input_list.append(["qc/" + s + "/" + s + "_stats_mqc.csv" for s in config["DNA_Samples"]])
    input_list.append("qc/batchQC_stats_mqc.json")
    input_list.append("qc/batchQC_stats_unsorted.csv")
    input_list.append("Results/DNA/MultiQC.html")

    return input_list

rule all:
    input:
        get_input()


include: "src/Snakemake/workflow/Twist_DNA_workflow.smk"
