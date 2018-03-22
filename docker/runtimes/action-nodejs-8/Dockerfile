# Latest image from Mar 22nd
FROM bucharestgold/centos7-s2i-nodejs@sha256:929dad2c6003a01d7b27fb6eec5cf94a43ac6cda8664ff5918e8482b82d8daf0

ARG OPENWHISK_RUNTIME_NODEJS_VERSION="8@1.3.0"

RUN curl -L -o nodejs.tar.gz https://github.com/apache/incubator-openwhisk-runtime-nodejs/archive/$OPENWHISK_RUNTIME_NODEJS_VERSION.tar.gz \
  && mkdir nodejs \
  && tar --strip-components=1 -xf nodejs.tar.gz -C nodejs \
  && mv nodejs/core/nodejsActionBase/app.js nodejs/core/nodejsActionBase/runner.js nodejs/core/nodejsActionBase/src /opt/app-root/src/ \
  && curl -L -O https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-nodejs/$OPENWHISK_RUNTIME_NODEJS_VERSION/core/nodejs8Action/package.json \
  # Cleanup
  && rm -rf /opt/app-root/src/nodejs/ /opt/app-root/src/nodejs.tar.gz \
  # Install
  && npm install \
  && npm cache clean --force

USER root

RUN chown -R default:root /opt/app-root/src \
  && chmod -R g+rwX /opt/app-root/src

USER 1001

CMD ["node", "--expose-gc", "app.js"]
