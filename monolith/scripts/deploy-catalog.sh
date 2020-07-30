#!/bin/bash

USERXX=$1
DELAY=$2

if [ -z $USERXX ]
  then
    echo "Usage: Input your username like deploy-catalog.sh user1"
    exit;
fi

echo Your username is $USERXX

echo Deploy Catalog service........

oc project $USERXX-catalog || oc new-project $USERXX-catalog
oc delete dc,deployment,bc,build,svc,route,pod,is --all

echo "Waiting 30 seconds to finialize deletion of resources..."
sleep 30

sed -i "s/userXX/${USERXX}/g" /projects/cloud-native-workshop-v2m2-labs/catalog/src/main/resources/application-openshift.properties

oc new-app --as-deployment-config -e POSTGRESQL_USER=catalog \
             -e POSTGRESQL_PASSWORD=mysecretpassword \
             -e POSTGRESQL_DATABASE=catalog \
             openshift/postgresql:latest \
             --name=catalog-database

mvn clean package install spring-boot:repackage -DskipTests -f $CHE_PROJECTS_ROOT/cloud-native-workshop-v2m2-labs/catalog/

oc new-build registry.access.redhat.com/ubi8/openjdk-11 --binary --name=catalog-springboot -l app=catalog-springboot

if [ ! -z $DELAY ]
  then
    echo Delay is $DELAY
    sleep $DELAY
fi

oc start-build catalog-springboot --from-file $CHE_PROJECTS_ROOT/cloud-native-workshop-v2m2-labs/catalog/target/catalog-1.0.0-SNAPSHOT.jar --follow
oc new-app catalog-springboot --as-deployment-config -e JAVA_OPTS_APPEND='-Dspring.profiles.active=openshift'
oc expose service catalog-springboot

REPLACEURL=$(oc get route -n $USERXX-catalog catalog-springboot -o jsonpath="{.spec.host}")
sed -i "s/REPLACEURL/${REPLACEURL}/g" /projects/cloud-native-workshop-v2m2-labs/monolith/src/main/webapp/app/services/catalog.js

oc label dc/catalog-database app.openshift.io/runtime=postgresql --overwrite && \
oc label dc/catalog-springboot app.openshift.io/runtime=spring --overwrite && \
oc label dc/catalog-springboot app.kubernetes.io/part-of=catalog --overwrite && \
oc label dc/catalog-database app.kubernetes.io/part-of=catalog --overwrite && \
oc annotate dc/catalog-springboot app.openshift.io/connects-to=catalog-database --overwrite && \
oc annotate dc/catalog-springboot app.openshift.io/vcs-uri=https://github.com/RedHat-Middleware-Workshops/cloud-native-workshop-v2m2-labs.git --overwrite && \
oc annotate dc/catalog-springboot app.openshift.io/vcs-ref=ocp-4.5 --overwrite
