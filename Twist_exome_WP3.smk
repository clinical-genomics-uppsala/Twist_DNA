
#snakemake -p -j 120 --drmaa "-A wp1 -p core -n {cluster.n} -t {cluster.time}"  -s ./Twist_exome_WP3.smk --use-singularity --singularity-args "--bind /data --bind /projects --bind /scratch " --cluster-config Config/Slurm/cluster.json

configfile: "Twist_exome_WP3.yaml"

wildcard_constraints:
    unit="[A-Za-z0-9-]+",
    sample="[^.]+",

sample_list = [s.Index  for s in samples.itertuples()]

def get_input():
    input_list = []
    '''Fastq'''
    input_list.append(["fastq/" + s + "_R1.fastq.gz" for s in sample_list])
    input_list.append(["fastq/" + s + "_R2.fastq.gz" for s in sample_list])

    '''Alignment'''
    input_list.append(["alignment/" + s + ".bam" for s in sample_list])
    input_list.append(["alignment/" + s + ".bam.bai" for s in sample_list])

    '''SNV / INDEL'''
    input_list.append(["haplotypecaller/" + s + ".vcf.gz" for s in sample_list])
    input_list.append(["haplotypecaller/" + s + ".vep.vcf.gz" for s in sample_list])
    input_list.append(["haplotypecaller/" + s + ".vep.filteredSNP.filteredINDEL.vcf.gz" for s in sample_list])
    input_list.append(["haplotypecaller/" + s + ".vep.filteredSNP.filteredINDEL.filteredAF.Cartagenia.vcf" for s in sample_list])
    input_list.append(["haplotypecaller/" + s + ".vep.filteredSNP.filteredINDEL.filteredAF.Cartagenia.noHLA.vcf" for s in sample_list])
    input_list.append(["haplotypecaller/" + s + ".vep.filteredSNP.filteredINDEL.filteredAF.Cartagenia.noHLA.chrX.vcf" for s in sample_list])
    input_list.append(["haplotypecaller/" + s + ".vep.filteredSNP.filteredINDEL.filteredAF.Cartagenia.noHLA.chrX.vcfstats.vcf" for s in sample_list])

    '''QC'''
    input_list.append(["results/sex." + s + ".txt" for s in sample_list])

    return input_list

rule all:
    input:
        get_input()


include: "src/Snakemake/workflow/Twist_exome_WP3_workflow.smk"
