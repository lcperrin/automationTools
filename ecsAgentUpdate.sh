#!/bin/bash

# assign variables, using instance metadata
CLUSTER=$(curl localhost:51678/v1/metadata | jq -r '.Cluster')
CONTAINERINSTANCE=$(curl localhost:51678/v1/metadata | jq -r '.ContainerInstanceArn' | cut -d "/" -f 2)

aws ecs update-container-agent --cluster $CLUSTER --container-instance $CONTAINERINSTANCE