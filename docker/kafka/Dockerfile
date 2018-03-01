FROM wurstmeister/kafka:0.11.0.1

# Fix perms for Openshift
RUN chgrp -R 0 /opt/kafka \
  && chmod -R g+rwX /opt/kafka
