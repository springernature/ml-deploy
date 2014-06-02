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


declare function create-permissions()
{
  xdmp:eval('
    xquery version "1.0-ml";
    import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
    declare variable $ROLE-NAME := "mldeploy-access-role";
    declare variable $ROLE-DESC := "provides read and execute access to modules managed by mldeploy";
    if (sec:role-exists($ROLE-NAME)) then () else sec:create-role($ROLE-NAME, $ROLE-DESC, (), (), ())
    ', (),
    <options xmlns="xdmp:eval">
      <database>{xdmp:database("Security")}</database>
      <isolation>different-transaction</isolation>
    </options>
  )
};

declare %private function get-permissions() {
  xdmp:permission("mldeploy-access-role", "read"),
  xdmp:permission("mldeploy-access-role", "execute")
};
