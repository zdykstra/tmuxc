#!/usr/bin/env bash

process() {
while read input; do 
  case "$input" in
    UNBLANK*) tmuxc -p ;; 
    LOCK*) tmuxc -p ;; 
  esac
done
}

/usr/local/bin/xscreensaver-command -watch | process
