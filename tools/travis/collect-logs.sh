#!/bin/bash

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"

cd $ROOTDIR

echo "Gathering logs to upload to https://app.box.com/v/openwhisk-travis-logs"

mkdir logs

# Logs from all the pods
oc logs $(oc get pod -lname=couchdb --no-headers | awk '{print $1}') >& logs/couchdb.log
oc logs $(oc get pod -lname=zookeeper --no-headers | awk '{print $1}') >& logs/zookeeper.log
oc logs $(oc get pod -lname=kafka --no-headers | awk '{print $1}') >& logs/kafka.log
oc logs controller-0 >& logs/controller-0.log
oc logs controller-1 >& logs/controller-1.log
# oc logs -lname=invoker -c docker-pull-runtimes >& logs/invoker-docker-pull.log
oc logs invoker-0 >& logs/invoker-invoker.log
oc logs $(oc get pod -lname=nginx --no-headers | awk '{print $1}') >& logs/nginx.log
# oc logs jobs/install-routemgmt >& logs/routemgmt.log
oc logs jobs/install-catalog >& logs/catalog.log
oc get pods -o wide --show-all >& logs/all-pods.txt
