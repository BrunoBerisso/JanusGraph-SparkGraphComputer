# JanusGraph - SparkGraphComputer

This image is based in a public [Hadoop Single Node Cluster](https://github.com/rancavil/hadoop-single-node-cluster.git) Dockerfile. 
This version adds Spark, Hbase and JanusGraph to the mix using the following versions:
- Hadoop 3.0.0
- Spark 2.4
- Hbase 2.3.6
- JanusGraph 0.5.3

### Build the image

```sh
$ docker build -t janusgraph-spark .
```

### Creating the container

```sh
$ docker run -it --name <container-name> -p 9864:9864 -p 9870:9870 -p 8088:8088 -p 8040:8040 -p 8042:8042 --hostname <your-hostname> janusgraph-spark
```

After the first run you can re start the container with:

```sh
$ docker start -i <container-name>
```

The container entry point will land in an interactive bash session when tests can be performed. To start a gremlin session run:
```sh
$ cd janusgraph-0.5.3
$ ./run-gremlin.sh
```

### Access UI

Hadoop - http://localhost:9870
Yarn   - http://localhost:8088/

Click around to navigate to the Spark UI and get see logs.

## Tests SparkGraphComputer

The Spark test case used was the following

1. Create the graph using `JanusGraphFactory`. This will create the table in HBase:
```groovy
gremlin> graph = JanusGraphFactory.open('conf/janusgraph-hbase.properties')
==>standardjanusgraph[hbase:[127.0.0.1]]
gremlin> graph.close()
==>null
gremlin> :exit
```

2. Run the gremlin shell or start the server with using the "run" scripts inside the JanusGraph installation folder.

3. If run in the interactive shell, open the graph using one of _client-mode-graph.properties_ or _cluster-mode-graph.properties_ files:
```groovy
gremlin> graph = GraphFactory.open(<name of the file>)
==>hadoopgraph[hbaseinputformat->nulloutputformat]
gremlin> g = graph.traversal().withComputer(SparkGraphComputer)
==>graphtraversalsource[hadoopgraph[hbaseinputformat->nulloutputformat], sparkgraphcomputer]
gremlin> g.V().count()
```

4. If you are connecting to the JanusGraph server, there should be two traversal sources:
- `cluster_graph_t` which will use cluster deploy-mode
- `client_graph_t` which will use client deploy-mode
