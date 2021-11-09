rule compress_and_index:
    input:
        vcf="{path}/{vcf_file}.vcf",
    output:
        vcf="{path}/{vcf_file,[^/]+}.vcf.gz",
        tbi="{path}/{vcf_file,[^/]+}.vcf.gz.tbi",
    container:
        config["singularity"].get("default", "")
    shell:
        "bgzip {input.vcf} && tabix {output.vcf}"


rule intron_filter:
    input:
        vcf="recall/{sample}.ensemble.vep.vcf.gz",
        bed=config["bed"]["bedfile"],
    output:
        vcf=temp("recall/{sample}.ensemble.vep.exon.vcf"),
    container:
        config["singularity"].get("python_htslib", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/filter_introns.py"


rule Soft_filter:
    input:
        vcf="recall/{sample}.ensemble.vep.exon.vcf.gz",
    output:
        vcf=temp("recall/{sample}.ensemble.vep.exon.soft_filter1.vcf"),
    params:
        filter="-e 'FORMAT/AD<20 || FORMAT/DP<50 || FORMAT/AF<0.05'",
    container:
        config["singularity"].get("bcftools", config["singularity"].get("default", ""))
    shell:
        "bcftools filter -O v -o {output.vcf} --soft-filter 'Soft_filter' {params.filter} -m '+' {input.vcf}"


rule Soft_artifact_filter:
    input:
        vcf="recall/{sample}.ensemble.vep.exon.soft_filter1.vcf",
    output:
        vcf=temp("recall/{sample}.ensemble.vep.exon.soft_filter2.vcf"),
    params:
        artifacts=config["TMB"]["Artifacts"],
    container:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/Soft_artifact_filter.py"


rule Soft_background_filter:
    input:
        vcf="recall/{sample}.ensemble.vep.exon.soft_filter2.vcf",
    output:
        vcf="recall/{sample}.ensemble.vep.exon.soft_filter.vcf",
    params:
        background_panel=config["Background"]["background_panel"],
    container:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/Soft_background_filter.py"


rule ffpe_filter:
    input:
        vcf="recall/{sample}.ensemble.vep.exon.soft_filter.vcf",
        bam="Bam/DNA/{sample}-ready.bam",
        bai="Bam/DNA/{sample}-ready.bam.bai",
    output:
        vcf=temp("Results/DNA/{sample}/vcf/{sample}.ensemble.vep.exon.soft_filter.ffpe.temp.vcf"),
    params:
        java=config["java"]["SOBDetector"],
    container:
        config["singularity"].get("default", "")
    shell:
        #"module load oracle-jdk-1.8/1.8.0_162 && "
        """
        java -jar {params.java} --input-type VCF --input-variants {input.vcf} --input-bam {input.bam} --output-variants {output.vcf}
        """


rule annotate_vcf_with_ffpe:
    input:
        vcf_ffpe="Results/DNA/{sample}/vcf/{sample}.ensemble.vep.exon.soft_filter.ffpe.temp.vcf",
    output:
        vcf_ffpe=temp("Results/DNA/{sample}/vcf/{sample}.ensemble.vep.exon.soft_filter.ffpe.vcf"),
    script:
        "../../../scripts/python/Add_FFPE_column_to_vcf.py"


rule copy_vcf_to_result:
    input:
        "recall/{sample}.{modifications}",
    output:
        "Results/DNA/{sample}/vcf/{sample}.{modifications}",
    shell:
        """
        cp {input} {output}
        """
