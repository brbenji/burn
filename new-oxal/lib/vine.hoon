::  /lib/vine: agent wrapper for easy http threads
::
::  routes inbound HTTP requests to spider threads in /ted/ based on a
::  filename naming convention:
::
::    /ted/http/<prefix>.hoon            matches url  /<prefix>
::    /ted/http/<prefix>--admin.hoon     matches url  /<prefix>/admin
::    /ted/http/<prefix>---foo.hoon      matches url  /<prefix>/*/foo   (wildcard)
::
::  double-hyphens (--) separate path segments in thread filenames.
::  triple-hyphens (---) match any single path segment (wildcard).
::
::  threads receive: [prefix=path rest=path query=(map @t @t) =bowl:gall rid=@ta req]
::  threads respond by sending http gifts on /http-response/[rid]
::
::  == usage ==
::
::    /+  vine
::    %-  (agent:vine %myapp)
::    ^-  agent:gall
::    |_  =bowl:gall  ...
::
/-  spider, vine
/+  zozo-1
/~  sheds  shed:khan  /lib/vines
|%
+$  card  card:agent:gall
::
+$  phase  ?(%fresh %headed)
+$  active-map  (map @ta =phase)
::
++  agent
  |=  prefix=@tas
  |=  inner=agent:gall
  =|  active=active-map
  ^-  agent:gall
  |_  =bowl:gall
  +*  this  .
      ig    ~(. inner bowl)
  ::
  ++  on-init
    ::
    ^-  (quip card _this)
    =/  [cards=(list card) ag=agent:gall]
      on-init:ig
    :_  this(inner ag)
    [(bind-card prefix dap.bowl) cards]
  ::
  ++  on-save
    ::
    ^-  vase
    !>([%vine-0 active on-save:ig])
  ::
  ++  on-load
    ::
    |=  ole=vase
    ^-  (quip card _this)
    =+  try=(mole |.(!<([%vine-0 m=active-map iv=vase] ole)))
    ?~  try
      ::
      ::  first upgrade to wrapped vine: ole has no wrapper; pass through
      ::
      =/  [cards=(list card) ag=agent:gall]
        (~(on-load inner bowl) ole)
      :_  this(inner ag)
      [(bind-card prefix dap.bowl) cards]
    =/  [cards=(list card) ag=agent:gall]
      (~(on-load inner bowl) iv.u.try)
    :_  this(active m.u.try, inner ag)
    [(bind-card prefix dap.bowl) cards]
  ::
  ++  on-poke
    ::
    |=  =cage
    ^-  (quip card _this)
    ::
    ?:  ?&  ?=(%handle-http-request p.cage)
            =+  !<  [rid=@ta req=inbound-request:eyre]  q.cage
            (starts-with:zozo-1 '/new-oxal' url.request.req)
        ==
      =/  [cards=(list card) new-entry=(unit @ta)]
        (dispatch cage bowl prefix)
      =.  active
        ?~  new-entry  active
        (~(put by active) u.new-entry %fresh)
      [cards this]
    ::
    ::  fallback to inner
    ::
    =/  [cards=(list card) ag=agent:gall]
      (~(on-poke inner bowl) cage)
    [cards this(inner ag)]
    ::
  ::
  ++  on-watch
    ::
    |=  =path
    ^-  (quip card _this)
    ?:  ?=([%http-response *] path)
      [~ this]
    =/  [cards=(list card) ag=agent:gall]
      (~(on-watch inner bowl) path)
    [cards this(inner ag)]
  ::
  ++  on-leave
    ::
    |=  =path
    ^-  (quip card _this)
    ?:  ?=([%http-response @ ~] path)
      ::
      ::  eyre dropped the http subscription — client disconnected
      ::
      =/  rid=@ta  i.t.path
      =/  e  (~(get by active) rid)
      ?~  e  [~ this]
      :_  this(active (~(del by active) rid))
      :~  :*  %pass  /thread-stop/[rid]  %agent  [our.bowl %spider]
              %poke  %spider-stop  !>([rid %.y])
          ==
      ==
    =/  [cards=(list card) ag=agent:gall]
      (~(on-leave inner bowl) path)
    [cards this(inner ag)]
  ::
  ++  on-peek
    ::
    |=  =path
    ^-  (unit (unit cage))
    (~(on-peek inner bowl) path)
  ::
  ++  on-agent
    ::
    |=  [=wire =sign:agent:gall]
    ^-  (quip card _this)
    ::
    ?:  ?=([%http-response @ ~] wire)
      ::
      =/  rid=@ta  i.t.wire
      =/  paths=(list path)  ~[wire]
      ?:  ?=(%fact -.sign)
        =?  active  ?=(%http-response-header p.cage.sign)
          (~(put by active) rid %headed)
        :_  this
        :~  [%give %fact paths cage.sign]
        ==
      ?:  ?=(%kick -.sign)
        :_  this
        :~  [%give %kick paths ~]
        ==
      `this
      ::
    ?:  ?=([%thread-stop @ ~] wire)
      ::
      ::  result of spider-stop poke from on-leave cancellation
      ::
      ?.  ?=(%poke-ack -.sign)  [~ this]
      ?~  p.sign  [~ this]
      %-  (slog leaf+"vine: spider-stop nacked" u.p.sign)
      [~ this]
    ?:  ?=([%thread @ ~] wire)
      ::
      =/  rid  i.t.wire
      ?-    -.sign
          %poke-ack
        ?~  p.sign  [~ this]
        %-  (slog leaf+"vine: spider-start nacked" u.p.sign)
        =/  [cards=(list card) new=active-map]
          (finalize-error active rid u.p.sign)
        [cards this(active new)]
      ::
          %watch-ack
        ?~  p.sign  [~ this]
        %-  (slog leaf+"vine: spider watch nacked" u.p.sign)
        [~ this]
      ::
          %kick  [~ this]
      ::
          %fact
        ?+    p.cage.sign  [~ this]
            %thread-fail
          =+  !<([=term =tang] q.cage.sign)
          =/  [cards=(list card) new=active-map]
            (finalize-error active rid tang)
          [cards this(active new)]
        ::
            %thread-done  [~ this]
        ==
      ==
    =/  [cards=(list card) ag=agent:gall]
      (~(on-agent inner bowl) wire sign)
    [cards this(inner ag)]
  ::
  ++  on-arvo
    ::
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)
    ?:  ?=([%eyre-bind ~] wire)
      [~ this]
    =/  [cards=(list card) ag=agent:gall]
      (~(on-arvo inner bowl) wire sign-arvo)
    [cards this(inner ag)]
  ::
  ++  on-fail
    ::
    |=  [=term =tang]
    ^-  (quip card _this)
    =/  [cards=(list card) ag=agent:gall]
      (~(on-fail inner bowl) term tang)
    [cards this(inner ag)]
  --
::
++  bind-card
  ::
  |=  [prefix=@tas dap=@tas]
  ^-  card
  [%pass /eyre-bind %arvo %e %connect [~ /[prefix]] dap]
::
++  dispatch
  ::
  |=  [=cage =bowl:gall prefix=@tas]
  ^-  [cards=(list card) new-entry=(unit @ta)]
  =/  [rid=@ta req=inbound-request:eyre]
    !<([@ta inbound-request:eyre] q.cage)
  =/  [url=path query=(map @t @t)]  (parse-url:zozo-1 url.request.req)
  =/  handler  (find-thread-handler url bowl)
  =/  pax=path  /http-response/[rid]
  ?~  handler
    =/  body=octs  (as-octs:mimes:html 'not found')
    :_  ~
    :~  [%give %fact ~[pax] %http-response-header !>([404 ['content-type' 'text/plain']~])]
        [%give %fact ~[pax] %http-response-data !>((some body))]
        [%give %kick ~[pax] ~]
    ==
  =/  =shed:khan  (~(got by sheds) name.u.handler)
  =/  args=^cage
    :-  %http-bowl  !>
    %*  .  *http-bowl:vine
      prefix  prefix.u.handler
      rest    rest.u.handler
      query  query
      rid  rid
      method  method.request.req
      url  url.request.req
      our  our.bowl
      now  now.bowl
      src  src.bowl
      eny  eny.bowl
      rid  rid
      dap  dap.bowl
      sup  sup.bowl
      wex  wex.bowl
      sky  sky.bowl
      byk  byk.bowl
      sap  sap.bowl
      secure  secure.req
      address  address.req
      header-list  header-list.request.req
      body  body.request.req
    ==
  :_  `rid
  :~
    [%pass /thread/[rid] %agent [our.bowl %spider] %watch /thread-result/[rid]]
    [%pass /thread/[rid] %agent [our.bowl %spider] %poke %spider-inline !>([~ `rid byk.bowl shed])]
    [%pass /http-response/[rid] %agent [our.bowl %spider] %watch /thread/[rid]/http-response/[rid]]
    [%pass /thread/[rid] %agent [our.bowl %spider] %poke %spider-input !>([rid args])]
  ==
::
++  finalize-error
  ::
  ::  handle a mid-flight thread failure: always slog; emit a
  ::  full 500+trace if no %head has been sent yet, or just a
  ::  %kick to close if the client already has a status line
  ::
  |=  [am=active-map rid=@ta =tang]
  ^-  [cards=(list card) new-active=active-map]
  %-  (slog leaf+"vine: thread failed" rid tang)
  =/  pax=path  [%http-response rid ~]
  =/  e  (~(get by am) rid)
  ?~  e  [~ am]
  =.  am  (~(del by am) rid)
  ?:  ?=(%headed phase.u.e)
    :_  am
    ~[[%give %kick ~[pax] ~]]
  =/  body=octs  (as-octt:mimes:html (print-tang:zozo-1 tang))
  :_  am
  :~  [%give %fact ~[pax] %http-response-header !>([500 ['content-type' 'text/plain']~])]
      [%give %fact ~[pax] %http-response-data !>(`(unit octs)`(some body))]
      [%give %kick ~[pax] ~]
  ==
::
++  unpack-thread-name
  ::
  |=  name=@ta
  ^-  (list @ta)
  =/  chars=tape  (trip name)
  =|  segments=(list @ta)
  =|  current=tape
  |-
  ?~  chars
    ~|  %thread-name-trailing-separator
    ?<  =(~ current)
    (flop [(crip current) segments])
  ?:  ?&  =('-' i.chars)
          ?=(^ t.chars)
          =('-' i.t.chars)
      ==
    ?:  ?&(?=(^ t.t.chars) =('-' i.t.t.chars))
      ~|  %thread-name-trailing-separator
      ?<  =(~ t.t.t.chars)
      %=  $
        chars    t.t.t.chars
        segments  ['' [(crip current) segments]]
        current  ~
      ==
    ~|  %thread-name-trailing-separator
    ?<  =(~ t.t.chars)
    %=  $
      chars    t.t.chars
      segments  [(crip current) segments]
      current  ~
    ==
  %=  $
    chars    t.chars
    current  (snoc current i.chars)
  ==
::
++  match-pattern
  ::
  |=  [pattern=(list @ta) line=path]
  ^-  (unit [prefix=path rest=path])
  =/  consumed=path  ~
  |-
  ?~  pattern
    (some [(flop consumed) line])
  ?~  line
    ~
  ?:  =(%$ i.pattern)
    $(pattern t.pattern, line t.line, consumed [i.line consumed])
  ?.  =(i.pattern i.line)
    ~
  $(pattern t.pattern, line t.line, consumed [i.line consumed])
::
++  compare-patterns
  ::
  |=  [a=(list @ta) b=(list @ta)]
  ^-  ?
  ?~  a
    ?~  b  %.y
    %.n
  ?~  b
    %.y
  ?:  =(i.a i.b)
    $(a t.a, b t.b)
  (aor i.b i.a)
::
++  find-thread-handler
  ::
  |=  [line=path bol=bowl:gall]
  ^-  (unit [name=@ta prefix=path rest=path])
  :: =/  ted-arch=arch
  ::  .^(arch %cy /(scot %p our.bol)/[q.byk.bol]/(scot %da now.bol)/ted)
  =/  handlers=(list [name=@ta pattern=(list @ta)])
    %+  turn  ~(tap in ~(key by sheds))
    |=  name=@ta
    [name (unpack-thread-name name)]
  =/  sorted=(list [name=@ta pattern=(list @ta)])
    %+  sort  handlers
    |=  [a=[name=@ta pattern=(list @ta)] b=[name=@ta pattern=(list @ta)]]
    (compare-patterns pattern.a pattern.b)
  |-
  ?~  sorted  ~
  =/  result  (match-pattern pattern.i.sorted line)
  ?~  result
    $(sorted t.sorted)
  (some [name.i.sorted prefix.u.result rest.u.result])
::
--
