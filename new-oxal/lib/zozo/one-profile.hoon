::  one-profile: remote profile viewer (feather-1)
::
::  fetches and displays another ship's profile index via remote scry,
::  lets the user drill into individual items, and pushes live
::  updates to the browser over SSE (datastar).
::
::  uses mantis mirrors for automatic keen polling with exponential
::  backoff (index mirror) and one-shot keen for item viewing.
::
::  ## data namespace
::
::  app-managed:
::    /viewing                pith   currently viewed item (absent = index view)
::    /cache/<pith>/tree      data   cached item data
::    /cache/<pith>/case      @ud    cached item case number
::
::  framework-managed (mantis mirror — index):
::    #/~/mirror/index/state    @tas   loading, success, error, timeout
::    #/~/mirror/index/case     @ud    monotonically increasing case counter
::    #/~/mirror/index/[ud/N]   data   the remote index tree (case-indexed)
::    #/~/mirror/index/attempt  @ud    consecutive failures
::
::  framework-managed (mantis keen — item):
::    #/~/keen/item/state       @tas   loading, success, error
::    #/~/keen/item/case        @ud    exact case number fetched
::    #/~/keen/item/~           data   current item data
::    #/~/keen/item/attempt     @ud    consecutive failures
::
/+  *zozo-one
::
|=  =profile-core
^-  feather-1-core
=>
|%
++  mirror-index-move
  ^-  move
  :+  #/o/mirror/index
      #/~/mirror/index
  :-  %ins
  :-  %data
  %-  ~(gas do *data)
  :~  [#/ship p+who.profile-core]
      [#/path pith+/~/index/grow]
      [#/care %cone]
  ==
::
++  keen-item-move
  |=  [item-pith=pith item-case=@ud]
  ^-  move
  =/  care  (rear item-pith)
  =/  base  (snip item-pith)
  :+  [%o %keen ta/'item' ~]
      #/~/keen/[ta/'item']
  :-  %ins
  :-  %data
  %-  ~(gas do *data)
  :~  [#/ship p+who.profile-core]
      [#/path pith+base]
      [#/care care]
      [#/case ud+item-case]
  ==
::
++  cache-item
  |=  [=data viewing-pith=pith]
  ^-  (list move)
  =/  d  ~(. do data)
  =/  item-data  (fall (get-data:d #/~/keen/[ta/'item']/~) (dip:d #/~/keen/[ta/'item']/~))
  =/  item-case  (gut-ud:d #/~/keen/[ta/'item']/case 0)
  :~  :+  /  :(welp /cache viewing-pith /tree)  [%ins [%data item-data]]
      :+  /  :(welp /cache viewing-pith /case)  [%ins ud+item-case]
  ==
::
++  get-mirror-data
  |=  =data
  ^-  (unit _data)
  =/  d  ~(. do data)
  =/  mp  #/~/mirror/index
  =/  cur-case  (gut-ud:d (welp mp /case) 0)
  ?:  =(0 cur-case)  ~
  =/  case-path  (welp mp /[ud/cur-case])
  `(fall (get-data:d case-path) (dip:d case-path))
::
++  render-status-bar
  |=  =data
  ^-  manx
  =/  d  ~(. do data)
  =/  mp  #/~/mirror/index
  =/  state     (gut-tas:d (welp mp /state) %idle)
  =/  attempt   (gut-ud:d (welp mp /attempt) 0)
  =/  case      (gut-ud:d (welp mp /case) 0)
  =/  timer-at  (fall (get-da:d (welp mp /timer-at)) *@da)
  ;div.fr.ac.g3.px3.py2.br2.b1.fs-1.f6.mono
    ;span: {<state>}
    ;span: case={<case>}
    ;span.f8: try={<attempt>}
    ;span.f8: {<timer-at>}
  ==
::
++  render-index
  |=  idx=data
  ^-  manx
  =/  items  ~(tap do idx)
  ;div.fc.g2.mono
    ;*  %+  turn  items
        |=  [=pith =node]
        =/  care  ?~(pith %$ (rear pith))
        ;form.fc.pulser(method "post", action "?action=view")
          ;input(type "hidden", name "path", value "{(pate pith)}");
          ;button.fr.ac.g3.p-3.bd1.br2.hover.b2(type "submit")
            ;span.fs-1.grow.tl: {(pate pith)}
            ;span.f6.fs-1: {(print-node node)}
            ;span.f8.fs-1: {<care>}
          ==
        ==
  ==
::
++  render-smart
  |=  [salt=@t =data]
  ^-  manx
  =/  has-kids  (~(has-kids do data) /)
  =/  smart=(unit manx)
    ?~  leaf.data  ~
    ?+  u.leaf.data  ~
      [%manx *]
        =/  htm  (en-xml:html +.u.leaf.data)
        :-  ~
        ;iframe
          =srcdoc  htm
          =sandbox  ""
          =style  "width:100%;min-height:400px;border:1px solid var(--b1)"
          ;*  ~
        ==
      [%mime *]
        `(render-mime +.u.leaf.data)
      [%json *]
        :-  ~
        ;pre: {(trip (en:json:html +.u.leaf.data))}
      [%t *]
        :-  ~
        ;pre: {(trip +.u.leaf.data)}
    ==
  ?~  smart
    (render-data-with-signals salt data)
  ?.  has-kids
    u.smart
  ;div.fc.g3
    ;+  u.smart
    ;details
      ;summary.pointer.f6.mono: tree data
      ;+  (render-data-with-signals salt data)
    ==
  ==
::
++  render-mime
  |=  =mime
  ^-  manx
  ?:  ?=([%image *] p.mime)
    =/  mt  (trip (en-mite:mimes:html p.mime))
    =/  b64  (trip (en:base64:mimes:html q.mime))
    =/  src  ;:(welp "data:" mt ";base64," b64)
    ;img(src src, style "max-width:100%");
  ?:  ?=([%text %html ~] p.mime)
    ;iframe
      =srcdoc  (trip q.q.mime)
      =sandbox  ""
      =style  "width:100%;min-height:400px;border:1px solid var(--b1)"
      ;*  ~
    ==
  ?:  ?=([%text *] p.mime)
    ;pre: {(trip q.q.mime)}
  =/  mt  (trip (en-mite:mimes:html p.mime))
  ;pre: {mt} ({<p.q.mime>} bytes)
::
++  render-item-view
  |=  [=data viewing-pith=pith]
  ^-  manx
  =/  d  ~(. do data)
  =/  cp  (welp /cache viewing-pith)
  =/  item-state  (gut-tas:d #/~/keen/[ta/'item']/state %unknown)
  =/  cached  (hos:d (welp cp /tree))
  =/  status
    ?:  cached  %ready
    item-state
  ;div.fc.g3
    ;form.fr.jb.g3.mono.pulser(method "post", action "?action=clear")
      ;button.b2.bd1.br2.p-3.pointer.hover.b2(type "submit"): back
      ;div.grow.tr: {(pate (snip viewing-pith))}
      ;div.f6: {<(gut-ud:d (welp cp /case) 0)>}
    ==
    ;+
    ?.  =(%error status)  ;span;
    ;div.fr.ac.jb.px3.py2.br2.bd1.bc-1
      ;span: failed to load
      ;form.pulser(method "post", action "?action=retry-data")
        ;button.b2.bd1.br2.px3.py1.pointer.hover.pulser(type "submit"): retry
      ==
    ==
    ;+
    ?:  cached
      (render-smart 'cached' (fall (get-data:d (welp cp /tree)) (dip:d (welp cp /tree))))
    ?:  (hos:d #/~/keen/[ta/'item']/~)
      (render-smart 'keen' (fall (get-data:d #/~/keen/[ta/'item']/~) (dip:d #/~/keen/[ta/'item']/~)))
    ?:  =(%error status)
      ;span;
    ;div.f6.pulse: loading...
  ==
--
|%
++  title
  |=  [here=pith =data]
  "{<who.profile-core>}"
::
++  get
  |=  [our=@p src=@p =data =stem =query]
  =/  d  ~(. do data)
  ^-  node
  :-  %manx
  ;div.wf.fc.g4.p3
    ;+  (render-status-bar data)
    ;h2: {<who.profile-core>}
    ;+
    ?^  pit=(get-pith:d /viewing)
      (render-item-view data u.pit)
    ?^  idx=(get-mirror-data data)
      (render-index u.idx)
    ;div.f6: No data yet
  ==
::
++  post
  |=  [our=@p src=@p =data =stem =query =body]
  =/  d  ~(. do data)
  =/  b  ~(. do body)
  =/  action=@tas  (crip (~(gut by (malt query)) 'action' ""))
  ?+  [action stem]  ~|  no-route/action  !!
    ::
    [%view ~]
      =/  path-cord  (gut-t:b #/[t/'path'] '')
      =/  viewing-pith=pith  (pave (stab path-cord))
      =/  idx  (fall (get-mirror-data data) *_data)
      =/  item-case=@ud
        =/  nod  (~(get do idx) viewing-pith)
        ?~  nod  0
        ?.  ?=([%ud @] u.nod)  0
        +.u.nod
      =/  cached-case  (gut-ud:d :(welp /cache viewing-pith /case) 0)
      :-  ~
      ^-  (list move)
      :-  [/ /viewing %ins pith+viewing-pith]
      ?:  &(=(cached-case item-case) (gth cached-case 0))
        ~
      ~[(keen-item-move viewing-pith item-case)]
    ::
    [%clear ~]
      :-  ~
      ^-  (list move)
      :~  [/ /viewing %lop ~]
      ==
    ::
    [%retry-data ~]
      ?~  vp=(get-pith:d /viewing)
        [~ ~]
      =/  idx  (fall (get-mirror-data data) *_data)
      =/  item-case=@ud
        =/  nod  (~(get do idx) u.vp)
        ?~  nod  0
        ?.  ?=([%ud @] u.nod)  0
        +.u.nod
      :-  ~
      ^-  (list move)
      :~  (keen-item-move u.vp item-case)
      ==
  ==
::
++  on
  |=  [=prov =move =file]
  ^-  (list _move)
  =/  d  ~(. do data.file)
  ::  install or reinstall: clear stale data and start index mirror
  ?:  ?=(%install -.action.move)
    :~  mirror-index-move
    ==
  ::  item fetch data arrived: cache it
  ?:  ?&  ?=([%i %keen [%ta @] ~] wire.move)
          =('item' ta.i.t.t.wire.move)
      ==
    ?~  vp=(~(get-pith do data.file) /viewing)  ~
    (cache-item data.file u.vp)
  ::  everything else: no-op (feather-1 auto-refreshes SSE)
  ~
--
