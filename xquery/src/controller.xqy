xquery version "1.0-ml";

module namespace controller = "springer.com/mldeploy/controller";

import module namespace rxq = "http://exquery.org/ns/restxq" at "rxq.xqy";
import module namespace apps = "springer.com/mldeploy/apps" at "apps.xqy";
import module namespace steps = "springer.com/mldeploy/steps" at "steps.xqy";

declare %rxq:GET %rxq:path("/") %rxq:produces("text/plain")
function home() {
  "Weclome to mldeploy. See https://github.com/springernature/ml-deploy for usage."
};

declare %rxq:GET %rxq:path("/apps") %rxq:produces("text/plain")
function list-apps() {
  rxq:response(apps:list-apps(), "No apps found")
};

declare %rxq:GET %rxq:path("/apps/([^/]+)") %rxq:produces("text/plain")
function list-versions($app as xs:string) {
  rxq:response(apps:list-versions($app), "App not found")
};

declare %rxq:GET %rxq:path("/apps/([^/]+)/([^/]+)") %rxq:produces("text/plain")
function list-version-files($app as xs:string, $version as xs:string) {
  rxq:response(apps:list-version-files($app, $version), "Version not found")
};

declare %rxq:GET %rxq:path("(/apps/.+)") %rxq:produces("text/plain")
function get-file($uri as xs:string) {
  rxq:response(apps:get-file($uri), "File not found")
};

declare %rxq:POST %rxq:PUT %rxq:path("/apps/([^/]+)/([^/]+)$") %rxq:produces("text/plain")
function install($app as xs:string, $version as xs:string) {
  let $artifact-url := xdmp:get-request-field("artifact")
  let $already-exists := apps:list-versions($app) = $version
  let $response-code := if ($already-exists) then 200 else 201
  return try {
    xdmp:set-response-code($response-code, "OK"),
    fn:concat("Installing app=", $app, " version=", $version),
    if ($already-exists) then "This version already exists. Doing nothing."
    else if (fn:exists($artifact-url)) then apps:install-from-url($app, $version, $artifact-url)
    else
      let $artifact-binary := xdmp:get-request-body("binary")/binary()
      let $ex := if (fn:empty($artifact-binary)) then fn:error((), "Error reading artifact from request body") else ()
      return apps:install($app, $version, $artifact-binary),
    fn:concat("Completed in ", xdmp:elapsed-time(), " at ", fn:current-dateTime())
  }
  catch * {
    rxq:error-response($err:description)
  }
};

declare %rxq:DELETE %rxq:path("/apps/([^/]+)/([^/]+)$") %rxq:produces("text/plain")
function delete-version($app as xs:string, $version as xs:string) {
  apps:delete-version($app, $version)
};



(: called in deploy script to do post install config :)
declare %rxq:POST %rxq:path("/apps/init") %rxq:produces("text/plain")
function steps-init($name as xs:string) {
  let $_ := apps:setup-permissions()
  return "OK&#10;"
};


(: steps :)

declare %rxq:GET %rxq:path("/steps") %rxq:produces("text/plain")
function list-steps() {
  rxq:response(steps:list() ! fn:concat(./@name, " ", ./@applied-at), "No steps found")
};

declare %rxq:PUT %rxq:path("/steps/(.+)") %rxq:produces("text/plain")
function apply-step($name as xs:string) {
  let $query := xdmp:get-request-body("text")
  let $db := xdmp:get-request-field("db", "Documents")
  let $once := xdmp:get-request-field("once", "") ne "false"
  return steps:apply($name, $query, $db, $once)
};


(: restart - checks boolean server field "restart-required" :)

declare %rxq:GET %rxq:path("/restart-required") %rxq:produces("text/plain")
function restart-required() {
  is-restart-required()
};

declare %rxq:POST %rxq:path("/restart") %rxq:produces("text/plain")
function restart() {
  let $force := xdmp:get-request-field("force", "") eq "true"
  return
    if ($force or is-restart-required()) then
      let $reason :=
        if ($force) then "because of request to [ml-deploy]/restart?force=true"
        else "because server field 'restart-required' set to true"
      let $_ := xdmp:restart(xdmp:hosts(), $reason)
      return "Restarting"
    else "Restart not required"
};

declare %private function is-restart-required() as xs:boolean
{
  xdmp:get-server-field("restart-required") eq fn:true()
};
