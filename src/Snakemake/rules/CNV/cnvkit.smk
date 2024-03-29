
rule Create_targets:
    input:
        bed=config["bed"]["bedfile"],
    output:
        bed="CNV/bed/cnvkit_manifest.target.bed",
    log:
        "logs/CNV_cnvkit/Create_targets.log",
    container:
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
    shell:
        "(cnvkit.py target --split {input.bed} -o {output.bed}) &> {log}"


rule Create_anti_targets:
    input:
        bed="CNV/bed/cnvkit_manifest.target.bed",
    output:
        bed="CNV/bed/cnvkit_manifest.antitarget.bed",
    log:
        "logs/CNV_cnvkit/Create_anti_targets.log",
    container:
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
    shell:
        "(cnvkit.py antitarget {input.bed} -o {output.bed}) &> {log}"


rule Call_cnv:
    input:
        bams=["Bam/DNA/" + s.Index + "-ready.bam" for s in samples.itertuples()],
        PoN=config["PoN"]["cnvkit"],
    output:
        regions=["CNV/cnvkit_calls/" + sample_id.Index + "-ready.cnr" for sample_id in samples.itertuples()],
        segments=["CNV/cnvkit_calls/" + sample_id.Index + "-ready.cns" for sample_id in samples.itertuples()],
    params:
        outdir="CNV/cnvkit_calls/",
        extra=config.get("cnvkit", {}).get("extra", ""),
    log:
        "logs/CNV_cnvkit/Call_cnv.log",
    threads: 8
    container:
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
    shell:
        "(cnvkit.py batch {input.bams} {params.extra} -r {input.PoN} -p {threads} -d {params.outdir}) &> {log}"


rule Filter_vcf_for_LoH:
    input:
        vcf="recall/{sample}.ensemble.vep.vcf.gz",
    output:
        vcf="recall/{sample}.ensemble.vep.LoH.vcf",
    container:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        "../../../scripts/python/Filter_vcf_LoH.py"


rule Call_LoH:
    input:
        segment="CNV/cnvkit_calls/{sample}-ready.cns",
        vcf="recall/{sample}.ensemble.vep.LoH.vcf",
    output:
        segment="CNV/cnvkit_calls/{sample}-LoH.cns",
    params:
        purity=lambda wildcards: samples.loc[wildcards.sample].TC,
    log:
        "logs/CNV_cnvkit/Call_LoH_{sample}.log",
    container:
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
    shell:
        "(cnvkit.py call {input.segment} -v {input.vcf} -o {output.segment} --purity {params.purity}) &> {log}"


checkpoint Filter_cnv:
    input:
        #cnvkit_segments=["CNV/cnvkit_calls/" + sample_id.Index + "-ready.cns" for sample_id in samples.itertuples()],
        cnvkit_segments=["CNV/cnvkit_calls/" + sample_id.Index + "-LoH.cns" for sample_id in samples.itertuples()],
        GATK_CNV_segments=["CNV/CNV_GATK/" + sample_id.Index + "_clean.modelFinal.seg" for sample_id in samples.itertuples()],
        relevant_genes=config["cnvkit"]["relevant_genes"],
        bed_file="CNV/bed/cnvkit_manifest.target.bed",
    output:
        relevant_cnvs="Results/DNA/CNV/Reported_cnvs.txt",
        relevant_cnvs_clinical="Results/DNA/CNV/Reported_cnvs_clinical.txt",
    params:
        purity=[sample.Index + ";" + str(sample.TC) for sample in samples.itertuples()],
        in_path="CNV/cnvkit_calls/",
        out_path="Results/DNA/CNV/",
    log:
        "logs/CNV_cnvkit/Filter_cnv.log",
    container:
        config["singularity"].get("python", config["singularity"].get("default", ""))
    script:
        #"../../../scripts/python/Filter_cnv.py"
        "../../../scripts/python/Filter_cnv_Loh.py"


rule create_cnv_kit_plots:
    input:
        cns="CNV/cnvkit_calls/{sample}-ready.cns",
        cnr="CNV/cnvkit_calls/{sample}-ready.cnr",
    output:
        png="Results/DNA/CNV/{sample}.cnvkit.png",
    params:
        extra="--y-min -2 --y-max 2",
    log:
        "logs/CNV_cnvkit/{sample}_scatter_cnv.log",
    threads: 8
    container:
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
    shell:
        "(cnvkit.py scatter {input.cnr} -s {input.cns} -o {output.png} {params.extra}) &> {log}"


