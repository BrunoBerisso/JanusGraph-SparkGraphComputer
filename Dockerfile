FROM ubuntu:18.04

RUN apt-get update -y && apt-get install -y vim wget ssh openjdk-8-jdk sudo zip unzip tmux

# Setup hduser
RUN useradd -m hduser && echo "hduser:supergroup" | chpasswd && adduser hduser sudo && echo "hduser     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && cd /usr/bin/ && sudo ln -s python3 python
COPY ssh_config /etc/ssh/ssh_config

USER hduser
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys

WORKDIR /home/hduser
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Install Hadoop 3.0.0
RUN wget -q https://archive.apache.org/dist/hadoop/common/hadoop-3.0.0/hadoop-3.0.0.tar.gz && tar zxvf hadoop-3.0.0.tar.gz && rm hadoop-3.0.0.tar.gz

# Install Spark 2.4
RUN wget -q https://archive.apache.org/dist/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz && tar zxvf spark-2.4.0-bin-hadoop2.7.tgz && rm spark-2.4.0-bin-hadoop2.7.tgz

# Install Hbase 2.3.6
RUN wget -q https://dlcdn.apache.org/hbase/stable/hbase-2.3.6-bin.tar.gz && tar zxvf hbase-2.3.6-bin.tar.gz && rm hbase-2.3.6-bin.tar.gz

# Install JanusGraph 0.5.3
RUN wget -q https://github.com/JanusGraph/janusgraph/releases/download/v0.5.3/janusgraph-0.5.3.zip && unzip -q janusgraph-0.5.3.zip && rm janusgraph-0.5.3.zip

# Configure Hadoop
ENV HDFS_NAMENODE_USER hduser
ENV HDFS_DATANODE_USER hduser
ENV HDFS_SECONDARYNAMENODE_USER hduser

ENV YARN_RESOURCEMANAGER_USER hduser
ENV YARN_NODEMANAGER_USER hduser

ENV HADOOP_HOME /home/hduser/hadoop-3.0.0
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
COPY --chown=hduser:hduser core-site.xml $HADOOP_HOME/etc/hadoop/
COPY --chown=hduser:hduser hdfs-site.xml $HADOOP_HOME/etc/hadoop/
COPY --chown=hduser:hduser yarn-site.xml $HADOOP_HOME/etc/hadoop/

ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Configure Hbase
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /home/hduser/hbase-2.3.6/conf/hbase-env.sh
COPY --chown=hduser:hduser hbase-site.xml /home/hduser/hbase-2.3.6/conf/

# Configure JanusGraph
COPY --chown=hduser:hduser client-mode-graph.properties /home/hduser/janusgraph-0.5.3/
COPY --chown=hduser:hduser cluster-mode-graph.properties /home/hduser/janusgraph-0.5.3/
COPY --chown=hduser:hduser empty-sample.groovy /home/hduser/janusgraph-0.5.3/scripts/empty-sample.groovy
COPY --chown=hduser:hduser gremlin-server.yaml /home/hduser/janusgraph-0.5.3/conf/gremlin-server/gremlin-server.yaml
COPY --chown=hduser:hduser run-gremlin.sh /home/hduser/janusgraph-0.5.3/
COPY --chown=hduser:hduser run-gremlin-server.sh /home/hduser/janusgraph-0.5.3/

# The following steps are required to use the SparkGraphComputer.
# 1 - Grab the uber jar from Expero JanusGraph training repo
RUN wget -q https://github.com/experoinc/janusgraph-training/releases/download/v1.0.2/janusgraph-spark-0.5.3.jar
# 2 - Create another zip with only the Spark jars
RUN mkdir spark-jars && cd spark-jars && cp /home/hduser/spark-2.4.0-bin-hadoop2.7/jars/* . \
  && zip spark-jars.zip * && mv spark-jars.zip /home/hduser && cd /home/hduser && rm -rf spark-jars
# 3 - The third step will be copy this files to the right location in HDFS. The locations will be
# - janusgraph-spark-0.5.3.jar to hdfs://localhost:9000/tmp/janusgraph-spark-0.5.3.jar
# - spark-jars.zip to hdfs://localhost:9000/tmp/spark-jars.zip
#
# This is done in the docker-entrypoint.sh because we need HDFS running. These paths are being set in spark-graph.properties

COPY --chown=hduser:hduser docker-entrypoint.sh /home/hduser
EXPOSE 50070 50075 50010 50020 50090 8020 9000 9864 9870 10020 19888 8088 8030 8031 8032 8033 8040 8042 22 2181 16010 8080 8081 7077 4040
ENTRYPOINT ["/home/hduser/docker-entrypoint.sh"]
