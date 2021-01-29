chrom_list = [
    'chr1',
    'chr2',
    'chr3',
    'chr4',
    'chr5',
    'chr6',
    'chr7',
    'chr8',
    'chr9',
    'chr10',
    'chr11',
    'chr12',
    'chr13',
    'chr14',
    'chr15',
    'chr16',
    'chr17',
    'chr18',
    'chr19',
    'chr20',
    'chr21',
    'chr22',
    'chrX',
    'chrY',
]


rule Split_bam_Markdup:
    input:
        bam="bam/{sample}-sort.bam",
        bai="bam/{sample}-sort.bam.bai",
    output:
        bam=temp("bam/Markdup_temp/{sample}-sort.{chr}.bam"),
    log:
        "logs/map/MarkDup/split_bam_realign_{sample}-sort.{chr}.log",
    singularity:
        config["singularity"]["samtools"]
    shell:
        "(samtools view -b {input.bam} {wildcards.chr} > {output.bam} &> {log}"


rule MarkDuplicates:
    input:
        bam="bam/Markdup_temp/{sample}-sort.{chr}.bam",
        bai="bam/Markdup_temp/{sample}-sort.{chr}.bam.bai",
    output:
        bam=temp("bam/Markdup_temp/{sample}-dup.{chr}.bam"),
    params:
        metric="qc/{sample}_DuplicationMetrics.{chr}.txt",
    log:
        "logs/map/MarkDup/{sample}-ready.{chr}.log",
    threads: 2
    singularity:
        config["singularity"]["picard"]
    shell:
        "(java -Xmx4g -jar /opt/conda/share/picard-2.20.1-0/picard.jar MarkDuplicates INPUT={input.bam} OUTPUT={output.bam} METRICS_FILE={params.metric}) &> {log}"


rule Merge_bam_Markdup:
    input:
        bams=expand("bam/Markdup_temp/{{sample}}-dup.{chr}.bam", chr=chrom_list),
    output:
        bam="DNA_bam/{sample}-ready.bam",
    log:
        "logs/map/MarkDup/merge_bam/{sample}.log",
    singularity:
        config["singularity"]["samtools"]
    shell:
        "(samtools merge {output.bam} {input.bams} &> {log}"
