#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# If this scripted is run out of /usr/bin or some other system bin directory
# it should be linked to and not copied. Things like java jar files are found
# relative to the canonical path of this script.
#

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container

# IP detection.
DETECTED_IP_LIST=($(
  ip addr show | grep -e "inet[^6]" | \
    sed -e "s/.*inet[^6][^0-9]*\([0-9.]*\)[^0-9]*.*/\1/" | \
    grep -v "^127\."
))
DETECTED_IP=${DETECTED_IP_LIST[0]}

# Set environment variables.
SOLR_PREFIX=${SOLR_PREFIX:-/opt/solr}
SOLR_HOME=${SOLR_HOME:-${SOLR_PREFIX}/server/solr}
SOLR_HOST=${SOLR_HOST:-${DETECTED_IP}}
SOLR_PORT=${SOLR_PORT:-8983}
ZK_HOST=${ZK_HOST:-""}

# Show environment variables.
echo "SOLR_PREFIX=${SOLR_PREFIX}"
echo "SOLR_HOME=${SOLR_HOME}"
echo "SOLR_HOST=${SOLR_HOST}"
echo "SOLR_PORT=${SOLR_PORT}"
echo "ZK_HOST=${ZK_HOST}"

# Stop function.
function stop() {
  NODE_NAME=${SOLR_HOST}:${SOLR_PORT}_solr

  if [ -n "${ZK_HOST}" ]; then
    COLLECTION_NAME_LIST=($(curl -s "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/collections?action=LIST&wt=json" | jq -r '.collections[]'))
    for COLLECTION_NAME in "${COLLECTION_NAME_LIST[@]}"
    do
      STATE_JSON=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/zookeeper?detail=true&path=%2Fcollections%2F${COLLECTION_NAME}%2Fstate.json")
      SHARD_NAME_LIST=($(echo ${STATE_JSON} | jq -r ".znode.data" | jq -r ".${COLLECTION_NAME}.shards | keys" | jq -r ".[]"))
      for SHARD_NAME in "${SHARD_NAME_LIST[@]}"
      do
        REPLICA_NAME_LIST=($(echo ${STATE_JSON} | jq -r ".znode.data" | jq -r ".${COLLECTION_NAME}.shards.${SHARD_NAME}.replicas" | jq -r "to_entries" | jq ".[]" | jq "select(.value.node_name == \"$NODE_NAME\")" | jq -r ".key"))
        for REPLICA_NAME in "${REPLICA_NAME_LIST[@]}"
        do
          curl -s "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/collections?action=DELETEREPLICA&collection=${COLLECTION_NAME}&shard=${SHARD_NAME}&replica=${REPLICA_NAME}" | xmllint --format -
        done
      done
    done
  fi
  
  ${SOLR_PREFIX}/bin/solr stop -p ${SOLR_PORT}

  echo "${NODE_NAME} is unavailable."
}

# Stop
stop
