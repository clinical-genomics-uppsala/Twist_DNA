
import glob
import gzip
import os
import subprocess


cnv_purity = open(snakemake.input.purity)
cnv_relevant_genes = open(snakemake.input.relevant_genes)
cnv_files = snakemake.input.segments
cnv_bed_file = open(snakemake.input.bed_file)
cnv_relevant = open(snakemake.output.relevant_cnvs, "w")


cnv_event = open(raw_cnv_filename, "w")

cnv_relevant.write("sample_path\tsample\tgene\tchrom\tregion\tregion_size\tnr_exons\tCNVkit_copy_ratio\tCN_CNVkit_100%\t")
cnv_relevant.write("\tpurity\tCN_CNVkit\n")

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
for line in cnv_purity:
    lline = line.strip().split("\t")
    sample = lline[0]
    purity = float(lline[1])
    sample_purity_dict[sample] = [0, 0, 0, purity]
cnv_purity.close()


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
        sample = lline[0].split("/")[-1].split(".")[0]
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
        regions = lline[3].split(",")
        relevant_gene = False
        genes = {}
        nr_exons = 0
        for region in regions:
            if (region.find("Exon") != -1 :
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
        CR = float(lline[4])
        if CR >= 0.5 or CR < -0.33:
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
                if cnvkit_corrected_cn > 4.0 :
                    cnv_relevant.write(long_sample + "\t" + sample2 + "\t" + gene + "\t" + chrom + "\t" + str(start_pos) + "-" +
                                       str(end_pos) + "\t" + str(region_size) + "\t" + str(nr_exons) + "\t" +
                                       str(round(Copy_ratio, 2)) + "\t" + str(cnvkit_cn_100) + "\t" +
                                       str(purity) + "\t" + str(cnvkit_corrected_cn) + "\n")
                elif cnvkit_corrected_cn < 1.0 :
                    cnv_relevant.write(long_sample + "\t" + sample2 + "\t" + gene + "\t" + chrom + "\t" + str(start_pos) + "-" +
                                       str(end_pos) + "\t" + str(region_size) + "\t" + str(nr_exons) + "\t" +
                                       str(round(Copy_ratio, 2)) + "\t" + str(cnvkit_cn_100) + "\t" +
                                       str(purity) + "\t" + str(cnvkit_corrected_cn) + "\n")





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
