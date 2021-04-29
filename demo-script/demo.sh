#!/usr/bin/env bash

tmux -S /tmp/demo-session.sock kill-session > /dev/null 2>&1
sleep 1

tmux -S /tmp/demo-session.sock new-session -d -s demo-session './subscript-1.sh'
tmux -S /tmp/demo-session.sock a
