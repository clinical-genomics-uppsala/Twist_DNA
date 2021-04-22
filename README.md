![snakemake dry run](https://github.com/clinical-genomics-uppsala/Twist_DNA/workflows/snakemake%20dry%20run/badge.svg?branch=develop)
![pycodestyle](https://github.com/clinical-genomics-uppsala/Twist_DNA/workflows/pycodestyle/badge.svg?branch=develop)
![snakefmt](https://github.com/clinical-genomics-uppsala/Twist_DNA/workflows/snakefmt/badge.svg?branch=develop)

# Twist_DNA

## Requirements
### Necessary
To be able to run Twist_DNA, the following softwares needs to be available on your system.
* snakemake: 5.31.1
* pandas: 1.2.0

### Development
Extra packages that are recommended for development
* snakefmt: 0.4.0
* pycodestyle: 2.6.0
* pytest

### Additional
To make it easer to run the pipeline, with specific version of softwares, we recommend installing
[singularity](https://sylabs.io/guides/3.0/user-guide/quick_start.html). This will make it possible to use
pre-build containers.
<br />
Snakemake can be run on your computer or on a cluster. Our examples will be submitting jobs to a slurm cluster using drmaa. Which will require the following softwares:
* [slurm](https://slurm.schedmd.com/documentation.html)
* [slurm-drmaa](https://apps.man.poznan.pl/trac/slurm-drmaa)

### Install requirements
All softwares except singularity, slurm and slurm-drmaa can be install using pip3

```bash
# Setup a local environment
virtualenv -p python3 virtualenv
# Init local environment
source venv/bin/activate
# Install dependency to local environment
pip3 install -r requirements.txt
```

## Github action
### Code style
To make sure that all submitted code follows the same standards/format all codes needs to pass two tests, one for python code and one for snakemake specific code. [Pycodestyle](https://pypi.org/project/pycodestyle/), with a max row length of 130 characters, will validate all python code (dirs src/scripts and src/libs). For snakemake specific code, snakefmt will be used.
### Snakemake execution
All pull-request will trigger snakemake dry-runs for the following workflows:
* gms_somatic.sm
* Twist_DNA.smk, using a few different configs
making sure that all workflows at least are defined properly.

## Running workflows
### Twist_DNA
#### Required files
Copy Config/Pipeline/configdefaults201012.yaml to the working directory and name the copy Twist_DNA.yaml. To it you will need to add a list of samples
```yaml
DNA_Samples:
  sample1: "S1"

```
#### Command
```bash
snakemake -n -s Twist_DNA.smk --directory tests/workflow_dry_run/twist_dna/
```
### Twist_exome_WP3
```bash

```
### gms_somatic
#### Required files
##### sample.tsv
```text
sample	platform	build
sample1	NextSeq	hg19
sample2	NextSeq	hg19
```
##### unit.tsv
File used to map fastq files back to sample
```text
sample	unit	fq1	fq2
sample1	L001	fastq/sample1_L001_R1.fastq.gz	fastq/sample1_L001_R2.fastq.gz
```

#### Command
```bash
snakemake -p -j 64 --drmaa "-A ACCOUNT_ID -s -p PARTION_NAME -n {cluster.n} -t {cluster.time}"  -s ./gms_somatic.smk --use-singularity --singularity-args "--bind /data --bind STORAGE_PATH " --cluster-config Config/Slurm/cluster.json
```

### demultiplxing
#### Required files
##### demultiplexconfig.yaml
The config file needs to be located in you working directory, working directory is also where output will be written and doesn't necessarily need to be the runfolder. Copy example from Config/Pipeline/demultiplexingconfig.yaml and modify the following variables:
* runfolder_path
* samplesheet
* notification_mail

```

runfolder_path: path/runfolder_name
samplesheet:  path/SampleSheet.csv

notification_mail: mail@mail.se

```

#### Command
```bash
# Example run using config files
snakemake -s demultiplex.smk --directory tests/workflow_dry_run/demultiplex

# Run and override config value samplesheet
snakemake -n -s demultiplex.smk --directory tests/workflow_dry_run/demultiplex/ --config samplesheet=./runfolder_name/SampleSheet.csv
```
