
import glob
import gzip
import os
import sys
import subprocess


cnv_purity = open(sys.argv[1])
cnv_relevant_genes = open(sys.argv[2])
cnv_files = sys.argv[3:-4]
cnv_ONCOCNV = open(sys.argv[-4])
cnv_bed_file = open(sys.argv[-3])
raw_cnv_filename = sys.argv[-2]
cnv_relevant = open(sys.argv[-1], "w")


cnv_event = open(raw_cnv_filename, "w")

cnv_relevant.write("sample_path\tsample\tgene\tchrom\tregion\tCNVkit_copy_ratio\tCN_CNVkit_100%\t")
cnv_relevant.write("CN_ONCOCNV_100%\tpurity\tCN_CNVkit\tCN_ONCOCNV\n")

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


'''Extract copy numbers from ONCOCNV'''
for line in cnv_ONCOCNV:
    lline = line.strip().split("\t")
    sample = lline[0].split("/")[1].split(".")[0]
    regions = lline[6].split(",")
    # #Filter flanking and intron only
    # Flanking_intron_only = True
    # for region in regions:
    #     if (region.find("Flanking") == -1 and region.find("Intron") == -1):
    #         Flanking_intron_only = False
    #         break
    # if Flanking_intron_only:
    #     continue
    relevant_gene = False
    genes = []
    for region in regions:
        if region.split("_")[0] in relevant_genes:
            relevant_gene = True
            genes.append(region.split("_")[0])
    if not relevant_gene:
        continue
    CN = float(lline[5].split("=")[1])
    for gene in genes:
        if sample not in relevant_genes[gene]:
            relevant_genes[gene][sample] = [2, 2]
        if CN > relevant_genes[gene][sample][1]:
            relevant_genes[gene][sample][1] = CN
        elif CN < relevant_genes[gene][sample][0]:
            relevant_genes[gene][sample][0] = CN
cnv_ONCOCNV.close()


'''Extract events from CNVkit'''
gain_loss_dict = {}
for cnv_file_name in cnv_files:
    cnv_file = open(cnv_file_name)
    header = True
    for line in cnv_file:
        if header:
            header = False
            continue
        lline = line.strip().split("\t")
        chrom = lline[0]
        if chrom == "chrX":
            continue
        cnv_regions = lline[3].split(",")
        # Filter flanking and intron only
        Flanking_intron_only = True
        for region in cnv_regions:
            if (region.find("Flanking") == -1 and region.find("Intron") == -1):
                Flanking_intron_only = False
                break
        if Flanking_intron_only:
            continue
        CR = float(lline[4])
        if CR >= 0.25:
            cnv_event.write(cnv_file_name + "\t" + line)
        # elif CR <= -0.25:
        #     cnv_event.write(cnv_file_name + "\t" + line)
    cnv_file.close()
cnv_event.close()


'''Pathological purity'''
sample_purity_dict = {}
for line in cnv_purity:
    lline = line.strip().split("\t")
    sample = lline[0]
    purity = float(lline[1])
    sample_purity_dict[sample] = [0, 0, 0, purity]
cnv_purity.close()


'''Find cnvs above cutoffs'''
cnv_event = open(raw_cnv_filename)
for line in cnv_event:
    lline = line.strip().split("\t")
    regions = lline[4].split(",")
    relevant_gene = False
    genes = {}
    for region in regions:
        gene = region.split("_")[0]
        if gene in relevant_genes:
            relevant_gene = True
            if gene in genes:
                genes[gene].append(region)
            else:
                genes[gene] = [region]
    if not relevant_gene:
        continue
    long_sample = lline[0]
    sample = lline[0].split("/")[-1].split(".")[0]
    if sample not in sample_purity_dict:
        print("Error: sample %s not in tumor purity file" % sample)
        cnv_relevant.close()
        subprocess.call("rm " + sys.argv[-1], shell=True)
        quit()
    chrom = lline[1]
    start_pos = int(lline[2])
    end_pos = int(lline[3])
    Copy_ratio = float(lline[5])
    cnvkit_cn_100 = round(2*pow(2, Copy_ratio), 2)
    purity = sample_purity_dict[sample][3]

    cnvkit_corrected_cn = round(2 + (cnvkit_cn_100 - 2) * (1/purity), 1)
    for gene in genes:
        ONCOCNV_CN_100 = 2
        sample2 = sample.split("-ready")[0]
        if sample2 in relevant_genes[gene]:
            if Copy_ratio > 0:
                ONCOCNV_CN_100 = relevant_genes[gene][sample2][1]
            else:
                ONCOCNV_CN_100 = relevant_genes[gene][sample2][0]
        ONCOCNV_corrected_cn = round(2 + (ONCOCNV_CN_100 - 2) * (1/purity), 1)
        if cnvkit_corrected_cn > 6.0 and ONCOCNV_corrected_cn > 6.0:
            cnv_relevant.write(long_sample + "\t" + sample2 + "\t" + gene + "\t" + chrom + "\t" + str(start_pos) + "-" +
                               str(end_pos) + "\t" + str(round(Copy_ratio, 2)) + "\t" + str(cnvkit_cn_100) + "\t" +
                               str(ONCOCNV_CN_100) + "\t" + str(purity) + "\t" + str(cnvkit_corrected_cn) + "\t" +
                               str(ONCOCNV_corrected_cn) + "\n")
cnv_relevant.close()


