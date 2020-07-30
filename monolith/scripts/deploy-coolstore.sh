#!/bin/bash

USERXX=$1

if [ -z $USERXX ]
  then
    echo "Usage: Input your username like deploy-boolstore.sh user1"
    exit;
fi

echo Your username is $USERXX

echo Deploy coolstore project........

oc project $USERXX-coolstore-dev || oc new-project $USERXX-coolstore-dev
oc delete dc,deployment,bc,build,svc,route,pod,is --all

echo "Waiting 30 seconds to finialize deletion of resources..."
sleep 30

oc new-app coolstore-monolith-binary-build --as-deployment-config -p USER_ID=$USERXX

mvn clean package -Popenshift -f $CHE_PROJECTS_ROOT/cloud-native-workshop-v2m2-labs/monolith/
oc start-build coolstore --from-file $CHE_PROJECTS_ROOT/cloud-native-workshop-v2m2-labs/monolith/deployments/ROOT.war

oc label dc/coolstore-postgresql app.openshift.io/runtime=postgresql --overwrite && \
oc label dc/coolstore app.openshift.io/runtime=jboss --overwrite && \
oc label dc/coolstore-postgresql app.kubernetes.io/part-of=coolstore --overwrite && \
oc label dc/coolstore app.kubernetes.io/part-of=coolstore --overwrite && \
oc annotate dc/coolstore app.openshift.io/connects-to=coolstore-postgresql --overwrite && \
oc annotate dc/coolstore app.openshift.io/vcs-uri=https://github.com/RedHat-Middleware-Workshops/cloud-native-workshop-v2m2-labs.git --overwrite && \
oc annotate dc/coolstore app.openshift.io/vcs-ref=ocp-4.5 --overwrite