rule create_chrom_plots:
    input:
        cns="CNV/cnvkit_calls/{sample}-ready.cns",
        cnr="CNV/cnvkit_calls/{sample}-ready.cnr",
        relevant_genes=config["cnvkit"]["relevant_genes"],
        cnv_kit_bed="CNV/bed/cnvkit_manifest.target.bed",
    output:
        png="Results/DNA/CNV/{sample}_{gene,[^_.]+}_{chr}.cnvkit.png",
    params:
        gene=lambda wildcards: wildcards.gene,
        title=lambda wildcards: wildcards.sample + " " + wildcards.chr + " " + wildcards.gene,
        chr=lambda wildcards: wildcards.chr,
    log:
        "logs/CNV_cnvkit/{sample}_{gene}_{chr}_scatter_cnv.gene.log",
    threads: 8
    container:
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
    shell:
        "(cnvkit.py scatter {input.cnr} -s {input.cns} -o {output.png} -c {params.chr} --title \"{params.title}\") &> {log}"


rule create_gene_region_plots:
    input:
        cns="CNV/cnvkit_calls/{sample}-ready.cns",
        cnr="CNV/cnvkit_calls/{sample}-ready.cnr",
        relevant_genes=config["cnvkit"]["relevant_genes"],
        cnv_kit_bed="CNV/bed/cnvkit_manifest.target.bed",
    output:
        png="Results/DNA/CNV/{sample}_{gene,[^_.]+}_{chr}:{gene_region,[0-9-]+}.cnvkit.png",
    params:
        gene=lambda wildcards: extract_gene_string(
            wildcards.gene, wildcards.gene_region, config["cnvkit"]["relevant_genes"], "CNV/bed/cnvkit_manifest.target.bed"
        ),
        title=lambda wildcards: wildcards.sample + " " + wildcards.chr + " " + wildcards.gene_region + " " + wildcards.gene,
        chr=lambda wildcards: wildcards.chr + ":" + wildcards.gene_region,
    log:
        "logs/CNV_cnvkit/{sample}_{gene}_{chr}:{gene_region}_scatter_cnv.gene.region.log",
    threads: 8
    container:
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
    shell:
        # "(cnvkit.py scatter {input.cnr} -s {input.cns} -o {output.png} -c {params.chr} -g {params.gene} --title \"{params.title}\") &> {log}"
        "(cnvkit.py scatter {input.cnr} -s {input.cns} -o {output.png} -c {params.chr} --title \"{params.title}\") &> {log}"


rule generate_cnv_plots:
    input:
        "CNV/bed/cnvkit_manifest.target.bed",
        lambda wildcards: expand(
            "Results/DNA/CNV/{file}", file=aggregate_input_gene(wildcards, "CNV/bed/cnvkit_manifest.target.bed")
        ),
    output:
        temp("Results/DNA/CNV/cnv_plots.txt"),
    shell:
        """
        touch {output}
        """


def extract_gene_string(gene, gene_region, cnv_relevant, bedfile):
    start_pos = int(gene_region.split("-")[0])
    end_pos = int(gene_region.split("-")[1])
    with open(bedfile) as bed:
        gene_string = ""
        gene_name_dict = {}
        for region in bed:
            lregion = region.strip().split("\t")
            # gene_name = lregion[3].split("_")[0]
            exon = lregion[3]
            # if gene_name not in gene_name_dict:
            if exon.find(gene + "_Exon") != -1:
                # gene_name_dict[gene_name] = ""
                s_pos = int(lregion[1])
                e_pos = int(lregion[2])
                if s_pos >= start_pos and e_pos <= end_pos:
                    if gene_string == "":
                        gene_string = exon
                    # gene_string = gene_name
                    else:
                        gene_string += ","
                        gene_string += exon
    return gene_string


def aggregate_input_gene(wildcards, bedfile):
    gene_list = []
    gene_region_list = []
    with checkpoints.Filter_cnv.get().output[1].open() as cnv_relevant:
        gene_regions = {}
        with open(bedfile) as cnv_bed_file:
            for line in cnv_bed_file:
                lline = line.strip().split("\t")
                chrom = lline[0]
                start = lline[1]
                end = lline[2]
                name = lline[3]
                gene = name.split("_")[0]
                if gene in gene_regions:
                    gene_regions[gene][2] = end
                else:
                    gene_regions[gene] = [chrom, start, end]
        next(cnv_relevant)
        for line in cnv_relevant:
            lline = line.strip().split("\t")
            sample = lline[1]
            gene = lline[2]
            if gene == "1p19q?":
                continue
            call_type = lline[0]
            if call_type == "GATK_CNV":
                continue
            chrom = lline[3]
            gene_regions_info = gene_regions[gene]
            gene_region1 = str(max(int(gene_regions_info[1]) - 10000000, 0)) + "-"
            gene_region1 += str(min(int(gene_regions_info[2]) + 10000000, config['reference']['chrom_len'][chrom]))
            gene_region2 = str(0) + "-" + str(config['reference']['chrom_len'][chrom])

            start_pos = int(gene_region1.split("-")[0])
            end_pos = int(gene_region1.split("-")[1])

            gene_region_list.append(sample + "_" + gene + "_" + chrom + ":" + gene_region1 + ".cnvkit.png")
            gene_list.append(sample + "_" + gene + "_" + chrom + ".cnvkit.png")
    return gene_region_list + gene_list
