#!/bin/bash

#################
# Helper functions for verifying pod creation
#################

couchdbHealthCheck () {
  # wait for the pod to be created before getting the job name
  sleep 5
  POD_NAME=$(oc get pods -o wide --show-all | grep "couchdb" | awk '{print $1}')

  PASSED=false
  TIMEOUT=0
  until [ $TIMEOUT -eq 60 ]; do
    if [ -n "$(oc logs $POD_NAME | grep "successfully setup and configured CouchDB")" ]; then
      PASSED=true
      break
    fi

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to finish deploying CouchDB"

    REPLICA_SET=$(oc get rs -o wide --show-all | grep "couchdb" | awk '{print $1}')
    oc describe rs $REPLICA_SET
    oc describe pod $POD_NAME
    oc logs $POD_NAME
    exit 1
  fi

  echo "CouchDB is up and running"
}

deploymentHealthCheck () {
  if [ -z "$1" ]; then
    echo "Error, component health check called without a component parameter"
    exit 1
  fi

  PASSED=false
  TIMEOUT=0
  until $PASSED || [ $TIMEOUT -eq 60 ]; do
    DEPLOY_STATUS=$(oc get pods -o wide | grep "$1" | awk '{print $3}')
    if [ "$DEPLOY_STATUS" == "Running" ]; then
      PASSED=true
      break
    fi

    oc get pods -o wide --show-all

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to finish deploying $1"

    oc logs $(oc get pods -o wide | grep "$1" | awk '{print $1}')
    exit 1
  fi

  echo "$1 is up and running"
}

statefulsetHealthCheck () {
  if [ -z "$1" ]; then
    echo "Error, StatefulSet health check called without a parameter"
    exit 1
  fi

  PASSED=false
  TIMEOUT=0
  until $PASSED || [ $TIMEOUT -eq 60 ]; do
    DEPLOY_STATUS=$(oc get pods -o wide | grep "$1"-0 | awk '{print $3}')
    if [ "$DEPLOY_STATUS" == "Running" ]; then
      PASSED=true
      break
    fi

    oc get pods -o wide --show-all

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to finish deploying $1"

    oc logs $(oc get pods -o wide | grep "$1"-0 | awk '{print $1}')
    exit 1
  fi

  echo "$1-0 is up and running"

}

jobHealthCheck () {
  if [ -z "$1" ]; then
    echo "Error, job health check called without a component parameter"
    exit 1
  fi

  PASSED=false
  TIMEOUT=0
  until $PASSED || [ $TIMEOUT -eq 60 ]; do
    SUCCESSFUL_JOB=$(oc get jobs -o wide | grep "$1" | awk '{print $3}')
    if [ "$SUCCESSFUL_JOB" == "1" ]; then
      PASSED=true
      break
    fi

    oc get jobs -o wide --show-all

    let TIMEOUT=TIMEOUT+1
    sleep 10
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to finish running $1"

    oc logs jobs/$1
    exit 1
  fi

  echo "$1 completed"
}

invokerHealthCheck () {
  PASSED=false
  TIMEOUT=0
  until [ $TIMEOUT -eq 60 ]; do
    if [ -n "$(oc logs controller-0 | grep "invoker status changed to 0 -> Healthy")" ]; then
      PASSED=true
      break
    fi

    let TIMEOUT=TIMEOUT+1
    sleep 5
  done

  if [ "$PASSED" = false ]; then
    echo "Failed to find a healthy Invoker"

    oc logs controller-0
    oc logs invoker-0
    exit 1
  fi

  echo "Invoker online and healthy"
}


#################
# Main body of script -- deploy OpenWhisk
#################

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"

cd $ROOTDIR

oc new-project openwhisk
oc process -f openshift/extras/template.yml | oc create -f -

couchdbHealthCheck

# # setup apigateway
# echo "Deploying apigateway"
# pushd kubernetes/apigateway
#   kubectl apply -f apigateway.yml

#   deploymentHealthCheck "apigateway"
# popd

deploymentHealthCheck "zookeeper"
deploymentHealthCheck "kafka"
statefulsetHealthCheck "controller"
deploymentHealthCheck "invoker"
deploymentHealthCheck "nginx"

# # install routemgmt
# echo "Installing routemgmt"
# pushd kubernetes/routemgmt
#   kubectl apply -f install-routemgmt.yml
#   jobHealthCheck "install-routemgmt"
# popd

jobHealthCheck "install-catalog"

invokerHealthCheck

# configure wsk CLI
AUTH_SECRET=$(oc get secret whisk.auth -o yaml | grep "system:" | awk '{print $2}' | base64 --decode)
wsk property set --auth $AUTH_SECRET --apihost $(oc get route/openwhisk --template={{.spec.host}})

# list packages and actions now installed in /whisk.system
wsk -i package list
wsk -i action list


#################
# Sniff test: create and invoke a simple Hello world action
#################

# create wsk action
cat > hello.js << EOL
function main() {
  return {payload: 'Hello world'};
}
EOL

wsk -i action create hello hello.js

# run the new hello world action
RESULT=$(wsk -i action invoke --blocking hello | grep "\"status\": \"success\"")

if [ -z "$RESULT" ]; then
  echo "FAILED! Could not invoked custom action"

  echo " ----------------------------- controller logs ---------------------------"
  oc logs controller-0

  echo " ----------------------------- invoker logs ---------------------------"
  oc logs invoker-0
  exit 1
fi

echo "PASSED! Deployed openwhisk and invoked Hello action"
