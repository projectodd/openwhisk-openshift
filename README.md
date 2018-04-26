# OpenWhisk on OpenShift

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
[![Build Status](https://travis-ci.org/projectodd/openwhisk-openshift.svg?branch=master)](https://travis-ci.org/projectodd/openwhisk-openshift)

This repository contains the necessary templates and compatible
[docker](docker/) images for deploying OpenWhisk on OpenShift.

* [Installation](#installation)
* [Using `wsk`](#using-wsk)
  * [Alarms](#alarms)
* [Using `minishift`](#using-minishift)
  * [Testing Local Changes](#testing-local-changes)
* [Shutdown](#shutdown)
* [Advanced Configuration](#advanced-configuration)
    * [Persistent Data](#persistent-data)
    * [Larger Clusters](#larger-clusters)
* [Performance Testing](#performance-testing)
    * [With `ab`](#with-ab)
    * [With `wrk`](#with-wrk)
* [Common Problems](#common-problems)

## Installation

The following command will deploy OpenWhisk in your OpenShift project
using the latest ephemeral template in this repo:

    oc process -f https://git.io/openwhisk-template | oc create -f -

The shortened URL redirects to https://raw.githubusercontent.com/projectodd/openwhisk-openshift/master/template.yml

This will take a few minutes. Verify that all pods eventually enter
the `Running` or `Completed` state. For convenience, use the
[watch](https://en.wikipedia.org/wiki/Watch_(Unix)) command.

    watch oc get all

The system is ready when the controller recognizes the invoker as
healthy:

    oc logs -f controller-0 | grep "invoker status changed"

You should see a message like `invoker status changed to 0 -> Healthy`

## Using `wsk`

Once your cluster is ready, you need to configure your `wsk` binary.
If necessary,
[download it](https://github.com/projectodd/openwhisk-openshift/releases/tag/latest),
unpack it, ensure it's in your PATH, and:

    AUTH_SECRET=$(oc get secret whisk.auth -o yaml | grep "system:" | awk '{print $2}' | base64 --decode)
    wsk property set --auth $AUTH_SECRET --apihost $(oc get route/openwhisk --template="{{.spec.host}}")

That configures `wsk` to use your OpenWhisk. Use the `-i` option to
avoid the validation error triggered by the self-signed cert in the
`nginx` service.

    wsk -i list
    wsk -i action invoke /whisk.system/utils/echo -p message hello -b

If either fails, ensure you have the latest
[wsk](https://github.com/projectodd/openwhisk-openshift/releases/latest)
installed.

### Alarms

The
[alarms](https://github.com/apache/incubator-openwhisk-package-alarms)
package is not technically a part of the default OpenWhisk catalog,
but since it's a simple way of experimenting with triggers and rules,
we include a resource specification for it in our templates.

Try the following `wsk` commands:

    wsk -i trigger create every-5-seconds \
        --feed  /whisk.system/alarms/alarm \
        --param cron '*/5 * * * * *' \
        --param maxTriggers 25 \
        --param trigger_payload "{\"name\":\"Odin\",\"place\":\"Asgard\"}"
    wsk -i rule create \
        invoke-periodically \
        every-5-seconds \
        /whisk.system/samples/greeting
    wsk -i activation poll

## Using minishift

First, start [minishift](https://github.com/minishift/minishift/) and
fix a networking bug in current releases:

    minishift start --memory 8GB
    minishift ssh -- sudo ip link set docker0 promisc on

If your minishift is running OpenShift 3.9.0, you'll need to fix
another bug:

    minishift openshift config set --patch \
        '{"admissionConfig":
            {"pluginConfig":
                {"openshift.io/ImagePolicy":
                    {"configuration":
                        {"apiVersion": "v1",
                         "kind": "ImagePolicyConfig",
                         "resolveImages": "AttemptRewrite"}}}}}'

Put your `oc` command in your PATH:

    eval $(minishift oc-env)

Assuming you have this repo cloned to your local workspace, run:

    ./tools/travis/build.sh

That will create an `openwhisk` project, install the resources from
[template.yml](template.yml) into it, and wait for all components to
be ready. When it completes, you should have a functioning OpenWhisk
platform, to which you can then
[point your `wsk` command](#using-wsk).

If you prefer not to clone this repo, you can simply follow the
[installation steps](#installation) after creating a new project:

    oc new-project openwhisk
    oc process -f https://git.io/openwhisk-template | oc create -f -

### Testing Local Changes

If you'd like to test local changes you make to upstream OpenWhisk,
e.g. the controller or invoker, first ensure you're using minishift's
docker repo:

    eval $(minishift docker-env)

Then when you build the OW images, override the prefix and tag:

    ./gradlew distDocker -PdockerImagePrefix=projectodd -PdockerImageTag=whatever

The `projectodd` prefix and `whatever` tag can be anything you like.
You'll patch the running StatefulSets to refer to them so that any new
pods they create will use your images.

    # Patch the controller's StatefulSet
    oc patch statefulset controller -p '{"spec":{"template":{"spec":{"containers":[{"name":"controller","image":"projectodd/controller:whatever"}]}}}}'

    # Patch the invoker's StatefulSet
    oc patch statefulset invoker -p '{"spec":{"template":{"spec":{"containers":[{"name":"invoker","image":"projectodd/invoker:whatever"}]}}}}'

    # Now delete one or both pods to run your latest images
    oc delete --force --now pod invoker-0 controller-0

With the StatefulSets patched, your *build-test-debug* cycle amounts
to this: edit the source, run your `distDocker` task, e.g.
`core:controller:distDocker` or `core:invoker:distDocker` with the
above prefix/tag, and finally delete the relevant pod, e.g.
`controller-0` or `invoker-0`. This will trigger your patched
StatefulSet to create a new pod with your changes.

Allow some time for the components to cleanly shutdown and rediscover
themselves, of course. And while you're waiting, consider coming up
with some good unit tests instead. ;)

And if you wish to publish your changes to DockerHub's projectodd
organization:

    COMMIT=$(git rev-parse HEAD | cut -c 1-7)
    ./gradlew distDocker -PdockerImagePrefix=projectodd -PdockerImageTag=$COMMIT -PdockerRegistry=docker.io

## Shutdown

All of the OpenWhisk resources can be shutdown gracefully using the
template. The `-f` parameter takes either a local file or a remote
URL.

    oc process -f template.yml | oc delete -f -
    oc delete all -l template=openwhisk

Alternatively, you can just delete the project:

    oc delete project openwhisk

## Advanced Configuration

### Persistent Data

If you'd like for data to survive reboots, there's a
`persistent-template.yml` that will setup PersistentVolumeClaims.

### Larger Clusters

There are some sensible defaults for larger persistent clusters in
[larger.env](larger.env) that you can use like so:

    oc process -f persistent-template.yml --param-file=larger.env | oc create -f -
    
## Performance Testing

Adjust the connection count and test duration of both below as
needed. On a large system, be sure to test with connection counts in
the hundreds.

### With `ab`

For simple testing, use `ab`:

    ab -c 5 -n 300 -k -m POST -H "Authorization: Basic $(oc get secret whisk.auth -o yaml | grep "system:" | awk '{print $2}')" "https://$(oc get route/openwhisk --template={{.spec.host}})/api/v1/namespaces/whisk.system/actions/utils/echo?blocking=true&result=true"

### With `wrk`

You can generate in-cluster load with `wrk`

    echo -e "function main() {\n  return {body: 'Hello world'};\n}" > helloWeb.js
    wsk -i action create helloWeb helloWeb.js --web=true
    oc run -it --image williamyeh/wrk wrk --restart=Never --rm   --overrides='{"apiVersion":"v1", "spec":{"volumes":[{"name": "data", "emptyDir": {}}], "containers":[{"name": "wrk", "image": "williamyeh/wrk", "args": ["--threads", "4", "--connections", "50", "--duration", "30s", "--latency", "--timeout", "10s", "http://nginx/api/v1/web/whisk.system/default/helloWeb"], "volumeMounts": [{"mountPath": "/data", "name": "data"}]}]}}'

### Activation statistics

The `bin/activationStats.sh` script can output throughput and waitTime
numbers for recent function activations. This is useful when
spot-checking overall system load and how long functions are waiting
in queues inside OpenWhisk before being invoked.

## Common Problems

### Empty catalog (nothing from `wsk list`)

The following command should show a number of system packages:

    wsk -i package list /whisk.system

If it doesn't, the `install-catalog` job probably failed. The first
time you install OpenWhisk may take a very long time, due to the
number of Docker images being pulled. This may cause the
`install-catalog` job to give up, leaving you without the default
system packages installed.

To remedy this, simply delete and recreate the job:

    oc delete job install-catalog
    oc process -f template.yml | oc create -f -

You'll see harmless `AlreadyExists` errors for all but the
`install-catalog` job. Once its associated pod runs to completion, you
should see output like the following:

    $ wsk -i package list /whisk.system
	packages
	/whisk.system/combinators                                              shared
	/whisk.system/websocket                                                shared
	/whisk.system/github                                                   shared
	/whisk.system/utils                                                    shared
	/whisk.system/slack                                                    shared
	/whisk.system/samples                                                  shared
	/whisk.system/watson-translator                                        shared
	/whisk.system/watson-textToSpeech                                      shared
	/whisk.system/watson-speechToText                                      shared
	/whisk.system/weather                                                  shared
	/whisk.system/alarms                                                   shared

### `The requested resource does not exist` when creating an action

It might happen that when creating an action you get an error that the requested resource does not exist:

    $ wsk -i action create md5hasher target/maven-java.jar --main org.apache.openwhisk.example.maven.App
    error: Unable to create action 'md5hasher': The requested resource does not exist. (code 619)

If this happens, it could be that the API host is incorrect.
So, start by inspecting the property values:

    $ wsk property get
    client cert
    Client key
    whisk auth                  789c46b1-...
    whisk API host              http://openwhisk-openwhisk.192.168.64.8.nip.io
    whisk API version           v1
    whisk namespace             _
    whisk CLI version           2018-02-28T21:13:48.864+0000
    whisk API build             2018-01-01T00:00:00Z
    whisk API build number      latest

API host should only contain the host name, no `http://` in front.
Fix it by resetting the API host:

    $ wsk property set --apihost openwhisk-openwhisk.192.168.64.8.nip.io
    ok: whisk API host set to openwhisk-openwhisk.192.168.64.8.nip.io

Now try adding the action again:

    $ wsk -i action create md5hasher target/maven-java.jar --main org.apache.openwhisk.example.maven.App
    ok: created action md5hasher

### Failing to pull ImageStream tags

You may see errors relating to pulling images on OpenShift 3.9:

    $ oc describe pod couchdb-0
    ...
	Warning  Failed                 6m (x4 over 10m)    kubelet, localhost  Failed to pull image "couchdb:whisky": rpc error: code = Unknown desc = Tag whisky not found in repository docker.io/library/couchdb
	Warning  Failed                 6m (x4 over 10m)    kubelet, localhost  Error: ErrImagePull
	Warning  Failed                 21s (x31 over 10m)  kubelet, localhost  Error: ImagePullBackOff

If so, run the following configuration patch:

    minishift openshift config set --patch \
        '{"admissionConfig":
            {"pluginConfig":
                {"openshift.io/ImagePolicy":
                    {"configuration":
                        {"apiVersion": "v1",
                         "kind": "ImagePolicyConfig",
                         "resolveImages": "AttemptRewrite"}}}}}'

You may then need to recreate your project and deploy the template again.
