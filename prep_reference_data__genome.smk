# vim: syntax=python tabstop=4 expandtab
# coding: utf-8


configfile: "config.yaml"

wildcard_constraints:
    genome="[^\.]+"

rule all:
    input:
        ["reference/" + config['reference']['assembly'] + "/hg19." + file for file in ["fasta", "amb", "ann", "bwt", "pac", "sa", "fai", "fasta.fai", "dict"]] + \
        [directory("reference/vep/cache")]


include: "src/Snakemake/workflow/setup_reference_data.smk"
