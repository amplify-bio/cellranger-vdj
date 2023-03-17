# based upon https://github.com/melaniedavila/cellranger-aws-pipeline/blob/ab304fcd61d58ac8e3243254029d53926ea2df38/Dockerfile#L1

# 10x officially supports ubuntu or centos/redhat
FROM ubuntu:20.04

# something has tzdata as a dependency, so we need to disable interaction...
ARG DEBIAN_FRONTEND=noninteractive
# ...and set our timezone
ENV TZ "UTC"

# install our system dependencies
RUN apt-get update \
    && apt-get install -y wget alien unzip

# install bcl2fast since cellranger mkfastq command requires it.
# instead of building it, we start with the rpm and use alien to convert to a deb package, and then install it as a system package
RUN cd /opt \
    && wget -O bcl2fastq2-v2-20-0-linux-x86-64.zip "http://429d498b-0d7e-4fac-a39e-8c715daf58b3.s3.amazonaws.com/10x-genomics/software/bcl2fastq/bcl2fastq2-v2-20-0-linux-x86-64.zip" \
    && unzip bcl2fastq2-v2-20-0-linux-x86-64.zip \
    && alien bcl2fastq2-v2.20.0.422-Linux-x86_64.rpm \
    && dpkg -i bcl2fastq2_0v2.20.0.422-2_amd64.deb \
    && rm bcl2fastq2-v2-20-0-linux-x86-64.zip bcl2fastq2-v2.20.0.422-Linux-x86_64.rpm bcl2fastq2_0v2.20.0.422-2_amd64.deb

# install cellranger, and then clean up to save space
RUN cd /opt \
    && wget -O cellranger-5.0.1.tar.gz "http://429d498b-0d7e-4fac-a39e-8c715daf58b3.s3.amazonaws.com/10x-genomics/software/cellranger/cellranger-5.0.1.tar.gz" \
    && tar -xzvf cellranger-5.0.1.tar.gz \
    && rm cellranger-5.0.1.tar.gz

# cellranger and space ranger need to be added to our system path
ENV PATH "$PATH:/opt/cellranger-5.0.1"
