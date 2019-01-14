#!/usr/bin/env bash

process() {
while read input; do 
  case "$input" in
    UNBLANK*) echo "tmuxc -p" ;; 
    LOCK*) echo "tmuxc -p" ;; 
  esac
done
}

/usr/local/bin/xscreensaver-command -watch | process
