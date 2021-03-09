_samtools_stats_input = "DNA_bam/{sample}-ready.bam"
try:
    _samtools_stats_input = samtools_stats_input
except:
    pass

_samtools_stats_output = "qc/{sample}/{sample}.samtools-stats.txt"
try:
    _samtools_stats_output = samtools_stats_output
except:
    pass


rule samtools_stats:
    input:
        bam=_samtools_stats_input,
    output:
        stats=_samtools_stats_output,
    params:
        extra="-t " + config["bed"]["bedfile"],
    log:
        "logs/qc/samtools_stats/{sample}.log",
    singularity:
        config["singularity"].get("samtools", config["singularity"].get("default", ""))
    wrapper:
        "0.72.0/bio/samtools/stats"
