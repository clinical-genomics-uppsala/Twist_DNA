
rule vep:
    input:
        vcf="recall/{sample}.ensemble.vcf.gz",
        cache=config["configfiles"]["vep"],
        fasta=config["reference"]["ref"],
    output:
        vcf=temp("recall/{sample}.ensemble.vep.vcf"),
    params:
        # "--everything --check_existing --pick"  #--exclude_null_alleles
        "--check_existing --pick --sift b --polyphen b --ccds --uniprot --hgvs --symbol --numbers --domains --regulatory --canonical --protein --biotype --uniprot --tsl --appris --gene_phenotype --af --af_1kg --af_gnomad --max_af --pubmed --variant_class ",
    log:
        "logs/variantCalling/vep/{sample}.log",
    singularity:
        config["singularity"]["vep"]
    threads: 10
    shell:
        "(vep --vcf --no_stats -o {output.vcf} -i {input.vcf} --dir_cache {input.cache} --fork {threads} --cache --refseq --offline --fasta {input.fasta} {params} ) &> {log}"


#rule bgzipVep:
#    input:
#        "recall/{sample}.ensemble.vep.vcf",
#    output:
#        "recall/{sample}.ensemble.vep.vcf.gz",
#        "recall/{sample}.ensemble.vep.vcf.gz.tbi",
#    log:
#        "logs/recall/vep/{sample}.bgzip.log",
#    singularity:
#        config["singularity"].get("bcftools", config["singularity"].get("default", ""))
#    shell:
#        "(bgzip {input} && tabix {input}.gz) &> {log}"
