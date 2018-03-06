FROM openwhisk/action-nodejs-v8:1.2.0

# OpenShift compatibility
RUN chgrp -R 0 /nodejsAction \
  && chmod -R g+rwX /nodejsAction
