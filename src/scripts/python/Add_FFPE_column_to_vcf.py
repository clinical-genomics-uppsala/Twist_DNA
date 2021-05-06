
import sys

try:
    infile = open(snakemake.input.vcf_ffpe)
except:
    infile = open(sys.argv[1])

try:
    outfile = open(snakemake.output.vcf_ffpe, "w")
except:
    outfile = open(sys.argv[2], "w")

header = True
for line in infile:
    if header:
        if line[:6] == "#CHROM":
            header = False
        outfile.write(line)
        continue
    lline = line.strip().split("\t")
    larti = lline[7].split(";")[-2:]
    parti = larti[0].split("pArtifact=")[1]
    arti = larti[1].split("artiStatus")[1]
    if arti[0] == "=":
        arti = arti[1:]
    outfile.write(line.strip() + "\t" + parti + "\t" + arti + "\n")

infile.close()
outfile.close()
