# docker-solr

## Standalone Solr example

### 1. Start standalone Solr

```sh
$ docker run -d -p 18983:8983 --name solr mosuka/docker-solr:release-5.5
032dd48d12496c65a3405da483c4c16e4c9b26f3f7e22e0592717cfbd5830110
```

### 2. Check container ID

```sh
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED             STATUS              PORTS                                         NAMES
032dd48d1249        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   15 seconds ago      Up 14 seconds       0.0.0.0:18983->8983/tcp                       solr
```

### 3. Get container IP

```sh
$ docker inspect -f '{{ .NetworkSettings.IPAddress }}' 032dd48d1249
172.17.0.3
```

### 4. Get host IP

```sh
$ docker-machine ip default
192.168.99.100
```

### 5. Open URL in a browser

Open Solr Admin([http://192.168.99.100:18983/solr/#/](http://192.168.99.100:18983/solr/#/)) in a browser.



## SolrCloud (2 shards across 4 nodes with replication factor 2) example

### 1. Start Zookeeper ensemble

See [ZooKeeper ensemble example](https://hub.docker.com/r/mosuka/docker-zookeeper/).

### 1. Start 1st Solr

```sh
$ docker run -d --net=network1 -p 18983:8983 --name=solr1 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
1b2b1b962dde9501a255d3cd7d3c5837035bb7ea0a9b3c0242a13ac6f0c49d5a
```

### 2. Start 2nd Solr

```sh
$ docker run -d --net=network1 -p 28983:8983 --name=solr2 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
b8c8bb8615f4217a2c0ea49b484fa85332feeef44a06ce5f276fadf0d3883279
```

### 3. Start 3rd Solr

```sh
$ docker run -d --net=network1 -p 38983:8983 --name=solr3 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
4d56b0e34538d343c465620139ad49174087088b13052b432f8e1ff6e5604741
```

### 4. Start 4th Solr

```sh
$ docker run -d --net=network1 -p 48983:8983 --name=solr4 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
3071d9db2c4d55176b5a04fb3fd1cb153edb5fa16719b82acbaa1e3a4b266a3e
```

### 5. Check container ID

```sh
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED              STATUS              PORTS                                         NAMES
3071d9db2c4d        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   13 seconds ago       Up 12 seconds       7983/tcp, 0.0.0.0:48983->8983/tcp             solr4
4d56b0e34538        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   23 seconds ago       Up 23 seconds       7983/tcp, 0.0.0.0:38983->8983/tcp             solr3
b8c8bb8615f4        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   34 seconds ago       Up 34 seconds       7983/tcp, 0.0.0.0:28983->8983/tcp             solr2
1b2b1b962dde        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   About a minute ago   Up About a minute   7983/tcp, 0.0.0.0:18983->8983/tcp             solr1
432afd32772c        mosuka/docker-zookeeper:release-3.4   "/usr/local/bin/docke"   9 hours ago          Up 9 hours          2888/tcp, 3888/tcp, 0.0.0.0:32181->2181/tcp   zookeeper3
d0c05513b4fd        mosuka/docker-zookeeper:release-3.4   "/usr/local/bin/docke"   9 hours ago          Up 9 hours          2888/tcp, 3888/tcp, 0.0.0.0:22181->2181/tcp   zookeeper2
fc366f620f79        mosuka/docker-zookeeper:release-3.4   "/usr/local/bin/docke"   9 hours ago          Up 9 hours          2888/tcp, 3888/tcp, 0.0.0.0:12181->2181/tcp   zookeeper1
```

### 6. Get container IP of 1st Solr

```sh
$ docker inspect -f '{{ .NetworkSettings.Networks.network1.IPAddress }}' solr1
172.18.0.5
```

### 7. Get container IP of 2nd Solr

```sh
$ docker inspect -f '{{ .NetworkSettings.Networks.network1.IPAddress }}' solr2
172.18.0.6
```

### 8. Get container IP of 3rd Solr

```sh
$ docker inspect -f '{{ .NetworkSettings.Networks.network1.IPAddress }}' solr3
172.18.0.7
```

### 9. Get container IP of 4th Solr

```sh
$ docker inspect -f '{{ .NetworkSettings.Networks.network1.IPAddress }}' solr4
172.18.0.8
```

### 10. Get host IP

```sh
$ docker-machine ip default
192.168.99.100
```

### 11. Create a collection

```sh
$ curl "http://192.168.99.100:18983/solr/admin/collections?action=CREATE&name=collection1&numShards=2&replicationFactor=2&maxShardsPerNode=1&createNodeSet=172.18.0.5:8983_solr,172.18.0.6:8983_solr,172.18.0.7:8983_solr,172.18.0.8:8983_solr&collection.configName=collection1_configs"
```
172.18.0.5:8983_solr,172.18.0.6:8983_solr,172.18.0.7:8983_solr,172.18.0.8:8983_solr
http://192.168.99.100:18983/admin/collections?action=CREATE&name=collection1&numShards=2&replicationFactor=2&maxShardsPerNode=1&createNodeSet=nodelist&collection.configName=configname

./bin/solr create -c collection1 -d server/solr/configsets/data_driven_schema_configs -n collection1_configs -shards 1 -replicationFactor 1

### 11. Open URL in a browser

Open Solr Admin([http://192.168.99.100:18983/solr/#/](http://192.168.99.100:18983/solr/#/)) in a browser.
