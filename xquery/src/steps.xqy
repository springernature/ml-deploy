xquery version "1.0-ml";

module namespace steps = "springer.com/mldeploy/steps";

declare variable $URI := "/steps.xml";

declare function list() as element(step)* {
  fn:doc($URI)/steps/step
};

declare function apply($name as xs:string, $query as xs:string, $db as xs:string, $apply-once as xs:boolean) {
  if (fn:not($apply-once) or fn:not(applied($name)))
  then (
    eval($query, $db),
    add($name, $db),
    fn:concat("Applied step: ", $name, " (db: ", $db, ")")
  )
  else "Skipped step: " || $name
};

declare %private function applied($name as xs:string) as xs:boolean {
  fn:exists(list()[@name eq $name])
};

declare %private function add($name as xs:string, $db as xs:string) as empty-sequence() {
  let $new-step := <step name="{$name}" applied-at="{fn:current-dateTime()}" db="{$db}"/>
  return
    if (fn:doc-available($URI))
    then xdmp:node-insert-child(fn:doc($URI)/steps, $new-step)
    else xdmp:document-insert($URI, <steps>{$new-step}</steps>)
};

declare %private function eval($query as xs:string, $db as xs:string) {
  xdmp:eval($query, (), db-options($db))
};


declare %private function db-options($db) {
  <options xmlns="xdmp:eval"><database>{xdmp:database($db)}</database></options>
};
