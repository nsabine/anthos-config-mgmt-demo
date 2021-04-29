#!/usr/bin/env bash

tmux -S /tmp/demo-session.sock kill-session > /dev/null 2>&1
sleep 1

hostname | grep gke
if [ $? -gt 0 ]; then
  echo "on local"
  tmux -S /tmp/demo-session.sock new-session -d -s demo-session './subscript-local.sh'
else
  echo "on gke"
  tmux -S /tmp/demo-session.sock new-session -d -s demo-session './subscript-gke.sh'
fi


tmux -S /tmp/demo-session.sock a
