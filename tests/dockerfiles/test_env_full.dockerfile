FROM jenkins/inbound-agent:4.3-4

ARG DEBIAN_FRONTEND=noninteractive

USER root

RUN apt-get update && apt-get install -y gnupg2
RUN wget -O- http://neuro.debian.net/lists/xenial.us-ca.full | tee /etc/apt/sources.list.d/neurodebian.sources.list
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com 0xA5D32F012649A5A9
RUN apt-get -qy update

RUN apt-get install -qy singularity-container python3 python3-dev python3-pip mailutils gawk vim

ADD requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

RUN mkdir /singularity
WORKDIR /singularity

RUN singularity pull docker://gmsuppsala/somatic:develop
RUN singularity pull docker://broadinstitute/gatk:4.1.9.0
RUN singularity pull docker://ensemblorg/ensembl-vep:release_99.0
