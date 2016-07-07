FROM centos:6

RUN yum -y update
RUN yum -y groupinstall "Development tools"
RUN yum -y install ed
RUN yum -y install readline-devel
RUN yum -y install zlib-devel
RUN yum -y install curl-devel
RUN yum -y install bzip2-devel
RUN yum -y install python-devel
RUN yum -y install apr-devel
RUN yum -y install libevent-devel
RUN yum -y install openssl-libs openssl-devel
RUN yum -y install libyaml libyaml-devel
RUN yum -y install epel-release
RUN yum -y install htop
RUN yum -y install ccache
RUN yum -y install libffi-devel
RUN yum -y install iproute
RUN yum -y install net-tools
RUN yum -y install openssh-server
RUN yum -y install perl-devel
RUN yum -y install perl-CPAN
RUN yum -y install perl-ExtUtils-Embed
RUN yum -y install libxml2-devel
RUN yum -y install java-1.8.0-openjdk*
RUN yum -y install pam-devel
RUN yum -y install wget

ADD https://bootstrap.pypa.io/get-pip.py /
RUN python /get-pip.py
RUN pip install psutil lockfile paramiko setuptools epydoc
RUN rm /get-pip.py

# Misc
RUN yum -y install vim mc psmisc

# cmake 3.0
WORKDIR /root

ADD http://www.cmake.org/files/v3.0/cmake-3.0.0.tar.gz ./
RUN tar -zxvf cmake-3.0.0.tar.gz
WORKDIR cmake-3.0.0
RUN ./bootstrap
RUN make
RUN make install
ENV PATH=/usr/local/bin:$PATH

# compile GPDB

WORKDIR /workspace

ADD . gpdb/

WORKDIR gpdb

WORKDIR gpAux

ENV BLD_ARCH=rhel5_x86_64
ENV BLD_TOP=/workspace/gpdb/gpAux
ENV GPROOT=/usr/local

RUN make sync_tools
RUN make dist

WORKDIR /workspace/gpdb

RUN ./docker/prep_for_ssh.bash

RUN chmod u+s `which ping`
