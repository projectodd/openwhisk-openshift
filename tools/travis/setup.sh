# This script assumes Docker is already installed
#!/bin/bash

set -x

# download and install the wsk cli
wget -q https://github.com/apache/incubator-openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-linux-amd64.tgz
tar xzf OpenWhisk_CLI-latest-linux-amd64.tgz
sudo cp wsk /usr/local/bin/wsk

# set docker0 to promiscuous mode
sudo ip link set docker0 promisc on

# Download and install the oc binary
sudo mount --make-shared /
sudo service docker stop
sudo sed -i 's/DOCKER_OPTS=\"/DOCKER_OPTS=\"--insecure-registry 172.30.0.0\/16 /' /etc/default/docker
sudo service docker start
wget https://github.com/openshift/origin/releases/download/v$OPENSHIFT_VERSION/openshift-origin-client-tools-v$OPENSHIFT_VERSION-$OPENSHIFT_COMMIT-linux-64bit.tar.gz
tar xvzOf openshift-origin-client-tools-v$OPENSHIFT_VERSION-$OPENSHIFT_COMMIT-linux-64bit.tar.gz > oc.bin
sudo mv oc.bin /usr/local/bin/oc
sudo chmod 755 /usr/local/bin/oc

# Start OpenShift
oc cluster up

oc login -u system:admin

# Wait until we have a ready node in openshift
TIMEOUT=0
TIMEOUT_COUNT=60
until [ $TIMEOUT -eq $TIMEOUT_COUNT ]; do
  if [ -n "$(oc get nodes | grep Ready)" ]; then
    break
  fi

  echo "openshift is not up yet"
  let TIMEOUT=TIMEOUT+1
  sleep 5
done

if [ $TIMEOUT -eq $TIMEOUT_COUNT ]; then
  echo "Failed to start openshift"
  exit 1
fi

echo "openshift is deployed and reachable"
oc describe nodes

oc login -u developer -p any
