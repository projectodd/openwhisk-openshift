FROM centos:7

RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN yum update -y \
  && yum install -y epel-release \
  && yum repolist \
  && yum install -y curl git npm zip \
  && yum clean all

# Clone the alarm provider
RUN git clone https://github.com/apache/incubator-openwhisk-package-alarms /openwhisk-package-alarms \
  && cd /openwhisk-package-alarms \
  && git checkout 1.9.0 \
  && cd /

# Install wsk binary
RUN mkdir -p /openwhisk/bin
RUN curl -L https://github.com/projectodd/openwhisk-openshift/releases/download/latest/OpenWhisk_CLI-latest-linux-amd64.tgz | tar xz && mv wsk /openwhisk/bin/wsk

# Ensure we can write to needed directories on OpenShift
RUN chgrp -R 0 /openwhisk-package-alarms \
  && chmod -R g+rwX /openwhisk-package-alarms \
  && mkdir -p /.npm \
  && chgrp -R 0 /.npm \
  && chmod -R g+rwX /.npm

ENV OPENWHISK_HOME /openwhisk
COPY alarms-init.sh /init.sh

ENTRYPOINT ["/bin/bash", "/init.sh"]
