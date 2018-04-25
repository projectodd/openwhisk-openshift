#!/bin/bash

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"
cd $ROOTDIR

TEMPLATE_PARAMS="INVOKER_MEMORY_REQUEST=512Mi INVOKER_MEMORY_LIMIT=512Mi INVOKER_JAVA_OPTS=-Xmx256m INVOKER_MAX_CONTAINERS=2 COUCHDB_MEMORY_REQUEST=256Mi COUCHDB_MEMORY_LIMIT=256Mi"
if [ -n "$1" ]; then            # additional template params may be passed to this script
  TEMPLATE_PARAMS="${TEMPLATE_PARAMS} $1"
fi

oc new-project ${PROJECT_NAME:-openwhisk}
oc process -f ${OPENSHIFT_TEMPLATE:-template.yml} $TEMPLATE_PARAMS | oc create -f -

./bin/wait_for_openwhisk.sh
