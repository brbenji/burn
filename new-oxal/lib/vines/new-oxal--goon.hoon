::  /lib/vines/new-oxal--goon: render /poots through goad-to-manx as a real page
::
::    GET  /new-oxal/goon   feather-1 + every-layout + goon-oxal stylesheets,
::                      with goad-to-manx's render-tree output inlined as
::                      the body
::
/+  *vineio, *zozo, goad-to-manx
::
=<
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
;<  =data  bind:m
  (scry ,data /gx/new-oxal/data/(scot %p our.bowl)/poots/noun)
;<  ~  bind:m  (send-html-payload:vio (render-page bowl data))
(pure:m !>(~))
::
|%
++  render-page
  |=  [bowl=http-bowl =data]
  ^-  manx
  =/  body=manx  (render-tree:goad-to-manx %root data 0 ~)
  ;html
    ;head
      ;meta(charset "UTF-8");
      ;meta
        =name  "viewport"
        =content  "width=device-width, initial-scale=1"
        ;*  ~
      ==
      ;title: /poots — goon render
      ;link(rel "stylesheet", href "/new-oxal-init/feather/1/style");
      ;link(rel "stylesheet", href "/new-oxal-init/every-layout/1/style");
      ;link(rel "stylesheet", href "/new-oxal-init/goon-oxal/1/style");
      ;script(src "/new-oxal-init/goon-oxal/1/nav", defer "");
    ==
    ;body.p5
      ;+  body
    ==
  ==
--
