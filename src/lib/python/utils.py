def extract_chr(file):
    chr = None
    with open(file) as lines:
        chr = [line.split("\t")[0] for line in lines]
    return chr
