# docker-solr

This is a Docker image for Apache Solr.

## What is Solr?

[Solr](http://lucene.apache.org/solr/) (pronounced "solar") is an open source enterprise search platform, written in Java, from the Apache Lucene project. Its major features include full-text search, hit highlighting, faceted search, real-time indexing, dynamic clustering, database integration, NoSQL features[1] and rich document (e.g., Word, PDF) handling. Providing distributed search and index replication, Solr is designed for scalability and Fault tolerance.

Learn more about Solr on the [Solr Wiki](https://cwiki.apache.org/confluence/display/solr/Apache+Solr+Reference+Guide).

## How to use this Docker image

### Standalone Solr example

#### 1. Start standalone Solr

```sh
$ docker run -d -p 8984:8983 --name solr mosuka/docker-solr:release-5.5
3f2efe1c75316e53b19e90df4c13210a16eac3b88e0c161c07ce05e883bed270
```

#### 2. Check container ID

```sh
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED             STATUS              PORTS                                         NAMES
3f2efe1c7531        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   2 minutes ago       Up 2 minutes        7983/tcp, 18983/tcp, 0.0.0.0:8984->8983/tcp   solr
```

#### 3. Get container IP

```sh
$ SOLR_CONTAINER_IP=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' solr)
$ echo ${SOLR_CONTAINER_IP}
172.17.0.2
```

#### 4. Get host IP and port

```sh
$ SOLR_HOST_IP=$(docker-machine ip default)
$ echo ${SOLR_HOST_IP}
192.168.99.100

$ SOLR_HOST_PORT=$(docker inspect -f '{{ $port := index .NetworkSettings.Ports "8983/tcp" }}{{ range $port }}{{ .HostPort }}{{ end }}' solr)
$ echo ${SOLR_HOST_PORT}
8984
```

#### 5. Open Solr Admin UI in a browser

```sh
$ SOLR_ADMIN_UI=http://${SOLR_HOST_IP}:${SOLR_HOST_PORT}/solr/#/
$ echo ${SOLR_ADMIN_UI}
http://192.168.99.100:8984/solr/#/
```

Open Solr Admin UI in a browser.

#### 6. Create core

```sh
$ CORE_NAME=collection1
$ CONFIG_SET=data_driven_schema_configs
$ DATA_DIR=data
$ curl -s "http://${SOLR_HOST_IP}:${SOLR_HOST_PORT}/solr/admin/cores?action=CREATE&name=${CORE_NAME}&configSet=${CONFIG_SET}&dataDir=${DATA_DIR}" | xmllint --format -
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <lst name="responseHeader">
    <int name="status">0</int>
    <int name="QTime">2944</int>
  </lst>
  <str name="core">collection1</str>
</response>
```

#### 7. Stop standalone Solr

```
$ docker stop solr
solr

$ docker rm solr
solr
```

### SolrCloud (2 shards across 4 nodes with replication factor 2) example

#### 1. Start Zookeeper ensemble

Run ZooKeeper ensemble.

See [https://github.com/mosuka/docker-zookeeper/tree/master/3.5](https://github.com/mosuka/docker-zookeeper/tree/master/3.5).

#### 2. Start Solr

```sh
$ docker run -d -p 8984:8983 --name=solr1 \
    -e ZK_HOST=${ZOOKEEPER_1_CONTAINER_IP}:2181,${ZOOKEEPER_2_CONTAINER_IP}:2181,${ZOOKEEPER_3_CONTAINER_IP}:2181/solr \
    mosuka/docker-solr:release-5.5
050266bf5d3ceb57722739c2a234f50a1da64257b9084637fb7d8fb7fec1706d

$ docker run -d -p 8985:8983 --name=solr2 \
    -e ZK_HOST=${ZOOKEEPER_1_CONTAINER_IP}:2181,${ZOOKEEPER_2_CONTAINER_IP}:2181,${ZOOKEEPER_3_CONTAINER_IP}:2181/solr \
    mosuka/docker-solr:release-5.5
a9389a7561bc82519bd937c7a198426d055efc1368a97570a4c61e51c3c81831

$ docker run -d -p 8986:8983 --name=solr3 \
    -e ZK_HOST=${ZOOKEEPER_1_CONTAINER_IP}:2181,${ZOOKEEPER_2_CONTAINER_IP}:2181,${ZOOKEEPER_3_CONTAINER_IP}:2181/solr \
    mosuka/docker-solr:release-5.5
1c51e85239070b1c6abbb3960410f37ba31adea4af576e235cc6f2f9559e3d40

$ docker run -d -p 8987:8983 --name=solr4 \
    -e ZK_HOST=${ZOOKEEPER_1_CONTAINER_IP}:2181,${ZOOKEEPER_2_CONTAINER_IP}:2181,${ZOOKEEPER_3_CONTAINER_IP}:2181/solr \
    mosuka/docker-solr:release-5.5
dabeb0bb021aa74d49fcae174fddf63dc68b2e93c071d67e2650392b1cf18f4c
```

#### 3. Check container ID

```sh
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED              STATUS              PORTS                                         NAMES
050266bf5d3c        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   11 seconds ago       Up 11 seconds       7983/tcp, 18983/tcp, 0.0.0.0:8987->8983/tcp   solr4
a9389a7561bc        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   28 seconds ago       Up 27 seconds       7983/tcp, 18983/tcp, 0.0.0.0:8986->8983/tcp   solr3
1c51e8523907        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   45 seconds ago       Up 45 seconds       7983/tcp, 18983/tcp, 0.0.0.0:8985->8983/tcp   solr2
dabeb0bb021a        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   About a minute ago   Up About a minute   7983/tcp, 18983/tcp, 0.0.0.0:8984->8983/tcp   solr1
fc8b3b3ed997        mosuka/docker-zookeeper:release-3.5   "/usr/local/bin/docke"   18 hours ago         Up 18 hours         2888/tcp, 3888/tcp, 0.0.0.0:2182->2181/tcp    zookeeper```

#### 4. Get container IP and port

```sh
$ SOLR_1_CONTAINER_IP=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' solr1)
$ echo ${SOLR_1_CONTAINER_IP}
172.17.0.5

$ SOLR_2_CONTAINER_IP=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' solr2)
$ echo ${SOLR_2_CONTAINER_IP}
172.17.0.6

$ SOLR_3_CONTAINER_IP=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' solr3)
$ echo ${SOLR_3_CONTAINER_IP}
172.17.0.7

$ SOLR_4_CONTAINER_IP=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' solr4)
$ echo ${SOLR_4_CONTAINER_IP}
172.17.0.8
```

#### 5. Get host IP and port

```sh
$ SOLR_HOST_IP=$(docker-machine ip default)
$ echo ${SOLR_HOST_IP}
192.168.99.100

$ SOLR_1_HOST_PORT=$(docker inspect -f '{{ $port := index .NetworkSettings.Ports "8983/tcp" }}{{ range $port }}{{ .HostPort }}{{ end }}' solr1)
$ echo ${SOLR_1_HOST_PORT}
8984

$ SOLR_2_HOST_PORT=$(docker inspect -f '{{ $port := index .NetworkSettings.Ports "8983/tcp" }}{{ range $port }}{{ .HostPort }}{{ end }}' solr2)
$ echo ${SOLR_2_HOST_PORT}
8985

$ SOLR_3_HOST_PORT=$(docker inspect -f '{{ $port := index .NetworkSettings.Ports "8983/tcp" }}{{ range $port }}{{ .HostPort }}{{ end }}' solr3)
$ echo ${SOLR_3_HOST_PORT}
8986

$ SOLR_4_HOST_PORT=$(docker inspect -f '{{ $port := index .NetworkSettings.Ports "8983/tcp" }}{{ range $port }}{{ .HostPort }}{{ end }}' solr4)
$ echo ${SOLR_4_HOST_PORT}
8987
```

#### 6. Open Solr Admin UI in a browser

```sh
$ SOLR_1_ADMIN_UI=http://${SOLR_HOST_IP}:${SOLR_1_HOST_PORT}/solr/#/
$ echo ${SOLR_1_ADMIN_UI}
http://192.168.99.100:8984/solr/#/

$ SOLR_2_ADMIN_UI=http://${SOLR_HOST_IP}:${SOLR_2_HOST_PORT}/solr/#/
$ echo ${SOLR_2_ADMIN_UI}
http://192.168.99.100:8985/solr/#/

$ SOLR_3_ADMIN_UI=http://${SOLR_HOST_IP}:${SOLR_3_HOST_PORT}/solr/#/
$ echo ${SOLR_3_ADMIN_UI}
http://192.168.99.100:8986/solr/#/

$ SOLR_4_ADMIN_UI=http://${SOLR_HOST_IP}:${SOLR_4_HOST_PORT}/solr/#/
$ echo ${SOLR_4_ADMIN_UI}
http://192.168.99.100:8987/solr/#/
```

Open Solr Admin UI in a browser.

#### 7. Create Collection

```sh
$ COLLECTION_NAME=collection1
$ NUM_SHARDS=2
$ COLLECTION_CONFIG_NAME=data_driven_schema_configs
$ REPLICATION_FACTOR=2
$ MAX_SHARDS_PER_NODE=10
$ CREATE_NODE_SET=$(echo $(curl -s "http://${SOLR_HOST_IP}:${SOLR_1_HOST_PORT}/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq -r ".cluster.live_nodes[]") | sed -e 's/ /,/g')
$ curl -s "http://${SOLR_HOST_IP}:${SOLR_1_HOST_PORT}/solr/admin/collections?action=CREATE&name=${COLLECTION_NAME}&numShards=${NUM_SHARDS}&replicationFactor=${REPLICATION_FACTOR}&maxShardsPerNode=${MAX_SHARDS_PER_NODE}&createNodeSet=${CREATE_NODE_SET}&collection.configName=${COLLECTION_CONFIG_NAME}" | xmllint --format -
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <lst name="responseHeader">
    <int name="status">0</int>
    <int name="QTime">22212</int>
  </lst>
  <lst name="success">
    <lst>
      <lst name="responseHeader">
        <int name="status">0</int>
        <int name="QTime">16029</int>
      </lst>
      <str name="core">collection1_shard2_replica2</str>
    </lst>
    <lst>
      <lst name="responseHeader">
        <int name="status">0</int>
        <int name="QTime">16688</int>
      </lst>
      <str name="core">collection1_shard2_replica1</str>
    </lst>
    <lst>
      <lst name="responseHeader">
        <int name="status">0</int>
        <int name="QTime">21176</int>
      </lst>
      <str name="core">collection1_shard1_replica1</str>
    </lst>
    <lst>
      <lst name="responseHeader">
        <int name="status">0</int>
        <int name="QTime">21608</int>
      </lst>
      <str name="core">collection1_shard1_replica2</str>
    </lst>
  </lst>
</response>
```

#### 8. Stop standalone Solr

```
$ docker stop solr1 solr2 solr3 solr4
solr

$ docker rm solr1 solr2 solr3 solr4
solr
```
