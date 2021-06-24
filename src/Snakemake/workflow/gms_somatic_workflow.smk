units = pd.read_table(config["units"], index_col=["sample", "unit"], dtype=str)
units.index = units.index.set_levels([i.astype(str) for i in units.index.levels])  # enforce str in index


def fastq_files(wildcards):
    return [v[0] for k, v in units.loc[wildcards.sample].items()]


mutect2_output_vcf = "mutect2/{sample}.mutect2.fixAF.vcf"


include: "../rules/Fastq/fix_fastq_DNA.smk"
include: "../rules/Alignment/index_bam.smk"
include: "../rules/Fastq/Fastp_trimming.smk"
include: "../rules/Alignment/bwa-mem.smk"


bam_split_input = _bwa_mem_output


include: "../rules/Alignment/bam-split.smk"
include: "../rules/Alignment/bam-merge.smk"
include: "../rules/SNV/mutect2.smk"
include: "../rules/SNV/vardict_T.smk"
include: "../rules/SNV/freebayes.smk"
include: "../rules/VCF_fix/fix_AF_all_callers.smk"
include: "../rules/VCF_fix/add_chr_to_header.smk"
include: "../rules/VCF_fix/Filter_VCF.smk"


ruleorder: mutect2 > compress > index
