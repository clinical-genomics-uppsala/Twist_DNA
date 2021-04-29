FROM centos:8

RUN yum update -y && \
    yum install -y epel-release && \
    yum update -y && \
    yum install -y singularity-runtime singularity mailx  && \
    yum install -y python38-devel python38-pip



RUN mkdir /Twist_DNA

WORKDIR /Twist_DNA

ADD ./ .

USER root

RUN ln -s /beegfs-storage/data /data
RUN ln -s /beegfs-storage/projects /projects

RUN cp -r tests/workflow_dry_run/gms_somatic /data_gms_somatic

RUN cp -r tests/workflow_dry_run/demultiplex /data_demultiplex


RUN cp -r tests/workflow_dry_run/twist_dna /data_twist_dna_fgbio
RUN cp tests/workflow_dry_run/twist_dna/configs/Twist_DNA_dup_fgbio.yaml /data_twist_dna_fgbio/Twist_DNA.yaml

RUN cp -r tests/workflow_dry_run/twist_dna /data_twist_dna_markdup
RUN cp tests/workflow_dry_run/twist_dna/configs/Twist_DNA_dup_markduplicates.yaml /data_twist_dna_markdup/Twist_DNA.yaml

RUN cp -r tests/workflow_dry_run/twist_dna /data_twist_dna_gpu
RUN cp tests/workflow_dry_run/twist_dna/configs/Twist_DNA_gpu.yaml  /data_twist_dna_gpu/Twist_DNA.yaml

RUN cp -r tests/workflow_dry_run/twist_dna /data_twist_dna_cutadapt
RUN cp tests/workflow_dry_run/twist_dna/configs/Twist_DNA_cutadapt.yaml  /data_twist_dna_cutadapt/Twist_DNA.yaml

RUN cp -r tests/workflow_dry_run/twist_dna /data_twist_dna_fastp
RUN cp tests/workflow_dry_run/twist_dna/configs/Twist_DNA_fastp.yaml  /data_twist_dna_fastp/Twist_DNA.yaml



RUN pip3 install -r requirements.txt
