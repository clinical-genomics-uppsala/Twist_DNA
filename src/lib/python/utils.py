def extract_chr(file):
    chr = None
    with open(file) as lines:
        chr = [line.split("\t")[0] for line in lines]
    return chr


def extract_stub(path, sep):
    parts = path[0].split(sep)
    if len(parts):
        raise Exception("Unable to split path: " + path)
    return parts[0]
