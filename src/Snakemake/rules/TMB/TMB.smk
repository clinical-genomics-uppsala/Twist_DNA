
rule TMB:
    input:
        vcf="Results/DNA/{sample}/vcf/{sample}.ensemble.vep.exon.soft_filter.multibp.vcf",
        artifacts=config["TMB"]["Artifacts"],
        #background_panel="DATA/background_panel.tsv",
        background_panel=config["Background"]["background_panel"],
        background_run="DATA/background_run.tsv",
        gvcf="mutect2/{sample}.mutect2.gvcf.gz",
    output:
        tmb="Results/DNA/{sample}/TMB/{sample}.TMB.txt",
    container:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/TMB.py"
