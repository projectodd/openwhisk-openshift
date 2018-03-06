# Dockerfile for docker skeleton (useful for running blackbox binaries, scripts, or Python 3 actions) .
FROM openwhisk/dockerskeleton:1.1.0

# OpenShift compatibility
RUN chgrp -R 0 /actionProxy \
  && chmod -R g+rwX /actionProxy
