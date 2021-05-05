# rule fastqc_bam:
#     input:
#         #"fastq/{sample}_R1-fastq.gz" ##one for each R1 and one for R2 should be from a samples.yaml file
#         #"Bam/DNA/{sample}-ready.bam"
#         #"bam/{sample}-sort.bam"
#         bam = "STAR2/{sample}Aligned.sortedByCoord.out.bam"
#     output:
#         html="qc/{sample}/{sample}Aligned.sortedByCoord.out_fastqc.html",
#         zip="qc/{sample}/{sample}Aligned.sortedByCoord.out_fastqc.zip" # the suffix _fastqc.zip is necessary for multiqc to find the file. If not using multiqc, you are free to choose an arbitrary filename
#     params:
#         outdir = "qc/{sample}/"
#     log:
#         "logs/qc/fastqc/{sample}Aligned.sortedByCoord.log"
#     threads: 10
#     singularity:
#         config["singularity"]["fastqc"]
#     shell:
#         "(fastqc --quiet -t {threads} --outdir {params.outdir} {input}) &> {log}"
#     # wrapper:
#     #     "0.38.0/bio/fastqc"


import src.lib.python.utils as utils


_fastqc_input = "fastq/DNA/"
try:
    _fastqc_input = fastqc_input
except:
    pass


_fastqc_input_r1 = _fastqc_input + "{sample}_R1.fastq.gz"
_fastqc_input_r2 = _fastqc_input + "{sample}_R2.fastq.gz"

if "units" in config:
    import src.lib.python.utils as utils

    _fastqc_input_r1 = lambda wildcards: "fastq/DNA/" + wildcards.sample + "_R1.fastq.gz"
    _fastqc_input_r2 = lambda wildcards: "fastq/DNA/" + wildcards.sample + "_R2.fastq.gz"


rule fastqc_prep_fastq:
    input:
        lambda wildcards: [
            "fastq/DNA/" + wildcards.sample + "_" + unit + "_" + wildcards.read + ".fastq.gz"
            for unit in utils.get_units(units, wildcards.sample)
        ],
    output:
        temp("fastq/DNA/{sample}_{read,[R12]+}.fastq.gz"),
    params:
        num_units=lambda wildcards: utils.get_num_units(units, wildcards.sample),
    shell:
        """
        if [[ {params.num_units} -gt 1 ]]
        then
            zcat {input} | gzip > {output}
        else
            cp {input} {output}
        fi
        """


rule fastqcR1:
    input:
        _fastqc_input_r1,  ##one for each R1 and one for R2 should be from a samples.yaml file
    output:
        html="qc/{sample}/{sample}_R1_fastqc.html",
        zip="qc/{sample}/{sample}_R1_fastqc.zip",  # the suffix _fastqc.zip is necessary for multiqc to find the file. If not using multiqc, you are free to choose an arbitrary filename
    params:
        outdir="qc/{sample}/",
        tmp="qc/",
    log:
        "logs/qc/fastqc/{sample}_R1.log",
    threads: 10
    container:
        config["singularity"].get("fastqc", config["singularity"].get("default", ""))
    # wrapper:
    #    "0.38.0/bio/fastqc"
    shell:
        "(fastqc --quiet -t {threads} -d {params.tmp} --outdir {params.outdir} {input}) &> {log}"


rule fastqcR2:
    input:
        _fastqc_input_r2,  ##one for each R1 and one for R2 should be from a samples.yaml file
    output:
        html="qc/{sample}/{sample}_R2_fastqc.html",
        zip="qc/{sample}/{sample}_R2_fastqc.zip",  # the suffix _fastqc.zip is necessary for multiqc to find the file. If not using multiqc, you are free to choose an arbitrary filename
    params:
        outdir="qc/{sample}/",
        tmp="qc/",
    log:
        "logs/qc/fastqc/{sample}_R2.log",
    threads: 10
    container:
        config["singularity"].get("fastqc", config["singularity"].get("default", ""))
    # wrapper:
    #    "0.38.0/bio/fastqc"
    shell:
        "(fastqc --quiet -t {threads} -d {params.tmp} --outdir {params.outdir} {input}) &> {log}"
