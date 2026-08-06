::  /lib/vines/oxal--poots: read-only render of /poots subtree
::
::    GET  /new-oxal/poots   list every leaf under our /poots/* with its value
::
/+  *vineio, *zozo
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
  ::
  ::  flat list of every leaf-bearing pith under /poots, with a
  ::  one-line +node-summary of each leaf value
  ::
  |=  [bowl=http-bowl =data]
  ^-  manx
  ::
  ::  ~(tap do data) returns leaf-bearing [pith node] pairs only —
  ::  no need to filter further
  ::
  =/  with-leaf=(list [=pith =node])  ~(tap do data)
  ;html
    ;head
      ;meta(charset "UTF-8");
      ;title: poots tree
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
    ==
    ;body.p5.fc.g5.pb15
      ;h1: /poots tree
      ;div.o6.fs-2
        ;-  "{(scow %ud (lent with-leaf))} leaf entries"
      ==
      ;ul.fc.g2
        ;*  ?:  =(~ with-leaf)
              :~  ;li.o6: empty
                  ==
              %+  turn  with-leaf
              |=  [=pith =node]
              ;li.fr.g3.bd1.br2.p3.b2.ac
                ;span.mono.bold.grow
                  ;-  (pate pith)
                ==
                ;span.o6
                  ;-  ": "
                ==
                ;span.mono.fs-2
                  ;-  (node-summary node)
                ==
              ==
      ==
    ==
  ==
--
