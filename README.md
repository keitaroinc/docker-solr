# docker-solr

## Standalone Solr example

### 1. Start standalone Solr

```sh
$ docker run -d -p 8984:8983 --name solr mosuka/docker-solr:release-5.5
032dd48d12496c65a3405da483c4c16e4c9b26f3f7e22e0592717cfbd5830110
```

### 2. Check container ID

```sh
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED             STATUS              PORTS                                         NAMES
032dd48d1249        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   15 seconds ago      Up 14 seconds       0.0.0.0:8984->8983/tcp                       solr
```

### 3. Get container IP

```sh
$ docker inspect -f '{{ .NetworkSettings.IPAddress }}' solr
172.17.0.2
```

### 4. Get host IP

```sh
$ docker-machine ip default
192.168.99.100
```

### 5. Create core

```sh
$ curl "http://192.168.99.100:8984/solr/admin/cores?action=CREATE&name=collection1&configSet=data_driven_schema_configs&dataDir=data" | \
    xmllint --format -
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   184    0   184    0     0     51      0 --:--:--  0:00:03 --:--:--    52
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <lst name="responseHeader">
    <int name="status">0</int>
    <int name="QTime">3520</int>
  </lst>
  <str name="core">collection1</str>
</response>
```

### 6. Open Solr Admin UI in a browser

Open Solr Admin UI ([http://192.168.99.100:8984/solr/#/](http://192.168.99.100:8984/solr/#/)) in a browser.



## SolrCloud (2 shards across 4 nodes with replication factor 2) example

### 1. Start Zookeeper ensemble

See [ZooKeeper ensemble example](https://hub.docker.com/r/mosuka/docker-zookeeper/).

### 1. Start 1st Solr

```sh
$ docker run -d --net=network1 -p 8984:8983 --name=solr1 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
aaef4999bd84f17387a0a868c864cf25154f743fd0519753172f20cac32d7334
```

### 2. Start 2nd Solr

```sh
$ docker run -d --net=network1 -p 8985:8983 --name=solr2 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
30d83c26c131e65791a9f22eba2f1e7410bda156a634b27ef7593c07c7904753
```

### 3. Start 3rd Solr

```sh
$ docker run -d --net=network1 -p 8986:8983 --name=solr3 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
18b80967aa730c11c49cd2ea5531044117469be7713de640b1fdc10cd3b8584b
```

### 4. Start 4th Solr

```sh
$ docker run -d --net=network1 -p 8987:8983 --name=solr4 \
    -e ZK_HOST=172.18.0.2:2181,172.18.0.3:2181,172.18.0.4:2181/solr \
    mosuka/docker-solr:release-5.5
7f6bf1fe58226942d9899a92c83377429381c93d4cd0075ee8a60c19e69d291b
```

### 5. Check container ID

```sh
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED              STATUS              PORTS                                         NAMES
7f6bf1fe5822        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   42 seconds ago       Up 41 seconds       7983/tcp, 0.0.0.0:8987->8983/tcp             solr4
18b80967aa73        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   53 seconds ago       Up 52 seconds       7983/tcp, 0.0.0.0:8986->8983/tcp             solr3
30d83c26c131        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   About a minute ago   Up About a minute   7983/tcp, 0.0.0.0:8985->8983/tcp             solr2
aaef4999bd84        mosuka/docker-solr:release-5.5        "/usr/local/bin/docke"   2 minutes ago        Up 2 minutes        7983/tcp, 0.0.0.0:8984->8983/tcp             solr1
1902ab480c57        mosuka/docker-zookeeper:release-3.4   "/usr/local/bin/docke"   15 hours ago         Up 15 hours         2888/tcp, 3888/tcp, 0.0.0.0:2184->2181/tcp   zookeeper3
182022f64ef7        mosuka/docker-zookeeper:release-3.4   "/usr/local/bin/docke"   15 hours ago         Up 15 hours         2888/tcp, 3888/tcp, 0.0.0.0:2183->2181/tcp   zookeeper2
a63962346037        mosuka/docker-zookeeper:release-3.4   "/usr/local/bin/docke"   15 hours ago         Up 15 hours         2888/tcp, 3888/tcp, 0.0.0.0:2182->2181/tcp   zookeeper1
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
$ curl "http://192.168.99.100:8984/solr/admin/collections?action=CREATE&name=collection1&numShards=2&replicationFactor=2&maxShardsPerNode=1&createNodeSet=172.18.0.5:8983_solr,172.18.0.6:8983_solr,172.18.0.7:8983_solr,172.18.0.8:8983_solr&collection.configName=data_driven_schema_configs" | \
    xmllint --format -
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   773    0   773    0     0     27      0 --:--:--  0:00:28 --:--:--   186
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <lst name="responseHeader">
    <int name="status">0</int>
    <int name="QTime">28423</int>
  </lst>
  <lst name="success">
    <lst>
      <lst name="responseHeader">
        <int name="status">0</int>
        <int name="QTime">22263</int>
      </lst>
      <str name="core">collection1_shard1_replica2</str>
    </lst>
    <lst>
      <lst name="responseHeader">
        <int name="status">0</int>
        <int name="QTime">21997</int>
      </lst>
      <str name="core">collection1_shard1_replica1</str>
    </lst>
    <lst>
      <lst name="responseHeader">
        <int name="status">0</int>
        <int name="QTime">26777</int>
      </lst>
      <str name="core">collection1_shard2_replica1</str>
    </lst>
    <lst>
      <lst name="responseHeader">
        <int name="status">0</int>
        <int name="QTime">27561</int>
      </lst>
      <str name="core">collection1_shard2_replica2</str>
    </lst>
  </lst>
</response>
```

### 12. Open Solr Admin UI in a browser

Open Solr Admin UI ([http://192.168.99.100:8984/solr/#/](http://192.168.99.100:8984/solr/#/)) in a browser.
