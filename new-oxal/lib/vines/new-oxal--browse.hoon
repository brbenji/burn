::  /lib/vines/oxal--browse  :  reactive remote browse via gall sub
::
::  url:    /new-oxal/browse/<ship>/<mesh-name>
::  watch:  <ship>'s %oxal on /sub/<mesh-name>/~
::          (pith [[%p ship] mesh-name [%n ~]] under that ship's faucet)
::
::  initial GET (no datastar header) returns a skeleton page that
::  fires data-on_load => @get(<same-url>) through datastar.  the
::  second request carries datastar-request: true; we watch the
::  remote, open SSE, and morph #oxal-tree on every %oxal-snap fact.
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
::  parse <ship>/<mesh-name> from rest
::
?>  ?=([@ @ ~] rest.bowl)
=/  ship=@p     ~|  bad-ship/rest.bowl  (slav %p i.rest.bowl)
=/  mesh=@tas   ~|  bad-mesh/rest.bowl  (slav %tas i.t.rest.bowl)
=/  cur-url=tape
  "/new-oxal/browse/{(scow %p ship)}/{(trip mesh)}"
=/  is-ds=?  =((get-header:vio 'datastar-request') `'true')
::
?.  is-ds
  ::
  ::  initial navigate: send the skeleton; datastar will refire @get
  ::
  ;<  ~  bind:m  (send-html-payload:vio (skeleton ship mesh cur-url))
  (pure:m !>(~))
::
::  datastar drove this @get; subscribe and stream
::
=/  watch-pith=pith  ~[mesh [%n ~]]
=/  watch-path=path  [%sub (pout watch-pith)]
=/  =wire           /oxal-browse/(scot %p ship)/[mesh]
::
;<  ~      bind:m  (watch wire [ship %oxal] watch-path)
;<  =cage  bind:m  (take-fact wire)
;<  ~      bind:m  open-sse:vio
=+  !<  init=[snap=data =move =life =case]  q.cage
;<  ~  bind:m  (morph:vio (render-tree ship mesh snap.init))
::
(stream wire ship mesh bowl)
::
|%
++  stream
  ::
  ::  loop: take-fact, render, morph, repeat.  spider/eyre will tear
  ::  the thread down when the client disconnects.
  ::
  |=  [=wire ship=@p mesh=@tas =http-bowl]
  =/  m  (strand ,vase)
  ^-  form:m
  =/  vio  ~(. server http-bowl)
  ;<  =cage  bind:m  (take-fact wire)
  =+  !<  upd=[snap=data =move =life =case]  q.cage
  ;<  ~  bind:m  (morph:vio (render-tree ship mesh snap.upd))
  $
  ::
::
++  skeleton
  ::
  ::  static page with a data-on_load that refires this url as a
  ::  datastar request; the SSE response then morphs #oxal-tree.
  ::
  |=  [ship=@p mesh=@tas cur-url=tape]
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
      ;title: {(scow %p ship)}/{(trip mesh)}
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
      ;script(type "module", src "/hawk-init/feather/1/datastar");
    ==
    ;body.fc.bbv.hf
      ;header.fr.af.g2.bbh.mono.b2
        ;form.fr.grow.af.bbh
          =onsubmit  "event.preventDefault();location.href='/new-oxal/browse/'+this.ship.value+'/'+this.mesh.value;return false"
          ;input.p-2.mono.fs-2.grow
            =type  "text"
            =name  "ship"
            =value  (scow %p ship)
            =placeholder  "~ship"
            =required  ""
            =spellcheck  "false"
            ;*  ~
          ==
          ;input.p-2.mono.fs-2.grow
            =type  "text"
            =name  "mesh"
            =value  (trip mesh)
            =placeholder  "mesh"
            =required  ""
            =spellcheck  "false"
            ;*  ~
          ==
          ;button.p-2.br2.bd1.b2.hover.f-1: go
        ==
      ==
      ;div#oxal-tree.fc.g3.p4.scroll-y.grow
        =data-init  "@get('{cur-url}')"
        ;div.o6.fs-2: connecting…
      ==
    ==
  ==
  ::
::
++  render-tree
  ::
  ::  fragment that morphs into #oxal-tree.  always carries the same
  ::  id so datastar can find it on every push.
  ::
  |=  [ship=@p mesh=@tas root=data]
  ^-  manx
  ;div#oxal-tree.fc.g3.p4.scroll-y.grow
    ;div.fr.g2.fs-2.o6.bbh.pb2
      ;span.mono: {(scow %p ship)}
      ;span: /
      ;span.mono.bold: {(trip mesh)}
      ;span.grow;
      ;span.b2.px2.br2.bd1: live
    ==
    ;+  ~(level dat-tree root)
  ==
  ::
::
++  dat-tree
  ::
  ::  read-only data tree renderer.  no code/meta info, no forms,
  ::  no auth — just a recursive view of (oxal node).
  ::
  =|  sug=(unit iota)
  |_  d=data
  ::
  ++  level
    ^-  manx
    ;div.fc
      ;+  part-row
      ;+  recurse
    ==
    ::
  ::
  ++  part-row
    ::
    ::  one row: the segment label (or "/" at the root) and, if the
    ::  node has a leaf, an "= <summary>" suffix.
    ::
    ^-  manx
    ;div.fr.g2.py-2.fs-2.mono
      ;span.bold
        ;-  ?~  sug  "/"
            (node-summary u.sug)
      ==
      ;+  ?~  leaf.d  ;/  ""
          ;span.o7
            ;-  " = "
            ;-  (node-summary u.leaf.d)
          ==
    ==
    ::
  ::
  ++  recurse
    ::
    ::  one indented child row per kid; rebuild the door with the
    ::  child's iota as sug and its data as d.
    ::
    ^-  manx
    ?:  =(~ kids.d)  ;/  ""
    ;div.pl4.fc
      ;*
      %+  turn  ~(kid-list do d)
      |=  [=iota dd=data]
      %=  level
        sug  `iota
        d    dd
      ==
    ==
    ::
  --
--
