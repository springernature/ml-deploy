#! /bin/bash
# -*- mode: sh; fill-column: 80; -*- [Emacs]

set -o errexit

remote_script_url=http://te-prod-go-01.springer-sbm.com/tools-engineering/${INCEPTION_BRANCH_NAME-master}/docker_env/docker_env.py
local_script_name=docker_env.py

# Make a temporary directory for this script to use
tmp="${TMPDIR=/tmp}/${local_script_name}$$"
trap 'rm -rf "$tmp" >/dev/null 2>&1' 0 # remove $tmp at program termination
trap 'exit 2' 1 2 3 13 15
mkdir "$tmp"

script="$tmp/$local_script_name"

if curl -q -sfLS "$remote_script_url" > "$script"; then
  chmod +x "$script"
  "$script" "$@"
else
  echo >&2 "Failed to download $remote_script_url"
  exit 1
fi
