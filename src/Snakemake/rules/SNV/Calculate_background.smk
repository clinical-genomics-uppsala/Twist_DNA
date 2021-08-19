

rule Calculate_background_panel:
    input:
        # gvcfs="DATA/gvcf_files.txt",
        gvcfs=config["Background"]["mutect2_gvcfs"],
    output:
        background="DATA/background_panel.tsv",
    params:
        type="panel",
    container:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/Calculate_background.py"


rule Calculate_background_run:
    input:
        gvcfs=["mutect2/" + sample.Index + ".mutect2.gvcf.gz" for sample in samples.itertuples()],
    output:
        background="DATA/background_run.tsv",
    params:
        type="run",
    container:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/Calculate_background.py"