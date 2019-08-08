xquery version "1.0-ml";

module namespace steps = "springer.com/mldeploy/steps";

import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare variable $URI := "/steps.xml";

declare %private function in-documents-db($fn as xdmp:function) {
  xdmp:invoke-function(function() {
      $fn(),
      xdmp:commit()
    },
    db-options("Documents")
  )
};

declare function list() as element(step)* {
  in-documents-db(function() {
    fn:doc($URI)/steps/step
  })
};

declare function apply($name as xs:string, $query as xs:string, $db as xs:string, $apply-once as xs:boolean) {
  if (fn:not($apply-once) or fn:not(applied($name)))
  then (
    eval($query, $db),
    if ($apply-once) then add($name, $db) else (),
    fn:concat("Applied step: ", $name, " (db: ", $db, ")")
  )
  else "Skipped step: " || $name
};

declare function save-config($config as element(configuration)) {
  let $needs-restart := admin:save-configuration-without-restart($config)
  where fn:exists($needs-restart)
  return (xdmp:set-server-field("restart-required", fn:true()), "Restart required")
};

declare %private function applied($name as xs:string) as xs:boolean {
  fn:exists(list()[@name eq $name])
};

declare %private function add($name as xs:string, $db as xs:string) as empty-sequence() {
  in-documents-db(function() {
    let $new-step := <step name="{$name}" applied-at="{fn:current-dateTime()}" db="{$db}"/>
    return
      if (fn:doc-available($URI))
      then xdmp:node-insert-child(fn:doc($URI)/steps, $new-step)
      else xdmp:document-insert($URI, <steps>{$new-step}</steps>)
  })
};

declare %private function eval($query as xs:string, $db as xs:string) {
  xdmp:eval($query, (), db-options($db))
};


declare %private function db-options($db) {
  <options xmlns="xdmp:eval">
    <database>{xdmp:database($db)}</database>
    <transaction-mode>update</transaction-mode>
  </options>
};
