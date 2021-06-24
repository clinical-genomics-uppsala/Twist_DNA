
rule HRD_score:
    input:
        segment="CNV/cnvkit_calls/{sample}-LoH.cns",
    output:
        HRD="Results/DNA/{sample}/HRD/HRD_score.txt",
    log:
        "logs/HRD/HRD_score_{sample}.log",
    container:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/HRD_score.py"
