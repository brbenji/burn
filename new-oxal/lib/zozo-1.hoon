/+  *zozo-0
|%
++  payload-cards
  ::
  |=  [rid=@ta pl=simple-payload:http]
  ^-  (list card:agent:gall)
  :~  [%give %fact ~[/http-response/[rid]] [%http-response-header !>(-.pl)]]
      [%give %fact ~[/http-response/[rid]] [%http-response-data !>(+.pl)]]
      [%give %kick ~[/http-response/[rid]] ~]
  ==
::
++  resource-payload-cards
  ::
  |=  [rid=@ta cached=(unit @dr) content-type=@t raw-file=@]
  ^-  (list card:agent:gall)
  %+  payload-cards  rid
  :-  :-  200
      :-  ['Content-Type' content-type]
      ?~  cached  ~
      =/  seconds=@ud  (div u.cached ~s1)
      :~  ['Cache-Control' (crip "public, max-age={(a-co:co seconds)}")]
      ==
  `(as-octs:mimes:html raw-file)
::
++  html-payload-cards
  ::
  |=  [rid=@ta hymn=manx]
  ^-  (list card:agent:gall)
  %:  resource-payload-cards
    rid
    ~
    'text/html'
    %-  crip
    :-  '<!DOCTYPE html>'
    (en-xml:html hymn)
  ==
::
++  feather-1-payload
  ::
  |=  [title=tape head=marl body=manx]
  ^-  simple-payload:http
  %-  simple-html-payload
  ;html
    ;head
      ;title:(-title)
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
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
      ;*  head
      ;script(type "module", src "/hawk-init/feather/1/text-editor");
      ;script(type "module", src "/hawk-init/feather/1/textarea");
      ;script(type "module", src "/hawk-init/feather/1/datastar-new");
      ;script(type "module", src "/hawk-init/feather/1/slide-panels");
    ==
    ;body
      ;+  body
    ==
  ==
::
++  simple-html-payload
  ::
  |=  hymn=manx
  ^-  simple-payload:http
  (static-html-payload ~ hymn)
::
++  static-html-payload
  ::
  |=  [cached=(unit @dr) hymn=manx]
  ^-  simple-payload:http
  %^  static-resource-payload  cached  'text/html'
  %-  crip
  :-  '<!DOCTYPE html>'
  (en-xml:html hymn)
::
++  static-mime-payload
  ::
  |=  [cached=(unit @dr) =mime]
  ^-  simple-payload:http
  %^  static-resource-payload  cached  (en-mite:mimes:html p.mime)
  q.q.mime
::
++  static-resource-payload
  ::
  |=  [cached=(unit @dr) content-type=@t raw-file=@]
  ^-  simple-payload:http
  =/  octs  (as-octs:mimes:html raw-file)
  :-  :-  200
      :-  ['Content-Type' content-type]
      ?~  cached  ~
      =/  seconds=@ud  (div u.cached ~s1)
      :~  ['Cache-Control' (crip "public, max-age={(a-co:co seconds)}")]
      ==
  `octs
::
++  redirect-payload
  ::
  |=  [status=@ud location=cord]
  ^-  simple-payload:http
  :_  ~
  :-  status
  :~  ['Location' location]
  ==
::
++  empty-payload-cards
  ::
  |=  rid=@ta
  %^  payload-cards  rid
    :-  200  ~
  ~
::
++  starts-with
  ::
  |=  [expected=@t real=@t]
  ^-  ?
  .=  expected
  (cut 3 [0 (met 3 expected)] real)
::
++  de-mite
  ::
  |=  content-type=@t
  ^-  mite
  %-  fall  :_  /application/x-unknown
  %-  mole  |.
  %-  stab
  %^  cat  3  '/'
  content-type
::
++  en-mite
  ::
  ::  mime type to text
  ::
  |=  myn=mite
  %-  crip
  |-  ^-  tape
  ?~  myn  ~
  ?:  =(~ t.myn)  (trip i.myn)
  (weld (trip i.myn) `tape`['/' $(myn t.myn)])
::
++  node-to-simple-payload
  |=  =node
  ^-  simple-payload:http
  =;  [content-type=@t =octs]
    :-  [200 ['content-type' content-type]~]
    [~ octs]
  ?+  node  ['text/plain' (as-octt:mimes:html (node-summary node))]
    :::
    [%mime *]  [(en-mite p.mime.node) q.mime.node]
    ::
    [%manx *]
      ::
      =/  m     manx.node
      =/  octt  as-octt:mimes:html
      =/  octs  as-octs:mimes:html
      =/  en    en-xml:html
      ?+  n.g.manx.node  ['application/xml' (octt (en m))]
        :::
        %rss
          :-  'application/rss+xml'
          %-  octt
          %+  welp  (trip '<?xml version="1.0" encoding="UTF-8"?>')
          (en m)
        ::
        %html
          :-  'text/html'
          %-  octt
          %+  welp  "<!doctype html>"
          (en m)
      ==
  ==
