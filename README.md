# docker-solr

### Start Standalone Solr

```sh
# Start Solr
$ docker run -d -p 18983:8983 --name solr1 mosuka/docker-solr:release-5.5
032dd48d12496c65a3405da483c4c16e4c9b26f3f7e22e0592717cfbd5830110

# Check container id
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED             STATUS              PORTS                                         NAMES
032dd48d1249        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   15 seconds ago      Up 14 seconds       0.0.0.0:18983->8983/tcp                       solr1

# Get container ip
$ docker inspect -f '{{ .NetworkSettings.IPAddress }}' 032dd48d1249
172.17.0.3

# Get host ip
$ docker-machine ip default
192.168.99.100
```

http://192.168.99.100:18983/solr/#/

### Start SolrCloud

```sh
# Start solr1
$ docker run -d -p 18983:8983 --name=solr1 -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr mosuka/docker-solr:release-5.5
c208161abfd4cb092aa7ec1a1de73a3c2f067b31982e3c626657a52022ae2652

# Start solr2
$ docker run -d -p 28983:8983 --name=solr1 -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr mosuka/docker-solr:release-5.5

# Start solr3
$ docker run -d -p 38983:8983 --name=solr1 -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr mosuka/docker-solr:release-5.5

# Start solr4
$ docker run -d -p 48983:8983 --name=solr1 -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr mosuka/docker-solr:release-5.5

# Check container id
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED             STATUS              PORTS                                         NAMES
032dd48d1249        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   15 seconds ago      Up 14 seconds       0.0.0.0:18983->8983/tcp                       solr1

```

