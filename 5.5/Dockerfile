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

RUN apt-get update \
 && apt-get install -y tar netcat lsof jq libxml2-utils \
 && apt-get clean

# Add group
ENV SOLR_GROUP solr
RUN groupadd -r $SOLR_GROUP

# Add user
ENV SOLR_USER solr
ENV SOLR_UID 8983
RUN useradd -r -u $SOLR_UID -g $SOLR_GROUP $SOLR_USER

# Install ZooKeeper
ENV INSTALL_DIR=/opt
ENV SOLR_VERSION 5.5.0
RUN mkdir -p ${INSTALL_DIR}
WORKDIR ${INSTALL_DIR}
RUN curl -L -o ${INSTALL_DIR}/solr-$SOLR_VERSION.tgz http://archive.apache.org/dist/lucene/solr/$SOLR_VERSION/solr-$SOLR_VERSION.tgz
RUN tar -xzf solr-$SOLR_VERSION.tgz && rm ${INSTALL_DIR}/solr-$SOLR_VERSION.tgz
ENV SOLR_PREFIX ${INSTALL_DIR}/solr-${SOLR_VERSION}
RUN chown -R $SOLR_USER:$SOLR_GROUP $SOLR_PREFIX

# Add start script
ADD docker-run.sh /usr/local/bin/

EXPOSE 8983 7983 18983
USER $SOLR_USER

WORKDIR $SOLR_PREFIX

CMD ["/usr/local/bin/docker-run.sh"]
