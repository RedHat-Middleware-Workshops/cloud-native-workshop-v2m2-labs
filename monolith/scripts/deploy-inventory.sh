#!/bin/bash

USERXX=$1

if [ -z $USERXX ]
  then
    echo "Usage: Input your username like deploy-inventory.sh user1"
    exit;
fi

echo Your username is $USERXX

echo Deploy Inveoc projntory service........

oc project $USERXX-inventory

cd /projects/cloud-native-workshop-v2m2-labs/inventory/

mvn clean package -DskipTests

oc new-app -e POSTGRESQL_USER=inventory \
  -e POSTGRESQL_PASSWORD=mysecretpassword \
  -e POSTGRESQL_DATABASE=inventory openshift/postgresql:10 \
  --name=inventory-database
  
oc new-build registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:1.5 --binary --name=inventory-quarkus -l app=inventory-quarkus

oc start-build inventory-quarkus --from-file target/*-runner.jar --follow

oc new-app inventory-quarkus -e QUARKUS_PROFILE=prod

oc expose service inventory-quarkus