::
++  form-encoded-body
  ::
  |=  body=octs
  ^-  data
  %-  ~(gas do *data)
  %+  turn
    %-  fall  :_  ~
    %-  mole  |.
    (rash +.body yquy:de-purl:html)
  |=  [k=@t v=@t]
  :-  #/[t/k]  t+v
::
::  datastar helpers
::
+$  datastar-fragment  [mode=tape selector=(unit tape) =manx]
::
++  datastar-sse
  ::
  |=  [rid=@ta sig-list=(list (pair @t @t)) fragments=(list datastar-fragment)]
  ^-  card
  %+  sse-data  rid
  %-  as-octs:mimes:html
  (datastar-response-body sig-list fragments)
::
++  datastar-response-body
  ::
  |=  [sig-list=(list (pair @t @t)) fragments=(list datastar-fragment)]
  ^-  cord
  %-  crip
  %+  welp
    ^-  tape
    ?~  sig-list  ""
    =/  signals  (map-to-json (malt sig-list))
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
::
::  url engine
::
++  href
  |_  [root=pith extra=(list [tape tape])]
  ++  as-tape
    ::
    |=  [stem=pith =pams]
    ^-  tape
    ;:  welp
      (pate (welp root stem))
      (render-query pams)
    ==
    ::
  ::
  ++  as-cord
    ::
    |=  arg=[pith pams]
    ^-  cord
    (crip (as-tape arg))
    ::
  ::
  ++  as-soq-tape
    ::
    |=  arg=[pith pams]
    "'{(as-tape arg)}'"
  ::
  ++  data-post
    ::
    |=  [where=pith =pams]
    "@post({(as-soq-tape where pams)}, \{openWhenHidden: true})"
  ::
  ++  data-get
    ::
    |=  [where=pith pams=(list [tape tape])]
    "@get({(as-soq-tape where pams)}, \{openWhenHidden: true})"
  ::
  ++  data-post-confirm
    ::
    |=  [where=pith pams=(list [tape tape]) prompt=tape]
    "if (confirm(`{prompt}`)) \{ @post({(as-soq-tape where pams)}, \{openWhenHidden: true}) }"
  ::
  ++  data-get-confirm
    ::
    |=  [where=pith pams=(list [tape tape]) prompt=tape]
    "if (confirm('{prompt}')) \{ @get({(as-soq-tape where pams)}, \{openWhenHidden: true}) }"
  ::
  ++  form-post
    ::
    |=  [where=pith =pams]
    "@post({(as-soq-tape where pams)}, \{contentType: 'form', openWhenHidden: true})"
  ::
  ++  form-get
    ::
    |=  [where=pith pams=(list [tape tape])]
    "@get({(as-soq-tape where pams)}, \{contentType: 'form', openWhenHidden: true})"
  ::
  +$  pams  (list [tape tape])
  ::
  ++  render-query
    ::
    |=  =pams
    %-  tail:en-purl:html
    ^-  quay:eyre
    %+  turn
      %~  tap  by
      (~(uni by (malt extra)) (malt pams))
    |=  [k=tape v=tape]
    [(crip k) (crip v)]
  --
::
::  manx helpers
::
++  patterns
  |%
  ++  tas  %-  trip  '^[a-z][a-z0-9\\-]*$'
  --
::
++  hid  "display:none;"
::
++  datastar-link
  ::
  |=  [url=tape =manx]
  %+  add-attribute
    href+url
  %+  add-attribute  :-  'data-on:click'
    "evt.preventDefault();".
    "@get('{url}');"
  manx
::
++  add-attribute
  ::
  |=  [[=term =tape] =manx]
  manx(a.g [[term tape] a.g.manx])
::
++  sse-keep-alive-interval  ~s30
++  sse-timeout  ~m4
::
++  sse-open
  ::
  |=  [rid=@ta]
  ^-  card
  =/  header-list
    :~  ['content-type' 'text/event-stream']
        ['cache-control' 'no-cache']
        ['Connection' 'keep-alive']
    ==
  [%give %fact ~[/http-response/[rid]] [%http-response-header !>([200 header-list])]]
