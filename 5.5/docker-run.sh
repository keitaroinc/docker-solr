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

# Show environment variables.
echo "SOLR_PREFIX=${SOLR_PREFIX}"
echo "SOLR_HOME=${SOLR_HOME}"
echo "SOLR_HOST=${SOLR_HOST}"
echo "SOLR_PORT=${SOLR_PORT}"
echo "ZK_HOST=${ZK_HOST}"

# Check ZK_HOST.
if [ -n "${ZK_HOST}" ]; then
  # Split ZK_HOST into ZK_HOST_LIST and ZK_ZNODE.
  declare -a ZK_HOST_LIST=()
  ZK_HOST_LIST=($(echo ${ZK_HOST} | sed -e 's/^\(.\{1,\}:[0-9]\{1,\}\)*\(.*\)$/\1/g' | tr -s ',' ' '))
  ZK_ZNODE=$(echo ${ZK_HOST} | sed -e 's/^\(.\{1,\}:[0-9]\{1,\}\)*\(.*\)$/\2/g')

  for ZK_HOST_SERVER in ${ZK_HOST_LIST}
  do
    # Split ZK_HOST_SERVER into ZK_HOST_NAME and ZK_HOST_PORT.
    ZK_HOST_NAME=$(echo ${ZK_HOST_SERVER} | cut -d":" -f1)
    ZK_HOST_PORT=$(echo ${ZK_HOST_SERVER} | cut -d":" -f2)

    # Check ZooKeeper node.
    if ! RESPONSE=$(echo "ruok" | nc ${ZK_HOST_NAME} ${ZK_HOST_PORT} 2>/dev/null); then
      echo "${ZK_HOST_NAME}:${ZK_HOST_PORT} does not working."
      continue
    fi
    if [ "${RESPONSE}" = "imok" ]; then
      # Check znode for SolrCloud.
      MATCHED_ZNODE=$(
        ${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | \
          grep -E "^\s+${ZK_ZNODE}\s+.*$" | \
          sed -e "s|^ \{1,\}\(${ZK_ZNODE}\) \{1,\}.*|\1|g"
      )
      if [ "${ZK_ZNODE}" != "${MATCHED_ZNODE}" ]; then
        # Create znode for SolrCloud.
        ${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd makepath ${ZK_ZNODE}
      else
        echo "${ZK_HOST_NAME}:${ZK_HOST_PORT} already has ${ZK_ZNODE}."
      fi

      # Get configsets name list.
      CONFIGSETS_LIST=$(find ${SOLR_HOME}/configsets -d 1 -type d | awk -F / '{ print $NF }')
      for CONFIGSETS in ${CONFIGSETS_LIST}
      do
        # Check configset.
        MATCHED_CONFIGSETS=$(
          ${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | \
            grep -E "^\s+${ZK_ZNODE}/configs/${CONFIGSETS}\s+.*$" | \
            sed -e "s|^ \{1,\}${ZK_ZNODE}/configs/\(${CONFIGSETS}\) \{1,\}.*|\1|g"
        )
        if [ "${CONFIGSETS}" != "${MATCHED_CONFIGSETS}" ]; then
          # Upload configset
          ${SOLR_PREFIX}/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT}${ZK_ZNODE} -cmd upconfig -confdir ${SOLR_HOME}/configsets/${CONFIGSETS}/conf/ -confname ${CONFIGSETS} 
        else
          echo "${ZK_HOST_NAME}:${ZK_HOST_PORT}${ZK_ZNODE} already has ${CONFIGSETS}."
          continue
        fi
      done
    else
      echo "${ZK_HOST_NAME}:${ZK_HOST_PORT} status NG."
      continue
    fi
  done

  # Start SolrCloud.
  ${SOLR_PREFIX}/bin/solr -f -h ${SOLR_HOST} -p ${SOLR_PORT} -z ${ZK_HOST} -s ${SOLR_HOME}
else
  # Start standalone Solr.
  ${SOLR_PREFIX}/bin/solr -f -h ${SOLR_HOST} -p ${SOLR_PORT} -s ${SOLR_HOME}
fi
