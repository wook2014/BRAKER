# Distributed under the terms of the Modified BSD License.
ARG OWNER=jupyter
ARG BASE_CONTAINER=$OWNER/minimal-notebook
FROM $BASE_CONTAINER

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    # for cython: https://cython.readthedocs.io/en/latest/src/quickstart/install.html
    build-essential \
    # for latex labels
    cm-super \
    dvipng \
    # for matplotlib anim
    ffmpeg \
    time && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN  apt update && \
     apt-get install -y --no-install-recommends \
     man-db \
     g++ \
     less \
     zlib1g-dev \
     && \
     apt-get clean && rm -rf /var/lib/apt/lists/*

RUN cd /opt && \ 
    git clone --recursive https://github.com/clwgg/seqstats && \
    cd seqstats && \
    make 
    
ENV PATH=${PATH}:/opt/seqstats

# cdbfasta
RUN cd /opt && \ 
    git clone https://github.com/gpertea/cdbfasta.git && \
    cd cdbfasta && \
    make 
    
ENV PATH=${PATH}:/opt/cdbfasta

# hisat2
RUN cd /opt && \ 
    git clone https://github.com/DaehwanKimLab/hisat2.git && \
    cd hisat2 && \
    make -j 16

ENV PATH=${PATH}:/opt/hisat2

# stringtie2 (ETP+)
RUN cd /opt && \
    wget http://ccb.jhu.edu/software/stringtie/dl/stringtie-2.2.1.Linux_x86_64.tar.gz && \
    tar -xvf stringtie-2.2.1.Linux_x86_64.tar.gz

ENV PATH=${PATH}:/opt/stringtie-2.2.1.Linux_x86_64

# gffread (ETP+)
RUN cd /opt && \
    git clone https://github.com/gpertea/gffread.git && \
    cd gffread && \
    make

ENV PATH=${PATH}:/opt/gffread

# diamond
RUN cd /opt && \
    mkdir diamond && \
    cd diamond && \
    wget http://github.com/bbuchfink/diamond/releases/download/v2.0.15/diamond-linux64.tar.gz && \
    tar -xf diamond-linux64.tar.gz && \
    rm diamond-linux64.tar.gz

ENV PATH=${PATH}:/opt/diamond

# tsebra
RUN cd /opt && \
    git clone https://github.com/Gaius-Augustus/TSEBRA && \
    cd TSEBRA && \
    git checkout braker3

ENV PATH=${PATH}:/opt/TSEBRA/bin

# makehub
RUN cd /opt && \
    git clone https://github.com/Gaius-Augustus/MakeHub.git && \
    cd MakeHub && \
    git checkout braker3 && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/bedToBigBed && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/genePredCheck && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/faToTwoBit && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/gtfToGenePred && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/hgGcPercent && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/ixIxx && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/twoBitInfo && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/wigToBigWig && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/genePredToBed && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/genePredToBigGenePred && \
    chmod u+x bedToBigBed genePredCheck faToTwoBit gtfToGenePred hgGcPercent ixIxx  twoBitInfo wigToBigWig genePredToBed genePredToBigGenePred make_hub.py

ENV PATH=${PATH}:/opt/MakeHub

# augustus

ENV AUGUSTUS_CONFIG_PATH=/usr/share/augustus/config/
ENV AUGUSTUS_BIN_PATH=/usr/bin/
ENV AUGUSTUS_SCRIPTS_PATH=/usr/share/augustus/scripts/

RUN apt update && \ 
    apt install -yq  augustus augustus-data augustus-doc && \
    apt clean all && \
    fix-permissions "${AUGUSTUS_CONFIG_PATH}"

# perl dependencies of BRAKER and GeneMark-ETP+

RUn apt update && \
    apt install -yq libyaml-perl libhash-merge-perl libparallel-forkmanager-perl libscalar-util-numeric-perl libclass-data-inheritable-perl libexception-class-perl libtest-pod-perl libfile-which-perl libmce-perl libthread-queue-perl libmath-utils-perl libscalar-list-utils-perl && \
    apt clean all
    

# bedtools (ETP+)

RUN apt update && \
    apt install -yq bedtools && \
    apt clean all

# sratools (ETP+)

RUN cd /opt && \
    wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz && \
    tar -xvf sratoolkit.current-ubuntu64.tar.gz

ENV PATH=${PATH}:/opt/sratoolkit.3.0.1-ubuntu64/bin/

# patch Augustus scripts (because Debian package is often outdated, this way we never need to worry)
RUN cd /usr/share/augustus/scripts && \
    rm optimize_augustus.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/optimize_augustus.pl && \
    rm aa2nonred.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/aa2nonred.pl && \
    rm gff2gbSmallDNA.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/gff2gbSmallDNA.pl && \
    rm new_species.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/new_species.pl && \
    rm filterGenesIn.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/filterGenesIn.pl && \
    rm filterGenesIn_mRNAname.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/filterGenesIn_mRNAname.pl && \
    rm filterGenes.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/filterGenes.pl && \
    rm join_mult_hints.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/join_mult_hints.pl && \
    rm randomSplit.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/randomSplit.pl && \
    rm join_aug_pred.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/join_aug_pred.pl && \
    rm getAnnoFastaFromJoingenes.py && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/getAnnoFastaFromJoingenes.py && \
    rm gtf2gff.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/gtf2gff.pl && \
    rm splitMfasta.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/splitMfasta.pl && \
    rm createAugustusJoblist.pl && \
    wget https://raw.githubusercontent.com/Gaius-Augustus/Augustus/master/scripts/createAugustusJoblist.pl && \
    chmod a+x optimize_augustus.pl aa2nonred.pl gff2gbSmallDNA.pl new_species.pl filterGenesIn_mRNAname.pl filterGenes.pl filterGenesIn.pl join_mult_hints.pl randomSplit.pl join_aug_pred.pl getAnnoFastaFromJoingenes.py gtf2gff.pl splitMfasta.pl createAugustusJoblist.pl

# bedtools (ETP+)

RUN apt update && \
    apt install -yq bedtools && \
    apt clean all

# include odb10 files for BRAKER3

RUN cd /opt && \
    mkdir odb && \
    cd odb && \
    wget https://v100.orthodb.org/download/odb10_arthropoda_fasta.tar.gz && \
    tar xvf odb10_arthropoda_fasta.tar.gz && \
    cat arthropoda/Rawdata/* > arthropoda_odb10.fasta && \
    rm -rf arthropoda && \
    wget https://v100.orthodb.org/download/odb10_fungi_fasta.tar.gz && \
    tar xvf odb10_fungi_fasta.tar.gz && \
    cat fungi/Rawdata/* > fungi_odb10.fasta && \
    rm -rf fungi && \
    wget https://v100.orthodb.org/download/odb10_metazoa_fasta.tar.gz && \
    tar xvf odb10_metazoa_fasta.tar.gz && \
    cat metazoa/Rawdata/* > metazoa_odb10.fasta && \
    rm -rf metazoa && \
    wget https://v100.orthodb.org/download/odb10_vertebrata_fasta.tar.gz && \
    tar xvf odb10_vertebrata_fasta.tar.gz && \
    cat vertebrate/Rawdata/* > vertebrata_odb10.fasta && \
    rm -rf vertebrate && \
    wget https://v100.orthodb.org/download/odb10_protozoa_fasta.tar.gz && \
    tar xvf odb10_protozoa_fasta.tar.gz && \
    cat protozoa/Rawdata/* > protozoa_odb10.fasta && \
    rm -rf protozoa && \
    wget https://v100.orthodb.org/download/odb10_plants_fasta.tar.gz && \
    tar xvf odb10_plants_fasta.tar.gz && \
    cat plants/Rawdata/* > plants_odb10.fasta && \
    rm -rf plants

USER ${NB_UID}

RUN mamba install --quiet -c bioconda -c anaconda --yes \
    biopython && \
    mamba clean  --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

WORKDIR "${HOME}"

USER root

# braker including RNAseq test file

RUN cd /opt && \
    git clone    https://github.com/Gaius-Augustus/BRAKER.git && \
    cd BRAKER && \
    git checkout braker3  && \
    cd example && \
    wget http://bioinf.uni-greifswald.de/augustus/datasets/RNAseq.bam

ENV PATH=${PATH}:/opt/BRAKER/scripts

USER ${NB_UID}
