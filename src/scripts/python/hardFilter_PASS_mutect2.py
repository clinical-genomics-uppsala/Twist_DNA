#!/bin/python3.6
import logging
from pysam import VariantFile

vcf_in = VariantFile(snakemake.input.vcf)
vcf_out = VariantFile(snakemake.output[0], 'w', header=vcf_in.header)


if len(snakemake.log) > 0:
    logging.basicConfig(filename=snakemake.log[0], encoding='utf-8', level=logging.INFO)


counter_pass = 0
counter_failed = 0
for record in vcf_in.fetch():
    if record.filter.keys() == ["PASS"]:
        vcf_out.write(record)
        counter_pass = counter_pass + 1
    else:
        counter_failed = counter_failed + 1

logging.info("Total variants filtered: {}, PASS: {}, REMOVED: {}".format(
    counter_pass+counter_failed, counter_pass, counter_failed))
