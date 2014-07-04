# mldeploy

## Overview

Bootstraps a fresh MarkLogic installation with an API for deploying applications and applying configuration steps.

* runs configuration scripts to create databases, add indexes etc.
* deploys xquery applications packaged as zip files
* manages multiple versions of applications


## Installation

To install the deployment endpoints in ML, simply run the following from the root of ml-deploy:

    ./build && ./deploy.sh

## Application Management

**Note:** To read and execute modules user must have role `mldeploy-access-role`.

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

### Module deployment

From within your apps, you can use the following script to help deploying modules:

    curl -fsSL "https://bitbucket.org/springersbm/ml-deploy/raw/master/extras/deploy-modules.sh" | bash /dev/stdin -h

In the build script of your app, you'd then typically have something like this:

    declare -r modules_version="0.42"
    declare -r app_version=${GO_PIPELINE_LABEL:-"LOCAL"}
    declare -r deploy_script="https://bitbucket.org/springersbm/ml-deploy/raw/master/extras/deploy-modules.sh"
    curl -fsSL $deploy_script | bash /dev/stdin -a my-app -v $app_version -p $modules_version

## Configuration Management

### Endpoints
    # List of applied steps
    GET /steps

    # Apply a step
    # db: Name of database context. Defaults to 'Documents'.
    # once: If set to false, will always execute step. Defaults to true.
    # HTTP request body: contents of step file 
    # Example: curl -X POST --digest -u admin:admin -d@step1.xqy http://localhost:7654/steps/step1.xqy?once=false
    POST /steps/[step_name]?db=[db_name]&once=[true|false]