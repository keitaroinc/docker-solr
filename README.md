# docker-solr

## Standalone Solr example

### 1. Start standalone Solr

```sh
$ docker run -d -p 18983:8983 --name solr1 mosuka/docker-solr:release-5.5
032dd48d12496c65a3405da483c4c16e4c9b26f3f7e22e0592717cfbd5830110
```

### 2. Check container ID

```sh
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED             STATUS              PORTS                                         NAMES
032dd48d1249        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   15 seconds ago      Up 14 seconds       0.0.0.0:18983->8983/tcp                       solr1
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
c208161abfd4cb092aa7ec1a1de73a3c2f067b31982e3c626657a52022ae2652
```

### 2. Start 2nd Solr

```sh
$ docker run -d --net=network1 -p 28983:8983 --name=solr2 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr mosuka/docker-solr:release-5.5
```

### 3. Start 3rd Solr

```sh
$ docker run -d --net=network1 -p 38983:8983 --name=solr3 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
```

### 4. Start 4th Solr

```sh
$ docker run -d --net=network1 -p 48983:8983 --name=solr4 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
```

### 5. Check container ID

```sh
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED             STATUS              PORTS                                         NAMES
032dd48d1249        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   15 seconds ago      Up 14 seconds       0.0.0.0:18983->8983/tcp                       solr1
```

### 6. Get container IP of 1st Solr

```sh
$ docker inspect -f '{{ .NetworkSettings.IPAddress }}' 032dd48d1249
172.17.0.3
```

### 7. Get container IP of 2nd Solr

```sh
$ docker inspect -f '{{ .NetworkSettings.IPAddress }}' 032dd48d1249
172.17.0.3
```

### 8. Get container IP of 3rd Solr

```sh
$ docker inspect -f '{{ .NetworkSettings.IPAddress }}' 032dd48d1249
172.17.0.3
```

### 9. Get container IP of 4th Solr

```sh
$ docker inspect -f '{{ .NetworkSettings.IPAddress }}' 032dd48d1249
172.17.0.3
```

### 10. Get host IP

```sh
$ docker-machine ip default
192.168.99.100
```

### 11. Open URL in a browser

Open Solr Admin([http://192.168.99.100:18983/solr/#/](http://192.168.99.100:18983/solr/#/)) in a browser.
