# The build-stage image:
FROM continuumio/miniconda3 AS build

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

LABEL bwa="0.7.17" samtools="1.9" python="3.8" bamtools="2.5.1" bcftools="1.11" gatk4="4.1.9.0"
LABEL snakemake-wrapper-utils="0.1.3"
################## MAINTAINER ######################
MAINTAINER Patrik Smeds <patrik.smeds@scilifelab.uu.se>


# Copy /venv from the previous stage:
# to /usr/local to make it possible
# running the softwares without activating
# any conda env
COPY --from=build /venv /usr/local

SHELL ["/bin/bash", "-c"]
