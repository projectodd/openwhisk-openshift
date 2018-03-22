# Latest images from Mar 22nd
FROM jboss/base@sha256:39bcf23f34ca58db0769121674d2a82aa4ea2ae9c956e280cb0ba1ef64c68b51

USER root

RUN yum -y --setopt=tsflags=nodocs install centos-release-scl-rh \
  && yum -y --setopt=tsflags=nodocs install rh-php71 rh-php71-php-mysqlnd rh-php71-php-gd rh-php71-php-mbstring \
  && yum clean all \
  && rm -rf /var/cache/yum \
  # Install composer
  && curl -s -f -L -o /tmp/installer.php https://getcomposer.org/installer \
  && scl enable rh-php71 "php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer" \
  && scl enable rh-php71 "composer --ansi --version --no-interaction" \
  && rm -rf /tmp/installer.php

USER 1000

ARG OPENWHISK_RUNTIME_PHP_VERSION="7.1@1.0.0"

RUN curl -L -O https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-php/$OPENWHISK_RUNTIME_PHP_VERSION/core/php7.1Action/composer.json \
  && curl -L -O https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-php/$OPENWHISK_RUNTIME_PHP_VERSION/core/php7.1Action/router.php \
  && curl -L -O https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-php/$OPENWHISK_RUNTIME_PHP_VERSION/core/php7.1Action/runner.php \
  && sed -i "s|/usr/local/bin/php|/opt/rh/rh-php71/root/usr/bin/php|" router.php \
  && scl enable rh-php71 "composer install --no-plugins --no-scripts --prefer-dist --no-dev -o" \
  && rm composer.lock \
  && mkdir src

USER root

RUN chgrp -R 0 /opt/jboss \
  && chmod -R g+rwX /opt/jboss

USER 1000

CMD ["scl", "enable", "rh-php71", "php -S 0.0.0.0:8080 -d expose_php=0 -d html_errors=0 -d error_reporting=E_ALL /opt/jboss/router.php"]
