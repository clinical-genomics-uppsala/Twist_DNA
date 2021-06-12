
rule fetch_reference_genome:
    output:
        temp("reference/{build}/{genome}.fastq.gz")
    params:
        url=config['reference']['url'],
    shell:
        "wget {params.url} -o {output}"

rule extract_reference_genome:
    input:
        "reference/{build}/{genome}.fastq.gz",
    output:
        "reference/{build}/{genome}.fastq",
    shell:
        "gunzip -c {input} > {output}"

rule prep_bwa_index:
    input:
        "reference/{build}/{genome}.fastq",
    output:
        "reference/{build}/{genome}.amb",
        "reference/{build}/{genome}.ann",
        "reference/{build}/{genome}.bwt",
        "reference/{build}/{genome}.pac",
        "reference/{build}/{genome}.sa",
    params:
        prefix="{genome}",
        algorithm=config['reference'].get('algorithm','bwtsw'),
    container:
        config["singularity"].get("bwa", config["singularity"].get("default", ""))
    wrapper:
        "v0.75.0/bio/bwa/index"
