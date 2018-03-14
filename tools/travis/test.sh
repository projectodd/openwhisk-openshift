#!/bin/bash

#################
# Smoke test: create and invoke simple actions for various runtimes
#################

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"
cd $ROOTDIR

# To avoid hiding "admin bugs", do it as a guest
AUTH_SECRET=$(oc get secret whisk.auth -o yaml | grep "guest:" | awk '{print $2}' | base64 --decode)
wsk property set --auth $AUTH_SECRET --apihost $(oc get route/openwhisk --template={{.spec.host}})

invoke () {
  if [ -z "$1" ]; then
    echo "Error, invoke called without function name parameter"
    exit 1
  fi

  RESULT=$(wsk -i action invoke -b "$1" | grep "\"status\": \"success\"")

  if [ -z "$RESULT" ]; then
      echo "FAILED! Error invoking action, $1, retrying to show output..."

      wsk -i action invoke -b "$1"

      exit 1
  fi

  echo "$1 invoked successfully"
}

# Create actions
wsk -i action create vars-py resources/vars.py 
wsk -i action create vars-js6 resources/vars.js --kind nodejs:6
wsk -i action create vars-java resources/vars.jar --main Vars

# Invoke then delete them
for i in {py,js6,java}; do
    invoke vars-$i
    wsk -i action delete vars-$i
done

echo "PASSED! All actions invoked successfully"
