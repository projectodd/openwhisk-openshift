FROM openwhisk/nodejs6action:1.5.0

# OpenShift compatibility
RUN chgrp -R 0 /nodejsAction \
  && chmod -R g+rwX /nodejsAction
