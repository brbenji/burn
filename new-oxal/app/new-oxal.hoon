::  new-oxal: networked reactive database (post-rebrand of %oxal)
::
/+  vine
/+  *zozo
/+  dt=doctest
::
|%
+$  state-0  [%0 =acer verb=_|]
+$  state-n  $%(state-0)
--
::
=|  state-0
=*  state  -
^-  agent:gall
%-  (agent:vine %new-oxal)
=<
|_  =bowl:gall
+*  this  .
    cor  ~(. +> [bowl ~])
++  on-init
  ::
  ^-  (quip card:agent:gall _this)
  =^  cards  state  abet:init:cor
  [cards this]
  ::
++  on-load
  ::
  |=  ole=vase
  ^-  (quip card:agent:gall _this)
  =^  cards  state  abet:(load:cor ole)
  [cards this]
  ::
++  on-poke
  ::
  |=  [=mark =vase]
  ^-  (quip card:agent:gall _this)
  =^  cards  state  abet:(poke:cor mark vase)
  [cards this]
  ::
++  on-fail
  ::
  |=  [=term =tang]
  ^-  (quip card:agent:gall _this)
  =^  cards  state  abet:(fail:cor term tang)
  [cards this]
  ::
++  on-watch
  ::
  |=  =path
  ^-  (quip card:agent:gall _this)
  =^  cards  state  abet:(watch:cor path)
  [cards this]
  ::
++  on-leave
  ::
  |=  =path
  ^-  (quip card:agent:gall _this)
  =^  cards  state  abet:(leave:cor path)
  [cards this]
  ::
++  on-agent
  ::
  |=  [=wire =sign:agent:gall]
  ^-  (quip card:agent:gall _this)
  =^  cards  state  abet:(agent:cor wire sign)
  [cards this]
  ::
++  on-arvo
  ::
  |=  [=wire =sign-arvo]
  ^-  (quip card:agent:gall _this)
  =^  cards  state  abet:(arvo:cor wire sign-arvo)
  [cards this]
  ::
++  on-save  save:cor
++  on-peek  peek:cor
::
--
::
|_  [=bowl:gall cards=(list card:agent:gall)]
+*  engine  ~(. ae acer our.bowl now.bowl verb &)
++  cor   .
++  abet  :-  (flop cards)  state
++  emit  |=  =card:agent:gall  cor(cards [card cards])
++  emil  |=  caz=(list card:agent:gall)  cor(cards (welp (flop caz) cards))
::
++  bind-card  [%pass /eyre-inner-bind %arvo %e %connect [~ `path`['-' ~]] %new-oxal]
::
++  init  (emit bind-card)
::
++  load
  ::
  |=  ole=vase
  ^+  cor
  =/  unit=(unit state-0)  (mole |.(!<(state-0 ole)))
  =.  cor  (emit bind-card)
  ?~  unit  cor
  cor(state u.unit)
::
++  fail
  ::
  |=  [=term =tang]
  ^+  cor
  %-  (slog term tang)
  cor
::
++  watch
  ::
  |=  =path
  ^+  cor
  ?+  path  cor
    [%sub *]
      =/  pax=pith  (pave t.path)
      =/  full-pax=pith  [p+our.bowl pax]
      ~|  forbidden/(spud path)
      ?:  (lth (lent full-pax) 2)  !!
      =/  =meta  (fall (~(get ox code.file.acer) full-pax) *meta)
      ?~  gall.meta  !!
      ?>  (check-auth u.gall.meta our.bowl src.bowl)
      =/  resp  (initial-watch-response:engine full-pax)
      (emit %give %fact ~ %oxal-snap !>([snap.resp [*hlc ~] life.resp case.resp]))
    ::
    [%code *]
      =/  pax=pith  (pave t.path)
      =/  full-pax=pith  [p+our.bowl pax]
      ~|  forbidden/(spud path)
      ?:  (lth (lent full-pax) 2)  !!
      =/  =meta  (fall (~(get ox code.file.acer) full-pax) *meta)
      ?~  gall.meta  !!
      ?>  (check-auth u.gall.meta our.bowl src.bowl)
      =/  resp  (initial-watch-response-code:engine full-pax)
      (emit %give %fact ~ %oxal-code !>([snap.resp ~ life.resp case.resp]))
    ::
    [%both *]
      =/  pax=pith  (pave t.path)
      ~&  watch/pax
      =/  full-pax=pith  [p+our.bowl pax]
      ~|  forbidden/(spud path)
      ?:  (lth (lent full-pax) 2)  !!
      =/  =meta  (fall (~(get ox code.file.acer) full-pax) *meta)
      ?~  gall.meta  !!
      ?>  (check-auth u.gall.meta our.bowl src.bowl)
      =/  dresp  (initial-watch-response:engine full-pax)
      =/  cresp  (initial-watch-response-code:engine full-pax)
      %-  emil
      :~  [%give %fact ~ %oxal-snap !>([snap.dresp [*hlc ~] life.dresp case.dresp])]
          [%give %fact ~ %oxal-code !>([snap.cresp ~ life.cresp case.cresp])]
      ==
    ::
    [%logs *]  cor
  ==
::
++  leave
  ::
  |=  =path
  cor
