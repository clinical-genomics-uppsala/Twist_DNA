
rule Find_multibp_SNV:
    input:
        vcf="recall/{sample}.ensemble.vep.exon.soft_filter.vcf",
        ref=config["reference"]["ref"],
    output:
        vcf=temp("recall/{sample}.ensemble.vep.exon.soft_filter.multibp.vcf.temp"),
    singularity:
        config["singularity"].get("python_samtools", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/Multibp_SNV.py"


_sort_input = "recall/{sample}.ensemble.vep.exon.soft_filter.multibp.vcf.temp"
try:
    _sort_input = sort_input
except:
    pass

_sort_output = "recall/{sample}.ensemble.vep.exon.soft_filter.multibp.vcf"
try:
    _sort_output = sort_output
except:
    pass


rule sort_multiplebp_vcf:
    input:
        vcf=_sort_input,
    output:
        vcf=_sort_output,
    singularity:
        config["singularity"].get("bcftools", config["singularity"].get("default", ""))
    wrapper:
        "0.72.0/bio/bcftools/sort"
