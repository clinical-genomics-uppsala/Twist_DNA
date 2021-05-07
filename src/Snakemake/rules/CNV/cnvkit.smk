
rule Create_targets:
    input:
        bed=config["bed"]["bedfile"],
    output:
        bed="CNV/bed/cnvkit_manifest.target.bed",
    log:
        "logs/CNV_cnvkit/Create_targets.log",
    singularity:
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
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
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
    shell:
        "(cnvkit.py antitarget {input.bed} -o {output.bed}) &> {log}"


rule Call_cnv:
    input:
        bams=["Bam/DNA/" + s.Index + "-ready.bam" for s in samples.itertuples()],
        PoN=config["PoN"]["cnvkit"],
    output:
        regions=["CNV/cnvkit_calls/" + sample_id.Index + "-ready.cnr" for sample_id in samples.itertuples()],
        segments=["CNV/cnvkit_calls/" + sample_id.Index + "-ready.cns" for sample_id in samples.itertuples()],
    params:
        outdir="CNV/cnvkit_calls/",
        extra=config.get("cnvkit",{}).get("extra",""),
    log:
        "logs/CNV_cnvkit/Call_cnv.log",
    threads: 8
    singularity:
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
    shell:
        "(cnvkit.py batch {input.bams} {params.extra} -r {input.PoN} -p {threads} -d {params.outdir}) &> {log}"


rule Filter_cnv:
    input:
        cnvkit_segments=["CNV/cnvkit_calls/" + sample_id.Index + "-ready.cns" for sample_id in samples.itertuples()],
        GATK_CNV_segments=["CNV/CNV_GATK/" + sample_id.Index + "_clean.modelFinal.seg" for sample_id in samples.itertuples()],
        relevant_genes=config["cnvkit"]["relevant_genes"],
        bed_file="CNV/bed/cnvkit_manifest.target.bed",
    output:
        relevant_cnvs="Results/DNA/CNV/Reported_cnvs.txt",
    params:
        purity=[sample.Index + ";" + str(sample.TC) for sample in samples.itertuples()],
        in_path="CNV/cnvkit_calls/",
        out_path="Results/DNA/CNV/",
    log:
        "logs/CNV_cnvkit/Filter_cnv.log",
    # singularity:
    #    config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/Filter_cnv.py"
