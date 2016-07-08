FROM ubuntu:14.04

RUN sudo apt-get update
RUN sudo apt-get install openssh-server -y

RUN sudo apt-get install default-jre -y
RUN sudo apt-get install default-jdk -y
ENV JAVA_HOME=/usr/lib/jvm/default-java

RUN sudo apt-get install unzip -y
RUN sudo apt-get install rsync -y

RUN sudo apt-get install python -y
ADD https://bootstrap.pypa.io/get-pip.py get-pip.py
RUN python get-pip.py
RUN sudo pip install awscli
RUN sudo apt-get install jq -y

ADD http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip ec2-api-tools.zip
RUN unzip ec2-api-tools.zip
RUN mv ec2-api-tools-* /usr/local/bin/ec2-api-tools
ENV PATH=/usr/local/bin/ec2-api-tools/bin/:$PATH
ENV EC2_HOME=/usr/local/bin/ec2-api-tools
