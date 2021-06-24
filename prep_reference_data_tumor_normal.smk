# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

import pandas as pd

configfile: "config.yaml"

wildcard_constraints:
    unit="[A-Za-z0-9]+",
    sample="[^.]+",
    chr="chr[0-9XYM]+",

if "samples" in  config:
    samples = pd.read_table(config["samples"], index_col="sample")

if "units" in config:
    units = pd.read_table(config["units"], index_col=["sample", "unit"], dtype=str)
    units.index = units.index.set_levels([i.astype(str) for i in units.index.levels])  # enforce str in index

rule all:
    input:
        "DATA/cnvkit.Twist_test.PoN.cnn",
        "DATA/gatk4.Twist_test.readCountPoN.hdf5"

include: "src/Snakemake/workflow/build_cnv_reference.smk"
