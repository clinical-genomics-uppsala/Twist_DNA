
rule fetch_reference_genome:
    output:
        "reference/{species}/{assembly}/{genome}.fa",
        "reference/{species}/{assembly}/{genome}.fa.fai",
        "reference/{species}/{assembly}/{genome}.dict"
    params:
        region=config['reference']['region'],
        url=config['reference']['url'],
        output="reference/{species}/{assembly}/"
    log:
        "logs/wget/{species}-{genome}-{assembly}.fasta.gz.log"
    container:
        config["singularity"].get("aws", config["singularity"].get("default", ""))
    shell:
        """
        aws s3 --no-sign-request --region {params.region} sync {params.url} {params.output}
        """

rule genome_fai_link:
    input:
        "reference/{species}/{assembly}/{genome}.fa.fai",
    output:
        "reference/{species}/{assembly}/{genome}.fai",
    params:
        dir="reference/{species}/{assembly}",
        genome="{genome}",
    shell:
        """
            cd {params.dir} && ln -s {params.genome}.fa.fai {params.genome}.fai
        """

rule prep_bwa_index:
    input:
        "reference/{species}/{assembly}/{genome}.fa",
    output:
        "reference/{species}/{assembly}/{genome}.amb",
        "reference/{species}/{assembly}/{genome}.ann",
        "reference/{species}/{assembly}/{genome}.bwt",
        "reference/{species}/{assembly}/{genome}.pac",
        "reference/{species}/{assembly}/{genome}.sa",
    params:
        prefix="reference/{species}/{assembly}/{genome}",
        algorithm=config['reference'].get('algorithm','bwtsw'),
    container:
        config["singularity"].get("bwa", config["singularity"].get("default", ""))
    wrapper:
        "v0.75.0/bio/bwa/index"

rule genome_amb_link:
    input:
        "reference/{species}/{assembly}/{genome}.amb",
    output:
        "reference/{species}/{assembly}/{genome}.fa.amb",
    params:
        dir="reference/{species}/{assembly}",
        genome="{genome}",
    shell:
        """
            cd {params.dir} && ln -s {params.genome}.amb {params.genome}.fa.amb
        """

rule genome_ann_link:
    input:
        "reference/{species}/{assembly}/{genome}.ann",
    output:
        "reference/{species}/{assembly}/{genome}.fa.ann",
    params:
        dir="reference/{species}/{assembly}",
        genome="{genome}",
    shell:
        """
            cd {params.dir} && ln -s {params.genome}.ann {params.genome}.fa.ann
        """

rule genome_bwt_link:
    input:
        "reference/{species}/{assembly}/{genome}.bwt",
    output:
        "reference/{species}/{assembly}/{genome}.fa.bwt",
    params:
        dir="reference/{species}/{assembly}",
        genome="{genome}",
    shell:
        """
            cd {params.dir} && ln -s {params.genome}.bwt {params.genome}.fa.bwt
        """

rule genome_pac_link:
    input:
        "reference/{species}/{assembly}/{genome}.pac",
    output:
        "reference/{species}/{assembly}/{genome}.fa.pac",
    params:
        dir="reference/{species}/{assembly}",
        genome="{genome}",
    shell:
        """
            cd {params.dir} && ln -s {params.genome}.pac {params.genome}.fa.pac
        """

rule genome_ann_link:
    input:
        "reference/{species}/{assembly}/{genome}.sa",
    output:
        "reference/{species}/{assembly}/{genome}.fa.sa",
    params:
        dir="reference/{species}/{assembly}",
        genome="{genome}",
    shell:
        """
            cd {params.dir} && ln -s {params.genome}.sa {params.genome}.fa.sa
        """
