# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

__author__ = "Jonas Almlöf, Patrik Smeds"
__copyright__ = "Copyright 2021, Patrik Smeds, Jonas Almlöf"
__email__ = "jonas.almlöf@scilifelab.uu.se, patrik.smeds@scilifelab.uu.se"
__license__ = "GPL3"

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

sample_list = [s.Index for s in samples.itertuples()]
sample_number = dict(zip(sample_list, range(1, len(sample_list) + 1)))

_fix_fastq_run_dna_input = (
    lambda wildcards: _fix_fastq_dna_input
    + "/"
    + wildcards.sample
    + "_"
    + str(sample_number[wildcards.sample])
    + "_"
    + wildcards.read
    + "_001.fastq.gz"
)
_fix_fastq_run_dna_output = "fastq_temp/DNA/{sample}_R2.fastq.gz"
if "units" in config:
    _fix_fastq_run_dna_input = lambda wildcards: utils.get_fastq_file(
        units, wildcards.sample, wildcards.unit, "fq1" if wildcards.read == "R1" else "fq2"
    )
    _fix_fastq_run_dna_output = "fastq_temp/DNA/{sample}_{unit}_{read}.fastq.gz"


rule fix_fastq_run_dn:
    input:
        fastq=_fix_fastq_run_dna_input,
    output:
        fastq=_fix_fastq_run_dna_output,
    shell:
        """
        zcat {input.fastq} | awk '{{if(/^@/){{split($0,a,":");gsub("+","-",a[8]);print(a[1]":"a[2]":"a[3]":"a[4]":"a[5]":"a[6]":"a[7]":UMI_"a[8]":"a[9]":"a[10]":"a[11])}}else{{print($0)}}}}' | gzip > {output.fastq}
        """
