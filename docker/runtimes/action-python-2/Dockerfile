FROM jboss/base:latest

USER root

RUN yum -y install python-setuptools gcc python-devel \
  && easy_install pip \
  && pip install --no-cache-dir --upgrade pip setuptools six \
  && pip install --no-cache-dir \
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
        twisted==16.4.0 \
  && yum -y remove gcc python-devel \
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

CMD ["/bin/bash", "-c", "cd /pythonAction && python -u pythonrunner.py"]
