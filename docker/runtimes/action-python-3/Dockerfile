FROM jboss/base:latest

USER root

RUN yum -y install centos-release-scl-rh gcc libxslt-devel libxml2-devel \
  && yum -y install rh-python36 rh-python36-python-pip rh-python36-python-setuptools rh-python36-python-six rh-python36-python-devel \
  && scl enable rh-python36 "pip3 install --no-cache-dir \
        gevent==1.1.2 \
        flask==0.11.1 \
        beautifulsoup4==4.5.1 \
        httplib2==0.9.2 \
        kafka_python==1.3.1 \
        lxml==3.6.4 \
        python-dateutil==2.5.3 \
        requests==2.11.1 \
        scrapy==1.1.2 \
        simplejson==3.8.2 \
        virtualenv==15.1.0 \
        twisted==16.4.0" \
  && yum -y remove gcc libxslt-devel libxml2-devel \
  && yum clean all \
  && rm -rf /var/cache/yum

ENV FLASK_PROXY_PORT 8080

ADD https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-docker/dockerskeleton%401.1.0/core/actionProxy/actionproxy.py /actionProxy/actionproxy.py
ADD https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-python/3%401.0.0/core/pythonAction/pythonrunner.py /pythonAction/pythonrunner.py

RUN mkdir /action \
  && chown jboss:root -R /action \
  && chmod -R g+rwX /action \
  # OpenShift compatibility
  && chgrp -R 0 /opt/jboss \
  && chmod -R g+rwX /opt/jboss \
  && chown jboss:root -R /pythonAction \
  && chgrp -R 0 /pythonAction \
  && chmod -R g+rwX /pythonAction \
  && chown jboss:root -R /actionProxy \
  && chgrp -R 0 /actionProxy \
  && chmod -R g+rwX /actionProxy

USER 1000

CMD ["/bin/bash", "-c", "cd /pythonAction && scl enable rh-python36 'python -u pythonrunner.py'"]

