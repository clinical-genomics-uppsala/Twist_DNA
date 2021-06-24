# vim: syntax=python tabstop=4 expandtab
# coding: utf-8


configfile: "config.yaml"

wildcard_constraints:
    genome="[^\.]+"

rule all:
    input:
        ["reference/" + config['reference']['species'] + "/" + config['reference']['assembly'] + "/genome." + file for file in ["fa", "amb", "ann", "bwt", "pac", "sa", "fai", "dict"]] + \
        ["reference/" + config['reference']['species'] + "/" + config['reference']['assembly'] + "/genome." + file for file in ["fa.amb", "fa.ann", "fa.bwt", "fa.pac", "fa.sa", "fa.fai"]] + \
        ["reference/vep/cache", config['bed']['interval_list']]


include: "src/Snakemake/workflow/setup_reference_data.smk"
