#!/usr/bin/env bash

# example usage:
#
# export DEPLOY_ZIP="target/xquery.zip"
# export APP_NAME="myapp"
#
# ./deploy-local-zip.sh
#

# MARKLOGIC_HOST and APP_VERSION are optional.

require_env_vars() {
  declare env_ok=true
  for var in "$@"; do
    if [ -z "${!var:-}" ]; then
      echo "ERROR: Environment variable not set: ${var}"
      env_ok=false
    fi
  done
  [ "${env_ok}" = true ] || exit 1
}

fetch_ml_modules() {
  declare version="${1}"
  declare credentials="${2}"
  declare local_artifact="${3}"
  declare repo_url="https://springernature.jfrog.io/springernature/libs-release-local/com/springer/ml-modules/ml-modules-${version}.zip"

  echo "Downloading ml-modules artifact ${repo_url} to ${local_artifact}"
  curl -q -fsS -u "${credentials}" -o ${local_artifact} ${repo_url}
  echo
}

deploy_to_marklogic() {
  declare hosts="${1}"
  declare app_name="${2}"
  declare app_version="${3}"
  declare modules_zip="${4}"

  for host in $(echo $hosts | tr -d '[:space:]' | tr ',' ' '); do

    declare ml_url="http://${host}:7654/apps/${app_name}/${app_version}"

    # delete first if the version is "LOCAL" or "v1" in order to replace existing modules
    if [[ "${app_version}" == "LOCAL" || "${app_version}" == "v1" ]]; then
      echo "Deleting existing version at ${ml_url}"
      curl -q -fsS --digest -u deployer:DeployMe -X DELETE ${ml_url}
      echo
    fi

    echo "Deploying ${modules_zip} to ${ml_url}"
    curl -q -fsS --digest -u deployer:DeployMe --upload-file ${modules_zip} ${ml_url}
    echo "Finished successfully. New modules available at: ${ml_url}"

  done
}

# set defaults
MARKLOGIC_HOST="${MARKLOGIC_HOST:-ml.local.springer-sbm.com}"
APP_VERSION="${APP_VERSION:-LOCAL}"

require_env_vars "APP_NAME" "DEPLOY_ZIP"

if [ ! -s "${DEPLOY_ZIP}" ]; then
  echo "error reading ${DEPLOY_ZIP}"
  exit 1
fi

deploy_to_marklogic "${MARKLOGIC_HOST}" "${APP_NAME}" "${APP_VERSION}" "${DEPLOY_ZIP}"

