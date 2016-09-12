# docker-solr

This is a Docker image for Apache Solr.

## What is Solr?

[Solr](http://lucene.apache.org/solr/) (pronounced "solar") is an open source enterprise search platform, written in Java, from the Apache Lucene project. Its major features include full-text search, hit highlighting, faceted search, real-time indexing, dynamic clustering, database integration, NoSQL features[1] and rich document (e.g., Word, PDF) handling. Providing distributed search and index replication, Solr is designed for scalability and Fault tolerance.

Learn more about Solr on the [Solr Wiki](https://cwiki.apache.org/confluence/display/solr/Apache+Solr+Reference+Guide).

## How to build this Docker image

```
$ git clone git@github.com:mosuka/docker-solr.git ${HOME}/git/docker-solr
$ cd ${HOME}/git/docker-solr
$ docker build -t mosuka/docker-solr:latest .
```

## How to pull this Docker image

```
$ docker pull mosuka/docker-solr:latest
```

## How to use this Docker image

### Standalone Solr example

#### 1. Start standalone Solr

```sh
$ docker run -d -p 8984:8983 --name solr -e ENABLE_CORS=true -e CORE_NAME=collection1 mosuka/docker-solr:6.1.0
8b141e3e7c23707c0615a36fe0590b1cd612f939b94663b27bb640be01f132f4
```

#### 2. Check container ID

```sh
$ docker ps
CONTAINER ID        IMAGE                      COMMAND                  CREATED              STATUS              PORTS                                         NAMES
8b141e3e7c23        mosuka/docker-solr:6.1.0   "/usr/local/bin/docke"   About a minute ago   Up About a minute   7983/tcp, 18983/tcp, 0.0.0.0:8984->8983/tcp   solr
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
$ SOLR_HOST_IP=${SOLR_HOST_IP:-127.0.0.1}
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

#### 6. Stop standalone Solr

```
$ docker stop solr; docker rm solr
solr
solr
```

### SolrCloud (2 shards across 4 nodes with replication factor 2) example

#### 1. Start Zookeeper

Run ZooKeeper. See following URL:

- Source: [https://github.com/mosuka/docker-zookeeper](https://github.com/mosuka/docker-zookeeper)
- Docker Image: [https://hub.docker.com/r/mosuka/docker-zookeeper/](https://hub.docker.com/r/mosuka/docker-zookeeper/)

#### 2. Start SolrCloud

```sh
$ docker run -d -p 8984:8983 --name=solr1 -e ENABLE_CORS=true -e COLLECTION_NAME=collection1 -e ZK_HOST=${ZOOKEEPER_CONTAINER_IP}:2181/solr -e NUM_SHARDS=2 -e REPLICATION_FACTOR=1 -e MAX_SHARDS_PER_NODE=1 mosuka/docker-solr:6.1.0
6c96fdc9e1f4381b4089eaaae975363d5fdbf8faac33f125032639ad9278fb6a

$ docker run -d -p 8985:8983 --name=solr2 -e ENABLE_CORS=true -e COLLECTION_NAME=collection1 -e ZK_HOST=${ZOOKEEPER_CONTAINER_IP}:2181/solr -e NUM_SHARDS=2 -e REPLICATION_FACTOR=1 -e MAX_SHARDS_PER_NODE=1 mosuka/docker-solr:6.1.0
c0b731cdc77c0768b9be4fee45751901c5add257ea3607499a62011fc771081e

$ docker run -d -p 8986:8983 --name=solr3 -e ENABLE_CORS=true -e COLLECTION_NAME=collection1 -e ZK_HOST=${ZOOKEEPER_CONTAINER_IP}:2181/solr -e NUM_SHARDS=2 -e REPLICATION_FACTOR=1 -e MAX_SHARDS_PER_NODE=1 mosuka/docker-solr:6.1.0
5bdd4d24193367598af4106ce70308bdbe5de334d6be457182ec482447e519de

$ docker run -d -p 8987:8983 --name=solr4 -e ENABLE_CORS=true -e COLLECTION_NAME=collection1 -e ZK_HOST=${ZOOKEEPER_CONTAINER_IP}:2181/solr -e NUM_SHARDS=2 -e REPLICATION_FACTOR=1 -e MAX_SHARDS_PER_NODE=1 mosuka/docker-solr:6.1.0
0a23aa37712fb037d98b0f2021ee8e2c216e300233b440673221045009e0183a
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
$ COLLECTION_CONFIG_NAME=data_driven_schema_configs
$ NUM_SHARDS=2
$ REPLICATION_FACTOR=2
$ docker exec -it solr1 ./bin/solr create_collection -c ${COLLECTION_NAME} -d ${COLLECTION_CONFIG_NAME} -n ${COLLECTION_NAME}_config -shards ${NUM_SHARDS} -replicationFactor ${REPLICATION_FACTOR}

Connecting to ZooKeeper at 172.17.0.2:2181,172.17.0.3:2181,172.17.0.4:2181/solr ...
Uploading /opt/solr-5.5.0/server/solr/configsets/data_driven_schema_configs/conf for config collection1_config to ZooKeeper at 172.17.0.2:2181,172.17.0.3:2181,172.17.0.4:2181/solr

Creating new collection 'collection1' using command:
http://localhost:8983/solr/admin/collections?action=CREATE&name=collection1&numShards=2&replicationFactor=2&maxShardsPerNode=1&collection.configName=collection1_config

{
  "responseHeader":{
    "status":0,
    "QTime":21682},
  "success":{"":{
      "responseHeader":{
        "status":0,
        "QTime":20873},
      "core":"collection1_shard2_replica1"}}}
```

#### 8. Stop SolrCloud

```
$ docker stop solr1 solr2 solr3 solr4; docker rm solr1 solr2 solr3 solr4
solr1
solr2
solr3
solr4
solr1
solr2
solr3
solr4
```
