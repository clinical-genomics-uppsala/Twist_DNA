
import src.lib.python.utils as utils


_genefuse_input = "fastq/DNA/"
try:
    _genefuse_input = genefuse_input
except:
    pass


_genefuse_input_r1 = _genefuse_input + "/{sample}_R1.fastq.gz",
_genefuse_input_r2 = _genefuse_input + "/{sample}_R2.fastq.gz",

if "units" in config:
    import src.lib.python.utils as utils
    _genefuse_input_r1 = "fastq/DNA/{sample}_R1.genefuse.prep.fastq.gz"
    _genefuse_input_r2 = lambda wildcards: "fastq/DNA/{sample}_R2.genefuse.prep.fastq.gz"



rule prep_fastq_for_genefuse:
    input:
        lambda wildcards: ["fastq/DNA/" + wildcards.sample + "_" + unit +"_" + wildcards.read + ".fastq.gz" for unit in utils.get_units(units, wildcards.sample)]
    output:
        temp("fastq/DNA/{sample}_{read,[R12]+}.genefuse.prep.fastq.gz")
    params:
        num_units=lambda wildcards: utils.get_num_units(units, wildcards.sample)
    shell:
        """
            if [[ {params.num_units} -gt 1 ]]
            then
                zcat {input} | gzip > {output};
            else
                cp {input} {output};
            fi
        """


rule geneFuse:
    input:
        fastq1=_genefuse_input_r1,
        fastq2=_genefuse_input_r2,
    output:
        html="Results/DNA/{sample}/geneFuse/geneFuse_report_{sample}.html",
        fusions="Results/DNA/{sample}/geneFuse/fusions_{sample}.txt",
    params:
        genes=config["geneFuse"]["genes"],
        ref=config["reference"]["ref"],
    threads: 4
    log:
        "logs/DNA_fusion/geneFuse/{sample}.log",
    container:
        config["singularity"].get("geneFuse", config["singularity"].get("default", ""))
    shell:
        "(genefuse -r {params.ref} -f {params.genes} -1 {input.fastq1} -2 {input.fastq2} -h {output.html} > {output.fusions}) &> {log}"
