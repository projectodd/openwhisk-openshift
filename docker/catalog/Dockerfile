# Latest images from Mar 22nd
FROM jboss/base@sha256:39bcf23f34ca58db0769121674d2a82aa4ea2ae9c956e280cb0ba1ef64c68b51

ENV \
  OPENWHISK_CATALOG_SHA=654b24b45600506f6dc787b4c178b0cfea963bd2 \
  OPENWHISK_HOME=/openwhisk

USER root

RUN \
  # Install CLI
  mkdir -p $OPENWHISK_HOME/bin \
  && curl -L https://github.com/projectodd/openwhisk-openshift/releases/download/latest/OpenWhisk_CLI-latest-linux-amd64.tgz | tar -xzf - -C $OPENWHISK_HOME/bin \
  # Install catalog packages
  && mkdir -p $OPENWHISK_HOME/catalog \
  && curl -L https://github.com/apache/incubator-openwhisk-catalog/archive/$OPENWHISK_CATALOG_SHA.tar.gz | tar --strip-components=2 -C $OPENWHISK_HOME/catalog -xzf - incubator-openwhisk-catalog-$OPENWHISK_CATALOG_SHA/packages/ \
  # Change the owner + OpenShift compatibility
  && for d in /openwhisk /.npm; do mkdir -p $d; chown jboss:root -R $d; chmod -R g+rwX $d; done

USER 1000

CMD ["/bin/sh", "-xc", "$OPENWHISK_HOME/catalog/installCatalog.sh $WHISK_AUTH $WHISK_API_HOST_NAME $OPENWHISK_HOME/bin/wsk"]
