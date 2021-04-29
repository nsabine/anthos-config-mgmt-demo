#!/usr/bin/env bash
PATH=${PATH}:/usr/local/share/google-cloud-sdk/bin

clear
echo "Starting Configuration Management Demo..."

# Should the demo continue automatically?
AUTO=true

# Go fast?
FAST=false

########################
# include the magic
########################
if [ -f ./demo-magic/demo-magic.sh ]; then
  . ./demo-magic/demo-magic.sh
else
  echo "Please make sure demo-magic is available. It should be included as a submodule here."
  error=true
fi

which watch > /dev/null 2>&1
if [ "$?" -gt "0" ]; then
  echo "Please install watch: "
  echo  "  $ brew install watch"
  error=true
fi

which pv > /dev/null 2>&1
if [ "$?" -gt "0" ]; then
  echo "Please install pv:"
  echo  "  $ brew install pv"
  error=true
fi

which jq > /dev/null 2>&1
if [ "$?" -gt "0" ]; then
  echo "Please install jq:"
  echo  "  $ brew install jq"
  echo  "  $ apt-get install jq"
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
  echo "Errors reported.  Press Enter to exit"
  read -rs 
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

