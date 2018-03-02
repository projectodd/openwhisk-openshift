This directory contains the Dockerfiles and other artifacts to
build specialized docker images for deploying OpenWhisk to OpenShift

## Rebuilding the images locally:

```
eval $(minishift docker-env)
docker build --tag projectodd/whisk_couchdb:openshift-latest docker/couchdb
docker build --tag projectodd/whisk_nginx:openshift-latest docker/nginx
docker build --tag projectodd/whisk_catalog:openshift-latest docker/openwhisk-catalog
docker build --tag projectodd/whisk_alarms:openshift-latest docker/alarms
```

## Public Docker Images

The projectodd/whisk_* images above are automatically built by
DockerHub on every push of this repository.

The OpenShift-specific OpenWhisk images
(projectodd/controller:openshift-latest and friends) are built from
https://github.com/projectodd/incubator-openwhisk/ with the command:

```
export SHORT_COMMIT=$(git rev-parse HEAD | cut -c 1-7)
./gradlew distDocker -PdockerImagePrefix=projectodd -PdockerImageTag=openshift-latest
./gradlew distDocker -PdockerImagePrefix=projectodd -PdockerImageTag=openshift-${SHORT_COMMIT}
```

To publish the above images, add `-PdockerRegistry=docker.io` to each of those commands.
