
import gzip

in_vcf = snakemake.input.vcf
out_vcf = open(snakemake.output.vcf, "w")

with gzip.open(in_vcf, 'rt') as f:
    data = f.read().split("\n")
    header = True
    for line in data:
        if header:
            out_vcf.write(line + "\n")
            if line[:6] == "#CHROM":
                header = False
            continue
        lline = line.strip().split("\t")
        if len(lline) == 1:
            continue
        ref = lline[3]
        alt = lline[4]
        if len(ref) > 1 or len(alt) > 1:
            continue
        filter = lline[6]
        INFO = lline[7]
        INFO_list = INFO.split(";")
        AF_index = 0
        Caller_index = 0
        i = 0
        for info in INFO_list:
            if info[:3] == "AF=":
                AF_index = i
            i += 1
        AF = float(INFO_list[AF_index][3:])
        VEP_INFO = INFO.split("CSQ=")[1]
        db1000G = VEP_INFO.split("|")[41]
        if db1000G == "":
            db1000G = 0
        else:
            db1000G = float(db1000G)
        GnomAD = VEP_INFO.split("|")[47]
        if GnomAD == "":
            GnomAD = 0
        else:
            GnomAD = float(GnomAD)
        FORMAT = lline[8].split(":")
        AD_index = 0
        DP_index = 0
        VD_index = 0
        i = 0
        for f in FORMAT:
            if f == "AD":
                AD_index = i
            elif f == "DP":
                DP_index = i
            elif f == "VD":
                VD_index = i
            i += 1
        DATA = lline[9].split(":")
        AD = DATA[AD_index].split(",")
        if len(AD) == 2:
            VD = int(AD[1])
        elif AD_index != 0:
            VD = int(AD[0])
        else:
            VD = int(DATA[VD_index])
        DP = int(DATA[DP_index])

        if (filter.find("PASS") != -1 and DP > 50 and AF >= 0.05 and AF <= 0.95 and (GnomAD >= 0.001 or db1000G >= 0.001)):
            out_vcf.write(line + "\n")
