---
layout: post
title:  "ELK Migration Tutorial"
date:   2018-06-22 23:42:00 +0300
categories: sysadmin
summary: In this tutorial I describe how to migrate ELK cluster version 5.6 to version 6.3
---

## An introduction to elasticsearch

Elasticsearch is a NoSQL database and search engine that stores documents in indexes
and can be searched in near real-time speed, it uses JSON for document structure
and provides a RESTFull API to index and retrieve documents easily using many
programming clients.

Elasticsearch is open source, written in Java and distributed under the Apache license.
It is based on Apache Lucene, you also can use Lucene queries to search for data in it.

In the next few sections we will describe its main features and components to get
some knowledge about it.

# Indices and Types
**Hint:**
  Before Starting this section I must tell you that multiple types support in a single
  index is removed in version 6.0.

An index is like a database in a SQL and a type is like a table, each index can have
multiple types in it but fields with the same name in different types in the same
index need to have the same type and structure this is one reason to remove multiple
types from elasticsearch.

Every operation to add, remove, retrieve and search for a document should be applied
on an index.

You can add document x to index y for example.

# Documents
  Elasticsearch stores data as documents in an index, each document can have
  different structure, a document can have any number of fields along with their
  values the following is an example document from Apache access log

  ```json
    {
      "client": "55.134.65.122",
      "method": "GET",
      "request": "/page",
      "version": "1.1",
      "agent": "Mozilla/5.0 (Linux; Android 7.0; SM-J701F Build/NRD90M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/67.0.3396.87 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/177.0.0.57.105;]",
      "referrer": "",
      "response": 200,
      "bytes": 2340
    }
  ```

  The previous document could be a line in apache access log, with help from ELK stack
  it is converted into a document in elasticsearch index and can be visualized using kibana.

  The structure of each document is defined using an index mapping if the index does
  not have a mapping then elasticsearch creates one on the fly when indexing documents.

# Shards and replicas
  Elasticsearch creates shards for each index and store documents in them.

  There are two kinds of shards: *Primary Shards* and *Secondary Shards*.

  Data is partitioned between primary shards and each primary shard has a replica
  for redundancy so if a server with the primary shard is lost the secondary shard
  can be used instead.

  By default when an index is created it has 5 shards and one replica for each one of them.

## Elasticsearch Cluster
  A single server is not enough for the majority of search needs, so we need to have
  elasticsearch installed and running on multiple servers to form an elasticsearch cluster.

  creating a cluster with elasticsearch is super easy all what you have to do is
  tell each node in your cluster about the addresses of other nodes and use the
  same cluster name on all of them, when the nodes are started they automatically form
  a cluster and elect one of them to be a master node and the others data nodes.

  Let's talk about node types in elasticsearch cluster:

  * Master nodes: These nodes are responsible for cluster management tasks, tracking
    which nodes are in the cluster, allocating shards to nodes and forwarding requests
    to other nodes which hold data.
  * Data nodes: These nodes hold the data in the cluster.
  * Ingest nodes: These nodes can be used to apply ingest pipeline on documents before
    they are indexed.
  * Tribe nodes: These nodes can forward requests to more than one cluster to get data
    from each one of them.

    By default every node in the cluster is master, data and ingest node, this is okay
    for small clusters, however for big clusters it is adviced to create dedicated nodes
    for each node type.

  Elasticsearch is evolving fast, to catch up with it we need to have a good strategy
  to migrate clusters from one version to another, in this tutorial I will describe
  how I did the migration from version 5.6.7 to version 6.3.0.

