# Creates pseudo distributed hadoop 2.7.1
#
# sudo docker build -t yarn_cluster .

FROM sequenceiq/pam:centos-6.5
MAINTAINER JiaHao Cheng jiahao0428@gmail.com

USER root

# install dev tools
RUN yum install -y curl which tar sudo openssh-server openssh-clients rsync | true && \
    yum update -y libselinux | true && \
    yum install dnsmasq -y && \
    echo source /etc/bashrc > /root/.bash_profile && \
    echo user=root >> /etc/dnsmasq.conf && \
    echo bogus-priv >> /etc/dnsmasq.conf && \
    echo interface=eth0 >> /etc/dnsmasq.conf && \
    echo no-dhcp-interface=eth0 >> /etc/dnsmasq.conf

# passwordless ssh
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# java
ADD jdk-8u73-linux-x64.rpm /tmp/
RUN rpm -i /tmp/jdk-8u73-linux-x64.rpm && \
    rm /tmp/jdk-8u73-linux-x64.rpm

# hadoop
ADD hadoop-2.7.1.tar.gz /usr/local/
RUN cd /usr/local && ln -s ./hadoop-2.7.1 hadoop && \
    rm  /usr/local/hadoop/lib/native/*

# sbt
RUN curl https://bintray.com/sbt/rpm/rpm | tee /etc/yum.repos.d/bintray-sbt-rpm.repo
RUN yum install -y sbt

# pip
RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum install -y python-pip

# fixing the libhadoop.so like a boss
ADD hadoop-native-64-2.7.0.tar /usr/local/hadoop/lib/native/

ENV HADOOP_PREFIX=/usr/local/hadoop \
    HADOOP_COMMON_HOME=/usr/local/hadoop \
    HADOOP_HDFS_HOME=/usr/local/hadoop \
    HADOOP_MAPRED_HOME=/usr/local/hadoop \
    HADOOP_YARN_HOME=/usr/local/hadoop \
    HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop \
    YARN_CONF_DIR=$HADOOP_PREFIX/etc/hadoop \
    JAVA_HOME=/usr/java/default \
    SPARK_HOME=/usr/local/spark \
    SPARK_YARN_QUEUE=dev \
    SCALA_HOME=/usr/local/scala \
    ELASTICSEARCH_HOME=/usr/local/elasticsearch \
    KIBANA_HOME=/usr/local/kibana \
    TERM=xterm
 
ENV PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HDFS_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$SCALA_HOME/bin:$ELASTICSEARCH_HOME/bin:$KIBANA_HOME/bin:.

ENV alias elasticsearch='elasticsearch -Des.insecure.allow.root=true'

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/java/default\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && \
    sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && \
    mkdir $HADOOP_PREFIX/input && \
    cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

# pseudo distributed
ADD core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml
#RUN sed s/HOSTNAME/localhost/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
ADD hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

ADD mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

RUN $HADOOP_PREFIX/bin/hdfs namenode -format

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config && \
    chown root:root /root/.ssh/config

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && \
    chmod 700 /etc/bootstrap.sh

ENV BOOTSTRAP /etc/bootstrap.sh

# workingaround docker.io build error
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh && \
    chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh && \
    ls -la /usr/local/hadoop/etc/hadoop/*-env.sh

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config && \
    echo "Port 2122" >> /etc/ssh/sshd_config

#Spark
ADD spark-1.6.1-bin-hadoop2.6.tgz /usr/local
ADD scala-2.10.4.tgz /usr/local
RUN cd /usr/local && ln -s ./spark-1.6.1-bin-hadoop2.6 spark && \
    cd /usr/local && ln -s ./scala-2.10.4 scala
    
#Elasticsearch
#ADD elasticsearch-2.2.1.tar.gz /usr/local
#RUN cd /usr/local && ln -s ./elasticsearch-2.2.1 elasticsearch

#kibana
#ADD kibana-4.4.2-linux-x64.tar.gz /usr/local
#RUN cd /usr/local && ln -s ./kibana-4.4.2-linux-x64 kibana

CMD ["/etc/bootstrap.sh", "-d"]

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 19888 8030 8031 8032 8033 8040 8042 8088 49707 2122
# Mapred ports
#EXPOSE 19888
#Yarn ports
#EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
#EXPOSE 49707 2122
# ElasticSearch Port
#EXPOSE 9200

