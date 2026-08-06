::  /views/goad-inspector.hoon — pretty-print oxal-to-goad output
::
::    GET  /new-oxal/goad-inspector            inspects /poots (default)
::    GET  /new-oxal/goad-inspector?path=/foo  inspects arbitrary subtree
::
::  Verification view for Run 1a. Scries an oxal data subtree, runs it
::  through oxal-to-goad, dumps the resulting goad structure as a
::  pre-formatted text block.
::
::  Type access: oxal-to-goad inlines the goad type defs in its core,
::  so we reference them as goad:oxal-to-goad etc.
::
/+  *vineio, *zozo, oxal-to-goad
::
=<
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::  read ?path= query parameter; default to /poots
=/  inspect-path=path
  =/  q  (~(get by query.bowl) 'path')
  ?~  q  /poots
  (stab u.q)
=/  scry-path=path
  ;:  welp
    /gx/new-oxal/data/[(scot %p our.bowl)]
    inspect-path
    /noun
  ==
;<  =data  bind:m  (scry ,data scry-path)
=/  =goad:oxal-to-goad  (oxal-to-goad:oxal-to-goad %root data)
;<  ~  bind:m  (send-html-payload:vio (render-page bowl inspect-path goad))
(pure:m !>(~))
::
|%
++  render-page
  |=  [bowl=http-bowl pth=path =goad:oxal-to-goad]
  ^-  manx
  =/  hdr=tape  :(welp "goad inspector — path: " (spud pth))
  =/  body=tape  (goad-tape goad)
  ;html
    ;head
      ;meta(charset "UTF-8");
      ;title: goad-inspector
    ==
    ;body
      ;h1: {hdr}
      ;pre: {body}
    ==
  ==
::
++  goad-tape
  |=  g=goad:oxal-to-goad
  =/  depth=@ud  0
  |^  ^-  tape
      (loop g depth)
  ::
  ++  loop
    |=  [g=goad:oxal-to-goad depth=@ud]
    ^-  tape
    =/  pad=tape  (reap (mul depth 2) ' ')
    =/  hdr=tape
      :(welp pad "iota: " (iota-tape p.g) " | attrs: " (attrs-tape q.g) "\0a")
    =/  kids=tape
      %-  zing
      %+  turn  r.g
      |=  c=goad:oxal-to-goad
      (loop c +(depth))
    (welp hdr kids)
  ::
  ++  iota-tape
    |=  =goon-iota:oxal-to-goad
    ^-  tape
    ?@  goon-iota  (trip goon-iota)
    :(welp "[" (trip -.goon-iota) " " (scow %ud +.goon-iota) "]")
  ::
  ++  attrs-tape
    |=  attrs=(list attr:oxal-to-goad)
    ^-  tape
    ?~  attrs  ""
    %-  zing
    %+  turn  attrs
    |=  =attr:oxal-to-goad
    ^-  tape
    ?-  -.attr
      %lede  :(welp "[lede '" (trip p.attr) "'] ")
      %info  :(welp "[info '" (trip p.attr) "'] ")
      %edit  "[edit] "
      %add   "[add] "
      %act
        =/  names=tape
          %-  zing
          %+  turn  p.attr
          |=  a=act:oxal-to-goad
          :(welp (trip p.a) ",")
        :(welp "[act " names "] ")
      %value  "[value] "
      %click  "[click] "
      %key   :(welp "[key %" (trip p.attr) "] ")
    ==
  --
--
