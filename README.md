# OpenWhisk on OpenShift

The following command will deploy OpenWhisk in your OpenShift project
using the latest template in this repo:

    oc process -f http://bit.ly/openwhisk-template | oc create -f -

It'll take a few minutes, but once all the pods are running/completed,
you can configure the `wsk` CLI to use your cluster:

    AUTH_SECRET=$(oc get secret whisk.auth -o yaml | grep "system:" | awk '{print $2}' | base64 --decode)
    wsk property set --auth $AUTH_SECRET --apihost $(oc get route/openwhisk --template={{.spec.host}})

## Sensible defaults for larger clusters

There are some sensible defaults for larger clusters in
[larger.env](larger.env) that you can use like so:

    oc process -f template.yml --param-file=larger.env | oc create -f -
    
## Testing performance with `ab`

    AUTH_SECRET=$(oc get secret whisk.auth -o yaml | grep "system:" | awk '{print $2}' | base64 --decode)
    ab -c 5 -n 300 -k -m POST -H "Authorization: Basic $(echo $AUTH_SECRET | base64 -w 0)" "https://$(oc get route/openwhisk --template={{.spec.host}})/api/v1/namespaces/whisk.system/actions/utils/echo?blocking=true&result=true"

## Installing on minishift

These instructions assume you've cloned this repo, cd'd into it, and
checked out the branch containing this file.

First, start [minishift](https://github.com/minishift/minishift/) and
fix a networking bug in current releases:

    minishift start --memory 8GB
    minishift ssh -- sudo ip link set docker0 promisc on
    eval $(minishift oc-env)

Then deploy OpenWhisk in its own project.

    oc new-project openwhisk
    oc process -f template.yml | oc create -f -

This will take a few minutes. Verify that all pods eventually enter
the `Running` or `Completed` state. For convenience, use the
[watch](https://en.wikipedia.org/wiki/Watch_(Unix)) command.

    watch oc get all

The system is ready when the controller recognizes the invoker as
healthy:

    oc logs -f controller-0 | grep "invoker status changed"

You should see a message like `invoker status changed to 0 ->
Healthy`, at which point you can test the system with your `wsk`
binary (download from
https://github.com/apache/incubator-openwhisk-cli/releases/):

    AUTH_SECRET=$(oc get secret whisk.auth -o yaml | grep "system:" | awk '{print $2}' | base64 --decode)
    wsk property set --auth $AUTH_SECRET --apihost $(oc get route/openwhisk --template={{.spec.host}})

That configures `wsk` to use your OpenWhisk. Use the `-i` option to
avoid the validation error triggered by the self-signed cert in the
`nginx` service.

    wsk -i list
    wsk -i action invoke /whisk.system/utils/echo -p message hello -b

Finally, all of the OpenWhisk resources can be shutdown by simply
deleting the project:

    oc delete project openwhisk