::
++  sse-data
  ::
  |=  [rid=@ta =octs]
  ^-  card
  [%give %fact ~[/http-response/[rid]] [%http-response-data !>(`octs)]]
::
++  sse-keep-alive
  ::
  |=  rid=@ta
  ^-  card
  (sse-data rid (as-octs:mimes:html ': keep-alive\0a\0a'))
::
++  sse-close
  ::
  |=  [rid=@ta]
  ^-  card
  [%give %kick ~[/http-response/[rid]] ~]
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
++  find-element
  ::
  ::  find first descendant (or self) with matching tag name
  ::
  |=  [name=mane =manx]
  ^-  ^manx
  ?:  =(name n.g.manx)  manx
  =/  kids  c.manx
  |-
  ?~  kids  *^manx
  =/  result  ^$(manx i.kids)
  ?.  =(*mane n.g.result)
    result
  $(kids t.kids)
::
++  find-elements
  ::
  ::  find all descendants (or self) with matching tag name
  ::
  |=  [name=mane =manx]
  ^-  (list ^manx)
  =/  found=(list ^manx)
    ?:  =(name n.g.manx)  ~[manx]
    ~
  =/  kids  c.manx
  |-
  ?~  kids  found
  =.  found  (welp found ^$(manx i.kids))
  $(kids t.kids)
::
++  find-child-text
  ::
  ::  get text content of first direct child with matching tag
  ::
  |=  [name=mane =manx]
  ^-  (unit @t)
  =/  kids  c.manx
  |-
  ?~  kids  ~
  =/  kid  i.kids
  ?.  =(name n.g.kid)
    $(kids t.kids)
  `(crip (text-content kid))
::
++  text-content
  ::
  ::  extract all text from a manx tree
  ::
  |=  =manx
  ^-  tape
  ?:  ?=(%$ n.g.manx)
    (zing (murn a.g.manx |=([n=mane v=tape] ?:(?=(%$ n) `v ~))))
  =/  kids  c.manx
  |-
  ?~  kids  ~
  (welp (text-content i.kids) $(kids t.kids))
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
++  collapse-tang
  ::
  |=  =tang
  ^-  tank
  [%rose ["\0a" "" ""] tang]
::
++  print-tang
  ::
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
++  fix-newlines
  ::
  |=  c=cord
  :: %^  cat  3
    %+  rap  3
    %+  murn  (rip 3 c)
    |=  char=@t
    ?:  =(char '\0d')  ~
    `char
  :: '\0a'
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
    %a  ''
    %o  !!
  ==
::
++  parse-url
  ::
  ::  XX there is a faster way to do this through direct parsing
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
++  render-data
  ::
  =|  pax=pith
  =|  seg=(unit iota)
  |=  =data
  ^-  manx
  %^  add-class-if  ?=(^ pax)  "bdr0"
  %^  add-attribute-if  ?=(~ pax)  open+""
  ;details.bd1.btlr2.bblr2.scroll-none
    ;summary.b1.hover.p-2.fr.ac.jb.g3
      ;div
        ;-
        ?~  seg  "/"
        <u.seg>
      ==
      ;div.fr.g3
        ;span
          ;-  ?~  leaf.data  ""
          %+  welp  "%"
          (print-aura u.leaf.data)
        ==
      ==
    ==
    ;div.bdt1.fc.bc9
      ;+  ?~  leaf.data  ;/  ""
      ;div.b0.p3.scroll-x.scroll-y.pre.max-h18
        ;-  (node-summary u.leaf.data)
      ==
      ;+
      =;  =marl
        ?~  marl  ;/  ""
        ;div.fc.pl3.pt3.pb3.g2.bdt1
          ;*  marl
        ==
      %+  turn  (tap:modi kids.data)
      |=  [=iota d=_data]
      ^$(pax (snoc pax iota), seg `iota, data d)
    ==
  ==
::
++  render-data-with-signals
  ::
  =|  pax=pith
  =|  seg=(unit iota)
  |=  [salt=@t =data]
  ^-  manx
  =/  nid  (uid [salt pax])
  %^  add-attribute-if  ?=(~ pax)  ['data-signals' "\{'_ren{nid}': true}"]
  ;div.fc.bc7
    ;+
    %^  add-class-if  (~(has-kids do data) /)  "b2 hover"
    ;button.bdt1.fr.jb.p-1
      =data-on_click  "$_ren{nid} = !$_ren{nid}"
      =data-class_active  "$_ren{nid}"
      ;div
        ;-
        ?~  seg  "/"
        (node-summary u.seg)
      ==
      ;div
        ;-  ?~  leaf.data  ""
        ;:  welp
            "%"
            (print-aura u.leaf.data)
            " : "
            ?@  u.leaf.data  (trip u.leaf.data)
            ?+  -.u.leaf.data  (scag 30 (node-summary u.leaf.data))
              ?(%da %p %ta %pith %ud)  (node-summary u.leaf.data)
            ==
        ==
      ==
    ==
    ;div
      =data-show  "$_ren{nid}"
      ;+
      =;  =marl
        ?~  marl  ;/  ""
        ;div.fc.pl3
          ;*  marl
        ==
      %+  turn  (tap:modi kids.data)
      |=  [=iota d=_data]
      ^$(pax (snoc pax iota), seg `iota, data d)
    ==
  ==
--
