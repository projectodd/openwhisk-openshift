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
  RESULT=$(wsk -i action invoke -b "$1" | grep "\"status\": \"success\"")

  if [ -z "$RESULT" ]; then
      wsk -i action invoke -b "$1"
      fail "error: unsuccessful status invoking action, $1"
  fi

  echo "$1 invoked successfully"
}

waitForGreeting () {
  NOW="$(date +%s)000"
  FOUND=false
  TIMEOUT=0
  until [ $TIMEOUT -eq 30 ]; do
    if [ -n "$(wsk -i activation list --since $NOW | grep greeting)" ]; then
      FOUND=true
      break
    fi

    let TIMEOUT=TIMEOUT+1
    sleep 1
  done

  if [ "$FOUND" = false ]; then
    fail "error: unable to detect a greeting activation"
  fi
}

deleteTerminatingPods () {
  for pod in $(oc get pod | grep Terminating | cut -f 1 -d ' '); do
    oc delete pod $pod --force --grace-period=0
  done
}

cleanup () {
  wsk -i rule    delete testsh-invoke-periodically
  wsk -i trigger delete testsh-every-second
  for i in $(wsk -i action list | grep testsh-vars | awk '{print $1}'); do
      wsk -i action delete $i
  done
}

fail () {
  cleanup
  echo $1
  exit 1
}

# Create actions
wsk -i action create testsh-vars-py2 resources/vars.py --kind python:2
wsk -i action create testsh-vars-py3 resources/vars.py --kind python:3
wsk -i action create testsh-vars-js6 resources/vars.js --kind nodejs:6
wsk -i action create testsh-vars-js8 resources/vars.js --kind nodejs:8
wsk -i action create testsh-vars-java resources/vars.jar --main Vars
wsk -i action create testsh-vars-php7 resources/vars.php --kind php:7.1
wsk -i action create testsh-vars-sh resources/vars.sh --native

# Invoke them, and delete them
for i in {py2,py3,js6,js8,java,php7,sh}; do
    invoke testsh-vars-$i
    wsk -i action delete testsh-vars-$i
    deleteTerminatingPods
done

# Fire a greeting every second
wsk -i trigger create testsh-every-second \
    --feed /whisk.system/alarms/alarm \
    --param cron '*/1 * * * * *' \
    --param trigger_payload "{\"name\":\"Odin\",\"place\":\"Asgard\"}"
wsk -i rule create testsh-invoke-periodically testsh-every-second /whisk.system/samples/greeting
if [ ! $? -eq 0 ]; then
    fail "error: failed to create alarm trigger/rule"
fi
# Account for stale reads in activation list
deleteTerminatingPods
waitForGreeting

# Grab the id for the most recent greeting
ID=$(wsk -i activation list | grep greeting | head -1 | awk '{print $1}')
# Ensure we see our expected greeting
RESULT=$(wsk -i activation get $ID | grep "Hello, Odin from Asgard!")
if [ -z "$RESULT" ]; then
    fail "error: unable to detect fired alarm trigger"
fi

cleanup
echo "PASSED! All actions invoked successfully"
