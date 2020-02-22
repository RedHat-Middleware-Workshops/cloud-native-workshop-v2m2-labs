#!/bin/bash

USERXX=$1
DELAY=$2

if [ -z "$USERXX" -o "$USERXX" = "userXX" ]
  then
    echo "Usage: Input your username like deploy-inventory.sh user1"
    exit;
fi

echo Your username is $USERXX

echo Deploy Inventory service........

oc project $USERXX-inventory || oc new-project $USERXX-inventory

cd /projects/cloud-native-workshop-v2m2-labs/inventory/

oc delete dc,bc,build,svc,route,pod,is --all

mvn clean package -DskipTests

echo "Waiting 30 seconds to finalize deletion of resources..."
sleep 30

oc new-app -e POSTGRESQL_USER=inventory \
  -e POSTGRESQL_PASSWORD=mysecretpassword \
  -e POSTGRESQL_DATABASE=inventory openshift/postgresql:latest \
  --name=inventory-database

oc new-build registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:1.5 --binary --name=inventory-quarkus -l app=inventory-quarkus

if [ ! -z $DELAY ]
  then 
    echo Delay is $DELAY
    sleep $DELAY
fi

rm -rf target/binary && mkdir -p target/binary && cp -r target/*runner.jar target/lib target/binary

oc start-build inventory-quarkus --from-dir=target/binary --follow
oc new-app inventory-quarkus -e QUARKUS_PROFILE=prod
oc expose service inventory-quarkus

clear
echo "Done! Verify by accessing in your browser:"
echo
echo "http://$(oc get route inventory-quarkus -o=go-template --template='{{ .spec.host }}')"
echo