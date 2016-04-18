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

SOLR_COLLECTIONS_API_PATH=/solr/admin/collections

# Stop function.
function stop() {
  NODE_NAME=${SOLR_HOST}:${SOLR_PORT}_solr

  # SolrCloud mode?
  if [ -n "${ZK_HOST}" ]; then
    # Get latest cluster state JSON.
    CLUSTERSTATUS_JSON=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=CLUSTERSTATUS&wt=json")

    # Get collection list.
    COLLECTION_NAME_LIST=($(echo ${CLUSTERSTATUS_JSON} | jq -r ".cluster.collections | to_entries | .[].key"))
    for COLLECTION_NAME in "${COLLECTION_NAME_LIST[@]}"
    do
      # Get shard list in a collection.
      SHARD_NAME_LIST=($(echo ${CLUSTERSTATUS_JSON} | jq -r ".cluster.collections.${COLLECTION_NAME}.shards | keys | .[]"))
      for SHARD_NAME in "${SHARD_NAME_LIST[@]}"
      do
        # Get replica list in a shard.
        REPLICA_NAME_LIST=($(echo ${CLUSTERSTATUS_JSON} | jq -r ".cluster.collections.${COLLECTION_NAME}.shards.${SHARD_NAME}.replicas | to_entries | .[] | select(.value.node_name == \"${NODE_NAME}\") | .key"))
        for REPLICA_NAME in "${REPLICA_NAME_LIST[@]}"
        do
          # Get latest cluster state JSON.
          CLUSTERSTATUS_JSON=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=CLUSTERSTATUS&wt=json")

          # Live nodes.
          LIVE_NODE_LIST=($(echo ${CLUSTERSTATUS_JSON} | jq -r ".cluster.live_nodes[]" | grep -v -e "^${NODE_NAME}$"))
          # Runnning nodes.
          RUNNING_NODE_LIST=($(echo ${CLUSTERSTATUS_JSON} | jq -r ".cluster.collections[].shards[].replicas[].node_name" | grep -v -e "^${NODE_NAME}$"))
          # Available nodes.
          AVAILABLE_NODE_LIST=(${LIVE_NODE_LIST[@]} ${RUNNING_NODE_LIST[@]})
          if [ ${#AVAILABLE_NODE_LIST[@]} -le 0 ]; then
            continue
          fi
          # Choose node to add (the node that hava minimum number of collections.).
          ADDREPLICA_NODE=$(for AVAILABLE_NODE in "${AVAILABLE_NODE_LIST[@]}"; do echo ${AVAILABLE_NODE}; done | sort | uniq -c | sort -n -k 1 | head -1 | awk -F " " '{print $2}')
          echo "ADDREPLICA_NODE=${ADDREPLICA_NODE}"
          # Add replica and added core name.
          CORE_NAME=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=ADDREPLICA&collection=${COLLECTION_NAME}&shard=${SHARD_NAME}&node=${ADDREPLICA_NODE}&wt=xml" | xmllint --xpath "/response/lst[@name=\"success\"]/lst/str[@name=\"core\"]/text()" -)
          echo "CORE_NAME=${CORE_NAME}"

          # Leader node?
          IS_LEADER_REPLICA=$(echo ${CLUSTERSTATUS_JSON} | jq -r ".cluster.collections.${COLLECTION_NAME}.shards.${SHARD_NAME}.replicas.${REPLICA_NAME}.leader")
          echo "IS_LEADER_REPLICA=${IS_LEADER_REPLICA}"
          # Get active replicas.
          ACTIVE_REPLICA_NUM=$(echo ${CLUSTERSTATUS_JSON} | jq -r ".cluster.collections.${COLLECTION_NAME}.shards.${SHARD_NAME}.replicas | to_entries | .[] | select(.value.state == \"active\") | .key" | grep -v -e "^${REPLICA_NAME}$" | wc -l)
          echo "ACTIVE_REPLICA_NUM=${ACTIVE_REPLICA_NUM}"
          if [ "${IS_LEADER_REPLICA}" == "true" -a ${ACTIVE_REPLICA_NUM} -lt 1 ]; then
            # Waiting core acvibate.
            while true
            do
              # Get latest cluster state JSON.
              CLUSTERSTATUS_JSON=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=CLUSTERSTATUS&wt=json")
              STATE=$(echo ${CLUSTERSTATUS_JSON} | jq -r ".cluster.collections.${COLLECTION_NAME}.shards.${SHARD_NAME}.replicas | to_entries | .[] | select(.value.core == \"${CORE_NAME}\") | .value.state")
              echo "STATE=${STATE}"
              if [ "${STATE}" == "active" ]; then
                break
              fi
              sleep 1
            done
          fi

          # Delete replica.
          curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=DELETEREPLICA&collection=${COLLECTION_NAME}&shard=${SHARD_NAME}&replica=${REPLICA_NAME}" | xmllint --format -

          if [ "${IS_LEADER_REPLICA}" == "true" ]; then
            # Waiting new leader.
            while true
            do
              # Get latest cluster state JSON.
              CLUSTERSTATUS_JSON=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=CLUSTERSTATUS&wt=json")
              NEW_LEADER_REPLICA=$(echo ${CLUSTERSTATUS_JSON} | jq -r ".cluster.collections.${COLLECTION_NAME}.shards.${SHARD_NAME}.replicas | to_entries | .[] | select(.value.leader == \"true\") | .key" | grep -v -e "^${REPLICA_NAME}$")
              echo "NEW_LEADER_REPLICA=${NEW_LEADER_REPLICA}"
              if [ -n "${NEW_LEADER_REPLICA}" ]; then
                break
              fi
              sleep 1
            done
          fi
        done
      done
    done
  fi
  
  ${SOLR_PREFIX}/bin/solr stop -p ${SOLR_PORT}
}

# Stop
stop
