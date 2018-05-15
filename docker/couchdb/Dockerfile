# Latest images from Mar 22nd
FROM jboss/base@sha256:39bcf23f34ca58db0769121674d2a82aa4ea2ae9c956e280cb0ba1ef64c68b51

COPY couchdb.repo /etc/yum.repos.d/couchdb.repo
COPY init.sh /init.sh
COPY docker-entrypoint.sh /docker-entrypoint.sh

ARG OPENWHISK_REPO_URL=https://github.com/apache/incubator-openwhisk
ARG OPENWHISK_REPO_HASH=fbc0091

USER root

RUN yum -y --setopt=tsflags=nodocs install epel-release \
  && yum -y --setopt=tsflags=nodocs install http://vault.centos.org/centos/7.1.1503/cr/x86_64/Packages/js-1.8.5-19.el7.x86_64.rpm \
  && yum -y --setopt=tsflags=nodocs install couchdb python2-pip gcc python-devel uid_wrapper openssl \
  && pip install -U ansible==2.3.0.0 couchdb argcomplete cffi markupsafe pyopenssl \
  && yum -y remove gcc python-devel \
  && yum clean all \
  && rm -rf /var/cache/yum \
  && chmod +x /init.sh /docker-entrypoint.sh \
  && mkdir /openwhisk \
  && mkdir /.ansible \
  && cd /openwhisk \
  && curl -L -o owsk.tar.gz $OPENWHISK_REPO_URL/archive/$OPENWHISK_REPO_HASH.tar.gz \
  && tar --strip-components=1 -xf owsk.tar.gz \
  && rm -rf owsk.tar.gz

COPY vm.args /opt/couchdb/etc/

RUN rm -f /opt/couchdb/etc/default.d/*.ini \
  && for d in /openwhisk /opt/couchdb /var/lib/couchdb /var/log/couchdb/ /.ansible; do chown jboss:root -R $d; chmod -R g+rwX $d; done

WORKDIR /opt/couchdb
EXPOSE 5984 4369 9100

USER 1000

CMD ["/init.sh"]

