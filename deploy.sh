#!/usr/bin/env bash
set -e

# defaults
HOST="ml.local.springer-sbm.com"
AUTH="admin:admin"
PACKAGE_ZIP="package.zip"

function usage() {
  printf '
usage: deploy.sh [options...]
Options:
  -t <target host>       Target hostname. Defaults to ml.local.springer-sbm.com
  -c <user:password>     Credentials. Defaults to admin:admin
  -p <package zip path>  Path to package zip. Defaults to package.zip
'
  exit 1
}

while getopts 't:c:p:' OPTION
do
  case $OPTION in
    t) HOST="$OPTARG";;
    c) AUTH="$OPTARG";;
    p) PACKAGE_ZIP="$OPTARG";;
    *) usage;;
  esac
done


PACKAGE_NAME="mldeploy"
PACKAGE_LOG="/tmp/mldeploy.log"
CREDENTIALS="--digest -u ${AUTH}"
URL="http://${HOST}:8002/manage/v2/packages"

function errorcheck() {
    if [ ${PIPESTATUS[0]} != 0 ]; then
      exit 1
    fi
    grep -q error $PACKAGE_LOG && exit 1 || true
}

echo "" > $PACKAGE_LOG

echo Deploying ${PACKAGE_ZIP} as ${PACKAGE_NAME} to ${URL}

echo Deleting existing package..
curl --progress-bar -X DELETE ${CREDENTIALS} \
    "${URL}/${PACKAGE_NAME}" \
    2>&1 | tee -a "${PACKAGE_LOG}"
errorcheck

echo Uploading package..
curl --progress-bar -X POST ${CREDENTIALS} -H "Content-type: application/zip" \
    --data-binary @"${PACKAGE_ZIP}" \
    "${URL}?pkgname=${PACKAGE_NAME}" \
    2>&1 | tee -a "${PACKAGE_LOG}"
errorcheck

echo Installing package..
curl --progress-bar -X POST ${CREDENTIALS} \
    --data-binary @/dev/null \
    "${URL}/${PACKAGE_NAME}/install" \
    2>&1 | tee -a "${PACKAGE_LOG}"
errorcheck


echo Initialising..
curl --progress-bar -X POST ${CREDENTIALS} \
    --data-binary @/dev/null \
    "http://${HOST}:7654/apps/init"

echo
echo "Finished"
