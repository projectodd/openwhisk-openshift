# Latest image from Mar 22nd
FROM bucharestgold/centos7-s2i-nodejs@sha256:4a6520ddaad50af4838d2f65013b350a4dd61c7db40208d5051df3226f484999

ARG OPENWHISK_RUNTIME_NODEJS_VERSION="6@1.6.0"

RUN curl -L -o nodejs.tar.gz https://github.com/apache/incubator-openwhisk-runtime-nodejs/archive/$OPENWHISK_RUNTIME_NODEJS_VERSION.tar.gz \
  && mkdir nodejs \
  && tar --strip-components=1 -xf nodejs.tar.gz -C nodejs \
  && mv nodejs/core/nodejsActionBase/app.js nodejs/core/nodejsActionBase/runner.js nodejs/core/nodejsActionBase/src /opt/app-root/src/ \
  && curl -L -O https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-nodejs/$OPENWHISK_RUNTIME_NODEJS_VERSION/core/nodejs8Action/package.json \
  && sed -i 's/action-nodejs-v8/action-nodejs-v6/' package.json \
  # Cleanup
  && rm -rf /opt/app-root/src/nodejs/ /opt/app-root/src/nodejs.tar.gz \
  # Install
  && npm install \
  && npm install \
    apn@2.1.2 \
    async@2.1.4 \
    body-parser@1.15.2 \
    btoa@1.1.2 \
    cheerio@0.22.0 \
    cloudant@1.6.2 \
    commander@2.9.0 \
    consul@0.27.0 \
    cookie-parser@1.4.3 \
    cradle@0.7.1 \
    errorhandler@1.5.0 \
    express@4.14.0 \
    express-session@1.14.2 \
    glob@7.1.1 \
    gm@1.23.0 \
    lodash@4.17.2 \
    log4js@0.6.38 \
    iconv-lite@0.4.15 \
    marked@0.3.6 \
    merge@1.2.0 \
    moment@2.17.0 \
    mongodb@2.2.11 \
    mustache@2.3.0 \
    nano@6.2.0 \
    node-uuid@1.4.7 \
    nodemailer@2.6.4 \
    oauth2-server@2.4.1 \
    openwhisk@3.13.1 \
    pkgcloud@1.4.0 \
    process@0.11.9 \
    pug@">=2.0.0-beta6 <2.0.1" \
    redis@2.6.3 \
    request@2.79.0 \
    request-promise@4.1.1 \
    rimraf@2.5.4 \
    semver@5.3.0 \
    sendgrid@4.7.1 \
    serve-favicon@2.3.2 \
    socket.io@1.6.0 \
    socket.io-client@1.6.0 \
    superagent@3.0.0 \
    swagger-tools@0.10.1 \
    tmp@0.0.31 \
    twilio@2.11.1 \
    underscore@1.8.3 \
    uuid@3.0.0 \
    validator@6.1.0 \
    watson-developer-cloud@2.29.0 \
    when@3.7.7 \
    winston@2.3.0 \
    ws@1.1.1 \
    xml2js@0.4.17 \
    xmlhttprequest@1.8.0 \
    yauzl@2.7.0 \
  && npm cache clean --force

USER root

RUN chown -R default:root /opt/app-root/src \
  && chmod -R g+rwX /opt/app-root/src

USER 1001

CMD ["node", "--expose-gc", "app.js"]