::
++  agent
  ::
  |=  [=wire =sign:agent:gall]
  cor
::
++  arvo
  ::
  |=  [=wire =sign-arvo]
  cor
::
++  save  !>(state)
::
++  peek
  ::
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  ~
    [%x %acer ~]  ``noun+!>(acer)
    [%x %data *]  ``noun+!>((~(dip do data.file.acer) (pave t.t.path)))
    [%x %code *]  ``noun+!>((~(dip ox code.file.acer) (pave t.t.path)))
    [%x %file ~]  ``noun+!>(file.acer)
    [%x %our ~]   ``noun+!>(our.bowl)   :: xx this should not be needed
  ==
::
++  poke
  :::
  |=  [=mark =vase]
  ^+  cor
  ?+  mark  ~|(bad-poke/mark !!)
    :::
    %verb
      ::
      =+  !<  val=?  vase
      %-  (slog leaf+"verbosity: {?:(val "y" "n")}" ~)
      cor(verb val)
      ::
    %wipe
      ::
      =.  file.acer  *file
      =.  meshes.acer  ~
      %-  (slog 'new-oxal: wipe' ~)
      cor
    ::
    %do-move
      ::
      ::  user pokes a bare (set chng); the engine stamps it on entry.
      ::  the move's time field is owned by the engine, not the user.
      ::
      =+  !<  changes=(set chng)  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(ingress-do-move:engine [*hlc changes])
      (emil cz)
      ::
    %load-mesh
      ::
      =+  !<  [name=term =mesh-source]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(ingress-load-mesh:engine name mesh-source)
      (emil cz)
      ::
    %set-poly-view
      ::
      =+  !<  [name=term stem=pith src=@t]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(ingress-set-poly-view:engine name stem src)
      (emil cz)
      ::
    %del-poly-view
      ::
      =+  !<  [name=term stem=pith]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(ingress-del-poly-view:engine name stem)
      (emil cz)
      ::
    %drop-mesh
      ::
      =+  !<  name=term  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(ingress-drop-mesh:engine name)
      (emil cz)
      ::
    ::
    %bump
      ::
      =+  !<  pax=pith  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(ingress-bump:engine pax)
      (emil cz)
      ::
    ::
    %set-grow
      ::
      =+  !<  [pax=pith val=?]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(ingress-set-grow:engine pax val)
      (emil cz)
      ::
    %set-eyre
      ::
      =+  !<  [pax=pith val=(unit auth)]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(ingress-set-eyre:engine pax val)
      (emil cz)
      ::
    %set-gall
      ::
      =+  !<  [pax=pith val=(unit auth)]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(ingress-set-gall:engine pax val)
      (emil cz)
      ::
    ::
    ::  dev-only shim: exercise +ingress-hear-remote without networking.
    ::  remove once the gall-networking layer lands.
    ::
    %hear-remote
      ::
      =+  !<  [=ship pax=pith snap=data =move =life =case]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(ingress-hear-remote:engine ship pax snap move life case)
      (emil cz)
      ::
    %hear-remote-code
      ::
      =+  !<  [=ship pax=pith snap=code =meta-move =life =case]  vase
      =^  cz=(list card:agent:gall)  acer
        abet:(ingress-hear-remote-code:engine ship pax snap meta-move life case)
      (emil cz)
      ::
    ::
    %doctest-build
      ::
      ::  install/refresh the %doctest mesh from a single $data input.
      ::  drops any existing %doctest mesh (which wipes its prior data
      ::  via the mesh's ++drop), loads a fresh %doctest mesh declaring
      ::  one form at /doctest, then do-moves the input data into the
      ::  form by welping /doctest onto each leaf's pith.
      ::
      =+  !<  mesh-data=data  vase
      =/  src=@t  doctest-mesh-source:dt
      =/  chngs=(set chng)  (data-to-doctest-chngs:dt mesh-data)
      =^  cz1=(list card:agent:gall)  acer
        abet:(ingress-drop-mesh:engine %doctest)
      =^  cz2=(list card:agent:gall)  acer
        abet:(ingress-load-mesh:engine %doctest [%mono src])
      =^  cz3=(list card:agent:gall)  acer
        abet:(ingress-do-move:engine [*hlc chngs])
      (emil :(welp cz1 cz2 cz3))
      ::
    ::
    %handle-http-request
      ::
      =+  !<  [rid=@ta req=inbound-request:eyre]  vase
      =/  [line=path query=(map @t @t)]  (parse-url url.request.req)
      =/  =stem  [p+our.bowl (tail (pave line))]
      =/  =meta  (fall (~(get ox code.file.acer) stem) *meta)
      =/  allowed=?
        ?~  eyre.meta  |
        (check-auth u.eyre.meta our.bowl src.bowl)
      %-  emil
      ?.  allowed
        %+  payload-cards  rid
        :-  [403 ['content-type' 'text/plain']~]
        `(as-octs:mimes:html 'forbidden')
      ?~  nude=(~(get do data.file.acer) stem)
        %+  payload-cards  rid
        :-  [404 ['content-type' 'text/plain']~]
        `(as-octs:mimes:html 'not found')
      %+  payload-cards  rid
      (node-to-simple-payload u.nude)
      ::
  ==
  ::
--
