FROM openwhisk/python2action:1.0.0

# OpenShift compatibility
RUN chgrp -R 0 /pythonAction \
  && chmod -R g+rwX /pythonAction \
  && mkdir -p /action \
  && chgrp -R 0 /action \
  && chmod -R g+rwX /action