## Steps before migration
  Before starting the migration we need to do the following steps first:
  * Take full snapshot of our data
    To take a snapshot we need first to create a snapshot repository, I will be showing
    commands using curl however I use [insomnia REST client](https://insomnia.rest)
    to do the required API requests to elasticsearch.

    Execute the following commands to do take snapshot.

    **Hint**: Keep in mind that the snapshot process make take a long time, it took
    me 30 hours to snapshot indexes which contain 5.6 Billion documents on two servers.
    ```bash
    # Create snapshot repository
    curl --request PUT \
      --url http://10.0.1.2:9200/_snapshot/my_hdfs_repo \
      --header 'content-type: application/json' \
      --data '{
        "type": "hdfs",
        "settings": {
          "uri": "hdfs://10.0.1.10:8020/",
          "path": "elk/elasticsearch_repos/my_hdfs_repo"
        }
      }'
      # Start the snapshot process
      curl --request PUT \
        --url http://10.0.1.2:9200/_snapshot/my_hdfs_repo/snap_1 \
        --header 'content-type: application/json' \
        --data '{
      	   "indices": "*",
      	    "ignore_unavailable": true,
            "include_global_state": false
          }'
      # You can monitor the snapshot progress using this command
      curl --request GET \
        --url http://10.0.1.2:9200/_snapshot/my_hdfs_repo/snap_1/_status
    ```
    The previous commands assumes you have en elasticsearch server on 10.0.1.2
    listening on port 9200 and hadoop name node on 10.0.1.10 listening on port 8020

    Here I am using HDFS as the store for elasticsearch snapshot, you can use
    Shared File System, S3, Azure or GCS as described
    [here](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/modules-snapshots.html).
  * Check breaking changes in the new version.

    Each new version of elasticsearch, logstash, kibana and beats have a change log
    and breaking changes page you need to check them and make sure your client programs
    are compatible with the new changes.
  * Check elasticsearch deprecation log

    Deprecation log can be found in the logs directory of elasticsearch, make sure
    it is empty if not modify your configuration or your clients behavior accordingly.
  * Upgrade kibana index

    Since the new version of elasticsearch does not support multiple types per an index
    we need to modify our kibana index to take this into consideration, do not worry
    the new index is compatible with the old one.
    Use these command to do the change
    ```bash
      # Create new index
      curl --request PUT \
        --url http://10.0.1.2:9200/.kibana-6 \
        --header 'content-type: application/json' \
        --data '{
          "settings" : {
            "number_of_shards" : 1,
            "index.mapper.dynamic": false,
            "index.format": 6,
            "index.mapping.single_type": true
          },
          "mappings" : {
            "doc": {
              "properties": {
                "type": {
                "type": "keyword"
              },
              "updated_at": {
                "type": "date"
              },
              "config": {
                "properties": {
                  "buildNum": {
                    "type": "keyword"
                  }
                }
              },
              "index-pattern": {
                "properties": {
                  "fieldFormatMap": {
                    "type": "text"
                  },
                  "fields": {
                    "type": "text"
                  },
                  "intervalName": {
                    "type": "keyword"
                  },
                  "notExpandable": {
                    "type": "boolean"
                  },
                  "sourceFilters": {
                    "type": "text"
                  },
                  "timeFieldName": {
                    "type": "keyword"
                  },
                  "title": {
                    "type": "text"
                  }
                }
              },
              "visualization": {
                "properties": {
                  "description": {
                    "type": "text"
                  },
                  "kibanaSavedObjectMeta": {
                    "properties": {
                      "searchSourceJSON": {
                        "type": "text"
                      }
                    }
                  },
                  "savedSearchId": {
                    "type": "keyword"
                  },
                  "title": {
                    "type": "text"
                  },
                  "uiStateJSON": {
                    "type": "text"
                  },
                  "version": {
                    "type": "integer"
                  },
                  "visState": {
                    "type": "text"
                  }
                }
              },
              "search": {
                "properties": {
                  "columns": {
                    "type": "keyword"
                  },
                  "description": {
                    "type": "text"
                  },
                  "hits": {
                    "type": "integer"
                  },
                  "kibanaSavedObjectMeta": {
                    "properties": {
                      "searchSourceJSON": {
                        "type": "text"
                      }
                    }
                  },
                  "sort": {
                    "type": "keyword"
                  },
                  "title": {
                    "type": "text"
                  },
                  "version": {
                    "type": "integer"
                  }
                }
              },
              "dashboard": {
                "properties": {
                  "description": {
                    "type": "text"
                  },
                  "hits": {
                    "type": "integer"
                  },
                  "kibanaSavedObjectMeta": {
                    "properties": {
                      "searchSourceJSON": {
                        "type": "text"
                      }
                    }
                  },
                  "optionsJSON": {
                    "type": "text"
                  },
                  "panelsJSON": {
                    "type": "text"
                  },
                  "refreshInterval": {
                    "properties": {
                      "display": {
                        "type": "keyword"
                      },
                      "pause": {
                        "type": "boolean"
                      },
                      "section": {
                        "type": "integer"
                      },
                      "value": {
                        "type": "integer"
                      }
                    }
                  },
                  "timeFrom": {
                    "type": "keyword"
                  },
                  "timeRestore": {
                    "type": "boolean"
                  },
                  "timeTo": {
                    "type": "keyword"
                  },
                  "title": {
                    "type": "text"
                  },
                  "uiStateJSON": {
                    "type": "text"
                  },
                  "version": {
                    "type": "integer"
                  }
                }
              },
              "url": {
                "properties": {
                  "accessCount": {
                    "type": "long"
                  },
                  "accessDate": {
                    "type": "date"
                  },
                  "createDate": {
                    "type": "date"
                  },
                  "url": {
                    "type": "text",
                    "fields": {
                      "keyword": {
                        "type": "keyword",
                        "ignore_above": 2048
                      }
                    }
                  }
                }
              },
              "server": {
                "properties": {
                  "uuid": {
                    "type": "keyword"
                  }
                }
              },
              "timelion-sheet": {
                "properties": {
                  "description": {
                    "type": "text"
                  },
                  "hits": {
                    "type": "integer"
                  },
                  "kibanaSavedObjectMeta": {
                    "properties": {
                      "searchSourceJSON": {
                        "type": "text"
                      }
                    }
                  },
                  "timelion_chart_height": {
                    "type": "integer"
                  },
                  "timelion_columns": {
                    "type": "integer"
                  },
                  "timelion_interval": {
                    "type": "keyword"
                  },
                  "timelion_other_interval": {
                    "type": "keyword"
                  },
                  "timelion_rows": {
                    "type": "integer"
                  },
                  "timelion_sheet": {
                    "type": "text"
                  },
                  "title": {
                    "type": "text"
                  },
                  "version": {
                    "type": "integer"
                  }
                }
              },
              "graph-workspace": {
                "properties": {
                  "description": {
                    "type": "text"
                  },
                  "kibanaSavedObjectMeta": {
                    "properties": {
                      "searchSourceJSON": {
                        "type": "text"
                      }
                    }
                  },
                  "numLinks": {
                    "type": "integer"
                  },
                  "numVertices": {
                    "type": "integer"
                  },
                  "title": {
                    "type": "text"
                  },
                  "version": {
                    "type": "integer"
                  },
                  "wsState": {
                    "type": "text"
                  }
                }
              }
            }
          }
        }
      }
      '
      # Make kibana index read only
      curl --request PUT \
        --url http://10.0.1.2:9200/.kibana/_settings \
        --header 'content-type: application/json' \
        --data '{
      	   "index.blocks.write": true
         }'
      # Reindex old kibana index to new one
      curl --request POST \
        --url http://10.0.1.2:9200/_reindex \
        --header 'content-type: application/json' \
        --data '{
        "source": {
          "index": ".kibana"
        },
        "dest": {
          "index": ".kibana-6"
        },
        "script": {
          "inline": "ctx._source = [ ctx._type : ctx._source ]; ctx._source.type = ctx._type; ctx._id = ctx._type + \":\" + ctx._id; ctx._type = \"doc\"; ",
          "lang": "painless"
        }
      }'
      # Alias new kibana index and remove old one
      curl --request POST \
        --url http://10.0.1.2:9200/_aliases \
        --header 'content-type: application/json' \
        --data '{
        "actions" : [
          { "add":  { "index": ".kibana-6", "alias": ".kibana" } },
          { "remove_index": { "index": ".kibana" } }
        ]
      }'
    ```

    Now we are all setup to start the migration process.

## Start migration

The components in ELK stack should be upgraded in the following order, first elasticsearch
then kibana, after that upgrade logstash and lastly upgrade beats, I will describe
the upgrade process of each one of them in the comming sections

# Upgrade elasticsearch
Upgrading elasticsearch is the most tricky part of the migration process, it consists
of the following steps which must be done on each node you want to upgrade:

* Disable shard allocation: When a node is shutdown its shards are allocated to another
  node in the cluster, since we only want to temporarily shutdown the node it is advised
  to disable shard allocation to not cause additional IO.

  Use this command to disable shard allocation
  ```bash
  curl --request PUT \
    --url http://10.0.1.2:9200/_cluster/settings \
    --header 'content-type: application/json' \
    --data '{
      "persistent": {
        "cluster.routing.allocation.enable": "none"
      }
    }'
  ```
* Stop non-essential indexing and do a synced flush (optional): This step is not required
  but it can be used to speed up the process.

  Use this command to do a synced flush
  ```bash
  curl --request POST \
    --url http://10.0.1.2:9200/_flush/synced
  ```
* Stop any running machine learning jobs, See [Stopping Machine Learning](https://www.elastic.co/guide/en/elastic-stack-overview/5.6/stopping-ml.html)
* Shut down the node you want to upgrade using this command
```bash
sudo systemctl stop elasticsearch.service
```

* Upgrade the node to the new version, this depends on how you installed elasticsearch
  on ubuntu you can upgrade with the following commands
  ```bash
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.3.0.deb
    sudo dpkg -i elasticsearch-6.3.0.deb
  ```
* Upgrade any plugins you have installed: You can use `elasticsearch-plugin` to upgrade
  plugins, for example to upgrade `repository-hdfs` plugin use the following commands:
  ```
    cd /usr/share/elasticsearch
    sudo bin/elasticsearch-plugin remove repository-hdfs
    sudo bin/elasticsearch-plugin install repository-hdfs
  ```
  Notice you need to remove the plugin first then install it again to upgrade it.
* Change your configuration according to the new version and start the upgraded node:
  In elasticsearch 6.3.0 there are some configuration changes which you must do before
  starting the upgraded node, I will list here the changes I needed to make when I upgraded
  from 5.6.7 to 6.3.0
  * The paths for data and logs need to be specified in the elasticsearch file explicitly
    in the previous version they had good defaults but now you must uncomment them and
    specify them as follows
    ```
      path.logs: /var/log/elasticsearch
      path.data: /var/lib/elasticsearch
    ```
  * On one of my nodes I needed to fix this file `/etc/default/elasticsearch`
    and change the following option `CONF_DIR` to `ES_PATH_CONF`.

  Now you can start the node using this command
  ```bash
    sudo systemctl start elasticsearch.service
  ```

  Make sure that the node joined the cluster with the following command
  ```bash
  curl --request GET \
    --url http://10.0.1.2:9200/_cat/nodes
  ```

* Re-enable shard allocation with this command
```bash
  curl --request PUT \
    --url http://192.168.2.8:9200/_cluster/settings \
    --header 'content-type: application/json' \
    --data '{
      "persistent": {
        "cluster.routing.allocation.enable": null
      }
    }'
```

* Wait until cluster health turns green:
  You can check the cluster health with this command
  ```bash
  curl --request GET \
    --url 'http://10.0.1.2:9200/_cat/health?v='
  ```
  **Hint** The cluster health might not reach green the first time you upgrade a node
    because shards allocated to the new node cannot have their replicas allocated to
    a node that still runs version 5.6.7.
* Upgrade the rest of the nodes

  Now we need to repeat all the previous steps for each node in the cluster.
* Restart machine learning jobs.

# Upgrade kibana
  Upgrading kibana is the easiest part, since we already migrated kibana index for the
  new version all what we need to do is install the new version with the following commands
  ```bash
    wget https://artifacts.elastic.co/downloads/kibana/kibana-6.3.0-amd64.deb
    sudo dpkg -i kibana-6.3.0-amd64.deb
  ```

# Upgrade logstash
  Now it is the time to upgrade logstash, before we upgrade we need to do some changes
  to our pipelines.

  I was using `document_type` in beats config to send the type of each log and create
  an index for it, now in 6.3.0 `document_type` is not supported and I must send the type
  using a field, so to access the fields in logstash pipeline I had to do some changes.

  Change `[type]` to `[fields][type]` in logstash filters, I used an if statement to get
  the type of the document and apply the right grok filter to it.

  In the output I deleted `document_type` option and changed the index option from
  `%{[@metadata][type]}-%{+YYYY.MM.dd}` to `%{[fields][type]}-%{+YYYY.MM.dd}`.

  No more changes are required, now you can install logstash with these two commands:
  ```bash
    wget https://artifacts.elastic.co/downloads/logstash/logstash-6.3.0.deb
    sudo dpkg -i logstash-6.3.0.deb
  ```

# Upgrade your beats
  In this section I will describe the upgrade process for filebeat and packetbeat.

  First I installed the new version of filebeat as follows:
  ```bash
    wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.3.0-amd64.deb
    sudo dpkg -i filebeat-6.3.0-amd64.deb
  ```
  After installation I had to do some changes to the configuration file, these changes are
  * Change `filebeat.prospectors:` to `filebeat.inputs:`.
  * Change `input_type: log` to `type: log`.
  * Remove `document_type: syslog` and add
  ```
  fields:
          type: syslog
  ```
  Now start filebeat with this command `sudo systemctl start filebeat.service`

  Now for packetbeat install the new version with these commands
  ```bash
    wget https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-6.3.0-amd64.deb
    sudo dpkg -i packetbeat-6.3.0-amd64.deb
  ```
  There is one configuration change, for each protocol `x`
  change `packetbeat.protocols.x:` to `- type: x`.

  Start packetbeat `sudo systemctl start packetbeat.service`

  Congratulations now you are running ELK stack version 6.3.0, enjoy the new kibana UI
  and all the new features in version 6.3.0

## Conclusion
  The migration process of any cluster is always frustrating and requires careful planning
  before starting the process.

  In this guide I shared my experience with you and hope it will help you to upgrade
  your own clusters to new versions.

  Please share your opinions in the comments bellow, if you have any questions you can
  contact me at my email address [mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk).

  In the coming days I will share my experience in scaling elasticsearch clusters up and
  down, stay tuned :)
