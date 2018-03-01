#!/bin/bash

set -a
if [ -e /alarmprovider_config/env ]; then
    source /alarmprovider_config/env
fi

echo "Waiting for controller to be available"
until $(curl --output /dev/null --silent --head --fail http://${CONTROLLER_HOST}:${CONTROLLER_PORT}/ping); do printf '.'; sleep 1; done

cd /openwhisk-package-alarms
./installCatalog.sh ${AUTH_WHISK_SYSTEM} http://${CONTROLLER_HOST}:${CONTROLLER_PORT} ${DB_PROTOCOL}://${DB_HOST} ${DB_PREFIX} ${ROUTER_HOST}
