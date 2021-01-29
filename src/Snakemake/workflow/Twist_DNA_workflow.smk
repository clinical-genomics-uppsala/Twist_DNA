
include: "../rules/Alignment/index_bam.smk"
include: "../rules/Fastq/demultiplex.smk"
include: "../rules/Fastq/fix_fastq_DNA.smk"


if config["programs"]["Trimming"] == "Cutadapt":

    include: "../rules/Fastq/Cutadapt_trimming.smk"


elif config["programs"]["Trimming"] == "Fastp":

    include: "../rules/Fastq/Fastp_trimming.smk"


else:

    include: "../rules/Fastq/move_fastq.smk"


include: "../rules/CNV/ONCOCNV.smk"
include: "../rules/CNV/cnvkit.smk"
include: "../rules/CNV/GATK_CNV.smk"


# include: "../rules/QC/check_coverage.smk"
# include: "../rules/VCF_fix/Collect_results_DNA.smk" #Change folder!
# include: "../rules/Mutect2/Mutect2.smk"


if config["programs"]["Duplicates"] == "fgbio":

    include: "../rules/Alignment/fgbio.smk"


else:
    if config["programs"]["markduplicate"] == "GPU":

        include: "../rules/Alignment/GPU_alignment.smk"


    else:

        bwa_mem_output = "bam/{sample}-sort.bam"

        include: "../rules/Alignment/bwa-mem.smk"
        include: "../rules/Alignment/MarkDuplicates.smk"


bam_split_input = "DNA_bam/{sample}-ready.bam"


include: "../rules/Alignment/bam-split.smk"
include: "../rules/SNV/freebayes.smk"
include: "../rules/SNV/mutect2.smk"
include: "../rules/SNV/vardict_T.smk"
include: "../rules/SNV/varscan.smk"
include: "../rules/VCF_fix/fix_AF_all_callers.smk"
include: "../rules/VCF_fix/normalize.smk"
include: "../rules/VCF_fix/recall.smk"
include: "../rules/VCF_fix/VEP.smk"
include: "../rules/MSI/msisensor2.smk"
include: "../rules/DNA_fusion/gridss.smk"
include: "../rules/QC/samtools-picard-stats.smk"
include: "../rules/QC/multiqc.smk"
# include: "../rules/QC/cartool.smk"
include: "../rules/QC/fastqc.smk"
