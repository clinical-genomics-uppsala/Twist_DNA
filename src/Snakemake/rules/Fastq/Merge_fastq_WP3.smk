

# fastq1_files = ["fastq_temp/" + s + "_" + i + "_L00" + L + "_R1_001.fastq.gz" for s, i, L in zip(config["DNA_Samples"], S_dna, L_numbers)]
# fastq2_files = ["fastq_temp/" + s + "_" + i + "_L00" + L + "_R2_001.fastq.gz" for s, i, L in zip(config["DNA_Samples"], S_dna, L_numbers)]


rule merge_Fastq:
    output:
        fastq1="fastq/{sample}_R1.fastq.gz",
        fastq2="fastq/{sample}_R2.fastq.gz",
    log:
        "logs/fastq/merge/{sample}.log",
    params:
        DNA_samples=[s for s in config["DNA_Samples"]],
    run:
        import subprocess

        #subprocess.call("mkdir fastq", shell=True)
        i = 0
        for sample in params.DNA_samples:
            bs = open("fastq_temp/" + sample + "_R1.fix_fastq.sh", "w")
            bs.write("zcat fastq_temp/" + sample + "_S*_L00*_R1.fastq.gz | pigz > " + output.fastq1 + "\n")
            bs.close()
            subprocess.call("chmod 774 fastq_temp/DNA/" + sample + "_R1.fix_fastq.sh", shell=True)
            i += 1
        i = 0
        for sample in params.DNA_samples:
            bs = open("fastq_temp/" + sample + "_R2.fix_fastq.sh", "w")
            bs.write("zcat fastq_temp/" + sample + "_S*_L00*_R2.fastq.gz | pigz > " + output.fastq1 + "\n")
            bs.close()
            subprocess.call("chmod 774 fastq_temp/DNA/" + sample + "_R2.fix_fastq.sh", shell=True)
            i += 1


rule fix_fastq_run_DNA_R1:
    input:
        bash_scripts_DNA_R1="fastq_temp/{sample}_R1.fix_fastq.sh",
    output:
        merged_fastq_R1_DNA="fastq_temp/{sample}_R1.fastq.gz",
    shell:
        "{input.bash_scripts_DNA_R1}"


rule fix_fastq_run_DNA_R2:
    input:
        bash_scripts_DNA_R2="fastq_temp/{sample}_R2.fix_fastq.sh",
    output:
        merged_fastq_R2_DNA="fastq_temp/{sample}_R2.fastq.gz",
    shell:
        "{input.bash_scripts_DNA_R2}"