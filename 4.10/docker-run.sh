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
SOLR_HEAP_SIZE=${SOLR_HEAP_SIZE:-512m}
ZK_HOST=${ZK_HOST:-""}

# Show environment variables.
echo "SOLR_PREFIX=${SOLR_PREFIX}"
echo "SOLR_HOME=${SOLR_HOME}"
echo "SOLR_HOST=${SOLR_HOST}"
echo "SOLR_PORT=${SOLR_PORT}"
echo "SOLR_HEAP_SIZE=${SOLR_HEAP_SIZE}"
echo "ZK_HOST=${ZK_HOST}"

CLOUD_SCRIPTS_DIR=${SOLR_PREFIX}/server/scripts/cloud-scripts

# Start function
function start() {
  NODE_NAME=${SOLR_HOST}:${SOLR_PORT}_solr

  # Standalo mode or SolrCloud mode?
  if [ -n "${ZK_HOST}" ]; then

    # Split ZK_HOST into ZK_HOST_LIST and ZK_ZNODE.
    declare -a ZK_HOST_LIST=()
    ZK_HOST_LIST=($(echo ${ZK_HOST} | sed -e 's/^\(.\{1,\}:[0-9]\{1,\}\)*\(.*\)$/\1/g' | tr -s ',' ' '))
    ZK_ZNODE=$(echo ${ZK_HOST} | sed -e 's/^\(.\{1,\}:[0-9]\{1,\}\)*\(.*\)$/\2/g')

    # Create a znode to ZooKeeper.
    for TMP_ZK_HOST in "${ZK_HOST_LIST[@]}"
    do
      # Split TMP_ZK_HOST into ZK_HOST_NAME and ZK_HOST_PORT.
      ZK_HOST_NAME=$(echo ${TMP_ZK_HOST} | cut -d":" -f1)
      ZK_HOST_PORT=$(echo ${TMP_ZK_HOST} | cut -d":" -f2)

      # Check znode for SolrCloud.
      MATCHED_ZNODE=$(${CLOUD_SCRIPTS_DIR}/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | grep -E "^\s+${ZK_ZNODE}\s+.*$")
      if [ -z "${MATCHED_ZNODE}" ]; then
        # Make /solr
        ${CLOUD_SCRIPTS_DIR}/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd makepath ${ZK_ZNODE} > /dev/null 2>&1
      fi
    done

    # Upload local configsets to ZooKeeper.
    declare -a CONFIGSETS_LIST=()
    CONFIGSETS_LIST=($(find ${SOLR_HOME}/configsets -type d -maxdepth 1 -mindepth 1 | awk -F / '{ print $NF }'))
    for CONFIGSETS in ${CONFIGSETS_LIST[@]}
    do
      for TMP_ZK_HOST in "${ZK_HOST_LIST[@]}"
      do
        # Split TMP_ZK_HOST into ZK_HOST_NAME and ZK_HOST_PORT.
        ZK_HOST_NAME=$(echo ${TMP_ZK_HOST} | cut -d":" -f1)
        ZK_HOST_PORT=$(echo ${TMP_ZK_HOST} | cut -d":" -f2)

        # Check configset.
        MATCHED_CONFIGSETS=$(${CLOUD_SCRIPTS_DIR}/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | grep -E "^\s+${ZK_ZNODE}/configs/${CONFIGSETS}\s+.*$")
        if [ -z "${MATCHED_CONFIGSETS}" ]; then
          # Upload configset
          ${CLOUD_SCRIPTS_DIR}/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT}${ZK_ZNODE} -cmd upconfig -confdir ${SOLR_HOME}/configsets/${CONFIGSETS}/conf/ -confname ${CONFIGSETS} > /dev/null 2>&1
        fi
      done
    done

    # Start Solr in SolrCloud mode.
    ${SOLR_PREFIX}/bin/solr start -h ${SOLR_HOST} -p ${SOLR_PORT} -m ${SOLR_HEAP_SIZE} -s ${SOLR_HOME} -z ${ZK_HOST}
  else
    # Start Solr standalone mode.
    ${SOLR_PREFIX}/bin/solr start -h ${SOLR_HOST} -p ${SOLR_PORT} -m ${SOLR_HEAP_SIZE} -s ${SOLR_HOME}
  fi
}

trap "docker-stop.sh; exit 1" TERM KILL INT QUIT

# Start
start

# Start infinitive loop
while true
do
 tail -F /dev/null & wait ${!}
done
