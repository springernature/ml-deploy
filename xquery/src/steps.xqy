xquery version "1.0-ml";

module namespace steps = "springer.com/mldeploy/steps";

declare variable $log := fn:doc("/steps.xml")/steps;

declare function list() as element(steps)? {
  $log
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
  fn:exists($log/step[@name eq $name])
};

declare %private function add($name as xs:string, $db as xs:string) as empty-sequence() {
  xdmp:node-insert-child($log, <step name="{$name}" applied-at="{fn:current-dateTime()}" db="{$db}"/>)
};

declare %private function eval($query as xs:string, $db as xs:string) {
  xdmp:eval($query, (), <options xmlns="xdmp:eval">
    <database>{xdmp:database($db)}</database>
  </options>)
};
