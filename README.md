# ml-deploy

## Overview

Bootstraps a fresh MarkLogic installation with an API for deploying applications and applying configuration deltas.

* runs configuration scripts (called steps) to create databases, add indexes etc.
* deploys xquery applications packaged as zip files
* manages multiple versions of applications


## Installation

To install the deployment endpoints in ML, run the following from the root of ml-deploy:

    ./build
    ./deploy.sh

## Application Management

### Endpoints

    # Install application from zip
    PUT /apps/[name]/[version]

    # List of installed applications
    GET /apps

    # List of installed versions of an application
    GET /apps/[name]

    # List of files installed for an application version
    GET /apps/[name]/[version]

    # View file
    GET /apps/[name]/[version]/[file path]

    # Delete an application version
    DELETE /apps/[name]/[version]

Apps are insalled in the `Modules` database. For executing application modules it is recommended to create an http app server with root `/apps`.

To read and execute application modules, the user must be assigned the role `mldeploy-access-role`.  

### Module deployment

From within your apps, you can use the following script to help deploying modules:

    curl -q -fsSL "https://bitbucket.org/springersbm/ml-deploy/raw/master/extras/deploy-modules.sh" | bash /dev/stdin -h

In the build script of your app, you'd then typically have something like this:

    declare -r modules_version="0.42"
    declare -r app_version=${GO_PIPELINE_LABEL:-"LOCAL"}
    declare -r deploy_script="https://bitbucket.org/springersbm/ml-deploy/raw/master/extras/deploy-modules.sh"
    curl -q -fsSL $deploy_script | bash /dev/stdin -a my-app -v $app_version -p $modules_version


### Housekeeping for old application versions

Over time the `Modules` database will grow in size as it stores every version of every application deployed. To keep this under control use `extras/delete-unused-versions.sh`. It deletes versions if no activity is found in the server access logs, except for the 10 latest versions which are always kept. See the script's comments and usage for more details.

## Configuration Management

### Applying configuration steps
    # List of applied steps
    GET /steps

    # Apply a step
    PUT /steps/[unique step name]?db=[db-name]&once=[true|false]

    # db: Name of database context. Defaults to 'Documents'.
    # once: If set to false, will always execute step. Defaults to true.
    # HTTP request body: contents of step file
    # Example: curl --digest -u admin:admin --upload-file step1.xqy http://localhost:7654/steps/step1.xqy?once=false


### Managing server restarts

In step files it is recommended to avoid server restarts by using the function `admin:save-configuration-without-restart`. If this function returns any host ids, then set the server field `requires-restart` to `true`.

For example:
`admin:save-configuration-without-restart($config)[1] ! xdmp:set-server-field("restart-required", fn:true())`

    # Check if a restart is required
    GET /restart-required

    # Restart the cluster
    POST /restart?force=[true|false]

    # force: defaults to false
    # Restarts the cluster if restart is required or force is true.


### Security

At the moment ml-deploy creates a user with admin privileges: `deployer:DeployMe`.

It's recommended that your first step file changes the password :)
