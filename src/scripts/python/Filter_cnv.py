
import glob
import gzip
import os
import subprocess
import logging

if len(snakemake.log) > 0:
    logging.basicConfig(filename=snakemake.log[0], level=logging.INFO)

cnv_purity = snakemake.params.purity
cnv_relevant_genes = open(snakemake.input.relevant_genes)
cnvkit_files = snakemake.input.cnvkit_segments
GATK_CNV_files = snakemake.input.GATK_CNV_segments
cnv_bed_file = open(snakemake.input.bed_file)
cnv_relevant = open(snakemake.output.relevant_cnvs, "w")
in_path = snakemake.params.in_path
out_path = snakemake.params.out_path

cnv_relevant.write("caller\tsample\tgene\tchrom\tregion\tregion_size\tnr_exons/nr_points\tCopy_ratio\tCN_100%_TC\t")
cnv_relevant.write("\tpurity\tCN_adjusted\n")

chrom_len = {"chr1": 249250621, "chr2": 243199373, "chr3": 198022430, "chr4": 191154276, "chr5": 180915260, "chr6": 171115067,
             "chr7": 159138663, "chr8": 146364022, "chr9": 141213431, "chr10": 135534747, "chr11": 135006516, "chr12": 133851895,
             "chr13": 115169878, "chr14": 107349540, "chr15": 102531392, "chr16": 90354753, "chr17": 81195210, "chr18": 78077248,
             "chr19": 59128983, "chr20": 63025520, "chr21": 48129895, "chr22": 51304566, "chrX": 155270560, "chrY": 59373566}

relevant_genes = {}
for line in cnv_relevant_genes:
    relevant_genes[line.strip()] = {}

gene_regions = {}
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


'''Pathological purity'''
sample_purity_dict = {}
for row in cnv_purity:
    column = row.split(";")
    purity = float(column[1])
    if purity == 0:
        purity = 1.0
    sample_purity_dict[column[0] + "-ready"] = [0, 0, 0, purity]


cnv_relevant_list = []
'''Extract events from CNVkit'''
for cnv_file_name in cnvkit_files:
    cnv_file = open(cnv_file_name)
    header = True
    for line in cnv_file:
        if header:
            header = False
            continue
        lline = line.strip().split("\t")
        chrom = lline[0]
        start_pos = int(lline[1])
        end_pos = int(lline[2])
        sample = cnv_file_name.split("/")[-1].split(".")[0]
        if chrom == "chrX":
            continue
        regions = lline[3].split(",")
        # Filter flanking and intron only
        Flanking_intron_only = True
        for region in regions:
            if (region.find("Flanking") == -1 and region.find("Intron") == -1):
                Flanking_intron_only = False
                break
        if Flanking_intron_only:
            continue
        relevant_gene = False
        genes = {}
        nr_exons = 0
        for region in regions:
            if region.find("Exon") != -1:
                nr_exons += 1
            gene = region.split("_")[0]
            if gene in relevant_genes:
                relevant_gene = True
                if gene in genes:
                    genes[gene].append(region)
                else:
                    genes[gene] = [region]
        if not relevant_gene:
            continue
        try:
            CR = float(lline[4])
        except ValueError:
            logging.warning("Could not convert column 4 in row to float: " + line)
            continue
        if CR >= 0.35 or CR < -0.25:
            if sample not in sample_purity_dict:
                print("Error: sample %s not in tumor purity file" % sample)
                cnv_relevant.close()
                subprocess.call("rm " + snakemake.output.relevant_cnvs, shell=True)
                quit()
            cnvkit_cn_100 = round(2*pow(2, CR), 2)
            purity = sample_purity_dict[sample][3]
            cnvkit_corrected_cn = round(2 + (cnvkit_cn_100 - 2) * (1/purity), 1)
            region_size = end_pos - start_pos
            for gene in genes:
                sample2 = sample.split("-ready")[0]
                if cnvkit_corrected_cn > 4.0:
                    cnv_relevant_list.append([chrom, start_pos, end_pos, sample2])
                    cnv_relevant.write("CNVkit\t" + sample2 + "\t" + gene + "\t" + chrom + "\t" + str(start_pos) + "-" +
                                       str(end_pos) + "\t" + str(region_size) + "\t" + str(nr_exons) + "\t" +
                                       str(round(CR, 2)) + "\t" + str(cnvkit_cn_100) + "\t" +
                                       str(purity) + "\t" + str(cnvkit_corrected_cn) + "\n")
                elif cnvkit_corrected_cn < 1.0:
                    cnv_relevant_list.append([chrom, start_pos, end_pos, sample2])
                    cnv_relevant.write("CNVkit\t" + sample2 + "\t" + gene + "\t" + chrom + "\t" + str(start_pos) + "-" +
                                       str(end_pos) + "\t" + str(region_size) + "\t" + str(nr_exons) + "\t" +
                                       str(round(CR, 2)) + "\t" + str(cnvkit_cn_100) + "\t" +
                                       str(purity) + "\t" + str(cnvkit_corrected_cn) + "\n")


