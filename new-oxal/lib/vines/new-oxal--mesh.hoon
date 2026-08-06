/+  *vineio
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
;<  ax=acer  bind:m  (scry ,acer /gx/new-oxal/acer/noun)
=/  mesh-name=@tas  ~|  %not-found  (head rest.bowl)
=/  =mesh  (got-mesh ax mesh-name)
=/  start=pith  #/[p+our.bowl]/[mesh-name]
::
|^
  :::
  ~>  %bout.[0 %mesh-render]
  =;  =(each form:m tang)  :: error handling
    ::
    ?:  ?=(%.y -.each)  p.each
    ;<  ~  bind:m
      %-  send-html-payload:vio
      ;div#error.p3.bdb1.lh0.fs-1.b-1.scroll-y
        =style  "max-height: 120px;"
        ;form(data-on_submit post)
          ;input(type "hidden", name "op", value "clear-error");
          ;button.p-2.br2.bd1.f-1.b-1.bc-1.hover: clear error
        ==
        ;+  (render-tang p.each)
      ==
    (pure:m !>(~))
    ::
  %-  mule  |.
  ^-  form:m
  ?:  =('POST' method.bowl)
    =/  body=(map @t @t)  formencoded-body:vio
    =/  op=@tas           (~(got by body) 'op')
    =/  is-ds=?           =((get-header:vio 'datastar-request') `'true')
    =/  route             [is-ds op]
    ::
    ?+  route  ~|  route-not-found/route  !!
      :::
      [%.y %set-source]
        ::
        =/  src=@t      (fix-newlines (~(got by body) 'source'))
        ;<  ~  bind:m  (poke-our:vio %load-mesh !>([mesh-name `mesh-source`[%mono src]]))
        ;<  new-ax=acer  bind:m  (scry ,acer /gx/new-oxal/acer/noun)
        =.  ax  new-ax
        =.  mesh  (got-mesh ax mesh-name)
        ;<  ~  bind:m  (send-html-payload:vio two-panels)
        (pure:m !>(~))
      ::
      [%.y %set-poly-view]
        ::
        =/  =pith  !<(pith (slap !>(.) (ream (~(got by body) 'pith'))))
        =/  src=@t  (fix-newlines (~(got by body) 'source'))
        ;<  ~  bind:m  (poke-our:vio %set-poly-view !>([mesh-name pith src]))
        ;<  new-ax=acer  bind:m  (scry ,acer /gx/new-oxal/acer/noun)
        =.  ax  new-ax
        =.  mesh  (got-mesh ax mesh-name)
        ;<  ~  bind:m  (send-html-payload:vio two-panels)
        (pure:m !>(~))
      ::
      [%.y %del-poly-view]
        ::
        =/  =pith  !<(pith (slap !>(.) (ream (~(got by body) 'pith'))))
        ;<  ~  bind:m  (poke-our:vio %del-poly-view !>([mesh-name pith]))
        ;<  new-ax=acer  bind:m  (scry ,acer /gx/new-oxal/acer/noun)
        =.  ax  new-ax
        =.  mesh  (got-mesh ax mesh-name)
        ;<  ~  bind:m  (send-html-payload:vio two-panels)
        (pure:m !>(~))
      ::
      [%.y %ins-node]
        ::
        =/  =pith  !<(pith (slap !>(.) (ream (~(got by body) 'pith'))))
        =/  value=@t   (fix-newlines (~(got by body) 'value'))
        =/  =node
          =/  try=(unit node)
            %-  mole  |.
            !<(node (slap !>(.) (ream value)))
          ?^  try  u.try
          (sily (trip value))
        =/  changes=(set chng)  (silt [%ins pith node]~)
        ;<  ~  bind:m  (poke-our:vio %do-move !>(changes))
        ;<  new-ax=acer  bind:m  (scry ,acer /gx/new-oxal/acer/noun)
        =.  ax  new-ax
        =.  mesh  (got-mesh ax mesh-name)
        ;<  ~  bind:m  (send-html-payload:vio part-file)
        (pure:m !>(~))
      ::
      [%.y %del-node]
        ::
        =/  =pith  !<(pith (slap !>(.) (ream (~(got by body) 'pith'))))
        =/  changes=(set chng)  (silt [%del pith]~)
        ;<  ~  bind:m  (poke-our:vio %do-move !>(changes))
        ;<  new-ax=acer  bind:m  (scry ,acer /gx/new-oxal/acer/noun)
        =.  ax  new-ax
        =.  mesh  (got-mesh ax mesh-name)
        ;<  ~  bind:m  (send-html-payload:vio part-file)
        (pure:m !>(~))
      ::
      [%.y %bump]
        ::
        =/  =pith  (stib (trip (~(got by body) 'pith')))
        ;<  ~  bind:m  (poke-our:vio %bump !>(pith))
        ;<  new-ax=acer  bind:m  (scry ,acer /gx/new-oxal/acer/noun)
        =.  ax  new-ax
        =.  mesh  (got-mesh ax mesh-name)
        ;<  ~  bind:m  (send-html-payload:vio part-file)
        (pure:m !>(~))
      ::
      [%.y %set-auth]
        ::
        =/  =pith    (stib (trip (~(got by body) 'pith')))
        =/  kind=@t  (~(got by body) 'kind')
        =/  val=(unit auth)
          ?:  =('none' kind)     ~
          ?:  =('private' kind)  `[%white ~]
          ?:  =('public' kind)   `[%black ~]
          ~|  bad-auth-kind/kind  !!
        ;<  ~  bind:m  (poke-our:vio %set-gall !>([pith val]))
        ;<  new-ax=acer  bind:m  (scry ,acer /gx/new-oxal/acer/noun)
        =.  ax  new-ax
        =.  mesh  (got-mesh ax mesh-name)
        ;<  ~  bind:m  (send-html-payload:vio part-file)
        (pure:m !>(~))
      ::
      [%.y %show-logs]
        ::
        =/  =pith  (stib (trip (~(got by body) 'pith')))
        ;<  ~  bind:m
          %-  send-html-payload:vio
          %~  info-logs-full  render-file
          [pith (~(dip fe file.ax) pith)]
        (pure:m !>(~))
        ::
      ::
      [%.y %hide-logs]
        ::
        =/  =pith  (stib (trip (~(got by body) 'pith')))
        ;<  ~  bind:m
          %-  send-html-payload:vio
          %~  info-logs-stub  render-file
          [pith (~(dip fe file.ax) pith)]
        (pure:m !>(~))
        ::
      ::
      [%.y %clear-error]
        ::
        ;<  ~  bind:m
          %-  send-html-payload:vio
          ;div#error;
        (pure:m !>(~))
        ::
      ::
      [%.n %drop-mesh]
        ::
        ;<  ~  bind:m  (poke-our:vio %drop-mesh !>(mesh-name))
        ;<  ~  bind:m
          %+  send-simple-payload:vio
            [303 ['location' '/new-oxal/meshes']~]
          ~
        (pure:m !>(~))
        ::
      ::
    ==
  ::
  ;<  ~  bind:m  (send-html-payload:vio hymn)
  ::
  (pure:m !>(~))
::
++  post  "@post('{(pate (welp [prefix rest]:bowl))}', \{contentType: 'form'})"
::
++  is-poly  ?=(%poly -.mesh-source.mesh)
::
++  hymn
  ::
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
      ;title: {(trip mesh-name)}
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
      ;script(type "module", src "/hawk-init/feather/1/textarea");
      ;script(type "module", src "/hawk-init/feather/1/text-editor");
      ;script(type "module", src "/hawk-init/feather/1/slide-panels");
      ;script(type "module", src "/hawk-init/feather/1/datastar");
    ==
    ;body.fc.bbv.hf
      ;+  part-header
      ;div#error;
      ;+  two-panels
    ==
  ==
  ::
::
++  part-header
  ::
  ^-  manx
  ;header.fr.af.bbh.mono.b2
    ;a.b2.f3.hover.p-3
      =href  "/new-oxal/meshes"
      ; <
    ==
    ;strong.grow.p-3: {"%"}{(trip mesh-name)}
    ;button.p-3.b2.f-3.hover
      =data-on_click  "$edit = !$edit"
      =data-class_toggled  "$edit"
      ; edit
    ==
  ==
  ::
::
++  part-error
  ::
  ^-  manx
  ?~  error.mesh  ;/  ""
  ;div
    ;+  (render-tang u.error.mesh)
  ==
::
++  two-panels
  ::
  ;feather-slide-panels.grow.scroll-none
    =id  "panels"
    ;+  part-file
    ;+  part-source
  ==
::
++  part-source
  ::
  ^-  manx
  ?:  is-poly  part-source-poly
  ;div.hf.fc.grow.scroll-none
    =id  "part-source"
    =data-show  "$edit"
    ;form.fc.grow.bbv.scroll-none
      =id  "mesh-source"
      =data-on_submit  post
      =data-indicator  "_savesource"
      =data-class_o7  "$_savesource"
      ;+  part-error
      ;input(type "hidden", name "op", value "set-source");
      ;feather-text-editor.grow.fs-2
        =auto-indent  ""
        =name  "source"
        ;-  ?:  ?=(%mono -.mesh-source.mesh)  (trip src.mesh-source.mesh)
            ""
      ==
    ==
    ;div.fr.bbh
      ;button.p3.b3.hover.grow
        =data-attr_disabled  "$_savesource"
        =type  "submit"
        =form  "mesh-source"
        ; load
      ==
      ;form(method "post")
        ;input(type "hidden", name "op", value "drop-mesh");
        ;button.p-3.b3.hover.f-1: drop
      ==
    ==
  ==
::
++  part-source-poly
  ::
  ::  right panel for poly meshes.  per-view editors live inline in
  ::  +part-info; this panel just holds the bootstrap "add view"
  ::  form and a drop button.
  ::
  ^-  manx
  ;div.hf.fc.grow.scroll-none
    =id  "part-source"
    =data-show  "$edit"
    ;div.fc.g3.p3.scroll-y.grow
      ;+  part-error
      ;+  part-poly-add-view
    ==
    ;div.fr.bbh
      ;form(method "post")
        ;input(type "hidden", name "op", value "drop-mesh");
        ;button.p-3.b3.hover.f-1.grow: drop
      ==
    ==
  ==
::
++  part-file
  ::
  =/  partial=file
    %.  start
    %~  dip  fe
    %-  ~(partial fe file.ax)
    %-  ~(run in ~(key by views.mesh))
    |=  =pith
    [p+our.bowl pith]
  ;div#file.p4.pb20.fc.g3.grow.hf.scroll-y-always
    ;+  (render-file [start partial])
  ==
::
++  part-poly-add-view
  ::
  ::  inline form for adding a new view to a poly mesh.  pith input
  ::  is parsed by +slap (so [#/foo/bar] etc. work); source is any
  ::  hoon expression evaluating to a view-spec.
  ::
  ;div.fc.g2.bd1.br2.p2
    ;form.fc.g2(data-on_submit post)
      ;input(type "hidden", name "op", value "set-poly-view");
      ;label.fc.g1
        ;span.fs-2.o6: pith
        ;input.p-2.br2.bd1.mono
          =type  "text"
          =name  "pith"
          =placeholder  "[#/foo/bar]"
          =required  ""
          =spellcheck  "false"
          ;*  ~
        ==
      ==
      ;label.fc.g1
        ;span.fs-2.o6: source
        ;feather-textarea.p2.mono.fs-2.bd1.br2
          =rows  "8"
          =name  "source"
          =placeholder  "[%form ~]"
          =required  ""
          =spellcheck  "false"
          ;*  ~
        ==
      ==
      ;button.p-2.br2.bd1.b3.hover: add view
    ==
  ==
  ::
::
++  render-file
  :::
  =|  sug=(unit iota)
  =|  under-view=_|
  =|  under-lens=_|
  =|  under-form=_|
  =|  at-view=_|
  =|  at-lens=_|
  =|  at-form=_|
  =|  data-below=_&
  |_  [pax=pith fap=file]
  ++  $  level
  ::
  ++  nid  (uid pax)
  ++  node-meta  (fall leaf.code.fap *meta)
  ++  pate-stem  (pate ?~(pax ~ t.pax))
  ++  pare-stem  (pare ?~(pax ~ t.pax))
  ::
  ++  recurse
    ::
    ^-  manx
    ;div.pl4
      ;*
      %+  turn  ~(kid-list fe fap)
      |=  [=iota =file]
      =/  node-meta=meta  (fall leaf.code.file *meta)
      =/  at-view         ?=(^ lord.node-meta)
      =/  at-lens         &(?=(^ lord.node-meta) ?=(%lens -.view.u.lord.node-meta))
      =/  at-form         &(?=(^ lord.node-meta) ?=(%form -.view.u.lord.node-meta))
      %=  level
        sug           `iota
        pax           (snoc pax iota)
        at-view       at-view
        at-lens       at-lens
        at-form       at-form
        under-view    |(under-view at-view)
        under-lens    |(under-lens at-lens)
        under-form    |(under-form at-form)
        data-below    |(?=(^ kids.data.file) ?=(^ leaf.data.file))
        fap  file
      ==
    ==
  ::
  ++  level
    ::
    ^-  manx
    ;div
      ;+  part-row
      ;+  recurse
    ==
  ::
  ++  render-node
    ::
    |=  =node
    ;span
      ;+  ?@  node  ;/("")
          ;span.fs-2.o6: {(print-aura node)}:
      ;+  ?:  ?=  [%pith *]  node
            ;span.ml2
              ;*
              =;  =marl  ?^  marl  marl
                ;=
                  ;-  "/"
                ==
              %+  turn  pith.node
              |=  nod=^node
              ;span
                ;-  "/"
                ;+  ^$(node nod)
              ==
            ==
          ;span: {(node-summary node)}
    ==
  ::
  ++  part-row
    ::
    =/  node-meta=meta  node-meta
    ^-  manx
    ;div.fc.g1
      ;div.fr.g2.wf
        ;+  %^  add-class-if  !data-below  "o4"
        ;button.fr.g4.hover.b1.grow.px2.br2
          =data-on_click  "$_rowopen{nid} = !$_rowopen{nid}"
          =data-class_active  "$_rowopen{nid}"
          ;+  %^  add-class-if  under-lens  "f-3"
              %^  add-class-if  under-form  "f-4"
              %^  add-class-if  at-view  "bold"
              ?~  sug  ;span:"/"
              (render-node u.sug)
          ;+  ?:  =(~ subs.node-meta)  ;/  ""
              ;span.f-3: [{<~(wyt in subs.node-meta)>}]
          ;+  ?:  =(~ view-subs.node-meta)  ;/  ""
              ;span.f-2: \{{<~(wyt in view-subs.node-meta)>}}
          ;+  ?~  leaf.data.fap  ;/  ""
              (render-node u.leaf.data.fap)
          ;+  part-indicators
          ;div.grow;
          ;div
            ;-  ^-  tape
                ?~  gall.node-meta  ""
                <kind.u.gall.node-meta>
          ==
          ;div
            ;-  <case.node-meta>
            ;-  ":"
            ;-  <life.node-meta>
          ==
        ==
      ==
      ;+  part-info
    ==
  ::
  ++  part-indicators
    ::
    =/  node-meta=meta  node-meta
    ^-  manx
    ?~  lord.node-meta  ;/  ""
    ?.  ?=  %lens  -.view.u.lord.node-meta  ;/  ""
    =/  =lens  +.view.u.lord.node-meta
    ?~  err.lens  ;/  ""
    ;div.f-1: •
    ::
  ::
  ++  part-info
    ::
    ^-  manx
    =/  infos=(list (unit [tape manx]))
      :~
        info-node
        info-lord
        info-logs
        info-bump
        info-auth
      ==
    ;div.mr5.ml3.b2
      =style  hid
      =data-show  "$_rowopen{nid}"
      ;+  (make-tabs "row" infos)
    ==
  ::
  ++  info-lord
    ::
    ::
    ::    mono+lens  read-only display: source/sauc, dep, lyf:cas,
    ::               in/out shape placeholders, error tang if any.
    ::    mono+form  out-shape placeholder + html form for adding
    ::               data below.
    ::    poly+lens  editor for the view's poly source.
    ::    poly+form  html form for adding data + editor for the
    ::               view's poly source.
    ::
    ^-  (unit [tape manx])
    =/  node-meta=meta  node-meta
    ?~  lord.node-meta  ~
    =/  v  view.u.lord.node-meta
    ?-  -.v
      %lens
        :-  ~
        :-  "lens"
        ?:  is-poly
          ;div.fc.g2
            ;+  (lens-err err.+.v)
            ;+  poly-edit
          ==
        (mono-lens +.v)
      %form
        :-  ~
        :-  "form"
        %+  make-tabs  "form"
        :~
          `["insert" data-add]
          ?.  is-poly  ~  `["edit" poly-edit]
        ==
    ==
  ::
  ++  make-tabs
    ::
    |=  [id=tape tabs=(list (unit [tape manx]))]
    =/  full=(list [tape manx])
      %+  murn  tabs
      |=  =(unit [tape manx])
      ?~  unit  ~
      `u.unit
    ?:  =(~ full)
      ;div.p3
        ; none
      ==
    =/  first=tape  (head (head full))
    =/  signal  "_tab{id}{nid}"
    ;div.fc.bbv.br2.bd1.scroll-none
      ;+  %^  add-class-if  =(1 (lent full))  "hidden"
      ;div.fr.bbh
        =data-signals  "\{'{signal}': '{first}'}"
        ;*
        %+  turn  full
        |=  [label=tape =manx]
        ;button.p-2.b2.hover
          =data-on_click  "${signal} = '{label}'"
          =data-class_toggled  "${signal} == '{label}'"
          ;-  label
        ==
      ==
      ;div.fc.p2
        ;*
        %+  turn  full
        |=  [label=tape =manx]
        ;div
          =style  hid
          =data-show  "${signal} == '{label}'"
          ;+  manx
        ==
      ==
    ==
    ::
  ::
  ++  poly-edit
    ::
    ::  editor for a poly mesh's per-view source code.  reads the
    ::  source for this stem from mesh-source; renders empty if no
    ::  source yet.  delete button removes the view.
    ::
    ^-  manx
    =/  src=@t
      ?.  ?=(%poly -.mesh-source.mesh)  ''
      =/  s=pith  ?~(pax ~ t.pax)
      (~(gut by srcs.mesh-source.mesh) s '')
    ;div.fc.bbv.br2.bd1.scroll-none
      ;form.fc.bbv
        =id  "polysrc{nid}"
        =data-on_submit  post
        ;input(type "hidden", name "op", value "set-poly-view");
        ;input(type "hidden", name "pith", value pare-stem);
        ;feather-textarea.p2.mono.fs-2
          =required  ""
          =name  "source"
          ;-  (trip src)
        ==
      ==
      ;div.fr.bbh
        ;button.b3.hover.p2.grow
          =form  "polysrc{nid}"
          =type  "submit"
          ; save
        ==
        ;form
          =data-on_submit  post
          ;input(type "hidden", name "op", value "del-poly-view");
          ;input(type "hidden", name "pith", value pare-stem);
          ;button.b3.hover.p-2.f-1
            ; delete
          ==
        ==
      ==
    ==
  ::
  ++  info-bump
    ::
    ^-  (unit [tape manx])
    ?.  under-form  ~
    :-  ~
    :-  "bump"
    ;form
      =data-on_submit  post
      ;input(type "hidden", name "op", value "bump");
      ;input(type "hidden", name "pith", value pate-stem);
      ;button.p2.br2.bd1.b3.hover
        ; bump
      ==
    ==
  ::
  ++  info-auth
    ::
    ::  configure gall (subscription) auth on this node:
    ::    none     no subscriptions allowed
    ::    private  only this ship can subscribe
    ::    public   any ship can subscribe
    ::
    ^-  (unit [tape manx])
    =/  node-meta=meta  node-meta
    =/  current=tape
      ?~  gall.node-meta  "none"
      ?:  ?=(%white kind.u.gall.node-meta)  "private"
      ?:  ?=(%black kind.u.gall.node-meta)  "public"
      "custom"
    :-  ~
    :-  "auth"
    ;div.fr.g2
      ;+  (auth-button "none" current)
      ;+  (auth-button "private" current)
      ;+  (auth-button "public" current)
    ==
  ::
  ++  auth-button
    ::
    ::  one of the three quick-auth buttons.  highlights when its
    ::  kind matches the node's current gall auth state.
    ::
    |=  [kind=tape current=tape]
    ^-  manx
    ;form
      =data-on_submit  post
      ;input(type "hidden", name "op", value "set-auth");
      ;input(type "hidden", name "pith", value pate-stem);
      ;input(type "hidden", name "kind", value kind);
      ;+  %^  add-class-if  =(kind current)  "b3"
          ;button.p2.br2.bd1.hover
            ;-  kind
          ==
    ==
  ::
  ++  info-node
    ::
    ^-  (unit [tape manx])
    ?~  leaf.data.fap  ~
    :-  ~
    :-  "node"
    ?.  under-form
      (view-node u.leaf.data.fap)
    (edit-node u.leaf.data.fap)
  ::
  ++  info-logs  `["logs" info-logs-stub]
  ::
  ++  info-logs-stub
    ::
    ^-  manx
    =/  node-meta=meta  node-meta
    ;form(id "logs{nid}")
      =data-on_submit  post
      ;input(type "hidden", name "op", value "show-logs");
      ;input(type "hidden", name "pith", value (pate pax));
      ;button.p2.br2.bd1.b3.hover: view logs ({<case.node-meta>})
    ==
    ::
  ::
  ++  info-logs-full
    ::
    =/  node-meta=meta  node-meta
    ;div.fc.g2
      =id  "logs{nid}"
      ;form
        =data-on_submit  post
        ;input(type "hidden", name "op", value "hide-logs");
        ;input(type "hidden", name "pith", value (pate pax));
        ;button.p2.br2.bd1.b3.hover: hide logs
      ==
      ::
      ;div.fc.bbv.br2.bd1.p2.fs-2
        ;*
        %-  flop
        =<  p
        %^  spin  logs.node-meta  0
        |=  [=move a=@]
        :_  +(a)
        ;div.fr.as.g3
          ;span: {<a>}
          ;span.fs-2.o6: {(scow %da phys.time.move)}
          ;span.fs-2.o4: .{(scow %ud logi.time.move)}
          ;div.fc.mono
            ;*
            %+  turn  ~(tap in chng-set.move)
            |=  =chng
            ?-  -.chng
              %ins
                ;div.fr.g3
                  ;span: %ins
                  ;span: {(pate pith.chng)}
                  ;span: {(print-aura node.chng)}
                ==
              %del
                ;div.fr.g3
                  ;span: %del
                  ;span: {(pate pith.chng)}
                ==
            ==
          ==
        ==
      ==
    ==
    ::
  ::
  ++  view-node
    ::
    |=  =node
    ^-  manx
    ;div.fc.bbv.br2.bd1.scroll-none
      ;+
      ?+  node  ;div: not renderable: {(print-aura node)}
        @tas  ;div: {"%"}{(trip node)}
        aota  ;div:(-(node-summary node))
        [%manx *]
          ;iframe.max-h20
            =srcdoc  (en-xml:html manx.node)
            ;*  ~
          ==
      ==
    ==
    ::
  ::
  ++  edit-node
    ::
    |=  =node
    ;div.fc.bbv.br2.bd1.scroll-none
      ;form.fc.bbv
        =id  "editnode{nid}"
        =data-on_submit  post
        ;input(type "hidden", name "op", value "ins-node");
        ;input(type "hidden", name "pith", value pare-stem);
        ;feather-textarea.p2.mono.fs-2
          =required  ""
          =name  "value"
          =placeholder  "ud+88"
          ;-  (nare node)
        ==
      ==
      ;div.fr.bbh
        ;button.b3.hover.p2.grow
          =form  "editnode{nid}"
          =type  "submit"
          ; save
        ==
        ;form
          =data-on_submit  post
          ;input(type "hidden", name "op", value "del-node");
          ;input(type "hidden", name "pith", value pate-stem);
          ;button.b3.hover.p-2.f-1
            ; delete
          ==
        ==
      ==
    ==
    ::
  ::
  ++  lens-err
    ::
    ::  error tang block for a lens; empty when no err.
    ::
    |=  err=(unit tang)
    ^-  manx
    ?~  err  ;/  ""
    ;div.br2.bd1.p2.scroll-none.lh0.fs-1
      ;+  (render-tang u.err)
    ==
  ::
  ++  mono-lens
    ::
    ::  read-only display for a mono-mesh lens lord: source/sauc,
    ::  dep, lyf:cas, error tang, and in/out shape placeholders.
    ::
    |=  =lens
    ;div.fc.g2
      ;+  (lens-err err.lens)
      ;div.fc.bbv.br2.bd1.scroll-none
        ;div.p2
          ; /{(scow %p ship.dep.lens)}{(pate root.dep.lens)}
          ; = {<cas.lens>}:{<lyf.lens>}
        ==
        ;div.p2.mono.pre.f3.fs-2.lh0
          ;-  ?@  sauc.lens  (trip sauc.lens)
              <sauc.lens>
        ==
      ==
      ;div.fr.g2.fs-2.o6
        ;span: in: -
        ;span: out: -
      ==
    ==
  ::
  ++  data-add
    ::
    ::  html form for inserting a node at a child pith.  pith input
    ::  pre-fills with the current node's stem; the user appends a
    ::  child segment to land the new node below.
    ::
    ;form.fc.bbv.br2.bd1.scroll-none
      =data-on_submit  post
      ;input(type "hidden", name "op", value "ins-node");
      ;input.p-1
        =name  "pith"
        =placeholder  "pith"
        =required  ""
        =value  pare-stem
        ;*  ~
      ==
      ;feather-textarea.p-1.mono.fs-2
        =name  "value"
        =placeholder  "value"
        =required  ""
        ;*  ~
      ==
      ;button.b3.hover.p2
        ; save
      ==
    ==
  ::
  --
::
--