# '''Create plots'''
# for sample_file in cnv_files:
#     sample = sample_file.split(".cns")[0].split("/")[1]
#     sample2 = sample.split("-ready")[0]
#     path = sample_file.split("/")[0]
#     vcf = "Results/DNA/" + sample2 + "/vcf/" + sample2 + "-ensemble.final.vcf"
#     os.system("gunzip -c " + vcf + ".gz > " + vcf)
#     vcf_in = open(vcf)
#     vcf_out = open(vcf + ".rs", "w")
#     header = True
#     for line in vcf_in:
#         if header:
#             if line[:2] == "#C":
#                 header = False
#             vcf_out.write(line)
#             continue
#         lline = line.strip().split("\t")
#         rs = lline[2]
#         if rs != ".":
#             AD_index = 0
#             AF_index = 0
#             i = 0
#             for l in lline[8].split(":"):
#                 if l == "AD":
#                     AD_index = i
#                 if l == "AF":
#                     AF_index = i
#                 i += 1
#             if len(lline[9].split(":")[AD_index].split(",")) == 2:
#                 if float(lline[9].split(":")[AF_index]) > 0.05 and float(lline[9].split(":")[AF_index]) < 0.95:
#                     vcf_out.write(line)
#     vcf_in.close()
#     vcf_out.close()
#     command_line = "singularity exec /projects/wp4/nobackup/workspace/somatic_dev/singularity/cnvkit_0.9.7--py_1.sif "
#     command_line += "cnvkit.py scatter "
#     command_line += path + "/" + sample + ".cnr "
#     command_line += "-s " + path + "/" + sample + ".cns "
#     command_line += "-o CNV_results/" + sample + ".png "
#     command_line += "-v " + vcf + ".rs "
#     command_line += "--y-min -2 --y-max 2"
#     print(command_line)
#     os.system(command_line)
#     os.system("rm " + vcf)
#     #os.system("rm " + vcf + ".rs")
#
# cnv_relevant = open(sys.argv[-1])
# header = True
# for line in cnv_relevant:
#     if header:
#         header = False
#         continue
#     lline = line.strip().split("\t")
#     print(lline)
#     sample = lline[0].split("/")[1].split(".cns")[0]
#     sample2 = sample.split("-ready")[0]
#     path = lline[0].split("/")[0]
#     vcf = "Results/DNA/" + sample2 + "/vcf/" + sample2 + "-ensemble.final.vcf.rs"
#     gene = lline[2]
#     chrom = lline[3]
#     #gene_region = lline[4]
#     gene_regions_info = gene_regions[gene]
#     #gene_region1 = str(int(gene_regions_info[1])) + "-" + str(int(gene_regions_info[2]))
#     gene_region1 = str(max(int(gene_regions_info[1])-10000000,0)) + "-" +
#                    str(min(int(gene_regions_info[2])+10000000,chrom_len[chrom]))
#     gene_region2 = str(0) + "-" + str(chrom_len[chrom])
#     print(gene, gene_regions_info, gene_region1, gene_region2)
#     start_pos = int(gene_region1.split("-")[0])
#     end_pos = int(gene_region1.split("-")[1])
#
#     bed = open("DATA/TST500C_manifest.bed")
#     gene_string = ""
#     gene_name_dict = {}
#     for region in bed:
#         lregion = region.strip().split("\t")
#         #gene_name = lregion[3].split("_")[0]
#         exon = lregion[3]
#         if exon.find(gene + "_Exon") != -1:
#         #if gene_name not in gene_name_dict:
#         #    gene_name_dict[gene_name] = ""
#             s_pos = int(lregion[1])
#             e_pos = int(lregion[2])
#             if (s_pos >= start_pos and e_pos <= end_pos):
#                 if gene_string == "":
#                     gene_string = exon
#                     #gene_string = gene_name
#                 else:
#                     gene_string += ","
#                     gene_string += exon
#                     #gene_string += gene_name
#     bed.close()
#     command_line = "singularity exec /projects/wp4/nobackup/workspace/somatic_dev/singularity/cnvkit_0.9.7--py_1.sif "
#     command_line += "cnvkit.py scatter "
#     command_line += path + "/" + sample + ".cnr "
#     command_line += "-s " + path + "/" + sample + ".cns "
#     command_line += "-c " + chrom + ":" + gene_region1
#     command_line += " -g " + gene_string
#     command_line += " -v " + vcf
#     command_line += " --title '" + sample + " " + chrom + " " + gene_region1 + " " + gene + "'"
#     command_line += " -o CNV_results/" + sample + "_" + gene + "_" + chrom + ":" + gene_region1 + ".png"
#     print(command_line)
#     os.system(command_line)
#     command_line = "singularity exec /projects/wp4/nobackup/workspace/somatic_dev/singularity/cnvkit_0.9.7--py_1.sif "
#     command_line += "cnvkit.py scatter "
#     command_line += path + "/" + sample + ".cnr "
#     command_line += "-s " + path + "/" + sample + ".cns "
#     command_line += "-c " + chrom + ":" + gene_region2
#     command_line += " -g " + gene_string
#     command_line += " -v " + vcf
#     command_line += " --title '" + sample + " " + chrom + " " + gene + "'"
#     command_line += " -o CNV_results/" + sample + "_" + gene + "_" + chrom + ".png"
#     print(command_line)
#     os.system(command_line)
#
# cnv_done = open("CNV_results/cnv_done.txt", "w")
# cnv_done.close()
