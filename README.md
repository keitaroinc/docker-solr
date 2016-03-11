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
fec0ce8c1e872b6863f9e1741b3f7d2e2497da4ddf9c841adc50658751ae7c26
```

### 2. Start 2nd Solr

```sh
$ docker run -d --net=network1 -p 28983:8983 --name=solr2 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
1dc08f15d02d1d3c27b90c2ad9e6222bb60fde06d568e627b55c4f592958db27
```

### 3. Start 3rd Solr

```sh
$ docker run -d --net=network1 -p 38983:8983 --name=solr3 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
f063d3ea5f04b30fc8a104d97c08632bfeda0e0353fb966145d22b2b53d2814f
```

### 4. Start 4th Solr

```sh
$ docker run -d --net=network1 -p 48983:8983 --name=solr4 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
d3cdf610e915c359f174aa3b7137707f7e274ddb7ff977766d4d0124330ead3e
```

### 5. Check container ID

```sh
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED              STATUS              PORTS                                         NAMES
d3cdf610e915        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   13 seconds ago       Up 12 seconds       7983/tcp, 0.0.0.0:48983->8983/tcp             solr4
f063d3ea5f04        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   29 seconds ago       Up 28 seconds       7983/tcp, 0.0.0.0:38983->8983/tcp             solr3
1dc08f15d02d        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   About a minute ago   Up About a minute   7983/tcp, 0.0.0.0:28983->8983/tcp             solr2
fec0ce8c1e87        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   2 minutes ago        Up 2 minutes        7983/tcp, 0.0.0.0:18983->8983/tcp             solr1
432afd32772c        mosuka/docker-zookeeper:release-3.4   "/usr/local/bin/docke"   6 hours ago          Up 6 hours          2888/tcp, 3888/tcp, 0.0.0.0:32181->2181/tcp   zookeeper3
d0c05513b4fd        mosuka/docker-zookeeper:release-3.4   "/usr/local/bin/docke"   6 hours ago          Up 6 hours          2888/tcp, 3888/tcp, 0.0.0.0:22181->2181/tcp   zookeeper2
fc366f620f79        mosuka/docker-zookeeper:release-3.4   "/usr/local/bin/docke"   6 hours ago          Up 6 hours          2888/tcp, 3888/tcp, 0.0.0.0:12181->2181/tcp   zookeeper1
```

### 6. Get container IP of 1st Solr

```sh
$ docker inspect -f '{{ .NetworkSettings.Networks.network1.IPAddress }}' fec0ce8c1e87
172.17.0.5
```

### 7. Get container IP of 2nd Solr

```sh
$ docker inspect -f '{{ .NetworkSettings.Networks.network1.IPAddress }}' 1dc08f15d02d
172.17.0.6
```

### 8. Get container IP of 3rd Solr

```sh
$ docker inspect -f '{{ .NetworkSettings.Networks.network1.IPAddress }}' f063d3ea5f04
172.17.0.7
```

### 9. Get container IP of 4th Solr

```sh
$ docker inspect -f '{{ .NetworkSettings.Networks.network1.IPAddress }}' d3cdf610e915
172.17.0.8
```

### 10. Get host IP

```sh
$ docker-machine ip default
192.168.99.100
```

### 11. Open URL in a browser

Open Solr Admin([http://192.168.99.100:18983/solr/#/](http://192.168.99.100:18983/solr/#/)) in a browser.
