#!/bin/bash

# Delete old app versions by checking access logs for usage

# Gets a list of all deployed apps/versions
# Sorts versions alphabetically
# Skips 10 most recent (last alphabetically) versions of each app
# Deletes version if no requests found in any access logs "*_AccessLog*.txt"

usage() {
  printf "
Deletes old application versions that are not being used.
With no options will just list apps suitable for deleting.

Usage:
    $0 [options...]

Options:
    -d  Actually do the deletions.
    -l  Login credentials in form 'username:password'. Defaults to 'deployer:DeployMe'.
"
  exit 1
}

set -e
set -u
declare auth="deployer:DeployMe"

declare do_delete=false # dry run by default


while getopts dhl: OPTION
do
  case $OPTION in
    d) do_delete=true;;
    l) auth=$OPTARG;;
    h) usage;;
    *) usage;;
  esac
done

declare -r hostname="localhost"
declare -r kurl="curl -sSf --digest -u ${auth}"
declare -r baseurl="http://${hostname}:7654/apps"
declare -r logs="/var/opt/MarkLogic/Logs/*_AccessLog*.txt"

delete_if_unused() {
  printf "Checking for usage of ${1} ... "
  set +e
  if grep -qlF -m1 " /${1}/" ${logs}; then
    printf "found\n"
  else
    printf "not found. Deleting ... "
    if ${do_delete}; then
      delete_version "${1}"
    else
      printf "skipped (use -d to delete)\n"
    fi
  fi
  set -e
}

delete_version() {
  $kurl -X DELETE "${baseurl}/${1}"
  printf "\n"
}

apps=$($kurl "${baseurl}")
for app in $apps; do
  versions=$($kurl "${baseurl}/${app}" | sort | sed -e :a -e '$d;N;2,10ba' -e 'P;D') # must be a better way to drop last n lines?
  for v in $versions; do
    delete_if_unused "${app}/${v}"
  done
done
