#!/bin/bash
#
# Use this script in apps that want to deploy modules to ML.
#
# curl -fsSL "https://bitbucket.org/springersbm/ml-deploy/raw/master/extras/deploy-modules.sh" | bash /dev/stdin -a my-app
#
set -e

declare app_name=
declare pp_version=LOCAL
declare target="ml.local.springer-sbm.com"
declare file=
declare published_version=
declare repo="http://repo.tools.springer-sbm.com:8081"
declare -r repo_path="nexus/content/repositories/releases"
declare -r repo_cache="${HOME}/.ivy2/cache"
declare -r artifact_name="ml-modules"
declare -r artifact_group="com.springer"

usage () {
  cat <<EOM
  Usage: ./deploy-modules.sh -a APP (-p VERSION | -f FILE)  [options]

  -h | -help                Print this message
  -a | -app <name>          The name of the app (required)
  -v | -app-version <arg>   The version of the app. Default: $app_version
  -t | -target <host>       The target ml host. Default: $target
  -f | -file <path>         Deploys a local modules artifact (required, unless -p is used)
  -p | -published <version> Deploys a specific version of a published modules artifact to (required, unless -f is used)
  -r | -repo <url>          Repository in which module artifacts are published. Default: $repo

  Examples:
  ---------
  Deploying published modules version 0.42 to http://ml.dev:7655/my-app/0.3.
  ./deploy-modules.sh -a my-app -v 0.3 -t ml.dev -p 0.42

  Deploying a locally built modules to http://ml.local.springer-sbm.com:7655/my-app/LOCAL.
  ./deploy-modules.sh -a my-app -f target/my-modules.zip

EOM
}

artifact_file () {
  echo "$artifact_name-$published_version.zip"
}

artifact_path () {
  echo $artifact_group | sed 's/\./\//'
}

artifact_remote_url () {
  echo "$repo/$repo_path/$(artifact_path)/$artifact_name/$published_version/$(artifact_file)"
}

artifact_cache_dir () {
  echo "$repo_cache/$artifact_group/$artifact_name/$published_version"
}

artifact_cache_path () {
  echo "$(artifact_cache_dir)/$(artifact_file)"
}

deploy_url () {
  echo "http://$target:7654/apps/$app_name/$app_version"
}

process_args () {
  require_arg () {
    local type="$1"
    local opt="$2"
    local arg="$3"

    if [[ -z "$arg" ]] || [[ "${arg:0:1}" == "-" ]]; then
      echo "Aborting: $opt requires <$type> argument"
      exit 1
    fi
  }
  while [[ $# -gt 0 ]]; do
    case "$1" in
       -h|-help)        usage; exit 1 ;;
       -a|-app)         require_arg name "$1" "$2" && app_name="$2" && shift 2 ;;
       -v|-app-version) require_arg arg "$1" "$2" && app_version="$2" && shift 2 ;;
       -t|-target)      require_arg host "$1" "$2" && target="$2" && shift 2 ;;
       -f|-file)        require_arg path "$1" "$2" && file="$2" && shift 2 ;;
       -p|-published)   require_arg version "$1" "$2" && published_version="$2" && shift 2 ;;
       -r|-repo)        require_arg url "$1" "$2" && repo="$2" && shift 2 ;;
       *)               shift ;;
    esac
  done

  if [[ -z $app_name ]]; then
    echo "Application name is missing."
    usage; exit 1
  fi

  if [[ -z $file ]] && [[ -z $published_version ]]; then
    echo "Please specify either a local modules file or a published version."
    usage; exit 1
  fi
}

process_args "$@"

if [ -n "$published_version" ]; then
  file="$(artifact_cache_path)"
  echo "Downloading $(artifact_remote_url) to $file"
  mkdir -p $(artifact_cache_dir)
  curl -f --silent --show-error -o $file $(artifact_remote_url)
fi

# locally we need to delete first because we always use the version "LOCAL"
if [[ "$app_version" == "LOCAL" ]]; then
  echo "No application version specified. Deploying as LOCAL."
  echo "Deleting LOCAL version at $(deploy_url)"
  curl -fsS --digest -u admin:admin -X DELETE $(deploy_url)
  echo
fi

echo "Deploying $file to $(deploy_url)"
curl -fsS --digest -u deployer:DeployMe --upload-file $file $(deploy_url)

echo
echo "Finished successfully. New modules available at: http://$target:7655/$app_name/$app_version/"
echo
