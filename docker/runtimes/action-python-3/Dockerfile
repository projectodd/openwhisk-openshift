# Latest image from Mar 22nd
FROM jboss/base@sha256:39bcf23f34ca58db0769121674d2a82aa4ea2ae9c956e280cb0ba1ef64c68b51

USER root

COPY requirements.txt .

RUN yum -y --setopt=tsflags=nodocs install centos-release-scl-rh gcc libxslt-devel libxml2-devel \
  && yum -y --setopt=tsflags=nodocs install rh-python36 rh-python36-python-pip rh-python36-python-setuptools rh-python36-python-six rh-python36-python-devel \
  && scl enable rh-python36 "pip3 install --no-cache-dir -r requirements.txt" \
  && yum -y remove gcc libxslt-devel libxml2-devel \
  && yum clean all \
  && rm -rf /var/cache/yum

ENV FLASK_PROXY_PORT 8080

ARG OPENWHISK_RUNTIME_DOCKER_VERSION="dockerskeleton@1.1.0"
ARG OPENWHISK_RUNTIME_PYTHON_VERSION="3@1.0.0"

ADD https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-docker/$OPENWHISK_RUNTIME_DOCKER_VERSION/core/actionProxy/actionproxy.py /actionProxy/actionproxy.py
ADD https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-python/$OPENWHISK_RUNTIME_PYTHON_VERSION/core/pythonAction/pythonrunner.py /pythonAction/pythonrunner.py

# OpenShift compatibility
RUN mkdir /action && for d in /action /opt/jboss /pythonAction /actionProxy; do chown jboss:root -R $d; chmod -R g+rwX $d; done

USER 1000

CMD ["/bin/bash", "-c", "cd /pythonAction && scl enable rh-python36 'python -u pythonrunner.py'"]

