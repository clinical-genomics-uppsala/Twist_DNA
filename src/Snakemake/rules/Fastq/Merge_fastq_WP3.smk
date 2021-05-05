sample_list = [s.Index for s in samples.itertuples()]


rule merge_Fastq_sh:
    output:
        fastq1=["fastq_temp/" + s + "_R1.merge_fastq.sh" for s in sample_list],
        fastq2=["fastq_temp/" + s + "_R2.merge_fastq.sh" for s in sample_list],
    log:
        "logs/fastq/merge/merge_fastq_sh.log",
    params:
        DNA_samples=[s for s in sample_list],
    run:
        import subprocess

        # subprocess.call("mkdir fastq", shell=True)
        i = 0
        for sample in params.DNA_samples:
            bs = open("fastq_temp/" + sample + "_R1.merge_fastq.sh", "w")
            bs.write("zcat fastq_temp/" + sample + "_S*_L00*_R1_001.fastq.gz | pigz > fastq/" + sample + "_R1.fastq.gz\n")
            bs.close()
            subprocess.call("chmod 774 fastq_temp/" + sample + "_R1.merge_fastq.sh", shell=True)
            i += 1
        i = 0
        for sample in params.DNA_samples:
            bs = open("fastq_temp/" + sample + "_R2.merge_fastq.sh", "w")
            bs.write("zcat fastq_temp/" + sample + "_S*_L00*_R2_001.fastq.gz | pigz > fastq/" + sample + "_R2.fastq.gz\n")
            bs.close()
            subprocess.call("chmod 774 fastq_temp/" + sample + "_R2.merge_fastq.sh", shell=True)
            i += 1


rule merge_Fastq_run_R1:
    input:
        bash_scripts_DNA_R1="fastq_temp/{sample}_R1.merge_fastq.sh",
    output:
        merged_fastq_R1_DNA="fastq/{sample}_R1.fastq.gz",
    shell:
        "{input.bash_scripts_DNA_R1}"


rule merge_Fastq_run_R2:
    input:
        bash_scripts_DNA_R2="fastq_temp/{sample}_R2.merge_fastq.sh",
    output:
        merged_fastq_R2_DNA="fastq/{sample}_R2.fastq.gz",
    shell:
        "{input.bash_scripts_DNA_R2}"
