#!/bin/bash
set -exu

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"
cd $ROOTDIR

COMMIT=$(git rev-parse HEAD | cut -c 1-7)
VERSION=${1:-$COMMIT}

# docker login -u "${DOCKER_USER}" -p "${DOCKER_PASSWORD}"

publish() {
  dockerhub_image_prefix="$1"
  dockerhub_image_name="$2"
  dockerhub_image_tag="$3"
  dir_to_build="$4"
  dockerhub_image="${dockerhub_image_prefix}/${dockerhub_image_name}:${dockerhub_image_tag}"

  docker build ${dir_to_build} --tag ${dockerhub_image}
  docker push ${dockerhub_image}
}

publish projectodd whisk_couchdb $VERSION docker/couchdb
publish projectodd whisk_nginx $VERSION docker/nginx
publish projectodd whisk_catalog $VERSION docker/catalog
publish projectodd whisk_alarms $VERSION docker/alarms

for i in $(ls docker/runtimes/); do
  publish projectodd $i $VERSION docker/runtimes/$i
done
