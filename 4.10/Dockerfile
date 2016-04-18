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

FROM java:openjdk-8-jre
MAINTAINER Minoru Osuka "minoru.osuka@gmail.com"

ENV SOLR_GROUP solr
ENV SOLR_USER solr
ENV SOLR_UID 8983
ENV HOME=/home/${SOLR_USER}
ENV SOLR_VERSION 4.10.4
ENV SOLR_PREFIX ${HOME}/solr-${SOLR_VERSION}

RUN apt-get update && \
    apt-get install -y tar netcat lsof jq libxml2-utils && \
    apt-get clean && \
    groupadd -r ${SOLR_GROUP} && \
    useradd -u ${SOLR_UID} -g ${SOLR_GROUP} -d ${HOME} ${SOLR_USER} && \
    curl -L -o ${HOME}/solr-${SOLR_VERSION}.tgz http://archive.apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz
    tar -xzf ${HOME}/solr-${SOLR_VERSION}.tgz -C ${HOME} && \
    rm ${HOME}/solr-${SOLR_VERSION}.tgz
    chown -R ${SOLR_USER}:${SOLR_GROUP} ${HOME}

# Add webdefault.xml (Enable CORS)
ADD webdefault.xml ${SOLR_PREFIX}/server/etc

# Add start script
ADD docker-run.sh /usr/local/bin/
ADD docker-stop.sh /usr/local/bin/

EXPOSE 8983 7983 18983
USER ${SOLR_USER}

CMD ["/usr/local/bin/docker-run.sh"]
