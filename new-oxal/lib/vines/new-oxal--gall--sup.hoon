::  /ted/http-oxal--bitt  :  render incoming subscriptions in sup.bowl
::
/+  *vineio
::
=<
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
=/  entries=(list [=duct =ship =path])
  %+  turn  ~(tap by sup.bowl)
  |=  [=duct [=ship =path]]
  [duct ship path]
::
=/  hymn=manx
  ::
  ;html
    ;head
      ;title: oxal bitt
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
    ==
    ;body.p5.fc.g9.pb15
      ;h1: sup.bowl
      ;div.f4.o6
        ;-  "{(scow %ud (lent entries))} incoming sub"
        ;-  ?:(=(1 (lent entries)) "" "s")
      ==
      ;div.fc.g3
        ;*
        =;  =marl  ?^  marl  marl
          ;=
            ;div.p3.o6: no incoming subscriptions
          ==
        %+  turn  entries
        |=  [=duct =ship =path]
        (render-sub duct ship path)
      ==
    ==
  ==
::
=/  pl=simple-payload:http
  :-  [200 ['content-type' 'text/html']~]
  :-  ~
  %-  as-octt:mimes:html
  %+  welp  "<!doctype html>"
  (en-xml:html hymn)
::
;<  ~  bind:m  (send-simple-payload:vio pl)
(pure:m !>(~))
::
|%
++  render-sub
  ::
  |=  [=duct =ship =path]
  ^-  manx
  ;div.fr.g3.p2.bd1.br2.mono.f5
    ;span.bold
      ;-  (scow %p ship)
    ==
    ;span.grow
      ;-  (render-path path)
    ==
    ;span.o6.f4
      ;-  (render-duct duct)
    ==
  ==
::
++  render-path
  ::
  |=  p=(list @t)
  ^-  tape
  ?~  p  "/"
  %-  zing
  %+  turn  p
  |=(seg=@t (weld "/" (trip seg)))
::
++  render-duct
  ::
  |=  =duct
  ^-  tape
  ~(ram re (sell !>(duct)))
--
