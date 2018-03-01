FROM apache/couchdb:2.1

ADD http://ftp.us.debian.org/debian/pool/main/a/apt/apt-transport-https_1.0.9.8.4_amd64.deb /tmp/apt-transport-https_1.0.9.8.4_amd64.deb
ADD http://ftp.us.debian.org/debian/pool/main/c/curl/libcurl3-gnutls_7.38.0-4+deb8u8_amd64.deb /tmp/libcurl3-gnutls_7.38.0-4+deb8u58_amd64.deb
RUN dpkg -i /tmp/libcurl3-gnutls_7.38.0-4+deb8u58_amd64.deb
RUN dpkg -i /tmp/apt-transport-https_1.0.9.8.4_amd64.deb

RUN apt-get -y update && apt-get -y install \
  git \
  curl \
  sudo \
  python-dev \
  python-pip \
  libffi-dev \
  libuid-wrapper \
  libssl-dev

RUN pip install --upgrade setuptools
RUN pip install argcomplete
RUN pip install couchdb
RUN pip install --upgrade cffi
RUN pip install markupsafe
RUN pip install ansible==2.3.0.0
RUN pip install -U pyopenssl

ARG OPENWHISK_REPO_URL=https://github.com/projectodd/incubator-openwhisk
ARG OPENWHISK_REPO_HASH=remotes/origin/kube-container-openshift

RUN git clone $OPENWHISK_REPO_URL /openwhisk && \
    cd /openwhisk && \
    git reset --hard $OPENWHISK_REPO_HASH

RUN chgrp -R 0 /openwhisk && \
    chmod -R g=u /openwhisk && \
    chgrp -R 0 /opt/couchdb && \
    chmod -R g=u /opt/couchdb && \
    chmod -R 0770 /opt/couchdb/data && \
    chmod 664 /opt/couchdb/etc/*.ini && \
    chmod 664 /opt/couchdb/etc/local.d/*.ini && \
    chmod 775 /opt/couchdb/etc/*.d && \
    mkdir -p /.ansible && \
    chgrp -R 0 /.ansible && \
    chmod -R g+rwX /.ansible

COPY init.sh /init.sh
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /init.sh /docker-entrypoint.sh

CMD ["/init.sh"]
