
include: "../rules/Fastq/Merge_fastq_WP3.smk"


bwa_mem_input = ["fastq/{sample}_R1.fastq.gz", "fastq/{sample}_R2.fastq.gz"]


include: "../rules/Alignment/bwa-mem.smk"
include: "../rules/Alignment/index_bam.smk"
# Bcbio reports variants not included in the bed file
include: "../rules/SNV/Haplotypecaller_WP3.smk"
# Only annotate with rs_number?
include: "../rules/VCF_fix/VEP_WP3.smk"
include: "../rules/VCF_fix/Filter_vcf_WP3.smk"
# Only sex check
include: "../rules/QC/sex_and_pedegree_WP3.smk"
