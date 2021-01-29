
import glob
import sys


cnv_files = snakemake.input.calls
cnv_event = open(snakemake.output.cnv_event, "w")

gain_loss_dict = {}
for cnv_file_name in cnv_files:
    cnv_file = open(cnv_file_name)
    header = True
    for line in cnv_file:
        if header:
            if line[0:3] == "chr":
                header = False
            else:
                continue
        if line[0:3] == "[1]":
            continue
        lline = line.strip().split("\t")
        chrom = lline[0]
        if chrom == "chrX":
            continue
        cnv_regions = lline[5].split(",")
        # Filter flanking and intron only
        Flanking_intron_only = True
        for region in cnv_regions:
            if (region.find("Flanking") == -1 and region.find("Intron") == -1):
                Flanking_intron_only = False
                break
        if Flanking_intron_only:
            continue
        cn = float(lline[4].split("=")[1])
        if cn >= 2.5:
            cnv_event.write(cnv_file_name + "\t" + line)
        # if cn <= 1.5:
        #     cnv_event.write(cnv_file_name + "\t" + line)
    cnv_file.close()

cnv_event.close()
