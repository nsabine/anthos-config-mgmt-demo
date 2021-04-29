#!/usr/bin/env bash
PATH=${PATH}:/usr/local/share/google-cloud-sdk/bin

clear
echo "Starting Configuration Management Demo..."

# Should the demo continue automatically?
AUTO=false

# Go fast?
FAST=false

########################
# include the magic
########################
if [ -f ~/Documents/demo-magic/demo-magic.sh ]; then
  . ~/Documents/demo-magic/demo-magic.sh
else
  echo "Please install demo-magic:"
  echo "  $ cd ~/Documents; git clone https://github.com/paxtonhare/demo-magic.git"
  error=true
fi

brew list watch > /dev/null 2>&1
if [ "$?" -gt "0" ]; then
  echo "Please install watch: "
  echo  "  $ brew install watch"
  error=true
fi

brew list pv > /dev/null 2>&1
if [ "$?" -gt "0" ]; then
  echo "Please install pv:"
  echo  "  $ brew install pv"
  error=true
fi

brew list jq > /dev/null 2>&1
if [ "$?" -gt "0" ]; then
  echo "Please install jq:"
  echo  "  $ brew install jq"
  error=true
fi

which gcloud > /dev/null 2>&1
if [ "$?" -gt "0" ]; then
  echo "Please install gcloud:"
  echo "  https://cloud.google.com/sdk/docs/quickstart"
  error=true
fi

gcloud components list --filter=id:kpt --format='value(state.name)' 2>/dev/null | egrep "^Installed" > /dev/null 2>&1
if [ "$?" -gt "0" ]; then
  echo "Please install kpt:"
  echo  "  $ gcloud components install kpt"
  echo  "or ensure kpt is on PATH"
  error=true
fi

if [ ${error} ]; then
  exit 1
fi

if ${AUTO}; then
  if ${FAST}; then
    PROMPT_TIMEOUT=1
  else
    PROMPT_TIMEOUT=5
  fi
fi

function pause() {
    echo
    echo
    if ${AUTO}; then
      secs=${PROMPT_TIMEOUT}
      while [ $secs -gt "0" ]; do
        echo -en "\rContinuing in ${secs} seconds. "
        secs=$(( $secs -1 ))
        sleep 1
      done
      echo -e "\r\033[KContinuing...."
    else
      echo "press enter to continue"
      read -rs
    fi
    clear
}

function openWindow2() {
  tmux list-panes | grep "1:" >/dev/null 2>&1
  if [ "$?" -gt "0" ]; then 
    tmux -S /tmp/demo-session.sock split-window -h
    tmux -S /tmp/demo-session.sock select-pane -t 0
  fi
}

function closeWindow2() {
  tmux list-panes | grep "1:" >/dev/null 2>&1
  if [ "$?" -eq "0" ]; then 
    tmux -S /tmp/demo-session.sock kill-pane -t 1
  fi
}

function runInWindow2() {
  openWindow2
  tmux -S /tmp/demo-session.sock send -t 1 "$1" ENTER
}

########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster
#
DEMO_SPEED=20
FAST_TYPE_SPEED=100

if ${FAST}; then
  DEMO_SPEED=1000
  FAST_TYPE_SPEED=1000
fi

TYPE_SPEED=$DEMO_SPEED

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

# text color
# DEMO_CMD_COLOR=${BLACK}
DEMO_COMMENT_COLOR=${GREEN}

# hide the evidence
clear

########################
# Start Demo
########################

# Set active project
pei "# First, let's set some variables to configure our command line environment..."
pei "PROJECT_ID=disa-deploy"
pei "REGION=us-central1"
pei "ZONE=us-central1-c"
pei "CLUSTER_NAME=gke-cluster"
pei "gcloud config set project ${PROJECT_ID}"
pei "gcloud config set compute/region ${REGION}"

pause

# enable APIs
pei "# Enable Google Service APIs..."
TYPE_SPEED=100
# pei "gcloud services enable cloudbuild.googleapis.com anthos.googleapis.com serviceusage.googleapis.com binaryauthorization.googleapis.com cloudkms.googleapis.com containeranalysis.googleapis.com secretmanager.googleapis.com"
pei "gcloud services enable anthos.googleapis.com"

# Set up CloudBuild service account, if needed
# export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
# pei "gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com --role roles/owner"
# pei "gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com --role roles/containeranalysis.admin"

TYPE_SPEED=$DEMO_SPEED

pei "# Provision a Kubernetes Cluster..."
gcloud container clusters list | grep ${CLUSTER_NAME} > /dev/null 2>&1
if [ "$?" -gt "0" ]; then
  pei "gcloud container clusters create ${CLUSTER_NAME} --zone=${ZONE} --workload-pool=${PROJECT_ID}.svc.id.goog --enable-stackdriver-kubernetes"
