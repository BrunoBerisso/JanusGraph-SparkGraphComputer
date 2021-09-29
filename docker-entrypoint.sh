#!/bin/bash

sudo service ssh start

if [ ! -d "/tmp/hadoop-hduser/dfs/name" ]; then
        $HADOOP_HOME/bin/hdfs namenode -format
fi

$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh
$HOME/hbase-2.3.6/bin/start-hbase.sh

echo "Copying JanusGraph zip files to HDFS..."
hdfs dfs -mkdir /tmp \
&& hdfs dfs -put $HOME/janusgraph-spark-0.5.3.jar /tmp \
&& hdfs dfs -put $HOME/spark-jars.zip /tmp \
&& rm $HOME/janusgraph-spark-0.5.3.jar && rm $HOME/spark-jars.zip

bash