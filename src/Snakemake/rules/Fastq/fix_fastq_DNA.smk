
_fix_fastq_dna_input = "fastq_temp/DNA/"

try:
    _fix_fastq_dna_input = fix_fastq_dna_input
except:
    pass

_fix_fastq_dna_output = "fastq_temp/DNA/"

try:
    _fix_fastq_dna_output = fix_fastq_dna_output
except:
    pass

sample_number = dict(zip(samples.itertuples(), range(1,len(samples.itertuples()) + 1))

_fix_fastq_run_dna_input = lambda wildcards: _fix_fastq_dna_input + "/" + wildcards.sample + "_" + str(sample_number[wildcards.sample]) + "_" + wildcards.read + "_001.fastq.gz"
_fix_fastq_run_dna_output = "fastq_temp/DNA/{sample}_R2.fastq.gz"
if "units" in config:
    _fix_fastq_run_dna_input = lambda wildcards: utils.get_fastq_file(units, wildcards.sample, wildcars.unit, "fq1") if wildcards.read == "read1" else utils.get_fastq_file(units, wildcards.sample, wildcars.unit, "fq2")
    _fix_fastq_run_dna_output = "fastq_temp/DNA/{sample}_{unit}_{re}.fastq.gz"


rule fix_fastq_run_DNA_R2:
    input:
        fastq=_fix_fastq_run_dna_input,
    output:
        fastq=_fix_fastq_run_dna_output,
    shell:
        "zcat {input.fastq} | awk '{if(/^@/){split(\$0,a,\\\":\\\");gsub(\\\"+\\\",\\\"-\\\",a[8]);print(a[1]\\\":\\\"a[2]\\\":\\\"a[3]\\\":\\\"a[4]\\\":\\\"a[5]\\\":\\\"a[6]\\\":\\\"a[7]\\\":UMI_\\\"a[8]\\\":\\\"a[9]\\\":\\\"a[10]\\\":\\\"a[11])}else{print(\$0)}}' | gzip > {output.fastq}"
