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

waitForGreeting () {
  NOW="$(date +%s)000"
  FOUND=false
  TIMEOUT=0
  until [ $TIMEOUT -eq 10 ]; do
    if [ -n "$(wsk -i activation list --since $NOW | grep greeting)" ]; then
      FOUND=true
      break
    fi

    let TIMEOUT=TIMEOUT+1
    sleep 1
  done

  if [ "$FOUND" = false ]; then
    echo "Failed to detect a greeting activation"
    exit 1
  fi
}

# Create actions
wsk -i action create testsh-vars-py2 resources/vars.py --kind python:2
wsk -i action create testsh-vars-py3 resources/vars.py --kind python:3
wsk -i action create testsh-vars-js6 resources/vars.js --kind nodejs:6
wsk -i action create testsh-vars-js8 resources/vars.js --kind nodejs:8
wsk -i action create testsh-vars-java resources/vars.jar --main Vars

# Invoke then delete them
for i in {py2,py3,js6,js8,java}; do
    invoke testsh-vars-$i
    wsk -i action delete testsh-vars-$i
done

# Fire a greeting every second
wsk -i trigger create testsh-every-second \
    --feed /whisk.system/alarms/alarm \
    --param cron '*/1 * * * * *' \
    --param trigger_payload "{\"name\":\"Odin\",\"place\":\"Asgard\"}"
wsk -i rule create testsh-invoke-periodically testsh-every-second /whisk.system/samples/greeting
if [ ! $? -eq 0 ]; then
    echo "Failed to create alarm trigger/rule"
    exit 1
fi
# Account for stale reads in activation list
waitForGreeting
# Grab the id for the most recent greeting
ID=$(wsk -i activation list | grep greeting | head -1 | awk '{print $1}')
# Ensure we see our expected greeting
RESULT=$(wsk -i activation get $ID | grep "Hello, Odin from Asgard!")
# Clean up
wsk -i rule    delete testsh-invoke-periodically
wsk -i trigger delete testsh-every-second

if [ -z "$RESULT" ]; then
    echo "FAILED! Unable to detect fired alarm trigger"
    exit 1
fi

echo "PASSED! All actions invoked successfully"
