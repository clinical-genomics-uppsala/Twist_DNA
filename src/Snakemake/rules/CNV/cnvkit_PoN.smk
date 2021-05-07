# vim: syntax=python tabstop=4 expandtab
# coding: utf-8


__author__ = "Jonas Almlöf, Patrik Smeds"
__copyright__ = "Copyright 2021, Patrik Smeds, Jonas Almlöf"
__email__ = "jonas.almlöf@scilifelab.uu.se, patrik.smeds@scilifelab.uu.se"
__license__ = "GPL3"


rule Create_targets:
    input:
        bed=config["bed"]["bedfile"],
    output:
        bed="CNV/bed/cnvkit_manifest.target.bed",
    log:
        "logs/CNV_cnvkit/Create_targets.log",
    singularity:
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
    shell:
        "(cnvkit.py target --split {input.bed} -o {output.bed}) &> {log}"


rule Create_anti_targets:
    input:
        bed="CNV/bed/cnvkit_manifest.target.bed",
    output:
        bed="CNV/bed/cnvkit_manifest.antitarget.bed",
    log:
        "logs/CNV_cnvkit/Create_anti_targets.log",
    singularity:
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
    shell:
        "(cnvkit.py antitarget {input.bed} -o {output.bed}) &> {log}"


rule Build_normal_reference:
    input:
        bams=["Bam/DNA/" + s.Index + "-ready.bam" for s in samples.itertuples()],
        bed1="CNV/bed/cnvkit_manifest.target.bed",
        bed2="CNV/bed/cnvkit_manifest.antitarget.bed",
        ref=config["reference"]["ref"],
        mappability=config["cnvkit"]["mappable"],
    output:
        PoN="DATA/cnvkit.{design,[^.]+}.PoN.cnn",
    params:
        extra=config.get("cnvkit", {}).get("extra", ""),
    threads: 4
    singularity:
        config["singularity"].get("cnvkit", config["singularity"].get("default", ""))
    shell:
        "cnvkit.py batch "
        " {params.extra} "
        "-n {input.bams} "
        "-m hybrid "
        "--output-reference {output.PoN} "
        "-t {input.bed1} "
        "-f {input.ref} "
        "-a {input.bed2} "
        "-g {input.mappability} "
        "-p {threads}"
