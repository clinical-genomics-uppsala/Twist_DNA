localrules:
    touchBatch,


rule samtools_stats:
    input:
        bam="DNA_bam/{sample}-ready.bam",
    output:
        "qc/{sample}/{sample}.samtools-stats.txt",
    params:
        # region="1:1000000-2000000"      # Optional: region string.
        extra="-t " + config["bed"]["bedfile"],  # Optional: extra arguments.
    log:
        "logs/qc/samtools_stats/{sample}.log",
    singularity:
        config["singularity"]["samtools"]
    shell:
        "(samtools stats {params.extra} {input} > {output} ) &> {log}"


# wrapper:
#     "0.38.0/bio/samtools/stats"


rule picardHsMetrics:
    input:
        bam="DNA_bam/{sample}-ready.bam",
        #bam = "STAR2/{sample}Aligned.sortedByCoord.out.bam",
        intervals=config["bed"]["intervals"],
    output:
        "qc/{sample}/{sample}.HsMetrics.txt",
    log:
        "logs/qc/picard/HsMetrics/{sample}.log",
    singularity:
        config["singularity"]["picard"]
    shell:
        "(java -Xmx4g -jar /opt/conda/share/picard-2.20.1-0/picard.jar CollectHsMetrics BAIT_INTERVALS={input.intervals} TARGET_INTERVALS={input.intervals} INPUT={input.bam} OUTPUT={output}) &> {log}"


rule picardInsertSize:
    input:
        bam="DNA_bam/{sample}-ready.bam",
    output:
        txt="qc/{sample}/{sample}.insert_size_metrics.txt",
        pdf="qc/{sample}/{sample}.insert_size_histogram.pdf",
    log:
        "logs/qc/picard/InsertSize/{sample}.log",
    singularity:
        config["singularity"]["picard"]
    shell:
        "(java -Xmx4g -jar /opt/conda/share/picard-2.20.1-0/picard.jar CollectInsertSizeMetrics INPUT={input.bam} O={output.txt} H={output.pdf}) &> {log}"


rule PicardAlignmentSummaryMetrics:
    input:
        bam="DNA_bam/{sample}-ready.bam",
        ref=config["reference"]["ref"],
    output:
        "qc/{sample}/{sample}.alignment_summary_metrics.txt",
    log:
        "logs/qc/picard/AlignmentSummaryMetrics/{sample}.log",
    singularity:
        config["singularity"]["picard"]
    shell:
        "(java -Xmx4g -jar /opt/conda/share/picard-2.20.1-0/picard.jar CollectAlignmentSummaryMetrics INPUT={input.bam} R={input.ref} OUTPUT={output}) &> {log}"


rule GcBiasSummaryMetrics:
    input:
        bam="DNA_bam/{sample}-ready.bam",
        ref=config["reference"]["ref"],
    output:
        summary="qc/{sample}/{sample}.gc_bias.summary_metrics.txt",
        gc="qc/{sample}/{sample}.gc_bias.metrics.txt",
        pdf="qc/{sample}/{sample}.gc_bias.metrics.pdf",
    log:
        "logs/qc/picard/GcBiasSummaryMetrics/{sample}.log",
    singularity:
        config["singularity"]["picard"]
    shell:
        "(java -Xmx4g -jar /opt/conda/share/picard-2.20.1-0/picard.jar CollectGcBiasMetrics I={input.bam} R={input.ref} O={output.gc} CHART={output.pdf} S={output.summary}) &> {log}"


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
        #batchTmp = "qc/{sample}/{sample}_batchStats.done",
        # batch = "qc/{seqID}_stats_mqc.tsv",
        sample="qc/{sample}/{sample}_stats_mqc.csv",
    # params:
    #    dir = config["programdir"]["dir"]
    log:
        "logs/qc/{sample}_stats.log",
    singularity:
        config["singularity"]["python"]
    script:
        #"(python3.6 src/lib/python/get_stats.py {input.picardMet1} {input.picardMet2} {input.picardMet3} {input.picardMet4} {input.samtools} {input.multiQCheader} {input.cartool} {wildcards.sample} {output.sample} {input.batch} && touch {output.batchTmp}) &> {log}"
        "../../../scripts/python/get_stats.py"


rule sortBatchStats:
    input:
        SampleSheetUsed=config["Sample_sheet"],
        batchUnsorted="qc/batchQC_stats_unsorted.csv",
        batchDone=expand("qc/{sample}/{sample}_batchStats.done", sample=config["DNA_Samples"]),
    output:
        batch="qc/batchQC_stats_mqc.json",
    # params:
    #    dir = config["programdir"]["dir"]
    log:
        "logs/qc/sortBatch_Stats.log",
    singularity:
        config["singularity"]["python"]
    shell:
        "../../../scripts/python/sortBatchStats.py"
