xquery version "1.0-ml";

module namespace apps = "springer.com/mldeploy/apps";

declare namespace zip = "xdmp:zip";


declare function app-collection($app as xs:string) as xs:string {
  "/apps/" || $app
};

declare function version-collection($app as xs:string, $version as xs:string) as xs:string {
  "/appversions/" || $app || "/" || $version
};

declare function list-apps() as xs:string* {
  cts:collection-match("/apps/*") ! fn:substring(., 7)
};

declare function list-versions($app as xs:string) as xs:string* {
  let $coll-prefix := "/appversions/" || $app || "/"
  return cts:collection-match($coll-prefix || "*") ! fn:substring-after(., $coll-prefix)
};

declare function list-version-files($app as xs:string, $version as xs:string) as xs:string* {
  cts:uris((), (), cts:collection-query(version-collection($app, $version)))
};

declare function get-file($uri as xs:string) {
  fn:doc($uri)
};

declare function install-from-url($app as xs:string, $version as xs:string, $artifact-url as xs:string) as xs:string+
{
  let $artifact := xdmp:document-get($artifact-url)/binary()
  let $ex := if (fn:empty($artifact)) then fn:error((), "Error fetching " || $artifact-url) else ()
  return install($app, $version, $artifact)
};

declare function install($app as xs:string, $version as xs:string, $artifact as binary()) {
  let $collections := (app-collection($app), version-collection($app, $version))
  let $permissions := get-permissions()
  for $part in xdmp:zip-manifest($artifact)/zip:part[@uncompressed-size ne '0']
  let $uri := fn:concat($collections[1], "/", $version, "/", $part)
  return (
    xdmp:document-insert($uri, xdmp:zip-get($artifact, $part), $permissions, $collections),
    fn:concat("Inserted ", $part, " at ", $uri)
  )
};

declare function delete-version($app as xs:string, $version as xs:string) as xs:string+
{
  xdmp:collection-delete(version-collection($app, $version)),
  fn:concat("Deleted ", $app, "/", $version)
};


declare function setup-permissions()
{
  xdmp:eval('
    import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
    if (sec:role-exists("mldeploy-access-role")) then ()
    else sec:create-role("mldeploy-access-role", "provides read and execute access to modules managed by ml-deploy", (), (), ()),
    if (sec:role-exists("mldeploy-role")) then ()
    else sec:create-role("mldeploy-role", "provides write access to modules managed by ml-deploy", (), (), ())
    ;
    import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
    sec:privilege-add-roles("http://marklogic.com/xdmp/privileges/unprotected-collections", "execute", "mldeploy-role"),
    sec:privilege-add-roles("http://marklogic.com/xdmp/privileges/unprotected-uri", "execute", "mldeploy-role")
    ;
    import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
    if (sec:user-exists("deployer")) then ()
    else sec:create-user("deployer", "ml-deploy user", "DeployMe", ("mldeploy-role", "mldeploy-access-role"), (), ())
    ', (),
    <options xmlns="xdmp:eval">
      <database>{xdmp:database("Security")}</database>
      <isolation>different-transaction</isolation>
    </options>
  ),
  xdmp:eval('
    xquery version "1.0-ml";
    for $uri in cts:uris(), $permission in ("read", "execute")
    return xdmp:document-add-permissions($uri, xdmp:permission("mldeploy-role", $permission))
    ', (),
    <options xmlns="xdmp:eval">
      <database>{xdmp:database("Documents")}</database>
      <isolation>different-transaction</isolation>
    </options>
  )
};

declare %private function get-permissions() {
  xdmp:permission("mldeploy-access-role", "read"),
  xdmp:permission("mldeploy-access-role", "execute"),
  xdmp:permission("mldeploy-role", "update")
};
