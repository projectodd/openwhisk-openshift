# OpenWhisk on OpenShift

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
[![Build Status](https://travis-ci.org/projectodd/openwhisk-openshift.svg?branch=master)](https://travis-ci.org/projectodd/openwhisk-openshift)

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

## Configuring `wsk`

Once your cluster is ready, you need to configure your `wsk` binary.
If necessary, download a recent one from
https://github.com/apache/incubator-openwhisk-cli/releases/, ensure
it's in your PATH, and:

    AUTH_SECRET=$(oc get secret whisk.auth -o yaml | grep "system:" | awk '{print $2}' | base64 --decode)
    wsk property set --auth $AUTH_SECRET --apihost $(oc get route/openwhisk --template="{{.spec.host}}")

That configures `wsk` to use your OpenWhisk. Use the `-i` option to
avoid the validation error triggered by the self-signed cert in the
`nginx` service.

    wsk -i list
    wsk -i action invoke /whisk.system/utils/echo -p message hello -b

If either fails, ensure you have the latest `wsk` installed.

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

## Persistent data

If you'd like for data to survive reboots, there's a
`persistent-template.yml` that will setup PersistentVolumeClaims.

## Sensible defaults for larger persistent clusters

There are some sensible defaults for larger persistent clusters in
[larger.env](larger.env) that you can use like so:

    oc process -f persistent-template.yml --param-file=larger.env | oc create -f -
    
## Testing performance with `ab`

    ab -c 5 -n 300 -k -m POST -H "Authorization: Basic $(oc get secret whisk.auth -o yaml | grep "system:" | awk '{print $2}')" "https://$(oc get route/openwhisk --template={{.spec.host}})/api/v1/namespaces/whisk.system/actions/utils/echo?blocking=true&result=true"

## Installing on minishift

First, start [minishift](https://github.com/minishift/minishift/) and
fix a networking bug in current releases:

    minishift start --memory 8GB
    minishift ssh -- sudo ip link set docker0 promisc on
    
Put your `oc` command in your PATH and create a new project:

    eval $(minishift oc-env)
    oc new-project openwhisk

Then deploy OpenWhisk as instructed above. Or if you have this repo
cloned to your local workspace:

    oc process -f template.yml | oc create -f -

## Shutting down the cluster

All of the OpenWhisk resources can be shutdown gracefully using the
template. The `-f` parameter takes either a local file or a remote
URL.

    oc process -f template.yml | oc delete -f -
    oc delete all -l template=openwhisk

## Common Problems

### Catalog of actions empty

You can inspect the catalog of actions by calling `wsk action list`.
It might happen that after installing OpenWhisk there is only a single action:

    $ wsk action list
    actions
    /whisk.system/invokerHealthTestAction0                                 private

If that happens, chances are that the default action catalog was not installed properly.
This could be due to the installation process being slow, e.g.

    $ oc get job
    NAME                         DESIRED   SUCCESSFUL   AGE
    install-catalog              1         0            1d
    preload-openwhisk-runtimes   1         1            1d

To get back the catalog, delete and execute the job again.
This can be done by extracting the `install-catalog` definition into a separate file and executing it again:

    $ oc delete job install-catalog
    job "install-catalog" deleted
    $ oc create -f install-catalog.yml
    job "install-catalog" created
    $ oc get pods
    NAME                               READY     STATUS      RESTARTS   AGE
    ...
    install-catalog-gj7r6              0/1       Completed   0          30s

Finally, retrieve the action list again:

    $ wsk action list
    actions
    /whisk.system/samples/greeting                                         private nodejs:6
    /whisk.system/watson-speechToText/speechToText                         private nodejs:6
    /whisk.system/weather/forecast                                         private nodejs:6
    /whisk.system/watson-textToSpeech/textToSpeech                         private nodejs:6
    ...

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
