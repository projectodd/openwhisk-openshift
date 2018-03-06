from ubuntu:latest

RUN apt-get -y update && apt-get -y install \
  git \
  wget

COPY init.sh /init.sh
RUN chmod +X /init.sh

# Ensure we can write to needed directories on OpenShift
RUN mkdir -p /openwhisk \
  && chgrp -R 0 /openwhisk \
  && chmod -R g+rwX /openwhisk \
  && mkdir -p /openwhisk-catalog \
  && chgrp -R 0 /openwhisk-catalog \
  && chmod -R g+rwX /openwhisk-catalog \
  && mkdir -p /.npm \
  && chgrp -R 0 /.npm \
  && chmod -R g+rwX /.npm

CMD ["/init.sh"]