'''Extract events from GATK_CNV'''
for cnv_file_name in GATK_CNV_files:
    cnv_file = open(cnv_file_name)
    header = True
    for line in cnv_file:
        if header:
            if line[:6] == "CONTIG":
                header = False
            continue
        lline = line.strip().split("\t")
        chrom = lline[0]
        start_pos = int(lline[1])
        end_pos = int(lline[2])
        nr_points_CR = int(lline[3])
        if nr_points_CR <= 2:
            continue
        nr_points_AF = int(lline[4])
        CR = float(lline[6])
        MAF = "NA"
        if nr_points_AF > 0:
            MAF = float(lline[9])
        sample2 = cnv_file_name.split("/")[-1].split("_")[0]
        sample = cnv_file_name.split("/")[-1].split("_")[0] + "-ready"
        if chrom == "chrX":
            continue
        gene = ""
        # if (CR >= 0.5 or CR < -0.33):
        if True:
            if sample not in sample_purity_dict:
                print("Error: sample %s not in tumor purity file" % sample)
                cnv_relevant.close()
                subprocess.call("rm " + snakemake.output.relevant_cnvs, shell=True)
                quit()
            in_cnv_kit = False
            for cnv in cnv_relevant_list:
                if (cnv[3] == sample2 and cnv[0] == chrom and
                    ((start_pos >= cnv[1] and start_pos <= cnv[2]) or
                        (end_pos >= cnv[1] and end_pos <= cnv[2]) or
                        (start_pos <= cnv[1] and end_pos >= cnv[2]))):
                    in_cnv_kit = True
            cn_100 = round(2*pow(2, CR), 2)
            purity = sample_purity_dict[sample][3]
            corrected_cn = round(2 + (cn_100 - 2) * (1/purity), 1)
            region_size = end_pos - start_pos
            if in_cnv_kit:
                cnv_relevant.write(
                    "GATK_CNV\t" + sample2 + "\t" + gene + "\t" + chrom + "\t" + str(start_pos) + "-" +
                    str(end_pos) + "\t" + str(region_size) + "\t" + str(nr_points_CR) + "\t" +
                    str(round(CR, 2)) + "\t" + str(cn_100) + "\t" +
                    str(purity) + "\t" + str(corrected_cn) + "\n"
                )
            # if corrected_cn > 4.0:
            #     cnv_relevant.write("GATK_CNV\t" + sample2 + "\t" + gene + "\t" + chrom + "\t" + str(start_pos) + "-" +
            #                        str(end_pos) + "\t" + str(region_size) + "\t" + str(nr_points_CR) + "\t" +
            #                        str(round(CR, 2)) + "\t" + str(cn_100) + "\t" +
            #                        str(purity) + "\t" + str(corrected_cn) + "\n")
            # elif corrected_cn < 1.0:
            #     cnv_relevant.write("GATK_CNV\t" + sample2 + "\t" + gene + "\t" + chrom + "\t" + str(start_pos) + "-" +
            #                        str(end_pos) + "\t" + str(region_size) + "\t" + str(nr_points_CR) + "\t" +
            #                        str(round(CR, 2)) + "\t" + str(cn_100) + "\t" +
            #                        str(purity) + "\t" + str(corrected_cn) + "\n")
cnv_relevant.close()
