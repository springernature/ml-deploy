xquery version "1.0-ml";

import module namespace rxq = "http://exquery.org/ns/restxq" at "rxq.xqy";

import module namespace controller = "springer.com/mldeploy/controller" at "controller.xqy";

declare variable $ENABLE-CACHE as xs:boolean := fn:false();

rxq:process-request($ENABLE-CACHE)
