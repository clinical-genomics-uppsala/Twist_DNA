def extract_chr(file, filter_out=["chrM"]):
    chr = None
    with open(file) as lines:
        chr = [line.split("\t")[0] for line in lines]
    return [c for c in chr if c not in filter_out]


def create_chr_entries_for_vff_header(file_fai, assembly):
    chr = []
    with open(file_fai) as lines:
        for line in lines:
            row = line.split("\t")
            chr.append([("ID", row[0]), ("length", row[1]), ("assembly", assembly)])
    return chr


def extract_stub(path, sep):
    parts = path.split(sep)
    if len(parts) <= 1:
        raise Exception("Unable to split path: " + path + " using separator " + sep)
    return parts[0]


def generate_sample_list_from_samplesheet(path):
    import re
    samples = {}
    with open(path, 'r') as samplesheet:
        header_map = None
        for line in samplesheet:
            if line.startswith("[Data]"):
                line = next(samplesheet)
                columns = re.split(";|,", line.rstrip())
                header_map = {name.lower(): index for name, index in zip(columns, range(0, len(columns)))}
                break
        sample_counter = 1
        for line in samplesheet:
            columns = re.split(",|;", line.rstrip())
            samples[columns[header_map['sample_id']]] = {"counter": sample_counter}
            if header_map.get('project', None) is None or header_map['project'] == "":
                samples[columns[header_map['sample_id']]]["projectpath"] = ""
            else:
                samples[columns[header_map['sample_id']]]["projectpath"] = columns[header_map['project']] + "/"
            sample_counter = sample_counter + 1
    return samples


def get_fastq_file(units, sample, unit, read_pair='fq1'):
    files = units.loc[(sample, unit), [read_pair]].dropna()
    if len(files) > 1:
        raise Exception("Multiple fastq files found")
    return units.loc[(sample, unit), [read_pair]].dropna()[0]


def get_num_units(units, sample):
    return len(units.loc[sample].index.tolist())


def get_units(units, sample):
    return units.loc[sample].index.tolist()
