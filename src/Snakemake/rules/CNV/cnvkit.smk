
rule Create_targets:
    input:
        bed=config["bed"]["bedfile"],
    output:
        bed="CNV/bed/cnvkit_manifest.target.bed",
    log:
        "logs/CNV_cnvkit/Create_targets.log",
    singularity:
        config["singularity"]["cnvkit"]
    shell:
        "(cnvkit.py target --split {input.bed} -o {output.bed}) &> {log}"


rule Create_anti_targets:
    input:
        bed="CNV/bed/cnvkit_manifest.target.bed",
    output:
        bed="CNV/bed/cnvkit_manifest.antitarget.bed",
    log:
        "logs/CNV_cnvkit/Create_anti_targets.log",
    singularity:
        config["singularity"]["cnvkit"]
    shell:
        "(cnvkit.py antitarget {input.bed} -o {output.bed}) &> {log}"


rule Call_cnv:
    input:
        bams=["DNA_bam/" + s + "-ready.bam" for s in config["DNA_Samples"]],
        PoN=config["PoN"]["cnvkit"],
    output:
        regions=["CNV/cnvkit_calls/" + sample_id + "-ready.cnr" for sample_id in config["DNA_Samples"]],
        segments=["CNV/cnvkit_calls/" + sample_id + "-ready.cns" for sample_id in config["DNA_Samples"]],
    params:
        outdir="CNV/cnvkit_calls/",
    log:
        "logs/CNV_cnvkit/Call_cnv.log",
    threads: 8
    singularity:
        config["singularity"]["cnvkit"]
    shell:
        "(cnvkit.py batch {input.bams} -r {input.PoN} -p {threads} -d {params.outdir}) &> {log}"


rule Filter_cnv:
    input:
        segments=["CNV/cnvkit_calls/" + sample_id + "-ready.cns" for sample_id in config["DNA_Samples"]],
        purity="DATA/Pathological_purity_BMS_validation.txt",
        relevant_genes="DATA/TSO500_relevant_genes.txt",
        ONCOCNV_events="CNV/ONCOCNV_calls/cnv_event.txt",
        bed_file="CNV/bed/cnvkit_manifest.target.bed",
    output:
        #cnv_done="CNV/CNV_calls/cnv_done.txt",
        relevant_cnvs="CNV/CNV_calls/relevant_cnv.txt",
    params:
        raw_cnv="CNV/CNV_calls/cnv_raw_event.txt",
    log:
        "logs/CNV_cnvkit/Filter_cnv.log",
    singularity:
        config["singularity"]["python"]
    script:
        "../../../scripts/python/Filter_cnv.py"
