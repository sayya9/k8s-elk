# ELK

ELK是Elasticsearch、Logstash與Kibana的簡稱，三者皆為open-source工具。

* Elaticsearch - 使用Java所開發，是一個基於Apache Lucene的分散式全文檢索引擎，支援RESTful接口，並可對數據進行即時分析。
* Logstash - 對日誌進行管理、收集、過濾與儲存，Logstash目前是es家族成員之一。
* Kibana - 負責日誌的視覺化。

## Elasticsearch

ELK所使用的資料庫，把收集到的日誌存在這裡，便於快速的查詢。


### Master-eligible node

會從所有候選的主節點選出一個真的做事主節點，主要負責集群裡輕量級的操作，例如：建立或是刪除索引、透過廣播機制與其他node聯繫、並決定哪些分片(shards)分給相關節點。

官方的master-eligible node的建議配置：

```
node.master: true 
node.data: false 
node.ingest: false
```

#### 腦裂(spilt brain)

`discovery.zen.minimum_master_nodes`這個參數的數字，代表有目前有多少候選主節點可通訊的情況下，才會從中推選一個真正的主節點出來，否則不滿足這個數字的話，es為了避免腦裂，整個集群為不可用。

這個參數預設是`1`，且如果目前候選主節點也是1那麼這個集群為可用狀態。

如果這個參數一樣為1，候選的主節點目前為2，這個情況乍看如果任何一個候選主節點掛掉時，另外一個會自動提升為票選為主節點，這個假象看起來沒錯！但假設有2個候選主節點(Node1, Node2)，Node1在啟動時被票選為主節點，但如果只是網路問題讓兩個候選主節點之間暫時失聯了，通訊斷了，兩個節點都認為彼此已經掛了，Node1不需要做什麼，它本來就被票選為主節點，關鍵在Node2會自動提升票選自己為主節點，此時Node2形成另外一個獨立的集群，如果Node2保存的是副分片的話，也會一併提升為主分片，因為它認為Node1已經掛了。現在集群在一個不一致的狀態，發在Node1與Node2的索引請求各自寫自己的！

因此建議配置3個以上的候選主節點，不但避免了腦裂的可能性，也同時保持高可用性的優點！

官方建議discovery.zen.minimum_master_nodes這個值的公式為：

```
(master_eligible_nodes / 2) + 1
```

例如：有3個候選主節點，(3/2)+1=2，那麼如果網路發生故障時，其中一個節點不能與其他節點通訊時，就不會形成另外一個獨立的集群！

### Data node

存放數據的節點，負責CRUD操作，以及查詢、聚合操作，對CPU、Memory、IO要求較高。

官方的data node的建議配置：

```
node.master: false 
node.data: true 
node.ingest: false
```

### Ingest node

es 5.x所新增的功能，原始數據在實際寫進資料庫之前，對數據執行管道預處理。例如：在document中增加field或是重命名field等操作，一個pipeline支援增加多個processor，按照順序輪流處理！

官方的ingest node的建議配置：

```
node.master: false 
node.data: false 
node.ingest: true 
search.remote.connect: false
```

### Coordinating only node

其實就是原來的client node，在所有節點預設就是coordinating node，主要用來發送請求與合併結果。因此，需要有足夠的CPU、Memory來處理合併數據的集合！

官方的coordinating node的建議配置：

```
node.master: false 
node.data: false 
node.ingest: false 
search.remote.connect: false
```

### Unicast discovery

es為了防止任一個節點無意間加入集群，提供了一個列表`discovery.zen.ping.unicast.hosts`，在此列表中的節點且具有集群相同名字才會加入集群。預設搜尋9300的port，且只有本機才能加入！

這個elk repository的es部分，使用了k8s的service cluster-ip，且es master deployment replicas為3，也就是我有3個候選主節點，因此當我k8s DNS解析這個`es-discovery`名稱時，會返回一個cluster-ip，這個cluster-ip有3個endpoint，每個endpoint對應的是master pod的ip，至於到哪個master pod由iptables決定！

因此，我只需要寫這樣就可以找到所有候選主節點，不需要每台都寫出來：

```
discovery.zen.ping.unicast.hosts: ["es-discovery"]
```

### 測試

* master node: 3
* data node: 2
* coordinating node: 2

因為是裝在k8s裡面的，所以請打開NodePort或者是在Pod裡面操作！

透過es提供的API確認基本訊息：

```
GET http://localhost:9200
```

返回：

```
{
  "name": "elk-es-coordinator-elk-79d687745d-mzhr6",
  "cluster_name": "elk",
  "cluster_uuid": "FPLbo5APSHCEQ5V3KhPmKA",
  "version": {
    "number": "6.2.4",
    "build_hash": "ccec39f",
    "build_date": "2018-04-12T20:37:28.497551Z",
    "build_snapshot": false,
    "lucene_version": "7.2.1",
    "minimum_wire_compatibility_version": "5.6.0",
    "minimum_index_compatibility_version": "5.0.0"
  },
  "tagline": "You Know, for Search"
}
```

集群健康值：

```
GET http://localhost:9200/_cluster/health?pretty
```

返回：

```
{
  "cluster_name": "elk",
  "status": "green",
  "timed_out": false,
  "number_of_nodes": 7,
  "number_of_data_nodes": 2,
  "active_primary_shards": 0,
  "active_shards": 0,
  "relocating_shards": 0,
  "initializing_shards": 0,
  "unassigned_shards": 0,
  "delayed_unassigned_shards": 0,
  "number_of_pending_tasks": 0,
  "number_of_in_flight_fetch": 0,
  "task_max_waiting_in_queue_millis": 0,
  "active_shards_percent_as_number": 100
}
```

各個node訊息：

```
GET http://localhost:9200/_cat/nodes?v
```

返回：

```
ip            heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
10.233.83.52            31          90   6    0.20    0.18     0.18 m         -      elk-es-master-elk-747456994d-rf6d6
10.233.68.101           37          83   3    0.34    0.56     0.47 m         -      elk-es-master-elk-747456994d-2nsb8
10.233.127.59           36          79  20    3.19    2.64     2.66 m         *      elk-es-master-elk-747456994d-ncs82
10.233.68.104           13          83   3    0.34    0.56     0.47 di        -      elk-es-data-elk-1
10.233.83.49            17          90   6    0.20    0.18     0.18 -         -      elk-es-coordinator-elk-79d687745d-mzhr6
10.233.68.112           28          83   3    0.34    0.56     0.47 -         -      elk-es-coordinator-elk-79d687745d-8p4bt
10.233.83.44             9          90   6    0.20    0.18     0.18 di        -      elk-es-data-elk-0
```

增加一個document：

```
PUT test-index1/test-type1/1?pretty
{
  "user": "andrew",
  "message": "hello elk"
}
```

返回：

```
{
  "_index" : "test-index1",
  "_type" : "test-type1",
  "_id" : "1",
  "_version" : 1,
  "result" : "created",
  "_shards" : {
    "total" : 2,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 0,
  "_primary_term" : 1
}
```