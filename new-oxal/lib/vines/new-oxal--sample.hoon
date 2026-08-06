::  /lib/vines/oxal--sample: inline /sample/cards lens output as a real page
::
::    GET  /new-oxal/sample   one HTML document, manx leaves inlined directly
::                        (NOT iframed like the admin's /new-oxal/mesh/sample)
::
/+  *vineio, *zozo
::
=<
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
;<  =data  bind:m
  (scry ,data /gx/new-oxal/data/(scot %p our.bowl)/sample/cards/noun)
;<  ~  bind:m  (send-html-payload:vio (render-page bowl data))
(pure:m !>(~))
::
|%
++  render-page
  ::
  ::  scry result is the subtree rooted at /sample/cards. ~(tap do data)
  ::  yields leaf-bearing [pith node] pairs; we keep only [%manx *] leaves
  ::  and splice them inline as direct children of the page body
  ::
  |=  [bowl=http-bowl =data]
  ^-  manx
  =/  manxes=(list manx)
    %+  murn  ~(tap do data)
    |=  [=pith =node]
    ^-  (unit manx)
    ?.  ?=([%manx *] node)  ~
    `manx.node
  ;html
    ;head
      ;meta(charset "UTF-8");
      ;meta
        =name  "viewport"
        =content  "width=device-width, initial-scale=1"
        ;*  ~
      ==
      ;title: sample cards
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
    ==
    ;body.p5.fc.g5.pb15
      ;header.fc.g2.bbh.pb3
        ;h1: /sample cards
        ;div.o6.fs-2
          ;-  "{(scow %ud (lent manxes))} cards (lens-derived from /sample/raw)"
        ==
      ==
      ;div.fc.g3
        ;*  manxes
      ==
    ==
  ==
--
