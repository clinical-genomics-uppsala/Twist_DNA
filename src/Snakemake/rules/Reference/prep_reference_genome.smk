
rule fetch_reference_genome:
    output:
        temp("reference/{build}/{genome}.fasta.gz")
    params:
        url=config['reference']['url'],
    log:
        "logs/wget/{genome}-{build}.fasta.gz.log"
    shell:
        "wget {params.url} -O {output} &> {log}"

rule extract_reference_genome:
    input:
        "reference/{build}/{genome}.fasta.gz",
    output:
        "reference/{build}/{genome}.fasta",
    shell:
        "gunzip -c {input} > {output}"

rule create_dict:
    input:
        "reference/{build}/{genome}.fasta
    output:
        "reference/{build}/{genome}.dict"
    log:
        "logs/picard/{build}.{genome}.create_dict.log"
    params:
        extra=""
    resources:
        mem_mb=1024
    container:
        config["singularity"].get("picard", config["singularity"].get("default", ""))
    wrapper:
        "v0.75.0/bio/picard/createsequencedictionary"

rule genome_fai:
    input:
        "reference/{build}/{genome}.fasta",
    output:
        "reference/{build}/{genome}.fastq.fai",
    container:
        config["singularity"].get("samtools", config["singularity"].get("default", ""))
    wrapper:
        "v0.75.0/bio/samtools/faidx"

rule genome_fai_link:
    input:
        "reference/{build}/{genome}.fasta.fai",
    output:
        "reference/{build}/{genome}.fai",
    params:
        dir=lambda wildcards: "reference/" + wildcards.build,
        genome=lambda wildcards: wildcards.genome,
    shell:
        """
            cd {params.dir} && ln -s {params.genome}.fasta.fai {params.genome}.fai
        """

rule prep_bwa_index:
    input:
        "reference/{build}/{genome}.fasta",
    output:
        "reference/{build}/{genome}.amb",
        "reference/{build}/{genome}.ann",
        "reference/{build}/{genome}.bwt",
        "reference/{build}/{genome}.pac",
        "reference/{build}/{genome}.sa",
    params:
        prefix="reference/{build}/{genome}",
        algorithm=config['reference'].get('algorithm','bwtsw'),
    container:
        config["singularity"].get("bwa", config["singularity"].get("default", ""))
    wrapper:
        "v0.75.0/bio/bwa/index"
