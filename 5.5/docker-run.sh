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
DETECTED_IP=$(
  ip addr show | grep -e "inet[^6]" | \
    sed -e "s/.*inet[^6][^0-9]*\([0-9.]*\)[^0-9]*.*/\1/" | \
    grep -v "^127\."
)

# Set environment variables.
SOLR_PREFIX=${SOLR_PREFIX:-/opt/solr}
SOLR_HOME=${SOLR_HOME:-${SOLR_PREFIX}/server/solr}
SOLR_HOST=${SOLR_HOST:-${DETECTED_IP[0]}}
SOLR_PORT=${SOLR_PORT:-8983}
ZK_HOST=${ZK_HOST:-""}

# Standalone Solr environment variables.
CORE_NAME=${CORE_NAME:-""}
CONFIG_SET=${CONFIG_SET:-data_driven_schema_configs}
DATA_DIR=${DATA_DIR:-data}

# SolrCloud environment variables.
COLLECTION_NAME=${COLLECTION_NAME:-""}
NUM_SHARDS=${NUM_SHARDS:-2}
COLLECTION_CONFIG_NAME=${COLLECTION_CONFIG_NAME:-data_driven_schema_configs}
REPLICATION_FACTOR=${REPLICATION_FACTOR:-2}
MAX_SHARDS_PER_NODE=${MAX_SHARDS_PER_NODE:-1}

# Show environment variables.
echo "SOLR_PREFIX=${SOLR_PREFIX}"
echo "SOLR_HOME=${SOLR_HOME}"
echo "SOLR_HOST=${SOLR_HOST}"
echo "SOLR_PORT=${SOLR_PORT}"
echo "ZK_HOST=${ZK_HOST}"

echo "CORE_NAME=${CORE_NAME}"
echo "CONFIG_SET=${CONFIG_SET}"
echo "DATA_DIR=${DATA_DIR}"

echo "COLLECTION_NAME=${COLLECTION_NAME}"
echo "NUM_SHARDS=${NUM_SHARDS}"
echo "REPLICATION_FACTOR=${REPLICATION_FACTOR}"
echo "MAX_SHARDS_PER_NODE=${MAX_SHARDS_PER_NODE}"
echo "COLLECTION_CONFIG_NAME=${COLLECTION_CONFIG_NAME}"

