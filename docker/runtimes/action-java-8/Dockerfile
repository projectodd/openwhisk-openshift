FROM jboss/base-jdk:8

ARG OPENWHISK_RUNTIME_JAVA_VERSION="8@1.0.1"

RUN curl -L -o java.tar.gz https://github.com/apache/incubator-openwhisk-runtime-java/archive/$OPENWHISK_RUNTIME_JAVA_VERSION.tar.gz \
  && mkdir java \
  && tar --strip-components=1 -xf java.tar.gz -C java \
  && cd java/core/javaAction/proxy \
  # Build the jar
  && ./gradlew oneJar \
  # Copy built jar to home directory
  && mv build/libs/proxy-all.jar /opt/jboss/javaAction-all.jar \
  # Cleanup
  && rm -rf /opt/jboss/java/ /opt/jboss/java.tar.gz \
  && rm -rf /opt/jboss/.gradle

USER root

RUN chgrp -R 0 /opt/jboss \
  && chmod -R g+rwX /opt/jboss

USER 1000

CMD ["java", "-jar", "/opt/jboss/javaAction-all.jar"]
