#!/bin/bash

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"

cd $ROOTDIR

# Logs from all the pods
echo "### STRIMZI LOGS ###"
oc logs $(oc get pods | grep strimzi-cluster-controller | awk '{print $1}')
echo ""
echo ""
echo "### ZOOKEEPER LOGS ###"
oc logs $(oc get pods | grep zookeeper | awk '{print $1}')
echo ""
echo ""
echo "### KAFKA LOGS ###"
oc logs $(oc get pods | grep kafka | awk '{print $1}')
echo ""
echo ""
echo "### COUCHDB LOGS ###"
oc logs $(oc get pods | grep couchdb | awk '{print $1}')
echo ""
echo ""
echo "### ALARMPROVIDER LOGS ###"
oc logs $(oc get pods | grep alarmprovider | awk '{print $1}')
echo ""
echo ""
echo "### CONTROLLER LOGS ###"
oc logs controller-0
echo ""
echo ""
echo "### INVOKER LOGS ###"
oc logs invoker-0
echo ""
echo ""
echo "### PODS ###"
oc get pods -o wide --show-all
oc describe pods
echo ""
echo ""
echo "### NODES ###"
oc login -u system:admin
oc describe nodes
