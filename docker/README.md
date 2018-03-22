This directory contains the Dockerfiles and other artifacts to
build specialized docker images for deploying OpenWhisk to OpenShift

## Rebuilding the images locally:

Ensure you're working with the same docker repo that your OpenShift
cluster is using. On minishift, do this:

    eval $(minishift docker-env)

The following are automatically built by DockerHub. To test local
changes, you can build them manually:
    
    docker build --tag projectodd/whisk_couchdb:openshift-latest docker/couchdb
    docker build --tag projectodd/whisk_catalog:openshift-latest docker/catalog
    docker build --tag projectodd/whisk_alarms:openshift-latest docker/alarms

The action runtimes are not built automatically. Their directory names
match the image names in the templates, so to build them locally:

    for i in $(ls docker/runtimes/); 
      do docker build --tag projectodd/$i:openshift-latest docker/runtimes/$i; 
    done

And to push them to DockerHub:

    for i in $(ls docker/runtimes/); do docker push projectodd/$i:openshift-latest; done

