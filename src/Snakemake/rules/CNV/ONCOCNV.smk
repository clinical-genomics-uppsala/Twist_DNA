
rule fix_bed_file:
    input:
        bed=config["bed"]["bedfile"],
    output:
        bed="CNV/bed/ONCOCNV.bed",
    log:
        "logs/CNV_ONCOCNV/fix_bed_file.log",
    shell:
        "(awk 'BEGIN{{ OFS=\"\t\"}}{{ print $1, $2, $3, NR, \"0\", $4 }}' {input.bed} > {output.bed}) &> {log}"


rule Tumor_levels:
    input:
        bam="DNA_bam/{sample}-ready.bam",
        PoN=config["PoN"]["ONCOCNV"],
    output:
        sample_stats="CNV/ONCOCNV_stats/{sample}.stats.txt",
    log:
        "logs/CNV_ONCOCNV/{sample}.Tumor_levels.log",
    singularity:
        config["singularity"]["ONCOCNV"]
    shell:
        "perl ONCOCNV/ONCOCNV_getCounts.pl getSampleStats "
        "-m Ampli "
        "-c {input.PoN} "
        "-s {input.bam} "
        "-o {output.sample_stats}"


rule Target_bed:
    input:
        PoN=config["PoN"]["cnvkit"],
    output:
        bed="CNV/bed/ONCOCNV_target.bed",
    log:
        "logs/CNV_ONCOCNV/Target_bed.log",
    shell:
        "(cat {input.stats} | grep -v start | awk '{{print $1,$2,$3}}' "
        "| sed \"s/ /\t/g\" > {output.bed}) &> {log}"


rule Target_GC:
    input:
        bed="CNV/bed/ONCOCNV_target.bed",
        reference=config["reference"]["ref"],
    output:
        GC="CNV/ONCOCNV_target.GC.txt",
    log:
        "logs/CNV_ONCOCNV/Target_GC.log",
    singularity:
        config["singularity"]["ONCOCNV"]
    shell:
        "(perl ONCOCNV/createTargetGC.pl "
        "-bed {input.bed} "
        "-fi {input.reference} "
        "-od stats/ "
        "-of {output.GC}) &> {log}"


rule Calls:
    input:
        tumor_stats="CNV/ONCOCNV_stats/{sample}.stats.txt",
        PoN_stats=config["PoN"]["ONCOCNV2"],
    output:
        call="CNV/ONCOCNV_calls/{sample}.output.txt",
    log:
        "logs/CNV_ONCOCNV/{sample}.Calls.log",
    singularity:
        config["singularity"]["ONCOCNV"]
    shell:
        "(cat ONCOCNV/processSamples.R | R --slave --args {input.tumor_stats} {input.PoN_stats} {output.call} cghseg) &> {log}"


rule CNV_event:
    input:
        calls=["CNV/ONCOCNV_calls/" + sample_id + ".output.txt" for sample_id in config["DNA_Samples"]],
    output:
        cnv_event="CNV/ONCOCNV_calls/cnv_event.txt",
    log:
        "logs/CNV_ONCOCNV/CNV_event.log",
    singularity:
        config["singularity"]["python"]
    shell:
        "(python src/python/get_cnv_ONCOCNV.py {input.calls} {output.cnv_event}) &> {log}"
