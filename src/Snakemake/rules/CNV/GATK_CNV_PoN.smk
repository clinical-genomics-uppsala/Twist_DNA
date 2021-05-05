# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

__author__ = "Jonas Almlöf, Patrik Smeds"
__copyright__ = "Copyright 2021, Patrik Smeds, Jonas Almlöf"
__email__ = "jonas.almlöf@scilifelab.uu.se, patrik.smeds@scilifelab.uu.se"
__license__ = "GPL3"


interval_list = "bedFiles/design.interval_list"
try:
    interval_list = config["bed"]["intervals"]
except:
    pass

preprocessIntervals = "bedFiles/design.preprocessed.interval_list"
try:
    preprocessIntervals = config["bed"]["preprocessed_intervals"]
except:
    pass


rule bedToIntervalList:
    input:
        bed=config["bed"]["bedfile"],  ## Annotated clostest bedfile? Really needed?
        refDict=config["reference"]["ref"],  ##Have to be a .dict in same folder as .fasta
    output:
        interval_list,  #Should be based on bedfile...
    log:
        "logs/gatk/bedToIntervalList.log",
    singularity:
        config["singularity"]["gatk4"]
    shell:
        "(gatk BedToIntervalList  -I {input.bed} -O {output} -SD {input.refDict} ) &> {log} "


rule preprocessIntervals:
    input:
        ref=config["reference"]["ref"],
        intervalList=interval_list,  #targets_C.interval_list interval list picard style
    output:
        preprocessIntervals,
    params:
        binLength=config['gatk4']['binLength'],  #WGS 1000
        extra=" ".join(config.get("gatk4", {}).get("preprocessIntervals", [])),
    log:
        "logs/Normals/GATK/preprocessIntervals.log",
    singularity:
        config["singularity"]["gatk4"]
    shell:
        "(gatk --java-options '-Xmx4g' PreprocessIntervals -L {input.intervalList} -R {input.ref} "
        "--bin-length {params.binLength} {params.extra} "
        "-O {output}) &> {log}"


# From here need to be redone when added new samples
rule collectReadCounts:
    input:
        #bam=lambda wildcards: config["normal"][wildcards.normal],
        bam="Bam/DNA/{normal}-ready.bam",
        bai="Bam/DNA/{normal}-ready.bam.bai",
        interval=preprocessIntervals,
    output:
        "Normals/GATK4/{normal}.counts.hdf5",  #Should have date in it?
    params:
        extra=" ".join(config.get("gatk4", {}).get("collectReadCounts", [])),
    log:
        "logs/Normals/GATK/{normal}.collectReadCounts.log",
    singularity:
        config["singularity"]["gatk4"]
    shell:
        "(gatk --java-options '-Xmx4g' CollectReadCounts -I {input.bam} -L {input.interval} "
        "{params.extra} -O {output}) &> {log}"


rule createReadCountPanelOfNormals:
    input:
        expand("Normals/GATK4/{normal}.counts.hdf5", normal=[s.Index for s in samples.itertuples()]),
    output:
        "DATA/gatk4.{design,[^.]+}.readCountPoN.hdf5",
    params:
        extra=" ".join(config.get("gatk4", {}).get("createReadCountPanelOfNormals", [])),
        input=lambda wildcards, input: " -I ".join(input),
    log:
        "logs/Normals/GATK/{design}.readCountPoN.log",
    singularity:
        config["singularity"]["gatk4"]
    shell:
        "(gatk --java-options '-Xmx4g' CreateReadCountPanelOfNormals -I {params.input} "
        "{params.extra} "
        "-O {output}) &> {log}"
