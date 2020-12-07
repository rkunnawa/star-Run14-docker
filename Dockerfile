# Use latest CentOs image as base image
FROM centos:latest

# Prepare dependencies for build
RUN yum groupinstall -y 'Development Tools'

# Install CERN ROOT package and its dependencies
RUN yum install -y epel-release && yum install -y root rsync wget which
WORKDIR /opt

# We need cmake >= 3.13.5 for the analysis package heppy
RUN cd /opt \
&& wget https://github.com/Kitware/CMake/releases/download/v3.17.0/cmake-3.17.0-Linux-x86_64.sh \
&& echo "y" | bash ./cmake-3.17.0-Linux-x86_64.sh \
&& ln -s /opt/cmake-3.17.0-Linux-x86_64/bin/* /usr/local/bin

# Install Pythia8 model
RUN wget http://home.thep.lu.se/~torbjorn/pythia8/pythia8303.tgz && \
    tar -xvzf pythia8303.tgz
WORKDIR /opt/pythia8303/
RUN ./configure && \
    make && \
    make install

# Install FastJet
WORKDIR /opt
RUN wget http://fastjet.fr/repo/fastjet-3.3.4.tar.gz  && \
    tar -xvzf fastjet-3.3.4.tar.gz && \
    mkdir fastjet
WORKDIR /opt/fastjet-3.3.4/
RUN ./configure --prefix=/opt/fastjet && \
    make && \
    make install
WORKDIR /opt

# Install FastJet contrib
RUN wget http://fastjet.hepforge.org/contrib/downloads/fjcontrib-1.045.tar.gz && \
    tar -xvzf fjcontrib-1.045.tar.gz
WORKDIR /opt/fjcontrib-1.045
RUN ./configure --fastjet-config=/opt/fastjet/bin/fastjet-config && \
    make && \
    make install

# Install RooUnfold
WORKDIR /opt
RUN git clone https://gitlab.cern.ch/RooUnfold/RooUnfold.git
WORKDIR /opt/RooUnfold
RUN make

# Install Jet Reader
WORKDIR /opt
RUN git clone --recurse-submodules git@github.com:nickelsey/jetreader.git \
&& cd jetreader && mkdir build && cd build \
&& cmake -DCMAKE_INSTALL_PREFIX=/opt/jetreader-build .. \ 
&& make && make install

# Install TStarJetPico for embedding files
WORKDIR /opt
RUN git clone https://github.com/imooney/eventStructuredAu.git
WORKDIR /opt/eventStructuredAu
RUN make 

# Set PATH variables
ENV PATH=/opt/pythia8303/bin/:/opt/fastjet/bin/:/opt/jetreader-build/:/opt/eventStructuredAu/:/opt/RooUnfold/:$PATH

RUN mkdir /star_run14
WORKDIR /star_run14
ENTRYPOINT ["/bin/bash"]
