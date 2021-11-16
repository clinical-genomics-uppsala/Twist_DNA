![snakemake dry run](https://github.com/clinical-genomics-uppsala/Twist_DNA/workflows/snakemake%20dry%20run/badge.svg?branch=develop)
![pycodestyle](https://github.com/clinical-genomics-uppsala/Twist_DNA/workflows/pycodestyle/badge.svg?branch=develop)
![snakefmt](https://github.com/clinical-genomics-uppsala/Twist_DNA/workflows/snakefmt/badge.svg?branch=develop)

# Twist_DNA

***********************

- [Twist_DNA](#twist_dna)
  - [System configuration](#system-configuration)
    - [Requirements](#requirements)
    - [DRMAA installation for HPC clusters users](#drmaa-installation-for-hpc-clusters-users)
    - [Clone the Twist_DNA github repo](#clone-the-twist_dna-github-repo)
  - [Reference files](#reference-files)
    - [Reference download](#reference-download)
    - [Reference indexing](#reference-indexing)
    - [VEP reference database download](#vep-reference-database-download)
    - [Interval list for Picard](#interval-list-for-picard)
  - [Configuration files](#configuration-files)
    - [Config file generation](#config-file-generation)
    - [Config file generation on HPC clusters](#config-file-generation-on-hpc-clusters)
    - [Additional required files](#additional-required-files)
  - [Run the workflow](#run-the-workflow)
  - [Possible adjustments in certain cases](#possible-adjustments-in-certain-cases)
    - [Adjustment in `rule recall`](#adjustment-in-rule-recall)
    - [Coverage analysis](#coverage-analysis)

***********************

## System configuration

### Requirements
The easier way is to create a conda environment by following these steps:

Create a yaml file named as `env.yml`.

```yaml=
name: Twist_DNA
channels:
  - conda-forge
  - bioconda
  - defaults
dependencies:
  - python=3.8.8
  - snakemake=5.31.1
  - pandas=1.2.0
  - pysam
  - pytest
  - singularity=3.7.1
  - picard=2.25.2
  - awscli
  - bwa
  - samtools
  #uncomment the following line if you run the pipeline on HPC cluster
  #- drmaa
```

Create the environment with conda:

```bash
conda env create -f env.yml
```

or if you use mamba:

```bash 
mamba env create -f env.yml
```


### DRMAA installation for HPC clusters users
It requires admin rights, please ask your system administrator. 
Libraries to be installed:

- gridengine-drmaa-dev
- gridengine-common


Export [libdrmaa.so.1.0](https://github.com/pygridtools/drmaa-python 'DRMAA Python'), generally you can find it at the following paths:

```bash
export DRMAA_LIBRARY_PATH=/usr/lib/libdrmaa.so.1.0
```

or

```bash
export DRMAA_LIBRARY_PATH=/usr/lib/gridengine-drmaa/lib/libdrmaa.so.1.0
```

### Clone the Twist_DNA github repo

```bash
THIS_PATH=$(pwd)
git clone https://github.com/clinical-genomics-uppsala/Twist_DNA.git
cd "$THIS_PATH/Twist_DNA"
```
<br>


## Reference files

### Reference download
NGI is using [iGenomes](https://github.com/ewels/AWS-iGenomes 'GitHub repository') hosted at [Amazon Web Services](https://aws.amazon.com/?nc2=h_lg 'Amazon Web Services').

To generate the proper command to download the reference files navigate to [Sync command builder](https://ewels.github.io/AWS-iGenomes/ 'Command builder direct link') and select hg19 genome assembly version from UCSC as shown in the screenshot below:

![](https://i.imgur.com/2jaWPAR.png)

You can run the following commands:

```bash=
conda activate Twist_DNA
REF_ASSEMBLY_PATH="path/to/reference"
aws s3 --no-sign-request --region eu-west-1 sync s3://ngi-igenomes/igenomes/Homo_sapiens/UCSC/hg19/Sequence/WholeGenomeFasta/ "$REF_ASSEMBLY_PATH"
```

### Reference indexing
To create the index for the reference genome run the following commands to download the hg19 reference directly from AWS:

```bash=
REF_ASSEMBLY_PATH="path/to/reference"
cd "$REF_ASSEMBLY_PATH"
bwa index -a bwtsw genome.fa
```

### VEP reference database download
You need the Ensembl Variant Effect Predictor (VEP) annotation database, [release 99](http://ftp.ensembl.org/pub/release-99/variation/indexed_vep_cache/ 'VEP release-99'). You can find the archive here:

```bash=
VEP_DATA_PATH="path/to/vep/database"
cd "$VEP_DATA_PATH"
wget http://ftp.ensembl.org/pub/release-99/variation/indexed_vep_cache/homo_sapiens_refseq_vep_99_GRCh37.tar.gz
tar xvzf homo_sapiens_refseq_vep_99_GRCh37.tar.gz
```

### Interval list for Picard
You may need to re-generate the Picard interval file, this depends upon the reference. If so, you can simply run [BedToIntervalList](https://gatk.broadinstitute.org/hc/en-us/articles/360036883931-BedToIntervalList-Picard- 'Picard BedToIntervalList'):

```bash
picard BedToIntervalList -I pool1_pool2_nochr_3c.sort.merged.hg19.210311.met.annotated.bed -O pool1_pool2_nochr_3c.sort.merged.padded20.hg19.210311.met.annotated.interval_list -SD genome.dict
```

If you have downloaded the reference from AWS, you should already have the genome dictionary in the reference folder. If not, you can generate this file using samtools:

```bash=
REF_ASSEMBLY_PATH="path/to/reference"
cd "$REF_ASSEMBLY_PATH"
samtools dict genome.fa
```
<br>

## Configuration files
You need to generate a configuration file named **Twist_DNA.yaml** before running Twist_DNA. You also need three additional files storing different information about your samples such as name, index and fastq files location.


### Config file generation
You can generate the config file directly using this command:

```bash
snakemake -p -j 1 -s path/to/Twist_DNA/src/Snakemake/rules/Twist_DNA_yaml/Twist_DNA_yaml.smk
```

Alternatively, you can use a template and change the paths to the reference files accordingly with your system. You can find the template [here](https://github.com/clinical-genomics-uppsala/Twist_DNA/blob/develop/Config/Pipeline/configdefaults201012.yaml 'Twist_DNA.yaml example') and rename it as Twist_DNA.yaml.


### Config file generation on HPC clusters
On HPC clusters users can run the following command to generate the config file:

```bash
snakemake -p -j 1 --drmaa "-A wp1 -p core -n 1 -t 2:00:00 " -s ./src/Snakemake/rules/Twist_DNA_yaml/Twist_DNA_yaml.smk
```

### Additional required files
You can find a template for each of the additional files needed to run Twist_DNA. Just modify them accordingly with your samples:

1. [samplesheet.csv](https://github.com/clinical-genomics-uppsala/Twist_DNA/blob/develop/tests/workflow_dry_run/twist_dna/samplesheet.csv 'samplesheet.csv example')
2. [units.tsv](https://github.com/clinical-genomics-uppsala/Twist_DNA/blob/develop/tests/workflow_dry_run/twist_dna/units.tsv 'units.tsv example')
3. [samples.tsv](https://github.com/clinical-genomics-uppsala/Twist_DNA/blob/develop/tests/workflow_dry_run/twist_dna/samples.tsv 'samples.tsv example')

<br>

## Run the workflow
Once everything is ready, you can activate the Twist_DNA conda environment (if you haven't already) and run the pipeline with a single command:

```bash
snakemake --cores 10 --use-singularity --singularity-args "--bind /mount/point/one --bind /mount/point/two"
```

You can add as many mount points as you want. It depends on how input files are distributed on your system. You can have the fastq files on /mount/point/one and the reference files /mount/point/two such as in the example above or if you have everything in the same place you can add just one mount point.

<br>

## Possible adjustments in certain cases

In order to run the pipeline in some OS:s some changes in certain rules may be necessary.

### Adjustment in `rule recall`

In a Red Hat Enterprise Linux release 8.4 (Ootpa) server `rule recall` (in file: `src/Snakemake/rules/VCF_fix/recall.smk`) may cause the following error:

![](https://i.imgur.com/uvm6hY7.png)

![](https://i.imgur.com/vPoTm5J.png)

and thus may need some adjustments. To fix the error, the following changes can be made:

1. Add lines to params

```python
bcbio_singularity=config["singularity"]["execute"] + config["singularity"].get("ensemble", config["singularity"].get("default", ""))
```

2. Adjust the shell section

```bash
{params.bcbio_singularity} bcbio-variation-recall ensemble -c 50 -n {params.support} --names {params.order} {output.vcf} {input.ref} {input.vcfs} &> {log}
```

**The final outcome**

After the changes, the rule should look something like [this](https://github.com/Genomic-Medicine-Linkoping/Twist_DNA/blob/c0c8230e0f1ac09dce5948a51c43f8bdc62ac22f/src/Snakemake/rules/VCF_fix/recall.smk#L24-L31).

### Coverage analysis

In case you wish to execute coverage analysis using `bedtools coverage` you might need to convert the appropriate interval list back to bed file that is understood by the tool. This can be accomplished with e.g. the following command:

```bash=
ILIST=pool1_pool2_nochr_3c.sort.merged.hg19.210311.met.annotated.interval_list
BED=pool1_pool2_nochr_3c.sort.merged.hg19.210311.met.annotated.bed
gatk IntervalListToBed -I "$ILIST" -O "$BED"
```

