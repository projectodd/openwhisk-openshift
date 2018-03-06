FROM openwhisk/action-php-v7.1:1.0.0

# OpenShift compatibility
RUN chgrp -R 0 /action \
  && chmod -R g+rwX /action
