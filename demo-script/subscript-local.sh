#!/usr/bin/env bash

. ./subscript-setup.sh

# hide the evidence
clear

########################
# Start Demo
########################

PROJECT_ID=disa-deploy
REGION=us-central1
ZONE=us-central1-c
CLUSTER_NAME=gke-cluster
ONPREM_CLUSTER_NAME=user-cluster1
ONPREM_KUBECONFIG=/home/ubuntu/user-cluster1-kubeconfig
gcloud config set project ${PROJECT_ID} > /dev/null 2>&1
gcloud config set compute/region ${REGION} > /dev/null 2>&1

pei "# Let's push a new change into our configuration management policy"
pei "# This is going to deploy a new application"
pei "git checkout -b new-app"
pei "mkdir ../policy/namespaces/dlp"
pei "pushd ../policy/namespaces/dlp"

cat <<EOF > namespace.yaml
# creates namespace named "dlp"
apiVersion: v1
kind: Namespace
metadata:
  name: dlp
EOF

cat <<EOF > dlp-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dlp-server-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: dlp-server
  template:
    metadata:
      labels:
        app: dlp-server
    spec:
      containers:
      - name: dlp-server
        image: gcr.io/disa-deploy/dlp_service_golden_backup:latest
        ports:
        - containerPort: 8080
          protocol: TCP
          name: "grpc"
        - containerPort: 8081
          protocol: TCP
          name: "cloud-grpc"
        args:
        - "--grpc_port=8080"
        - "--cloud_grpc_port=8081"
EOF

cat <<EOF > dlp-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: dlp-lb
spec:
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
    name: grpc
  selector:
    app: dlp-server
  type: LoadBalancer
EOF

pei "# First, we create the namepsace"
pei "cat namespace.yaml"

pause

pei "# Next, we create the deployment"
pei "cat dlp-deployment.yaml"

pause

pei "# Last, we create the service"
pei "cat dlp-service.yaml"

pause

pei "# Now let's commit it to our Development branch and create a pull request"
pei "git add ."
pei "git commit -m 'New DLP Deployment'"
pei "git push --set-upstream origin new-app"

pause

pei "# Now Create the Pull Request, Review, and Merge the code:"
pei "# https://github.com/nsabine/anthos-config-mgmt-demo/pull/new/new-app"


popd 

