|%
+$  card  card:agent:gall
++  hid  "display:none;"
++  add-attribute
  ::
  |=  [[=term =tape] =manx]
  manx(a.g [[term tape] a.g.manx])
  ::
++  add-attribute-if
  ::
  |=  [=flag [=term =tape] =manx]
  ?.  flag  manx
  manx(a.g [[term tape] a.g.manx])
  ::
++  for-each
  ::
  |=  do=$-(manx manx)
  |=  =marl
  %+  turn  marl  do
  ::
++  get-attribute
  ::
  |=  [=term manx]
  ^-  (unit tape)
  ?~  a.g  ~
  ?:  =(term n.i.a.g)  `v.i.a.g
  $(a.g t.a.g)
  ::
++  set-attribute
  ::
  =|  =mart
  |=  [=term =(unit tape) =manx]
  ^+  manx
  ?~  a.g.manx
    ?~  unit  manx
    manx(a.g [[term u.unit] mart])
  ?:  =(term n.i.a.g.manx)
    ?~  unit
      %=  manx
        a.g
          (welp mart a.g.manx)
      ==
    %=  manx
      a.g
        (welp mart [[term u.unit] a.g.manx])
    ==
  $(a.g.manx t.a.g.manx, mart [i.a.g.manx mart])
  ::
++  mod-attribute
  ::
  |=  [=term do=$-((unit tape) (unit tape)) =manx]
  ^+  manx
  %=  manx
    a.g
      =<  a.g
      =/  rib
        %+  get-attribute  term  manx
      %^  set-attribute  term
        (do rib)
      manx
  ==
  ::
++  add-class
  ::
  |=  [class=tape =manx]
  ^+  manx
  %^  mod-attribute  %class
    |=  =(unit tape)
    ?~  unit  `class
    `:(welp u.unit " " class)
  manx
  ::
++  add-class-if
  ::
  |=  [=flag class=tape =manx]
  ?.  flag  manx
  (add-class class manx)
  ::
++  uid
  ::
  |=  x=*
  ^-  tape
  =+  (scow %p (mug x))
  %+  welp  (swag [1 6] -)
  (slag 8 -)
  ::
++  is-ancestor
  ::
  |=  [a=path b=path]
  ^-  ?
  ?&
    =(b (scag (lent b) a))
    !=(a b)
  ==
  ::
++  href
  ::
  |_  [root=path extra=(list [tape tape])]
  ++  as-tape
    ::
    |=  [stem=path =pams]
    ^-  tape
    ;:  welp
      (spud (welp root stem))
      (render-query pams)
    ==
    ::
  ++  as-cord
    ::
    |=  arg=[path pams]
    ^-  cord
    (crip (as-tape arg))
    ::
  ++  as-soq-tape
    ::
    |=  arg=[path pams]
    "'{(as-tape arg)}'"
    ::
  ++  data-post
    |=  [where=path =pams]
    "@post({(as-soq-tape where pams)}, \{openWhenHidden: true})"
  ++  data-get
    |=  [where=path pams=(list [tape tape])]
    "@get({(as-soq-tape where pams)}, \{openWhenHidden: true})"
  ++  data-post-confirm
    |=  [where=path pams=(list [tape tape]) prompt=tape]
    "if (confirm(`{prompt}`)) \{ @post({(as-soq-tape where pams)}, \{openWhenHidden: true}) }"
  ++  data-get-confirm
    |=  [where=path pams=(list [tape tape]) prompt=tape]
    "if (confirm('{prompt}')) \{ @get({(as-soq-tape where pams)}, \{openWhenHidden: true}) }"
  ::
  +$  pams  (list [tape tape])
  ++  render-query
    ::
    |=  =pams
    %-  tail:en-purl:html
    ^-  quay:eyre
    %+  turn  (welp pams extra)
    |=  [k=tape v=tape]
    [(crip k) (crip v)]
  --
++  print-tang
  |=  =tang
  ^-  tape
  %-  zing
  ^-  wall
  %+  turn  (scag 50 tang)
  |=  =tank
  %-  of-wall:format
  (~(win re tank) 0 80)
  ::
++  render-tang
  ::
  |=  =tang
  ^-  manx
  ;pre.pre.mono.scroll-x.p2.f-1
    ;*
    %+  turn  (scag 50 tang)
    |=  =tank
    ;/  %-  of-wall:format
    (~(win re tank) 0 80)
  ==
  ::
++  predent
  ::
  |=  [front=tape text=tape]
  ^-  tape
  %-  zing
  %+  turn  (to-wain:format (crip text))
  |=  =cord
  "{front}{(trip cord)}\0a"
  ::
++  form-body
  |=  body=(unit octs)
  ^-  (map @t @t)
  %-  fall  :_  ~
  %-  mole  |.
  (malt (rash +:(need body) yquy:de-purl:html))
  ::
++  map-to-json
  ::
  |=  m=(map @t @t)
  ^-  json
  :-  %o
  %-  malt
  %+  turn  ~(tap by m)
  |=  [k=@t v=@t]
  :-  k
  ?:  =(v 'true')   b+&
  ?:  =(v 'false')  b+|
  s+v
  ::
++  json-to-map
  ::
  ::  assumes a single layered json
  ::
  =|  m=(map @t @t)
  |=  son=json
  ^+  m
  ?~  son  m
  ?>  ?=(%o -.son)
  =/  items  p.son
  %-  malt
  ^-  (list [@t @t])
  %+  turn  ~(tap by items)
  |=  [key=@t s=json]
  :-  key
  ^-  @t
  ?~  s  ''
  ?-  -.s
    %s  p.s
    %b  ?:(p.s 'true' 'false')
    %n  p.s
    %a  !!
    %o  !!
  ==
++  parse-url
  ::
  |=  url=cord
  ^-  (pair path (map @t @t))
  %-  fall  :_  [/unknown ~]
  %-  mole  |.
  =/  [maybe-trailing=path pams=(list (pair @t @t))]
    %+  rash  url
      ;~  plug
          ;~(pfix fas (more fas smeg:de-purl:html))
          yque:de-purl:html
      ==
  :_  (malt pams)
  ?~  maybe-trailing  /
  =/  last=knot  (rear maybe-trailing)
  ?:  ?=(%$ last)
    (snip `path`maybe-trailing)
  ^-  path
  maybe-trailing
  ::
++  datastar-signals
  |=  [pams=(map @t @t) body=(unit octs)]
  ^-  (map @t @t)
  %-  json-to-map
  %-  fall  :_  *json
  %-  mole  |.
  %-  need
  %-  de:json:html
  ?^  j=(~(get by pams) 'datastar')  u.j
  ?~  b=body  ''
  +:u.b
++  server
  |_  [rid=@ta req=inbound-request:eyre]
  ++  formencoded-body
    ^-  (map @t @t)
    %-  fall  :_  ~
    %-  mole  |.
    (malt (rash +:(need body.request.req) yquy:de-purl:html))
  ++  is-datastar
    .=  `'true'
    (get-header:http 'datastar-request' header-list.request.req)
  ++  signals
    ^-  (map @t @t)
    %+  datastar-signals  q:(parse-url url.request.req)
    body.request.req
  ++  datastar-response-map
    |=  [signals=(map @t @t) fragments=(list [mode=tape selector=(unit tape) =manx])]
    %+  datastar-response  (map-to-json signals)
    fragments
  ++  datastar-response
    ::
    ::  supports all sse events
    ::
    ::XX optimize if just signals or single outer-swap manx
    ::
    |=  [signals=json fragments=(list [mode=tape selector=(unit tape) =manx])]
    ^-  (list card)
    %^  static-resource  ~
      'text/event-stream'
    %-  crip
    %+  welp
      ^-  tape
      ?~  signals  ""
      %-  zing
      %+  join  "\0a"
      ^-  wall
      :~
        "event: datastar-patch-signals"
        "data: signals {(trip (en:json:html signals))}"
        "\0a\0a"
      ==
    =|  out=tape
    |-
    ^-  tape
    ?~  fragments  out
    =/  fragment  i.fragments
    =.  out
      %+  welp  out
      %-  zing
      %+  join  "\0a"
      ^-  wall
      :~
        "event: datastar-patch-elements"
        ::
        %+  welp  "data: mode {mode.fragment}"
        ?~  selector.fragment  ""
        "\0adata: selector {u.selector.fragment}"
        ::
        ?:  |(=(manx.fragment *manx) =(manx.fragment ;/("")))  ""
        %+  predent  "data: elements "
        (en-xml:html manx.fragment)
        ::
        "\0a\0a"
      ==
    $(fragments t.fragments)
  ++  static-html
    ::
    |=  [cached=(unit @dr) hymn=manx]
    ^-  (list card)
    %^  static-resource  cached  'text/html'
    %-  crip
    :-  '<!DOCTYPE html>'
    (en-xml:html hymn)
  ++  static-resource
    ::
    |=  [cached=(unit @dr) content-type=@t raw-file=@]
    ^-  (list card)
    =/  octs  (as-octs:mimes:html raw-file)
    %-  payload-cards
    :-  :-  200
        :-  ['Content-Type' content-type]
        ?~  cached  ~
        =/  seconds=@ud  (div u.cached ~s1)
        :~  ['Cache-Control' (crip "public, max-age={(a-co:co seconds)}")]
        ==
    `octs
  ++  redirect
    |=  [status=@ud location=cord]
    %-  payload-cards
    :-  :-  status
        :~  ['Location' location]
        ==
    ~
  ++  payload-cards
    ::
    |=  pl=simple-payload:http
    :~  [%give %fact ~[/http-response/[rid]] [%http-response-header !>(-.pl)]]
        [%give %fact ~[/http-response/[rid]] [%http-response-data !>(+.pl)]]
        [%give %kick ~[/http-response/[rid]] ~]
    ==
  --
--
