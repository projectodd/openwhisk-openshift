#!/usr/bin/env bash

set -e

quiet="false"
warnings="false"
errors="false"

for arg in $@; do
  if [ "$arg" == "-q" ]; then
    quiet="true"
  fi
  if [ "$arg" == "-h" ]; then
    echo "Usage: $0 [options]"
    echo ""
    echo "Run a quick sanity check to verify the health of an Apache "
    echo "OpenWhisk on OpenShift deployment. If any errors or warnings "
    echo "are found, this command will have a non-zero exit status."
    echo ""
    echo "Options:"
    echo "  -q : Only print warnings or errors"
    exit 0
  fi
done

info() {
  if [ "$quiet" == "false" ]; then
    echo -e "[INFO]: $@"
  fi
}

warn() {
  echo -e "[WARNING]: $@"
  warnings="true"
}

error() {
  echo -e "[ERROR]: $@"
  errors="true"
}

check_pod_status() {
  pod=$1
  pod_status=$(oc get po --no-headers $pod | awk '{print $3}')
  info "$pod Status: ${pod_status}"
  if [ "$pod_status" != "Running" ]; then
    error "Pod $pod isn't running! Status is ${pod_status}."
  fi
}

check_pv_usage() {
  pod=$1
  mount=$2
  max_percent=$3
  percent_used=$(oc rsh $pod df -h | grep $mount | awk '{print $5}' | tr -d '%')
  if [ -n "${percent_used}" ]; then
    info "$pod PV Usage: ${percent_used}%"
    if [ $percent_used -gt $max_percent ]; then
      error "Pod $pod is running out of persistent volume space! ${percent_used}% is used."
    fi
  fi
}

check_invokers_healthy() {
  pod=$1
  num_expected=$2
  healthy_list=$(oc logs controller-0 | grep "invoker status changed to" | tail -n 1)
  num_healthy=$(echo $healthy_list | grep -o '\-> Healthy' | wc -l)
  info "$pod has $num_healthy healthy invokers"
  if [ $num_healthy -ne $num_expected ]; then
    error "Pod $pod has unhealthy invokers! Number healthy: ${num_healthy}, expected: $num_expected"
    error "    $healthy_list"
  fi
}

num_replicas() {
  resource="$1"
  oc get $resource --template='{{.spec.replicas}}'
}

kafka_count=$(num_replicas "statefulset/strimzi-openwhisk-kafka")
for ((i=0; i < $kafka_count; i++)); do
  pod="strimzi-openwhisk-kafka-${i}"
  check_pod_status $pod
  check_pv_usage $pod "/var/lib/kafka" 65
done

zookeeper_count=$(num_replicas "statefulset/strimzi-openwhisk-zookeeper")
for ((i=0; i < $zookeeper_count; i++)); do
  pod="strimzi-openwhisk-zookeeper-${i}"
  check_pod_status $pod
  check_pv_usage $pod "/var/lib/zookeeper" 65
done

couchdb_count=$(num_replicas "statefulset/couchdb")
for ((i=0; i < $couchdb_count; i++)); do
  pod="couchdb-${i}"
  check_pod_status $pod
  check_pv_usage $pod "/var/lib/couchdb" 65
done

controller_count=$(num_replicas "statefulset/controller")
invoker_count=$(num_replicas "statefulset/invoker")
for ((i=0; i < $controller_count; i++)); do
  pod="controller-${i}"
  check_pod_status $pod
  check_invokers_healthy $pod $invoker_count
done

for ((i=0; i < $invoker_count; i++)); do
  pod="invoker-${i}"
  check_pod_status $pod
done

output=$(wsk action invoke /whisk.system/utils/echo -p payload check_openwhisk -b)

if [[ $output != *"\"status\": \"success\""* ]]; then
  error "Unable to invoke echo action. Action output: \n$output"
else
  info "Successfully invoked /whisk.system/utils.echo"
fi

if [ $errors != "false" ] || [ $warnings != "false" ]; then
  exit 1
fi

echo "All tests passed"
