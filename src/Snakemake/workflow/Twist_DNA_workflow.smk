if "units" in config:
    units = pd.read_table(config["units"], index_col=["sample", "unit"], dtype=str)
    units.index = units.index.set_levels([i.astype(str) for i in units.index.levels])  # enforce str in index

include: "../rules/Alignment/index_bam.smk"


demultiplex_output = "fastq_temp"


include: "../rules/Fastq/demultiplex.smk"
include: "../rules/Fastq/fix_fastq_DNA.smk"


if config["programs"]["Trimming"] == "Cutadapt":

    include: "../rules/Fastq/Cutadapt_trimming.smk"


elif config["programs"]["Trimming"] == "Fastp":

    include: "../rules/Fastq/Fastp_trimming.smk"


else:

    include: "../rules/Fastq/move_fastq.smk"
# include: "../rules/CNV/ONCOCNV.smk"
include: "../rules/CNV/cnvkit.smk"
include: "../rules/CNV/GATK_CNV.smk"


# include: "../rules/QC/check_coverage.smk"
# include: "../rules/VCF_fix/Collect_results_DNA.smk" #Change folder!
# include: "../rules/Mutect2/Mutect2.smk"

if config["programs"]["Duplicates"] == "fgbio":

    bam_split_input = "Bam/DNA/{sample}-ready.bam"

    include: "../rules/Alignment/fgbio.smk"


else:
    if config["programs"]["markduplicate"] == "GPU":

        include: "../rules/Alignment/GPU_alignment.smk"


    elif config["programs"]["markduplicate"] == "picard":

        bam_split_input = "alignment/{sample}.sort.bam"
        markduplicates_input = "alignment/{sample}.{chr}.bam"
        markduplicates_output = "alignment/{sample}.dedup.{chr}.bam"
        bam_merge_input = "alignment/{sample}.dedup.__CHR__.bam"
        bam_merge_output = "Bam/DNA/{sample}-ready.bam"
        mutect_input = "alignment/{sample}.dedup.{chr}.bam"
        freebayes_input = "alignment/{sample}.dedup.{chr}.bam"
        vardict_input = "alignment/{sample}.dedup.{chr}.bam"

        include: "../rules/Alignment/bwa-mem.smk"
        include: "../rules/Alignment/MarkDuplicates.smk"


    elif config["programs"]["markduplicate"] == "picard_UMI":

        bwa_mem_output = "alignment/{sample}.sort.noUMI.bam"
        bam_split_input = "alignment/{sample}.sort.bam"
        markduplicates_input = "alignment/{sample}.{chr}.bam"
        markduplicates_output = "alignment/{sample}.dedup.{chr}.bam"
        bam_merge_input = "alignment/{sample}.dedup.__CHR__.bam"
        bam_merge_output = "Bam/DNA/{sample}-ready.bam"
        mutect_input = "alignment/{sample}.dedup.{chr}.bam"
        freebayes_input = "alignment/{sample}.dedup.{chr}.bam"
        vardict_input = "alignment/{sample}.dedup.{chr}.bam"

        include: "../rules/Alignment/bwa-mem.smk"
        include: "../rules/Alignment/MarkDuplicatesUMI.smk"



include: "../rules/Alignment/bam-split.smk"
include: "../rules/Alignment/bam-merge.smk"
include: "../rules/SNV/freebayes.smk"
include: "../rules/SNV/mutect2.smk"
include: "../rules/SNV/vardict_T.smk"
include: "../rules/SNV/varscan.smk"
include: "../rules/VCF_fix/fix_AF_all_callers.smk"
include: "../rules/VCF_fix/normalize.smk"
include: "../rules/VCF_fix/recall.smk"
include: "../rules/VCF_fix/add_chr_to_header.smk"
include: "../rules/VCF_fix/VEP.smk"
include: "../rules/VCF_fix/Filter_VCF.smk"
include: "../rules/VCF_fix/Multibp_SNV.smk"
include: "../rules/MSI/msisensor2.smk"
# include: "../rules/MSI/msisensor-pro.smk"
include: "../rules/QC/picard.smk"
include: "../rules/QC/samtools.smk"
include: "../rules/QC/QC_stats.smk"
include: "../rules/QC/multiqc.smk"
# include: "../rules/QC/cartool.smk"
include: "../rules/QC/fastqc.smk"
include: "../rules/QC/check_coverage.smk"
include: "../rules/DNA_fusion/geneFuse.smk"
