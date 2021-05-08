# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

__author__ = "Patrik Smeds"
__copyright__ = "Copyright 2021, Patrik Smeds"
__email__ = "patrik.smeds@scilifelab.uu.se"
__license__ = "MIT"

import re
import argparse
import pysam

regex_string = ":UMI_([A-Za-z]+-[A-Za-z]+)"
regex = re.compile(regex_string)

# parser = argparse.ArgumentParser(description="Will look for UMI_{TAG1}-{TAG2} in read name, remove it and add it as attribute.")
# parser.add_argument('-i', '--input', help='input bam file', required, default=snakemake.input.bam)
# parser.add_argument('-o', '--output', help='output bam file', required, default=output.bam)
# parser.add_argument('-a', '--attribute', help='attribute name', default="RX")

# args = parser.parse_args()

input_bam_file = pysam.AlignmentFile(snakemake.input.bam, "r" if snakemake.input.bam.endswith(".sam") else "rb")

write_mode = "w" if snakemake.output.bam.endswith(".sam") else "wb"

with pysam.AlignmentFile(snakemake.output.bam, write_mode, template=input_bam_file) as output_bam_file:
    for read in input_bam_file.fetch():
        umi = regex.search(read.query_name)[1]
        read.query_name = regex.sub("", read.query_name)
        read.tags += [("RX", umi)]
        output_bam_file.write(read)
