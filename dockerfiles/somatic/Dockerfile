# The build-stage image:
FROM continuumio/miniconda3  AS build

RUN apt update && apt install procps -y
# Install the package as normal:
COPY environment.yml /
RUN conda env create -f /environment.yml



# Install conda-pack:
RUN conda install -c conda-forge conda-pack

# Use conda-pack to create a standalone enviornment
# in /venv:
RUN conda-pack -n gms_somatic -o /tmp/env.tar && \
  mkdir /venv && cd /venv && tar xf /tmp/env.tar && \
  rm /tmp/env.tar

# We've put venv in same path it'll be in final image,
# so now fix up paths:
RUN /venv/bin/conda-unpack

# The runtime-stage image; we can use Debian as the
# base image since the Conda env also includes Python
# for us.
FROM debian:buster-slim AS runtime

################## METADATA ######################

LABEL VERSION=0.0.30
LABEL bamtools=2.5.1
LABEL bcbio-variation-recall=0.2.6
LABEL bcftools=1.11
LABEL bedtools=2.29
LABEL bioconductor-rsamtools=2.2.0
LABEL biobambam=2.0.87
LABEL bwa=0.7.17
LABEL cnvkit=0.9.8
LABEL cutadapt=3.2
LABEL fastqc=0.11.8
LABEL fastp=0.20.1
LABEL fgbio=1.3.0
LABEL freebayes=1.3.2
LABEL gatk4=4.1.9.0
LABEL genefuse=0.6.1
LABEL gridss=2.10.2
LABEL msisensor-pro=1.1.a
LABEL multiqc=1.9
LABEL pandas=1.2.1
LABEL parallel=20190522
LABEL picard=2.25.0
LABEL pysam=0.16.0.1
LABEL python=3.7
LABEL r-gert=1.3.0
LABEL r-devtools=2.0.2
LABEL r-openssl=1.4.4
LABEL r-usethis=2.0.1
#LABEL r-base=4.1.0
LABEL samtools=1.11
LABEL sed=4.7
LABEL snakemake-wrapper-utils=0.1.3
LABEL umis=1.0.7
LABEL vardict-java=1.8.2
LABEL varscan=2.4.3-0
LABEL vt=2015.11.10
################## MAINTAINER ######################
MAINTAINER Patrik Smeds <patrik.smeds@scilifelab.uu.se>


# Copy /venv from the previous stage:
# to /usr/local to make it possible
# running the softwares without activating
# any conda env

RUN apt-get update && apt-get install libgfortran4 libgit2-dev libfreetype6 fontconfig fonts-dejavu -y && apt-get clean

COPY --from=build /venv /usr/local
COPY --from=build /bin/ps /bin
COPY --from=build /lib/* /lib/

RUN wget https://github.com/sgilab/JuLI/raw/master/JuLI-v0.1.6.1.zip
RUN unzip JuLI-v0.1.6.1.zip
RUN mkdir /references_JuLI
RUN cp -r /JuLI-v0.1.6.1/references /references_JuLI
RUN rm -r /JuLI-v0.1.6.1 JuLI-v0.1.6.1.zip

RUN mkdir /venv
RUN ln -s /usr/local/lib /venv/lib
RUN ln -s /usr/local/bin /venv/bin
RUN ln -s /usr/local/ssl /venv/ssl

#RUN apt-get update && apt-get install software-properties-common -y && apt-get clean
#RUN add-apt-repository ppa:cran/libgit2 && apt-get update && apt-get install libfreetype6 fontconfig fonts-dejavu r-cran-rcurl libgit2-dev -y && apt-get clean

ENV FONTCONFIG_PATH="/etc/fonts"
ENV FONTCONFIG_FILE="/etc/fonts/fonts.conf"
#Install R devtool package JuLI and its dependencies
RUN R --slave -e 'library("devtools"); devtools::install_github("jonca79/JuLI")'
#SHELL ["/bin/bash", "-c"]
