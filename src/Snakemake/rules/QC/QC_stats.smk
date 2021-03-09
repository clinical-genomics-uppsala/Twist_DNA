rule touchBatch:
    input:
        expand("DNA_bam/{sample}-ready.bam", sample=config["DNA_Samples"]),
    output:
        temp("qc/batchQC_stats_unsorted.csv"),
    log:
        "logs/touch.log",
    shell:
        "(touch {output}) &> {log}"


rule getStatsforMqc:
    input:
        #picardDup = "qc/{sample}/{sample}_DuplicationMetrics.txt", #Not running this step in picard
        picardMet1="qc/{sample}/{sample}.HsMetrics.txt",
        picardMet2="qc/{sample}/{sample}.insert_size_metrics.txt",
        picardMet3="qc/{sample}/{sample}.alignment_summary_metrics.txt",
        picardMet4="qc/{sample}/{sample}.gc_bias.summary_metrics.txt",
        samtools="qc/{sample}/{sample}.samtools-stats.txt",
        #multiQCheader = config["programdir"]["dir"]+"src/qc/multiqc-header.txt",
        multiQCheader="DATA/multiqc-header.txt",
        #cartool = "qc/{sample}/{sample}_Log.csv",
        batch="qc/batchQC_stats_unsorted.csv",
    output:
        batchTmp=temp(touch("qc/{sample}/{sample}_batchStats.done")),
        sample="qc/{sample}/{sample}_stats_mqc.csv",
    log:
        "logs/qc/{sample}_stats.log",
    singularity:
        config["singularity"]["python"]
    script:
        "../../../scripts/python/get_stats.py"


rule sortBatchStats:
    input:
        SampleSheetUsed=config["Sample_sheet"],
        batchUnsorted="qc/batchQC_stats_unsorted.csv",
        batchDone=expand("qc/{sample}/{sample}_batchStats.done", sample=config["DNA_Samples"]),
    output:
        batch="qc/batchQC_stats_mqc.json",
    log:
        "logs/qc/sortBatch_Stats.log",
    singularity:
        config["singularity"]["python"]
    script:
        "../../../scripts/python/sortBatchStats.py"