# Start function
function start() {
  if [ -n "${ZK_HOST}" ]; then
    NODE_NAME=${SOLR_HOST}:${SOLR_PORT}_solr

    # Split ZK_HOST into ZK_HOST_LIST and ZK_ZNODE.
    declare -a ZK_HOST_LIST=()
    ZK_HOST_LIST=($(echo ${ZK_HOST} | sed -e 's/^\(.\{1,\}:[0-9]\{1,\}\)*\(.*\)$/\1/g' | tr -s ',' ' '))
    ZK_ZNODE=$(echo ${ZK_HOST} | sed -e 's/^\(.\{1,\}:[0-9]\{1,\}\)*\(.*\)$/\2/g')
    ZNODE_LOCK=${ZK_ZNODE}/collections/${COLLECTION_NAME}/lock

    # Create znode of SolrCloud
    for ZK_HOST_SERVER in "${ZK_HOST_LIST[@]}"
    do
      # Split ZK_HOST_SERVER into ZK_HOST_NAME and ZK_HOST_PORT.
      ZK_HOST_NAME=$(echo ${ZK_HOST_SERVER} | cut -d":" -f1)
      ZK_HOST_PORT=$(echo ${ZK_HOST_SERVER} | cut -d":" -f2)

      # Check ZooKeeper node.
      if ! RESPONSE=$(echo "ruok" | nc ${ZK_HOST_NAME} ${ZK_HOST_PORT} 2>/dev/null); then
        continue
      fi
      if [ "${RESPONSE}" = "imok" ]; then
        # Check znode for SolrCloud.
        MATCHED_ZNODE=$(${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | grep -E "^\s+${ZK_ZNODE}\s+.*$" | sed -e "s|^ \{1,\}\(${ZK_ZNODE}\) \{1,\}.*|\1|g")
        if [ -z "${MATCHED_ZNODE}" ]; then
          # Make /solr
          ${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd makepath ${ZK_ZNODE}
        fi
        break
      else
        echo "${ZK_HOST_NAME}:${ZK_HOST_PORT} status NG."
      fi
    done

    # Upload configset.
    declare -a CONFIGSETS_LIST=()
    CONFIGSETS_LIST=($(find ${SOLR_HOME}/configsets -type d -maxdepth 1 -mindepth 1 | awk -F / '{ print $NF }'))
    for CONFIGSETS in ${CONFIGSETS_LIST[@]}
    do
      for ZK_HOST_SERVER in "${ZK_HOST_LIST[@]}"
      do
        # Split ZK_HOST_SERVER into ZK_HOST_NAME and ZK_HOST_PORT.
        ZK_HOST_NAME=$(echo ${ZK_HOST_SERVER} | cut -d":" -f1)
        ZK_HOST_PORT=$(echo ${ZK_HOST_SERVER} | cut -d":" -f2)

        # Check ZooKeeper node.
        if ! RESPONSE=$(echo "ruok" | nc ${ZK_HOST_NAME} ${ZK_HOST_PORT} 2>/dev/null); then
          continue
        fi
        if [ "${RESPONSE}" = "imok" ]; then
          # Check configset.
          MATCHED_CONFIGSETS=$(${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | grep -E "^\s+${ZK_ZNODE}/configs/${CONFIGSETS}\s+.*$" | sed -e "s|^ \{1,\}${ZK_ZNODE}/configs/\(${CONFIGSETS}\) \{1,\}.*|\1|g")
          if [ -z "${MATCHED_CONFIGSETS}" ]; then
            # Upload configset
            ${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT}${ZK_ZNODE} -cmd upconfig -confdir ${SOLR_HOME}/configsets/${CONFIGSETS}/conf/ -confname ${CONFIGSETS}
          fi
          break
        else
          echo "${ZK_HOST_NAME}:${ZK_HOST_PORT} status NG."
        fi
      done
    done

    # Start SolrCloud.
    ${SOLR_PREFIX}/bin/solr start -h ${SOLR_HOST} -p ${SOLR_PORT} -z ${ZK_HOST} -s ${SOLR_HOME}
    
    # Cluster setting.
    LIVE_NODE_LIST=($(curl -s "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/zookeeper?detail=true&path=%2Flive_nodes" | jq -r '.tree[].children[].data.title'))
    FIRST_NODE_NAME=$(echo "${LIVE_NODE_LIST[@]}" | sed -e 's/^\([^ ]\{1,\}\) \{1,\}.*/\1/')
    if [[ "${FIRST_NODE_NAME}" = "${NODE_NAME}" ]]; then
      # lock
      for ZK_HOST_SERVER in "${ZK_HOST_LIST[@]}"
      do
        # Split ZK_HOST_SERVER into ZK_HOST_NAME and ZK_HOST_PORT.
        ZK_HOST_NAME=$(echo ${ZK_HOST_SERVER} | cut -d":" -f1)
        ZK_HOST_PORT=$(echo ${ZK_HOST_SERVER} | cut -d":" -f2)

        # Check ZooKeeper node.
        if ! RESPONSE=$(echo "ruok" | nc ${ZK_HOST_NAME} ${ZK_HOST_PORT} 2>/dev/null); then
          continue
        fi
        if [ "${RESPONSE}" = "imok" ]; then
          # Check znode for Lock.
          MATCHED_ZNODE=$(${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | grep -E "^\s+${ZNODE_LOCK}\s+.*$" | sed -e "s|^ \{1,\}\(${ZNODE_LOCK}\) \{1,\}.*|\1|g")
          if [ -z "${MATCHED_ZNODE}" ]; then
            # Make lock node
            ${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd makepath ${ZNODE_LOCK}
          fi
          break
        fi
      done

      # Waiting until minimal nodes have started.
      while [ ${#LIVE_NODE_LIST[@]} -lt ${NUM_SHARDS} ]
      do
        LIVE_NODE_LIST=($(curl -s "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/zookeeper?detail=true&path=%2Flive_nodes" | jq -r ".tree[].children[].data.title"))
        sleep 2
      done

      # Get collection list.
      COLLECTION_NAME_LIST=($(curl -s "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/collections?action=LIST&wt=json" | jq -r '.collections[]'))
      if [[ ! " ${COLLECTION_NAME_LIST[@]} " =~ " ${COLLECTION_NAME} " ]]; then
        # Create collection.
        curl -s "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/collections?action=CREATE&name=${COLLECTION_NAME}&numShards=${NUM_SHARDS}&collection.configName=${COLLECTION_CONFIG_NAME}" | xmllint --format -
      fi

      # unlock
      for ZK_HOST_SERVER in "${ZK_HOST_LIST[@]}"
      do
        # Split ZK_HOST_SERVER into ZK_HOST_NAME and ZK_HOST_PORT.
        ZK_HOST_NAME=$(echo ${ZK_HOST_SERVER} | cut -d":" -f1)
        ZK_HOST_PORT=$(echo ${ZK_HOST_SERVER} | cut -d":" -f2)

        # Check ZooKeeper node.
        if ! RESPONSE=$(echo "ruok" | nc ${ZK_HOST_NAME} ${ZK_HOST_PORT} 2>/dev/null); then
          continue
        fi
        if [ "${RESPONSE}" = "imok" ]; then
          # Check znode for Lock.
          MATCHED_ZNODE=$(${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | grep -E "^\s+${ZNODE_LOCK}\s+.*$" | sed -e "s|^ \{1,\}\(${ZNODE_LOCK}\) \{1,\}.*|\1|g")
          if [ -n "${MATCHED_ZNODE}" ]; then
            # Delete lock node
            ${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd clear ${ZNODE_LOCK}
          fi

        fi
      done
    else
      sleep 5
    fi

    # Waiting until the collection has unlocked.
    COLLECTION_LOCK=1
    while [ ${COLLECTION_LOCK} -eq 1 ]
    do
      for ZK_HOST_SERVER in "${ZK_HOST_LIST[@]}"
      do
        # Split ZK_HOST_SERVER into ZK_HOST_NAME and ZK_HOST_PORT.
        ZK_HOST_NAME=$(echo ${ZK_HOST_SERVER} | cut -d":" -f1)
        ZK_HOST_PORT=$(echo ${ZK_HOST_SERVER} | cut -d":" -f2)

        # Check ZooKeeper node.
        if ! RESPONSE=$(echo "ruok" | nc ${ZK_HOST_NAME} ${ZK_HOST_PORT} 2>/dev/null); then
          continue
        fi
        if [ "${RESPONSE}" = "imok" ]; then
          MATCHED_ZNODE=$(${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | grep -E "^\s+${ZNODE_LOCK}\s+.*$" | sed -e "s|^ \{1,\}\(${ZNODE_LOCK}\) \{1,\}.*|\1|g")
          if [ -z "${MATCHED_ZNODE}" ]; then
            COLLECTION_LOCK=0
            break
          fi
        fi
      done
    done

    # Waiting until the collection has created.
    COLLECTION_NAME_LIST=($(curl -s "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/collections?action=LIST&wt=json" | jq -r '.collections[]'))
    while [[ ! " ${COLLECTION_NAME_LIST[@]} " =~ " ${COLLECTION_NAME} " ]]
    do
      COLLECTION_NAME_LIST=($(curl -s "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/collections?action=LIST&wt=json" | jq -r '.collections[]'))
      sleep 1
    done

    # Add replica.
    STATE_JSON=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/zookeeper?detail=true&path=%2Fcollections%2F${COLLECTION_NAME}%2Fstate.json")
    NODE_LIST=($(echo ${STATE_JSON} | jq -r ".znode.data" | jq -r ".${COLLECTION_NAME}.shards[].replicas[].node_name"))
    if [[ ! " ${NODE_LIST[@]} " =~ " ${NODE_NAME} " ]]; then
      # Get shard name to add node.
      SHARD_NAME=$(echo ${STATE_JSON} | jq -r ".znode.data" | jq -r ".${COLLECTION_NAME}.shards" | jq "to_entries" | jq "min_by(.value.replicas | length)" | jq -r ".key")
      # Add node as replica to shard of collection.
      curl -s "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/collections?action=ADDREPLICA&collection=${COLLECTION_NAME}&shard=${SHARD_NAME}&node=${NODE_NAME}" | xmllint --format -
    fi

    echo "${NODE_NAME} is available."
  else
    # Start standalone Solr.
    ${SOLR_PREFIX}/bin/solr start -h ${SOLR_HOST} -p ${SOLR_PORT} -s ${SOLR_HOME}

    if [ -n "${CORE_NAME}" ]; then
      # Create core.
      curl -s "http://${SOLR_HOST}:${SOLR_PORT}/solr/admin/cores?action=CREATE&name=${CORE_NAME}&configSet=${CONFIG_SET}&dataDir=${DATA_DIR}" | xmllint --format -
    fi

    echo "Standalone Solr is available."
  fi
}

# Stop function.
function stop() {
  if [ -n "${ZK_HOST}" ]; then
    NODE_NAME=${SOLR_HOST}:${SOLR_PORT}_solr
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
}

trap "stop; exit 1" TERM KILL INT QUIT

# Start
start

# Start infinitive loop
while true
do
 tail -F /dev/null & wait ${!}
done
