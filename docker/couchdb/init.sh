#!/bin/bash
set -ex

if [ ! -z "$NODENAME_HOSTNAME" ]; then
  export NODENAME="$NODENAME_HOSTNAME.$NODENAME_SUBDOMAIN"
fi

# start couchdb with a background process
/docker-entrypoint.sh /opt/couchdb/bin/couchdb &

# wait for couchdb to be up and running
TIMEOUT=0
echo "wait for CouchDB to be up and running"
until $( curl --location --output /dev/null --fail --head --silent http://localhost:$DB_PORT/_utils ) || [ $TIMEOUT -eq 30 ]; do
  echo "waiting for CouchDB to be available"
  sleep 2
  let TIMEOUT=TIMEOUT+1
done

if [ $TIMEOUT -eq 30 ]; then
  echo "failed to setup CouchDB"
  exit 1
fi

if [ ! -f /opt/couchdb/data/_openwhisk_initialized.stamp ]; then

  LAST_NODE_INDEX="$(($COUCHDB_NODE_COUNT-1))"

  if [ $COUCHDB_NODE_COUNT -gt 1 ]; then

    if [[ "$NODENAME" == couchdb-$LAST_NODE_INDEX* ]]; then
      for (( i=0; i < $LAST_NODE_INDEX; i++ )); do
        ADD_NODE_JSON="{ \"action\": \"add_node\",\"host\":\"couchdb-$i.$NODENAME_SUBDOMAIN\",\"port\": ${DB_PORT},\"username\": \"${COUCHDB_USER}\",\"password\":\"${COUCHDB_PASSWORD}\"}"
        curl -H "Content-Type: application/json" -X POST http://$COUCHDB_USER:$COUCHDB_PASSWORD@localhost:$DB_PORT/_cluster_setup -d "$ADD_NODE_JSON"
      done

      curl -H "Content-Type: application/json" -X POST http://$COUCHDB_USER:$COUCHDB_PASSWORD@localhost:$DB_PORT/_cluster_setup -d '{"action": "finish_cluster"}'
    fi
  else
    # single node, directly create the couchdb system databases
    curl -X PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@localhost:$DB_PORT/_users
    curl -X PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@localhost:$DB_PORT/_replicator
    curl -X PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@localhost:$DB_PORT/_global_changes
  fi

  if [[ "$NODENAME" == couchdb-$LAST_NODE_INDEX* ]]; then
    pushd /openwhisk

    # if auth guest overwrite file
    if [ -n "$AUTH_GUEST" ]; then
      echo "$AUTH_GUEST" > /openwhisk/ansible/files/auth.guest
    fi

    # if auth whisk system overwrite file
    if [ -n "$AUTH_WHISK_SYSTEM" ]; then
      echo "$AUTH_WHISK_SYSTEM" > /openwhisk/ansible/files/auth.whisk.system
    fi

    # Fake our UID because OpenShift runs with random uids
    export LD_PRELOAD=/usr/lib64/libuid_wrapper.so
    export UID_WRAPPER=1
    export UID_WRAPPER_ROOT=1

    # setup and initialize DB
    pushd ansible
      ansible-playbook -i environments/local setup.yml
      ansible-playbook -i environments/local couchdb.yml --tags ini \
        -e db_prefix=$DB_PREFIX \
        -e db_host=$DB_HOST \
        -e db_username=$COUCHDB_USER \
        -e db_password=$COUCHDB_PASSWORD \
        -e db_port=$DB_PORT \
        -e openwhisk_home=/openwhisk
    popd

    pushd ansible
      # initialize the DB
      ansible-playbook -i environments/local initdb.yml \
        -e db_prefix=$DB_PREFIX \
        -e db_host=$DB_HOST \
        -e db_username=$COUCHDB_USER \
        -e db_password=$COUCHDB_PASSWORD \
        -e db_port=$DB_PORT \
        -e openwhisk_home=/openwhisk

      # wipe the DB
      ansible-playbook -i environments/local wipe.yml \
        -e db_prefix=$DB_PREFIX \
        -e db_host=$DB_HOST \
        -e db_username=$COUCHDB_USER \
        -e db_password=$COUCHDB_PASSWORD \
        -e db_port=$DB_PORT \
        -e openwhisk_home=/openwhisk
    popd

    # Unfake the UID
    unset LD_PRELOAD UID_WRAPPER UID_WRAPPER_ROOT
  popd

  # stamp that we successfully initialized the database
  date > /opt/couchdb/data/_openwhisk_initialized.stamp

  echo "successfully setup and configured CouchDB for OpenWhisk"

  fi

fi

sleep inf
