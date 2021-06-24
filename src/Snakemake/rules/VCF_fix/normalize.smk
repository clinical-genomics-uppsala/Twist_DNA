
rule decompose:  #Do we need decompose as well, maybe for all but vardict??
    input:
        vcf="{method}/{sample}.{method}.okAF.vcf.gz",
        tbi="{method}/{sample}.{method}.okAF.vcf.gz.tbi",
    output:
        temp("{method}/{sample}.{method}.decomposed.vcf.gz"),
    log:
        "logs/variantCalling/vt/{sample}.{method}.decomposed.log",
    container:
        config["singularity"].get("vt", config["singularity"].get("default", ""))
    shell:
        "(vt decompose -s {input.vcf} | vt decompose_blocksub -o {output} -) &> {log}"


rule normalizeAll:
    input:
        vcf="{method}/{sample}.{method}.decomposed.vcf.gz",
        ref=config["reference"]["ref"],
    output:
        "{method}/{sample}.{method}.normalized.vcf.gz",
    log:
        "logs/variantCalling/vt/{sample}.{method}.normalized.log",
    container:
        config["singularity"].get("vt", config["singularity"].get("default", ""))
    shell:
        "(vt normalize -n -r {input.ref} -o {output} {input.vcf} ) &> {log}"


# rule indexNormalize:
#    input:
#        vcf="{method}/{sample}.{method}.normalized.vcf.gz",
#    output:
#        tbi="{method}/{sample}.{method}.normalized.vcf.gz.tbi",
#    log:
#        "logs/variantCalling/vt/{sample}.{method}.index.log",
#    container:
#        config["singularity"].get("bcftools", config["singularity"].get("default", ""))
#    shell:
#        "(tabix {input.vcf}) 2> {log}"
