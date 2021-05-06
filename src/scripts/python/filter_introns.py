
import gzip
import sys

try:
    invcf = snakemake.input.vcf
except:
    invcf = sys.argv[1]

try:
    inbed = open(snakemake.input.bed)
except:
    inbed = open(sys.argv[2])

try:
    outvcf = open(snakemake.output.vcf, "w")
except:
    outvcf = open(sys.argv[3], "w")


# Add all regions annotated with Exons
exon_dict = {}
for line in inbed:
    lline = line.strip().split("\t")
    chrom = lline[0]
    start_pos = int(lline[1])
    end_pos = int(lline[2])
    region = lline[3]
    if region.find("Exon") != -1:
        if chrom not in exon_dict:
            exon_dict[chrom] = []
        exon_dict[chrom].append([start_pos, end_pos])


with gzip.open(invcf, 'rt') as f:
    data = f.read().split("\n")
    header = True
    for line in data:
        if header:
            outvcf.write(line + "\n")
            if line[:6] == "#CHROM":
                header = False
            continue
        lline = line.strip().split("\t")
        if lline == [""]:
            continue
        chrom = lline[0]
        pos = int(lline[1])
        found = False
        if chrom not in exon_dict:
            continue
        for exon in exon_dict[chrom]:
            if pos >= exon[0] and pos <= exon[1]:
                found = True
                break
        if found:
            outvcf.write(line + "\n")
outvcf.close()
