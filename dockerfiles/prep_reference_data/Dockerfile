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

LABEL VERSION=0.0.2
LABEL bwa=0.7.17
LABEL ensembl-vep=101
LABEL awscli=1.19.97
LABEL picard=2.25.0
LABEL snakemake-wrapper-utils=0.1.3

################## MAINTAINER ######################
MAINTAINER Patrik Smeds <patrik.smeds@scilifelab.uu.se>


# Copy /venv from the previous stage:
# to /usr/local to make it possible
# running the softwares without activating
# any conda env


COPY --from=build /venv /usr/local
COPY --from=build /bin/ps /bin
COPY --from=build /lib/* /lib/

RUN mkdir /venv
RUN ln -s /usr/local/lib /venv/lib
RUN ln -s /usr/local/bin /venv/bin
RUN apt-get update && apt-get install libfreetype6 fontconfig fonts-dejavu -y && apt-get clean
ENV FONTCONFIG_PATH="/etc/fonts"
ENV FONTCONFIG_FILE="/etc/fonts/fonts.conf"
#SHELL ["/bin/bash", "-c"]
