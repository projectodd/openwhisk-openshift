FROM nginx:1.11

RUN mkdir -p /var/cache/nginx \
  && chgrp -R 0 /var/cache/nginx \
  && chmod -R g+rwX /var/cache/nginx \
  && chgrp -R 0 /var/run \
  && chmod -R g+rwX /var/run
