xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "../xray/src/assertions.xqy";

import module namespace apps = "springer.com/mldeploy/apps" at "../src/apps.xqy";

declare variable $test-uris := (
  "/apps/test-app1/0.001/sample.txt",
  "/apps/test-app1/0.002/sample.txt",
  "/apps/test-app2/0.001/sample.txt",
  "/apps/test-app2/0.001/sample.xqy"
);

declare %test:setup function insert-test-data() {
  for $uri in $test-uris
  let $app-coll := fn:string-join(fn:tokenize($uri, "/")[1 to 3], "/")
  let $version-coll := "/appversions/" || fn:string-join(fn:tokenize($uri, "/")[3 to 4], "/")
  return xdmp:document-insert($uri, text { $uri }, (), ($app-coll, $version-coll))
};


declare %test:teardown function delete-test-data() {
  cts:uri-match("/apps/test-app*") ! xdmp:document-delete(.)
};

declare %test:case function should-list-apps()
{
  assert:true(apps:list-apps() = ("test-app1", "test-app2"))
};

declare %test:case function should-list-versions-of-app()
{
  assert:equal(apps:list-versions("test-app1"), ("0.001", "0.002")),
  assert:equal(apps:list-versions("test-app2"), "0.001")
};

declare %test:case function should-list-version-files()
{
  assert:equal(apps:list-version-files("test-app1", "0.002"), "/apps/test-app1/0.002/sample.txt"),
  assert:equal(apps:list-version-files("test-app2", "0.001"), ("/apps/test-app2/0.001/sample.txt", "/apps/test-app2/0.001/sample.xqy"))
};

declare %test:case function should-return-file-contents()
{
  assert:equal(apps:get-file($test-uris[1])/fn:string(), $test-uris[1])
};


declare function create-artifact($files as xs:string+) {
  xdmp:zip-create(<parts xmlns="xdmp:zip">{ $files ! <part>{.}</part> }</parts>, $files ! document {.})
};

declare %test:case function should-install-an-artifact()
{
  let $app := "test-app3"
  let $version := "0.1"
  let $artifact := create-artifact(("foo.xqy", "bar.xqy"))
  let $actual := apps:install($app, $version, $artifact)
  return (
    assert:equal(fn:count($actual), 2),
    assert:true($actual = "Inserted foo.xqy at /apps/test-app3/0.1/foo.xqy", fn:string-join($actual, "&#10;"))
  )
};

declare %test:case function should-delete-a-version()
{
  let $app := "test-app5"
  let $version := "0.003"
  return assert:equal(apps:delete-version($app, $version), "Deleted test-app5/0.003")
};
