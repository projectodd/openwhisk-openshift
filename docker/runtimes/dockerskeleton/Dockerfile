# Latest images from Mar 22nd
FROM jboss/base@sha256:39bcf23f34ca58db0769121674d2a82aa4ea2ae9c956e280cb0ba1ef64c68b51

ARG OPENWHISK_RUNTIME_VERSION="dockerskeleton@1.2.0"

ENV FLASK_PROXY_PORT 8080

USER root

RUN yum -y --setopt=tsflags=nodocs install epel-release \
  && yum -y --setopt=tsflags=nodocs install python-pip \
  && yum clean all \
  && rm -rf /var/cache/yum \
  && pip install --no-cache-dir gevent==1.2.1 flask==0.12 \
  && mkdir -p /action /actionProxy \
  && curl -sSL https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-docker/$OPENWHISK_RUNTIME_VERSION/core/actionProxy/actionproxy.py -o /actionProxy/actionproxy.py \
  && curl -sSL https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-docker/$OPENWHISK_RUNTIME_VERSION/core/actionProxy/stub.sh -o /action/exec \
  && chmod +x /action/exec \
  && for d in /action /actionProxy; do chown jboss:root -R $d; chmod -R g+rwX $d; done

USER 1000

CMD ["/bin/bash", "-c", "cd /actionProxy && python -u actionproxy.py"]
