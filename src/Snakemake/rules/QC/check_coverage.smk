

rule check_DNA_coverage:
    input:
        bam="Bam/DNA/{sample}-ready.bam",
        bai="Bam/DNA/{sample}-ready.bam.bai",
        vcf="Results/DNA/{sample}/vcf/{sample}.ensemble.vep.exon.soft_filter.multibp.vcf",
        bed=config["hotspot_combined"],
    output:
        coverage="Results/DNA/{sample}/QC/Low_coverage_positions.txt",
        coverage2="Results/DNA/{sample}/QC/All_coverage_positions.txt",
    log:
        "logs/qc/{sample}_check_DNA_coverage.log",
    container:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/check_coverage.py"
