FROM openwhisk/java8action:1.0.1

# OpenShift compatibility
RUN chgrp -R 0 /javaAction \
  && chmod -R g+rwX /javaAction
