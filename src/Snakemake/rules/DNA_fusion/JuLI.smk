

rule JuLI_call:
    input:
        bam="Bam/DNA/{sample}-ready.bam",
        bai="Bam/DNA/{sample}-ready.bam.bai",
    output:
        fusions="Results/DNA/{sample}/Fusions/JuLI/{sample}.txt",
    params:
        ref=config["reference"]["ref"],
        Refgene="/references_JuLI/references/refGene_hg19.txt",
        Gap="/references_JuLI/references/gap_hg19.txt",
        OutputPath="Results/DNA/{sample}/Fusions/JuLI",
        sample_name=lambda wildcards: wildcards.sample,
        MinMappingQuality='20',
    threads: 10
    log:
        "logs/DNA_fusion/JuLI_call/{sample}.log",
    container:
        config["singularity"].get("JuLI", config["singularity"].get("default", ""))
    shell:
        "(Rscript -e '"
        "library(juliv0.1.6.1); "
        "callfusion(CaseBam=\"{input.bam}\", "
        "TestID=\"{params.sample_name}\", "
        "OutputPath=\"{params.OutputPath}\", "
        "MinMappingQuality=\"{params.MinMappingQuality}\", "
        "Thread=\"{threads}\", "
        "Refgene=\"{params.Refgene}\", "
        "Gap=\"{params.Gap}\", "
        "Reference=\"{params.ref}\")')  &> {log}"


rule JuLI_filter_druggable:
    input:
        fusions="Results/DNA/{sample}/Fusions/JuLI/{sample}.txt",
        genes="DATA/druggable.hg19.csv",
    output:
        fusions="Results/DNA/{sample}/Fusions/JuLI/{sample}.filtered.txt",
    container:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/JuLI_filter.py"


rule JuLI_annotate:
    input:
        fusions="Results/DNA/{sample}/Fusions/JuLI/{sample}.filtered.txt",
    output:
        fusions="Results/DNA/{sample}/Fusions/JuLI/{sample}.filtered.annotated.txt",
    params:
        ref=config["reference"]["ref"],
        Refgene="/references_JuLI/references/refGene_hg19.txt",
        Cosmic="/references_JuLI/references/CosmicFusionExport_V76.tsv",
        Pfam="/references_JuLI/references/Pfam-A.full.human",
        Uniprot="/references_JuLI/references/HGNC_GeneName_UniProtID_160524.txt",
    log:
        "logs/DNA_fusion/JuLI_annotate/{sample}.log",
    container:
        config["singularity"].get("JuLI", config["singularity"].get("default", ""))
    shell:
        "(Rscript -e '"
        "library(juliv0.1.6.1); "
        "annofusion(Output=\"{input.fusions}\", "
        "Refgene=\"{params.Refgene}\", "
        "Cosmic=\"{params.Cosmic}\", "
        "Pfam=\"{params.Pfam}\", "
        "Uniprot=\"{params.Uniprot}\")'"
        " && touch {output.fusions}) &> {log}"
