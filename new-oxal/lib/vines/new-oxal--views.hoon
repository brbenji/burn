::  /lib/vines/oxal--views  :  flat list of every view in the acer
::
::    GET  /new-oxal/views   one row per view: mesh name, kind, stem path.
::
/+  *vineio, *zozo
::
=<
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
;<  =acer  bind:m  (scry ,acer /gx/new-oxal/acer/noun)
=/  rows=(list [name=term =stem =view])
  %-  zing
  %+  turn  meshes.acer
  |=  [name=term =mesh]
  ^-  (list [term stem view])
  %+  turn  ~(tap by views.mesh)
  |=  [=stem =view]
  [name stem view]
::
;<  ~  bind:m
  %-  send-simple-payload:vio
  %+  node-to-simple-payload  %manx
  (render rows)
(pure:m !>(~))
::
|%
++  render
  ::
  |=  rows=(list [name=term =stem =view])
  ^-  manx
  ;html
    ;head
      ;meta(charset "UTF-8");
      ;meta
        =name  "viewport"
        =content  "width=device-width, ".
                  "initial-scale=1, ".
                  "maximum-scale=1, ".
                  "user-scalable=no, ".
                  "viewport-fit=cover"
        ;*  ~
      ==
      ;title: oxal views
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
    ==
    ;body.p5.fc.g5.pb15
      ;h1: views
      ;div.fr.g3.f4.o6
        ;span
          ;-  "{(scow %ud (lent rows))} view"
          ;-  ?:(=(1 (lent rows)) "" "s")
        ==
      ==
      ;div.fc
        ;*
        =;  =marl  ?^  marl  marl
          ;=
            ;div.p3.bd1.br2.o6: no views
          ==
        %+  turn  rows
        |=  [name=term =stem =view]
        (render-row name stem view)
      ==
    ==
  ==
::
++  render-row
  ::
  |=  [name=term =stem =view]
  ^-  manx
  =/  href=tape  (trip (spat /new-oxal/mesh/[name]))
  ;div.fr.g3.p2.bbh.ac
    ;span.fs-2.o6: {?-(-.view %form "form", %lens "lens")}
    ;a.bold.mono.hover
      =href  href
      ;-  "%"
      ;-  (trip name)
    ==
    ;span.mono.grow
      ;-  (pate stem)
    ==
  ==
--
