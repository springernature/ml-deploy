xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "../xray/src/assertions.xqy";

import module namespace steps = "springer.com/mldeploy/steps" at "../src/steps.xqy";

declare variable $steps-uri := "/steps.xml";

declare variable $steps :=
  <steps>
    <step name="step1.xqy" applied-at="2001-02-03T04:05:06" db="foo"/>
  </steps>;

declare %test:setup function insert-test-data() {
  xdmp:document-insert($steps-uri, $steps)
};

declare %test:teardown function delete-test-data() {
  xdmp:document-delete($steps-uri)
};

declare %test:case function should-list-apps()
{
  let $actual := steps:list()
  return assert:not-empty($actual/step[@name eq "step1.xqy" and @db eq "foo"])
};

declare %test:case function should-apply-step-not-already-applied()
{
  let $actual := steps:apply("step2.xqy", "'hello'", "Documents", fn:true())
  return (
    assert:equal($actual[1], "hello"),
    assert:equal($actual[2], "Applied step: step2.xqy (db: Documents)")
  )
};

declare %test:case function should-skip-existing-step-when-apply-once-is-true()
{
  assert:equal(steps:apply("step1.xqy", "'hello'", "Documents", fn:true()), "Skipped step: step1.xqy")
};

declare %test:case function should-apply-step-when-apply-once-is-false()
{
  assert:equal(steps:apply("step1.xqy", "'hello'", "Documents", fn:false())[1], "hello")
};

declare %test:case function should-error-if-db-missing()
{
  let $actual := try { steps:apply("step3.xqy", "'hello'", "FOO", fn:true()) } catch($ex) { $ex }
  return assert:error($actual, "XDMP-NOSUCHDB")
};
