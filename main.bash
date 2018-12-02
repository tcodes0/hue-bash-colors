#! /usr/bin/env bash

hue() {
  local program=~/Code/hue/hue.sh
  [ -f "$program" ] && eval "$program" "$@"
}
