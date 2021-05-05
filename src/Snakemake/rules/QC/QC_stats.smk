sample_list = [s.Index for s in samples.itertuples()]


rule touchBatch:
    input:
        expand("Bam/DNA/{sample}-ready.bam", sample=sample_list),
    output:
        temp("qc/batchQC_stats_unsorted.csv"),
    log:
        "logs/touch.log",
    shell:
        "(touch {output}) &> {log}"


rule getStatsforMqc:
    input:
        picardMet1="qc/{sample}/{sample}.HsMetrics.txt",
        picardMet2="qc/{sample}/{sample}.insert_size_metrics.txt",
        picardMet3="qc/{sample}/{sample}.alignment_summary_metrics.txt",
        #picardMet4="qc/{sample}/{sample}.gc_bias.summary_metrics.txt",
        picardMet5="qc/{sample}/{sample}.duplication_metrics.txt",
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
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/get_stats.py"


rule sortBatchStats:
    input:
        SampleSheetUsed=config["samplesheet"],
        batchUnsorted="qc/batchQC_stats_unsorted.csv",
        batchDone=expand("qc/{sample}/{sample}_batchStats.done", sample=sample_list),
    output:
        batch="qc/batchQC_stats_mqc.json",
    log:
        "logs/qc/sortBatch_Stats.log",
    singularity:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/sortBatchStats.py"
