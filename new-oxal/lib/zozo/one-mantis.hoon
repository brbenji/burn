/+  *zozo-one
::
::  one-mantis: all i/o happens via namespace writes
::
::    converts a mantis-core into a raw-core, bridging the gap
::    between hawk's change-based model and gall's event arms.
::
::    mantis is very untyped. it is too low level for most developer
::    use cases. it is meant to be a compile target for higher-level
::    application models like feather-1.
::
::    io convention:
::
::      framework code handles /o/...
::      user code handles /i/* and all other wires.
::      user code emits /o/... to interact with the system.
::      user code emits other wires to interact with itself.
::      user code cannot emit /~ wires.
::
::        WIRE                  STEM                       ACTION      PURPOSE
::
::        /i/eyre/[rid]         #/~/eyre/[rid]             %ins data   incomming http request
::        /o/eyre/[rid]         #/~/eyre/[rid]/head        %ins data   HTTP head (open)
::        /o/eyre/[rid]         #/~/eyre/[rid]/[ud]        %ins mime   HTTP payload body (for sse, write multiple with incrementing ud)
::        /~/eyre/keepalive     #/~/eyre/[rid]/keepalive   %ins ud     incremented when the keepalive timer goes off (framework must send keepalive)
::        /o/eyre/[rid]         #/~/eyre/[rid]             %lop ~      close HTTP connection
::        /o/eyre/[rid]         #/~/eyre/[rid]             %del ~      close HTTP connection
::        /i/eyre/[rid]         #/~/eyre/[rid]             %lop ~      browser disconnected
::
::                                                                     if mantis detects that a connection is long-lived,
::                                                                     (because the content-type was /text/event-stream)
::                                                                     it will automatically handle sending keepalives every 25s.
::
::        /o/behn/[wire]        #/~/behn/[wire]            %ins da     set timer
::        /o/behn/[wire]        #/~/behn/[wire]            %lop ~      cancel timer
::        /o/behn/[wire]        #/~/behn/[wire]            %del ~      cancel timer
::        /i/behn/[wire]        #/~/behn/[wire]            %lop ~      wake-up
::
::        /o/iris/[pith]        #/~/iris/[pith]            %ins data   outbound HTTP request
::        /o/iris/[pith]        #/~/iris/[pith]            %lop ~      cancel HTTP request
::        /o/iris/[pith]        #/~/iris/[pith]            %del ~      cancel HTTP request
::        /i/iris/[pith]        #/~/iris/[pith]/~          %ins data   HTTP response
::
::        /o/keen/[iota]        #/~/keen/[iota]            %ins data   static request
::        /o/keen/[iota]        #/~/keen/[iota]            %lop pith   cancel static request
::        /o/keen/[iota]        #/~/keen/[iota]            %del pith   cancel static request
::        /i/keen/[iota]        #/~/keen/[iota]/~          %ins data   static response
::
::        /o/mirror/[iota]      #/~/mirror/[iota]          %ins data   start subscription
::        /o/mirror/[iota]      #/~/mirror/[iota]          %lop ~      end subscription
::        /o/mirror/[iota]      #/~/mirror/[iota]          %del ~      end subscription
::        /i/mirror/[iota]      #/~/mirror/[iota]/[case]   %ins data   new data
::
::
::    all other wires are passed to the user's mantis-core gate.
::
|=  mantis=mantis-core
^-  raw-core
::
::  raw-core wrapper: delegates each arm to the machine door
::
=;  machine
  ^-  raw-core
  |%
  ++  on-arvo       |=  [=wire =sign-arvo =quest =file]      deal:(~(on-arvo machine quest file ~) wire sign-arvo)
  ++  on-http       |=  [=http-req =quest =file]             deal:(~(on-http machine quest file ~) http-req)
  ++  cancel-http   |=  [rid=@ta =stem =quest =file]         deal:(~(cancel-http machine quest file ~) rid stem)
  ++  on-crash      |=  [=tang =change =quest =file]         deal:(~(on-crash machine quest file ~) tang change)
  ++  on-change     |=  [=prov =move =quest =file]           done:(~(on-change machine quest file ~) prov move)
  --
::
::  machine: the door that holds state and does the actual work.
::  accumulates cards and returns them via ++done or ++deal.
::
|_  [=quest =file cards=(list card)]
+*  f   ~(. fe file)                                        ::  file engine
    d   ~(. do data.file)                                   ::  data engine
    h   ~(. href [%oxal here.quest] ~)                      ::  URL builder
++  cor   .
++  emit  |=  =card  cor(cards [card cards])                ::  emit one card
++  emil  |=  caz=(list card)  cor(cards (welp (flop caz) cards))
::
::  cancel-pending-timer: cancel an in-flight behn timer if one exists.
::  reads the @da from base/timer-at, emits %rest to cancel it.
::
++  cancel-pending-timer
  |=  [base=pith timer-wire=@tas name=iota]
  ^-  (list card)
  ?~  old=(get-da:d (welp base /timer-at))  ~
  :~  [%pass `pith`[timer-wire name da+u.old ~] %arvo %b %rest u.old]
  ==
::
::  build-spur: construct a keen spur from case, path, and care.
::
++  build-spur
  |=  [case=@ud =pith care=@tas]
  ^-  spur
  :*  %g  %x  (scot %ud case)  %oxal
      %$  (scot %ud 1)
      (pout (welp pith #/[care]))
  ==
::
::  schedule-retry: exponential backoff timer for error/timeout states.
::
++  schedule-retry
  |=  [base=pith timer-wire=@tas name=iota attempt=@ud cancel=(list card)]
  ^+  cor
  =/  limit=@dr  ~m5
  =/  delay=@dr  (min limit (mul ~s4 (xeb attempt)))
  =/  retry=@da  (add now.quest delay)
  %-  emil
  %+  welp  cancel
  :~  [%hawk ~ (welp base /timer-at) %ins da+retry]
      [%pass `pith`[timer-wire name da+retry ~] %arvo %b %wait retry]
  ==
::
::  on-keen-timer: handle mirror/keen timer wakeup (timeout or retry).
::
++  on-keen-timer
  |=  [base=pith expected=@da do-wire=pith state-prov=pith]
  ^+  cor
  ?.  (hos:d base)  cor
  ?.  =((get-da:d (welp base /timer-at)) `expected)
    ~&  unexpected-timer-expected/expected
    cor
  =/  state  (gut-tas:d (welp base /state) %loading)
  ?+  state  cor
    %loading  ::  keen timed out
      =/  attempt  (add 1 (gut-ud:d (welp base /attempt) 0))
      %-  emil
      :~  [%hawk ~ (welp base /timer-at) %lop ~]
          [%hawk state-prov (welp base /attempt) %ins ud+attempt]
          [%hawk state-prov (welp base /state) %ins %timeout]
          [%hawk do-wire (welp base /do) %ins da+now.quest]
      ==
    ?(%error %timeout)  ::  retry backoff complete
      %-  emil
      :~  [%hawk ~ (welp base /timer-at) %lop ~]
          [%hawk state-prov (welp base /state) %ins %loading]
          [%hawk do-wire (welp base /do) %ins da+now.quest]
      ==
  ==
++  done  (flop cards)                                      ::  finalize: all cards
++  deal                                                    ::  finalize: %hawk cards only
  %-  flop
  %+  murn  cards
  |=  =card
  ?:  ?=([%hawk *] card)  `card  ~
::
::  log crash and continue
::
++  on-crash
  |=  [=tang =change]
  ^+  cor
  %-  (slog %mantis-crash >here.quest< tang)
  cor
::
::  translate arvo signs into data-tree changes.
::  eyre: mark the request at #/~/eyre/[wire]
::  behn: handle keepalives or pass through at #/~/behn/[wire]
::  iris: unpack HTTP client response at #/~/iris/[wire]
::
++  on-arvo
  |=  [=wire s=sign-arvo]
  ^+  cor
  ?+  s  ~|  mantis-unhandled-sign/-.s  !!
    ::
    [%eyre *]
      %-  emit
      [%hawk (welp #/i/eyre wire) (welp #/~/eyre wire) %ins %eyre]
    ::
    [%behn *]
      ?>  ?=([%behn %wake *] s)
      ::  eyre keepalive timer
      ?:  ?=([%eyre-ka @ ~] wire)
        =/  rid=@ta  i.t.wire
        ?.  (hos:d #/~/eyre/[ta/rid]/head)  cor
        %-  emit
        [%hawk #/~/eyre/keepalive #/~/eyre/[ta/rid]/keepalive %ins ud+(gut-ud:d #/~/eyre/[ta/rid]/keepalive 0)]
      ::  mirror timer: timeout or retry
      ?:  ?=([%mirror-timer * [%da @] ~] wire)
        =/  name=iota  i.t.wire
        (on-keen-timer #/~/mirror/[name] da.i.t.t.wire #/mirror-do/[name] /mr)
      ::  keen timer: timeout or retry
      ?:  ?=([%keen-timer * [%da @] ~] wire)
        =/  name=iota  i.t.wire
        (on-keen-timer #/~/keen/[name] da.i.t.t.wire #/keen-do/[name] /kr)
      %-  emit
      [%hawk (welp #/i/behn wire) (welp #/~/behn wire) %lop ~]
    ::
    ::  keen/mirror keen response
    ::
    [%ames *]
      ?>  ?=([%ames %sage *] s)
      ::  keen response
      ?:  ?=([%keen-req [%ta @] [%da @] ~] wire)
        =/  name=@ta   ta.i.t.wire
        =/  nonce=@da  da.i.t.t.wire
        =/  fp  #/~/keen/[ta/name]
        ?.  (hos:d fp)  cor
        ?.  =((fall (get-da:d (welp fp /keen-nonce)) *@da) nonce)  cor
        =/  =sage:mess:ames  sage.s
        ?:  ?|  ?=(~ q.sage)
                ?=(~ ((soft data) q.q.sage))
            ==
          =/  attempt  (add 1 (gut-ud:d (welp fp /attempt) 0))
          %-  emil
          :~  [%hawk /ke (welp fp /state) %ins %error]
              [%hawk /ka (welp fp /attempt) %ins ud+attempt]
              [%hawk #/keen-do/[ta/name] (welp fp /do) %ins da+now.quest]
          ==
        =/  dat=data  (need ((soft data) q.q.sage))
        %-  emil
        :~  [%hawk /ks (welp fp /state) %ins %success]
            [%hawk /ka (welp fp /attempt) %ins ud+0]
            [%hawk #/i/keen/[ta/name] (welp fp #/~) %ins [%data dat]]
        ==
      ::  mirror keen response
      ?>  ?=([%mirror-keen * [%da @] ~] wire)
      ~&  %mirror-keen-response
      =/  name=iota   i.t.wire
      =/  nonce=@da  da.i.t.t.wire
      =/  mp  #/~/mirror/[name]
      ?.  (hos:d mp)  cor
      ?.  =((fall (get-da:d (welp mp /keen-nonce)) *@da) nonce)
        ~&  nonce-doesnt-match/nonce
        cor
      =/  =sage:mess:ames  sage.s
      ?:  ?|  ?=(~ q.sage)
              ?=(~ ((soft data) q.q.sage))
          ==
        =/  attempt  (add 1 (gut-ud:d (welp mp /attempt) 0))
        %-  emil
        :~  [%hawk /me (welp mp /state) %ins %error]
            [%hawk /ma (welp mp /attempt) %ins ud+attempt]
            [%hawk [%mirror-do name ~] (welp mp /do) %ins da+now.quest]
        ==
      =/  dat=data  (need ((soft data) q.q.sage))
      =/  cur-case  (gut-ud:d (welp mp /case) 0)
      %-  emil
      %+  welp
        ?:  =(0 cur-case)  ~
        :~  [%hawk ~ (welp mp /[ud/cur-case]) %lop ~]
        ==
      :~  [%hawk /ms (welp mp /state) %ins %success]
          [%hawk /mc (welp mp /case) %ins ud++(cur-case)]
          [%hawk /ma (welp mp /attempt) %ins ud+0]
          [%hawk [%i %mirror name ~] (welp mp /[ud/+(cur-case)]) %ins [%data dat]]
          [%hawk [%mirror-do name ~] (welp mp /do) %ins da+now.quest]
      ==
    ::
    [%iris *]
      ?>  ?=([%iris %http-response *] s)
      ?:  ?=([%progress *] client-response.s)  cor
      ?:  ?=([%cancel *] client-response.s)
        %-  emit
        [%hawk #/i/iris/[pith+wire] #/~/iris/[pith+wire]/~ %ins %cancel]
      %-  emit
      =-  [%hawk #/i/iris/[pith+wire] #/~/iris/[pith+wire]/~ %ins %data -]
      ^-  data
      %-  ~(gep do *data)
      :~  :-  /status   %-  mono  ud+status-code.response-header.client-response.s
          :-  /headers
            ^-  data
            %-  ~(gas do *data)
            %+  turn  headers.response-header.client-response.s
            |=  [k=@t v=@t]
            :-  #/[t/k]  t+v
          :-  /body
            ^-  data
            ?~  full-file.client-response.s  *data
            %-  mono  t+q.data.u.full-file.client-response.s
      ==
  ==
::
::  cancel-http: client disconnected, clean up eyre request data
::
++  cancel-http
  |=  [rid=@ta stem]
  ^+  cor
  %-  emit
  [%hawk #/i/eyre/[ta/rid] #/~/eyre/[ta/rid] %lop ~]
::
::  on-http: pack an incoming HTTP request into the data tree
::  at #/~/eyre/[rid] with fields: src, now, eny, line (stem),
::  method, our, here, headers, body (form-decoded), query.
::  then emits a change on wire /i/eyre/[rid] to trigger
::  the mantis (or feather-1) handler.
::
++  on-http
  |=  =http-req
  ^+  cor
  =/  rid  rid.http-req
  %-  emit
  =-  [%hawk #/i/eyre/[ta/rid] #/~/eyre/[ta/rid] %ins [%data -]]
  ^-  data
  %-  ~(gep do *data)
  :~
    :-  /src        %-  mono  p+src.quest
    :-  /now        %-  mono  da+now.quest
    :-  /eny        %-  mono  uv+(@uv eny.quest)
    :-  /line       %-  mono  pith+stem.http-req
    :-  /method     %-  mono  method.http-req
    :-  /our        %-  mono  p+our.quest
    :-  /here       %-  mono  pith+here.quest
    :-  /headers
      ^-  data
      %-  ~(gas do *data)
      %+  turn  header-list:http-req
      |=  [k=@t v=@t]
      :-  #/[t/k]  t+v
    :-  /body
      ^-  data
      ?~  bud=body.http-req  *data
      =/  content-type
        %+  fall  (get-header:http 'content-type' header-list:http-req)
        'application/x-unknown'
      ?:  (starts-with 'application/x-www-form-urlencoded' content-type)
        (form-encoded-body u.bud)
      ~|  unknown-content-type/content-type
      !!
    ::
    :-  /query
      ^-  data
      %-  ~(gas do *data)
      %+  turn  ~(tap by pams.http-req)
      |=  [k=@t v=@t]
      :-  #/[t/k]  t+v
    ::
  ==
::
::  on-change: route changes by wire pattern.
::  known wires (/o/eyre, /o/behn, etc.) are translated
::  into gall effects. unknown wires are passed to the user's
::  mantis-core gate for custom handling.
::
++  on-change
  |=  [=prov =move]
  =/  wire  ((pole iota) wire.move)
  =/  =stem  stem.move
  ::
  ^+  cor
  ?+    wire
      ::
      ::  unrecognized wire: delegate to user's mantis-core
      ::  inject meta values from quest so user code can always read them
      ::
      %-  emil
      %+  turn
        %^   mantis  prov  move
        %=  file
          data
            %+  ~(rep do data.file)  `pith`#/~/meta
            %-  ~(gas do *data)
            :~  [#/our p+our.quest]
                [#/here pith+here.quest]
                [#/now da+now.quest]
            ==
        ==
      |=  =_move
      [%hawk move]
    ::
    [~]  cor  ::  no-op
    ::
    ::  HTTP eyre: head/body/close translation
    ::
    ::  %ins at .../head: extract status+headers, emit %give http-response-header.
    ::    if content-type is text/event-stream, start keepalive timer.
    ::  %ins at .../[ud]: body payload, emit %give http-response-data.
    ::  %lop or %del at base: close connection, emit %give %kick.
    ::
    [%o %eyre rid=[%ta @] ~]
      =/  rid=@ta  ta.rid.wire
      ?:  ?=(?([%lop ~] [%del ~]) action.move)
        ::  close connection
        %-  emil
        ^-  (list card)
        %+  welp
          ::  cancel keepalive timer if one is active
          ?~  ka-at=(get-da:d #/~/eyre/[ta/rid]/keepalive/timer-at)  ~
          :~  [%pass #/eyre-ka/[ta/rid] %arvo %b %rest u.ka-at]
          ==
        :~  [%hawk ~ stem %lop ~]
            (sse-close rid)
        ==
      ::  %ins action: head or body
      ?>  ?=([%ins *] action.move)
      =/  pax  ((pole iota) stem)
      ?+    pax
          ~&  unknown-pax/rid
          cor
        ::  head: extract status and headers, emit http-response-header
        [[%n ~] %eyre [%ta @] %head ~]
          =/  hd  ~(. do (got-data:d stem))
          =/  status=@ud  (got-ud:hd /status)
          =/  hdrs=header-list:http
            %+  turn  kid-list:(dit:hd /headers)
            |=  [=node =data]
            ?>  ?=([%t @] node)
            [t.node (~(got-t do data) ~)]
          %-  emil
          ^-  (list card)
          :-  [%give %fact ~[/http-response/[rid]] [%http-response-header !>([status hdrs])]]
          ::  auto-detect SSE: start keepalive timer
          =/  ct  (get-header:http 'content-type' hdrs)
          ?.  ?&  ?=(^ ct)
                  (starts-with 'text/event-stream' u.ct)
              ==
            ~
          =/  ka-time=@da  (add now.quest ~s25)
          :~  [%hawk ~ #/~/eyre/[ta/rid]/keepalive/timer-at %ins da+ka-time]
              [%pass #/eyre-ka/[ta/rid] %arvo %b %wait ka-time]
          ==
        ::  body: emit http-response-data, then lop the body node
        [[%n ~] %eyre [%ta @] [%ud @] ~]
          =/  nd  node.action.move
          =/  =octs
            ?>  ?=([%mime *] nd)
            q.mime.nd
          %-  emil
          :~  [%give %fact ~[/http-response/[rid]] [%http-response-data !>(`octs)]]
              [%hawk ~ stem %lop ~]
          ==
        ::  close signal: send kick and clean up eyre subtree
        [[%n ~] %eyre [%ta @] %close ~]
          %-  emil
          ^-  (list card)
          %+  welp
            ?~  ka-at=(get-da:d #/~/eyre/[ta/rid]/keepalive/timer-at)  ~
            :~  [%pass #/eyre-ka/[ta/rid] %arvo %b %rest u.ka-at]
            ==
          :~  (sse-close rid)
              [%hawk ~ #/~/eyre/[ta/rid] %lop ~]
          ==
      ==
    ::
    ::  eyre keepalive: timer fired, send keepalive and reschedule
    ::
    [[%n ~] %eyre %keepalive ~]
      ::  find which rid this keepalive is for by reading the stem
      =/  pax  ((pole iota) stem)
      ?>  ?=([[%n ~] %eyre rid=[%ta @] %keepalive ~] pax)
      =/  rid=@ta  ta.rid.pax
      ?.  (hos:d #/~/eyre/[ta/rid]/head)
        ::  connection gone, clean up
        %-  emit
        [%hawk ~ stem %lop ~]
      =/  ka-time=@da  (add now.quest ~s25)
      %-  emil
      ^-  (list card)
      :~  [%hawk ~ stem %lop ~]
          [%hawk ~ #/~/eyre/[ta/rid]/keepalive/timer-at %ins da+ka-time]
          (sse-keep-alive rid)
          [%pass #/eyre-ka/[ta/rid] %arvo %b %wait ka-time]
      ==
    ::
    ::  timer: read the @da, set behn timer. %lop/%del = cancel.
    ::
    [%o %behn rest=*]
      ?:  ?=(?([%lop ~] [%del ~]) action.move)
        ::  cancel timer: read existing @da from stem
        ?~  tim=(get-da:d stem)  cor
        %-  emil
        :~  [%hawk ~ stem %lop ~]
            [%pass rest.wire %arvo %b %rest u.tim]
        ==
      =/  tim=@da  (got-da:d stem)
      %-  emit
      [%pass rest.wire %arvo %b %wait tim]
    ::
    ::  outbound HTTP: read url, method, headers, body from the
    ::  data tree, send iris request. %lop/%del = cancel.
    ::
    [%o %iris name=[%pith *] ~]
      ::
      ::  cancel
      ::
      ?:  ?=(?([%lop ~] [%del ~]) action.move)
        %-  emil
        :~  [%hawk ~ stem %lop ~]
            [%pass pith.name.wire %arvo %i %cancel-request ~]
        ==
      ?:  =((get-f:d (snoc stem %sent)) `f+&)
        ::
        ::  prevent wire re-use
        ::
        ~|  reusing-iris-wire/name.wire
        !!
      =/  cd  ~(. do (got-data:d stem))
      =/  url=@t   (got-t:cd /url)
      =/  met  (method:http (got-t:cd /method))
      =/  hdrs=header-list:http
        %+  turn  kid-list:(dit:cd /headers)
        |=  [=node =data]
        ?>  ?=([%t @] node)
        [t.node (~(got-t do data) ~)]
      =/  body=(unit octs)
        ?~  bod=(get-t:cd /body)  ~
        ?:  =(met %'GET')  ~|  %get-cannot-have-body  !!
        `(as-octs:mimes:html u.bod)
      %-  emil
      :~  [%hawk / #/~/iris/[name.wire]/sent %ins f+&]
          [%pass pith.name.wire %arvo %i %request `request:http`[met url ~ body] *outbound-config:iris]
      ==
    ::
    ::  mirror: start or stop a remote data mirror
    ::
    [%o %mirror name=* ~]
      =/  name=iota  name.wire
      =/  mp  #/~/mirror/[name]
      ?:  ?=(?([%lop ~] [%del ~]) action.move)
        ?.  (hos:d mp)  cor
        =/  ship=@p  (got-p:d (welp mp /ship))
        =/  path=pith  (got-pith:d (welp mp /path))
        =/  care=@tas  (gut-tas:d (welp mp /care) %cone)
        =/  cur-case  (gut-ud:d (welp mp /case) 0)
        =/  =spur  (build-spur +(cur-case) path care)
        =/  old-nonce=@da  (fall (get-da:d (welp mp /keen-nonce)) *@da)
        =/  cancel=(list card)  (cancel-pending-timer mp %mirror-timer name)
        %-  emil
        %+  welp  cancel
        :~  [%pass #/mirror-keen/[name]/[da+old-nonce] %arvo %a %yawn ship spur]
            [%hawk ~ mp %lop ~]
        ==
      =/  cd  ~(. do (got-data:d stem))
      =/  ship=@p  (got-p:cd /ship)
      =/  path=pith  (got-pith:cd /path)
      =/  care=@tas  (got-tas:cd /care)
      ::  reset case and data if path changed
      =/  new-target=?
        ?|  !=(ship (fall (get-p:d (welp mp /ship)) *@p))
            !=(path (fall (get-pith:d (welp mp /path)) *pith))
            !=(care (gut-tas:d (welp mp /care) %cone))
        ==
      =/  cur-case  ?:(new-target 0 (gut-ud:d (welp mp /case) 0))
      =/  =spur  (build-spur +(cur-case) path care)
      =/  timeout=@da  (add now.quest ~s15)
      =/  cancel=(list card)  (cancel-pending-timer mp %mirror-timer name)
      %-  emil
      %+  welp  cancel
      %+  welp
        ?.  new-target  ~
        :~  [%hawk /m4 (welp mp /case) %ins ud+0]
            [%hawk /m7 (welp mp /data) %lop ~]
        ==
      :~  [%hawk /m1 (welp mp /ship) %ins p+ship]
          [%hawk /m2 (welp mp /path) %ins pith+path]
          [%hawk /m3 (welp mp /care) %ins care]
          [%hawk /m5 (welp mp /attempt) %ins ud+0]
          [%hawk /m6 (welp mp /state) %ins %loading]
          [%hawk ~ (welp mp /timer-at) %ins da+timeout]
          [%hawk ~ (welp mp /keen-nonce) %ins da+now.quest]
          [%pass #/mirror-keen/[name]/[da+now.quest] %keen %.n [ship spur]]
          [%pass #/mirror-timer/[name]/[da+timeout] %arvo %b %wait timeout]
      ==
    ::
    ::  keen: one-shot keen at an exact case number
    ::
    [%o %keen name=[%ta @] ~]
      ?:  ?=(?([%lop ~] [%del ~]) action.move)
        =/  name=@ta  ta.name.wire
        =/  fp  #/~/keen/[ta/name]
        ?.  (hos:d fp)  cor
        =/  ship=@p  (got-p:d (welp fp /ship))
        =/  path=pith  (got-pith:d (welp fp /path))
        =/  care=@tas  (gut-tas:d (welp fp /care) %cone)
        =/  case=@ud  (gut-ud:d (welp fp /case) 0)
        =/  =spur  (build-spur case path care)
        =/  old-nonce=@da  (fall (get-da:d (welp fp /keen-nonce)) *@da)
        =/  cancel=(list card)  (cancel-pending-timer fp %keen-timer ta/name)
        %-  emil
        %+  welp  cancel
        :~  [%pass #/keen-req/[ta/name]/[da+old-nonce] %arvo %a %yawn ship spur]
            [%hawk ~ fp %lop ~]
        ==
      =/  name=@ta  ta.name.wire
      =/  fp  #/~/keen/[ta/name]
      =/  cd
        ?^  x=(get-data:d stem)  ~(. do u.x)
        (dit:d stem)
      =/  ship=@p  (got-p:cd /ship)
      =/  path=pith  (got-pith:cd /path)
      =/  care=@tas  (gut-tas:cd /care %cone)
      =/  case=@ud  (got-ud:cd /case)
      =/  cancel=(list card)  (cancel-pending-timer fp %keen-timer ta/name)
      =/  =spur  (build-spur case path care)
      =/  timeout=@da  (add now.quest ~s15)
      %-  emil
      %+  welp  cancel
      :~  [%hawk /k1 (welp fp /ship) %ins p+ship]
          [%hawk /k2 (welp fp /path) %ins pith+path]
          [%hawk /k3 (welp fp /care) %ins care]
          [%hawk /k4 (welp fp /case) %ins ud+case]
          [%hawk /k5 (welp fp /attempt) %ins ud+0]
          [%hawk /k6 (welp fp /state) %ins %loading]
          [%hawk ~ (welp fp /timer-at) %ins da+timeout]
          [%hawk ~ (welp fp /keen-nonce) %ins da+now.quest]
          [%pass #/keen-req/[ta/name]/[da+now.quest] %keen %.n [ship spur]]
          [%pass #/keen-timer/[ta/name]/[da+timeout] %arvo %b %wait timeout]
      ==
    ::
    ::  keen-do: internal signal, dispatch keen retry with backoff
    ::
    [%keen-do name=[%ta @] ~]
      =/  name=@ta  ta.name.wire
      =/  fp  #/~/keen/[ta/name]
      ?.  (hos:d fp)  cor
      =/  state=@tas  (gut-tas:d (welp fp /state) %loading)
      =/  attempt  (gut-ud:d (welp fp /attempt) 0)
      =/  ship=@p  (got-p:d (welp fp /ship))
      =/  path=pith  (got-pith:d (welp fp /path))
      =/  care=@tas  (gut-tas:d (welp fp /care) %cone)
      =/  case=@ud  (gut-ud:d (welp fp /case) 0)
      =/  cancel=(list card)  (cancel-pending-timer fp %keen-timer ta/name)
      ?+  state  cor
        ::  loading: yawn old keen, re-keen same case
        %loading
          =/  =spur  (build-spur case path care)
          =/  timeout=@da  (add now.quest ~s15)
          =/  old-nonce=@da  (fall (get-da:d (welp fp /keen-nonce)) *@da)
          %-  emil
          %+  welp  cancel
          :~  [%pass #/keen-req/[ta/name]/[da+old-nonce] %arvo %a %yawn ship spur]
              [%hawk /kl (welp fp /state) %ins %loading]
              [%hawk ~ (welp fp /timer-at) %ins da+timeout]
              [%hawk ~ (welp fp /keen-nonce) %ins da+now.quest]
              [%pass #/keen-req/[ta/name]/[da+now.quest] %keen %.n [ship spur]]
              [%pass #/keen-timer/[ta/name]/[da+timeout] %arvo %b %wait timeout]
          ==
        ::  error or timeout: schedule retry with backoff
        ?(%error %timeout)
          (schedule-retry fp %keen-timer ta/name attempt cancel)
      ==
    ::
    ::  mirror-do: internal signal, dispatch keen/timer/retry
    ::
    [%mirror-do name=* ~]
      =/  name=iota  name.wire
      =/  mp  #/~/mirror/[name]
      ?.  (hos:d mp)  cor
      =/  state=@tas  (gut-tas:d (welp mp /state) %loading)
      =/  attempt  (gut-ud:d (welp mp /attempt) 0)
      =/  ship=@p  (got-p:d (welp mp /ship))
      =/  path=pith  (got-pith:d (welp mp /path))
      =/  care=@tas  (gut-tas:d (welp mp /care) %cone)
      =/  cur-case  (gut-ud:d (welp mp /case) 0)
      =/  cancel=(list card)  (cancel-pending-timer mp %mirror-timer name)
      ?+  state  cor
        ::  success or loading: keen the next case
        ?(%success %loading)
          =/  next-case  +(cur-case)
          =/  =spur  (build-spur next-case path care)
          =/  timeout=@da  (add now.quest ~s15)
          ::  yawn in-flight keen if retrying (state was %loading)
          =/  old-nonce=@da  (fall (get-da:d (welp mp /keen-nonce)) *@da)
          =/  yawn=(list card)
            ?.  =(%loading state)  ~
            :~  [%pass #/mirror-keen/[name]/[da+old-nonce] %arvo %a %yawn ship spur]
            ==
          %-  emil
          %+  welp  cancel
          %+  welp  yawn
          :~  [%hawk /ml (welp mp /state) %ins %loading]
              [%hawk ~ (welp mp /timer-at) %ins da+timeout]
              [%hawk ~ (welp mp /keen-nonce) %ins da+now.quest]
              [%pass #/mirror-keen/[name]/[da+now.quest] %keen %.n [ship spur]]
              [%pass #/mirror-timer/[name]/[da+timeout] %arvo %b %wait timeout]
          ==
        ::  error or timeout: schedule retry with backoff
        ?(%error %timeout)
          (schedule-retry mp %mirror-timer name attempt cancel)
      ==
  ==
--
