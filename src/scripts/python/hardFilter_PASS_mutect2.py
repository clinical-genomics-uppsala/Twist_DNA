#!/bin/python3.6
import sys
from pysam import VariantFile

vcf_in = VariantFile(snakemake.input.vcf)
vcf_out = VariantFile(snakemake.output, 'w', header=vcf_in.header)

for record in vcf_in.fetch():
    if record.filter.keys() == ["PASS"]:
        vcf_out.write(record)