else
  pei "# ... the Kubernetes Cluster is already running!"
fi 

pei "# Get Kubernetes credentials"
pei "gcloud container clusters get-credentials ${CLUSTER_NAME} --region=${REGION}"

pei "# We now have a Kubernetes cluster running and ready."
pei "# Let's kick the tires..."

pei "kubectl get nodes"
pei "kubectl get namespaces"
pei "# Looks good!"

pei "# Next, let's configure Anthos Configuration Management"

pause

# get workload identity
# pei "gcloud container clusters describe ${CLUSTER_NAME} --format='value(workloadIdentityConfig.workloadPool)' --region us-central1"

# Grant permissions to user
# pei "kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user USER_ACCOUNT"

pei "# Enable Anthos Config Management"
pei "gcloud alpha container hub config-management enable"

pei "# Register GKE Cluster with Anthos Config Management..."
gcloud beta container hub memberships describe ${CLUSTER_NAME} > /dev/null 2>&1
if [ "$?" -gt "0" ]; then
  pei "gcloud beta container hub memberships register ${CLUSTER_NAME} --gke-cluster=${REGION}/${CLUSTER_NAME} --enable-workload-identity"
else
  pei "# ... Anthos Config Management membership already exists, moving on..."
fi

pei "# Retrieve config management configuration from the git repository"
pei "curl -s -O https://raw.githubusercontent.com/nsabine/anthos-config-mgmt-demo/main/config-management.yaml"

pei "# ... and apply the configuration to the cluster"
pei "gcloud alpha container hub config-management apply --membership=${CLUSTER_NAME} --config=config-management.yaml --project=$PROJECT_ID"

pause

pei "# Let's take a look at what that's doing."
pei "cat config-management.yaml"

pei "# Key points are:"
pei "# 1. It's a Kubernetes yaml"
pei "# 2. It enables the Policy Controller, which is an admission controller that enforces compliance with policies."
pei "# 3. It points to a Git repo for the policy."

pause 

pei "# Now we watch and wait for Status SYNCED.  It will show ERROR state while the pods initialize.  This will take a few moments."

runInWindow2 "watch -n 15 'gcloud alpha container hub config-management status --project=$PROJECT_ID'"

SYNCED=false

while ! $SYNCED; do
  echo -n "."
  sleep 1
  gcloud alpha container hub config-management status --project=$PROJECT_ID | grep "SYNCED" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    SYNCED=true
  fi
done
echo

pei "# Great, status is SYNCED, and we're ready to go!"

closeWindow2

pause 

pei "# Now let's see what ACM can do for us...."
pei "# The simple policy in our git repository says a namespace should exist called 'hello'."
pei "# Let's see if has been created:"
pei "kubectl get ns/hello"
pei "# Looks good!  Now let's see what happens if we allow our configuration to 'drift' by deleting the namespace."
pei "# I'll start a command to watch the namespaces, then delete 'hello' and see how the system responds!"

runInWindow2 "watch -d kubectl get ns/hello"
pei "# Ok, now let's delete it"

namespaceExists=true

pei "kubectl delete ns/hello"

#while $namespaceExists; do
#  echo -n "."
#  kubectl get ns/hello
#  if [ $? -gt 0 ]; then
#    namespaceExists=false
#  fi
#  sleep 1
#done

echo
pei "# See the namespace disappear?  Now let's watch ACM bring it back."

while ! $namespaceExists; do
  echo -n "."
  sleep 1
  kubectl get ns/hello
  if [ $? -eq 0 ]; then
    namespaceExists=true
  fi
done
echo
pei "# Success!  Anthos Config Management noticed the drift and corrected it."

sleep 3

closeWindow2

pause

pei "# Anthos Configuration Management comes with a set of templates for common constraints."
pei "# Here's how to retrieve a list of the constraint templates that are pre-installed"
pei "kubectl get constrainttemplates -l='configmanagement.gke.io/configmanagement=config-management'"

pei "# Great, now let's look at one..."
pause

pei "kubectl get constrainttemplate k8spspprivilegedcontainer -o jsonpath='{.spec}'"

pei "# This disallows privileged containers.  Cool!"

pause

pei "# Now, let's install Anthos Service Mesh"
if [ ! -f install_asm ]; then
  curl -s https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9 > install_asm
fi

if [ ! -x install_asm ]; then
  chmod u+x install_asm
fi

kubectl get ns asm-system > /dev/null 2>&1
if [ "$?" -gt "0" ]; then
  pei "./install_asm --project_id $PROJECT_ID --cluster_name $CLUSTER_NAME --cluster_location $REGION --mode install --enable_all"
else
  pei "# ... Anthos Service Mesh is already installed and ready!"
fi

pei "# Demo complete"

AUTO=false
pause
