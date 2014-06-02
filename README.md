# MarkLogic Config


## Overview

MarkLogic configuration management and application deployment

* run configuration scripts to create databases, add indexes etc.
* deploy applications packaged as zip files
* manage multiple versions of applications
* common admin utilities

## Application Management

A version of an application is packaged as a zip file. To read and execute modules user must have role `mldeploy-access-role`.

### Install application from http repo
POST `/apps/[name]/[version]?artifact=http://repo/artifact.zip`

### Install application from zip
PUT `/apps/[name]/[version]`

e.g. `curl -sS -f --digest -u admin:admin --upload-file artifact.zip http://localhost:7654/apps/[name]/[version]`

### List of installed applications
GET `/apps`

### List of installed versions of an application
GET `/apps/[name]`

### List of files installed for an application version
GET `/apps/[name]/[version]`

### View file
GET `/apps/[name]/[version]/[file path]`

### Delete an application version
DELETE `/apps/[name]/[version]`


## Configuration Management

Manages applying configuration steps.

### List of applied steps
GET `/steps`

### Apply a step
POST `/steps/[step name]?db=[target db name]&once=[true|false]`  

request body = contents of step file  
`db` Name of database context. Defaults to 'Documents'  
`once` Control whether steps will be skipped if they have already been run on the host. Defaults to true.

e.g `curl -X POST --digest -u admin:admin -d@step1.xqy http://localhost:7654/steps/step1.xqy?db=SomeDatabase`
