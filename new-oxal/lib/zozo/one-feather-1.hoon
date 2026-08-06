::  one-feather-1: batteries-included view adapter
::
::    converts a feather-1-core into a mantis-core, providing
::    HTTP routing, session management, SPA navigation,
::    and crash-safe rendering.
::
::    SSE lifecycle (keepalive) is handled by mantis automatically.
::    feather-1 emits head/body/close on /o/eyre/[rid] for responses.
::
::    the user writes these arms:
::      ++title  tape         page title
::      ++get    manx         render the page for a given stem+query
::      ++post   body ->      handle form submission; return optional
::                            redirect and list of data writes
::      ++on                  mantis mutation function (but never triggers for http plumbing)
::
::    it is built atop mantis so that it may use the same structure of io
::    for non-http events.
::
::    except for http responses, effects are emitted the same ways as mantis.
::
::    framework state lives under #/~ in the data tree:
::
::      #/~/meta/our           ship identity
::      #/~/meta/here          view location in the namespace
::      #/~/eyre/[rid]/*       http sessions (method, headers, body, query, line)
::      #/~/session/[rid]/*    session stem+query
::      #/~/sse/[rid]/session  ta+session-rid (sse->session mapping)
::      #/~/sse/[rid]/seq      ud+seq (body sequence counter)
::
::     this code will emit http responses (including sse) by doing writes under #/~/eyre/[rid]/*
::
::     the purpose of this framework is to allow the backend to control the
::     location and contents of a browser tab with an SSE connection.
::
::   the get arm renders the correct data for a given stem, the post arm
::   responds to forms.
::
::   there should be javascript on the page which changes how POST forms submit.
::   it should not trigger a refresh, because i want the page to change from
::   the SSE connection sending down datastar.js commands to update the content and url.
::
::   the advantage of this is that users get live updating for free!
::   they can think in terms of simple get/post, but their UIs will
::   be reactive to backend changes automatically.
::
::   and these small little files will be able to write simple, powerful, and responsive apps easily.
::
::   all feather-1 apps will use the feather style.css stylesheet.
::
/+  *zozo-one
::
::  convert feather-1-core to mantis-core
::
|=  =feather-1-core
^-  mantis-core
::
::  mantis gate: process a move against the file, produce changes
::
|=  [=prov =move =file]
^-  (list ^move)
%.  ~
|_  out=(list ^move)
::
::::  accumulator helpers
::
+*  cor   .                                             ::  self reference
    d     ~(. do data.file)                             ::  data engine door
++  abet  (flop out)                                    ::  finalize: reverse output list
++  emit  |=  =^move  cor(out [move out])               ::  emit one move
++  emil  |=  moves=(list ^move)  cor(out (welp (flop moves) out))
::
++  get-session-rid
  |=  [rid=@ta =query]
  ^-  @ta
  %-  fall  :_  rid
  %-  mole  |.
  ^-  @ta
  (crip (~(gut by (malt query)) 'session' ""))
::
::
::  response helpers: emit head/body/close pattern
::
::  html-response: one-shot HTML response (page load, navigate, error)
::
++  html-response
  |=  [rid=@ta page=manx]
  ^+  cor
  =/  html-text=@t
    %-  crip
    :-  '<!DOCTYPE html>'
    (en-xml:html page)
  =/  =octs  (as-octs:mimes:html html-text)
  %-  emil
  :~
    ::  head
    :*
      #/o/eyre/[ta/rid]
      #/~/eyre/[ta/rid]/head
      %ins
      %data
      %-  ~(gep do *data)
      :~  :-  /status  (mono ud+200)
          :-  /headers
            %-  ~(gas do *data)
            :~  :-  #/[t/'content-type']  t+'text/html'
            ==
      ==
    ==
  ::
    ::  body
    :*  #/o/eyre/[ta/rid]
        #/~/eyre/[ta/rid]/[ud+0]
        %ins
        mime+[/text/html octs]
    ==
  ::
    ::  close signal
    :*  #/o/eyre/[ta/rid]
        #/~/eyre/[ta/rid]/close
        %ins
        %close
    ==
  ==
::
::  sse-head: open SSE connection (mantis auto-starts keepalive)
::
++  sse-head
  |=  rid=@ta
  ^+  cor
  %-  emit
  :*
    #/o/eyre/[ta/rid]
    #/~/eyre/[ta/rid]/head
    %ins
    :-  %data
    %-  ~(gep do *data)
    :~  /status^(mono ud+200)
        :-  /headers
        %-  ~(gas do *data)
        :~  #/[t/'content-type']^t+'text/event-stream'
            #/[t/'cache-control']^t+'no-cache'
            #/[t/'connection']^t+'keep-alive'
        ==
    ==
  ==
::
::  sse-body: send SSE event body with auto-incrementing seq
::
++  sse-body
  |=  [rid=@ta event-text=@t]
  ^+  cor
  =/  seq=@ud  (gut-ud:d #/~/sse/[ta/rid]/seq 0)
  =.  cor  (emit ~ #/~/sse/[ta/rid]/seq %ins ud++(seq))
  =/  =octs  (as-octs:mimes:html event-text)
  (emit #/o/eyre/[ta/rid] #/~/eyre/[ta/rid]/[ud+seq] %ins mime+[/text/event-stream octs])
::
::  main routing
::
++  $
  =<  abet
  =/  wir  ((pole iota) wire.move)
  ::
  ::  external changes trigger refresh
  ::
  ?:  ?|  ?=  %.n  -.prov
          ?=  ^    p.prov
      ==
    on-other
  =>   .(prov `^prov`prov)
  ::
  ?+    wir
      ::
      ::  unrecognized wire: delegate to ++on:feather-1-core
      ::
      on-other
    ::
    [~]  cor  ::  no-op
    [%refresh ~]  (refresh ~)
    ::
    [%i %eyre rid=[%ta @] ~]
      ?:  ?=([%lop ~] action.move)
        (cancel-http ta.rid.wir)
      (on-http ta.rid.wir)
  ==
::
::  HTTP request routing
::
++  on-http
  |=  rid=@ta
  ^+  cor
  =/  req  (got-data:d #/~/eyre/[ta/rid])
  =/  rd  ~(. do req)
  =/  method   (gut-tas:rd /method %$)
  =/  =stem    (gut-pith:rd /line /)
  =/  =query
    %+  turn  kid-list:(dit:rd /query)
    |=  [=iota =data]
    ?>  ?=([%t @] iota)
    :-  t.iota
    (print-node (fall leaf.data t+''))
  =/  headers=data  (dip:rd /headers)
  =/  has-datastar=?
    ?|  .=  `'true'
        ?~  leaf.headers  ~
        leaf:(~(dip do headers) #/[t/'datastar-request'])
    ::
        !=('' (git-t:(dit:rd /query) #/[t/'datastar']))
    ==
  =/  session-param=@t
    (git-t:(dit:rd /query) #/[t/'session'])
  ::
  ?:  =(%'POST' method)
    (handle-post rid stem query)
  ::
  ?:  =(%'GET' method)
    ::  GET without datastar header
    ::
    ?.  has-datastar
      ?:  =('' session-param)
        (initial-get rid stem query)
      (navigate rid stem query)
    ::  GET with datastar header = SSE connect
    ::
    (sse-connect rid stem query)
  ::
  cor
::
::  initial-get: first page load
::
++  initial-get
  |=  [rid=@ta =stem =query]
  ^+  cor
  ::
  ::  persist metadata
  ::
  =/  req  (got-data:d #/~/eyre/[ta/rid])
  =/  rd  ~(. do req)
  =/  our-node=node   (gut:rd /our p+~zod)
  =/  here-node=node  (gut:rd /here pith+/)
  =/  now-node=node   (gut:rd /now da+*@da)
  =.  cor  (emit ~ #/~/meta/our %ins our-node)
  =.  cor  (emit ~ #/~/meta/here %ins here-node)
  =.  cor  (emit ~ #/~/meta/now %ins now-node)
  ::
  ::  store session
  ::
  =.  cor  (emit ~ #/~/session/[ta/rid]/stem %ins pith+stem)
  =.  cor  (emit ~ #/~/session/[ta/rid]/query %ins [%data (query-to-data query)])
  ::
  ::
  ::  extract our and src
  ::
  =/  our=@p  ?>(?=([%p @] our-node) p.our-node)
  =/  src=@p  (gut-p:rd /src ~zod)
  ::
  ::  call get:feather-1-core in mule
  ::
  =/  result=(each node tang)
    (mule |.(~!(*node (get:feather-1-core our src data.file stem query))))
  ::
  ::  build page
  ::
  =/  here=pith  ?>(?=([%pith *] here-node) pith.here-node)
  =/  view-path=tape  (pate [%oxal here])
  =/  stem-path=tape  ?~(stem "" (pate stem))
  =/  sse-url=tape
    "{view-path}{stem-path}/?session={(trip rid)}"
  ::
  =/  rendered=manx  (build-ui =(our src) result)
  ::
  =/  page=manx
    ;html
      ;head
        ;title: {(title:feather-1-core here data.file)}
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
        ;script(type "module", src "/hawk-init/feather/1/text-editor");
        ;script(type "module", src "/hawk-init/feather/1/textarea");
        ;script(type "module", src "/hawk-init/feather/1/datastar-new");
        :: ;script(type "module", src "/hawk-init/feather/1/datastar-inspector");
        ;base(href "{view-path}{stem-path}/");
      ==
      ;body
        =rid  (trip rid)
        =data-init  "@get('{sse-url}');"
        ;div(id "url-sync");
        ;+  rendered
        ;script
          ;+  ;/  %-  trip
          '''
          document.addEventListener('submit', evt => {
            const form = evt.target;
            if (form.tagName !== 'FORM') return;
            if ((form.method || '').toUpperCase() !== 'POST') return;
            evt.preventDefault();
            form.classList.add('is-loading');
            const fd = new FormData(form);
            const base = document.querySelector('base')?.href || window.location.href;
            const url = new URL(form.action || window.location.href, base);
            url.searchParams.set('session', document.body.getAttribute('rid'));
            fetch(url.toString(), { method: 'POST', body: new URLSearchParams(fd) })
              .then(() => { form.dispatchEvent(new CustomEvent('post-complete')); });
          });
          document.addEventListener('click', evt => {
            const a = evt.target.closest('a[href]');
            if (!a) return;
            const href = a.getAttribute('href');
            if (!href || href.startsWith('http') || href.startsWith('//')) return;
            evt.preventDefault();
            const base = document.querySelector('base')?.href || window.location.href;
            const url = new URL(href, base);
            const sseUrl = url.pathname + url.search + (url.search ? '&' : '?') + 'session=' + document.body.getAttribute('rid');
            fetch(sseUrl);
          });
          window.addEventListener('popstate', () => {
            const url = new URL(window.location.href);
            const sseUrl = url.pathname + url.search + (url.search ? '&' : '?') + 'session=' + document.body.getAttribute('rid');
            fetch(sseUrl);
          });
          '''
        ==
      ==
    ==
  ::
  (html-response rid page)
::
::  navigate: SPA navigation via fetch (session already exists)
::
++  navigate
  |=  [rid=@ta =stem =query]
  ^+  cor
  =/  session-rid=@ta  (get-session-rid rid query)
  ::
  ::  update session stem/query
  ::
  =.  cor  (emit ~ #/~/session/[ta/session-rid]/stem %ins pith+stem)
  ::  strip 'session' param before storing (framework-only param)
  =/  clean-query=^query  (skip query |=([k=@t v=tape] =(k 'session')))
  =.  cor  (emit ~ #/~/session/[ta/session-rid]/query %ins [%data (query-to-data clean-query)])
  ::
  =.  cor  (html-response rid ;html;)
  (emit #/refresh #/~/refresh %ins ud+0)
::
::  sse-connect: datastar SSE connection
::
++  sse-connect
  |=  [rid=@ta =stem =query]
  ^+  cor
  =/  session-rid=@ta  (get-session-rid rid query)
  ::
  ::  store SSE -> session mapping
  ::
  =.  cor  (emit ~ #/~/sse/[ta/rid]/session %ins ta+session-rid)
  ::
  ::  open SSE connection and send initial comment
  ::
  =.  cor  (sse-head rid)
  (sse-body rid ': connected\0a\0a')
::
::  handle-post: process form submission
::
++  handle-post
  |=  [rid=@ta =stem =query]
  ^+  cor
  ::
  =/  req  (got-data:d #/~/eyre/[ta/rid])
  =/  rd  ~(. do req)
  =/  =body  (dip:rd /body)
  ::
  ::  extract our and src
  ::
  =/  our=@p  (gut-p:d #/~/meta/our ~zod)
  =/  src=@p  (gut-p:rd /src ~zod)
  ::
  ::  call post:feather-1-core in mule
  ::
  =/  result=(each [(unit [^stem ^query]) (list ^move)] tang)
    (mule |.(~!(*([(unit [^stem ^query]) (list ^move)]) (post:feather-1-core our src data.file stem query body))))
  ::
  ::  on crash: emit error page response
  ::
  ?:  ?=  %.n  -.result
    =/  err=manx
      ;div.p5.pb15.fc.g5.mono
        ;div: post crash
        ;+  (render-tang p.result)
      ==
    (html-response rid err)
  ::
  =/  [redirect=(unit [=^stem =^query]) moves=(list ^move)]  p.result
  ::
  ::  emit data changes from user
  ::
  =.  cor  (emil moves)
  =/  session-rid=@ta  (get-session-rid rid query)
  ::
  ::  if redirect, update session stem/query
  ::
  =?  cor  ?=(^ redirect)
    =.  cor  (emit ~ #/~/session/[ta/session-rid]/stem %ins pith+stem.u.redirect)
    (emit ~ #/~/session/[ta/session-rid]/query %ins [%data (query-to-data query.u.redirect)])
  ::
  ::  emit minimal response
  ::
  =.  cor  (html-response rid ;html;)
  ::
  ::  signal refresh for all SSE connections
  ::
  (emit #/refresh #/~/refresh %ins ud+0)
::
::  cancel-http: client disconnected
::
++  cancel-http
  |=  rid=@ta
  ^+  cor
  ?~  (get:d #/~/sse/[ta/rid]/session)  cor
  (emit ~ #/~/sse/[ta/rid] %lop ~)
::
::
::  on-other: non-HTTP events
::
++  on-other
  ^+  cor
  ::
  ::  call on:feather-1-core in mule
  ::
  =/  result=(each (list ^move) tang)
    (mule |.(~!(*((list ^move)) (on:feather-1-core prov move file))))
  ::
  ?:  ?=  %.n  -.result
    %-  (slog 'feather-1-on-crash' p.result)
    cor
  ::
  ::  wrap returned moves as changes
  ::
  =.  cor  (emil p.result)
  ::
  ::  signal refresh for all SSE connections
  ::
  (emit #/refresh #/~/refresh %ins ud+0)
::
::  render-to-sse: render and emit SSE for one connection
::
++  build-ui
  |=  [admin=? result=(each node tang)]
  ^-  manx
  ;div.wf.hf.fc
    =id  "feather-tippy-top"
    ;+  ?.  admin  ;div;
    ;div.fixed.bottom0.left0.z2
      ;button.p-2.b3.hover.btrr5.bdt2.bdr2.bc4
        =data-on_click  "$_debug = !$_debug"
        =data-class_toggled  "$_debug"
        =data-class_o3  "!$_debug"
        ; ⚙
      ==
    ==
    ;+  ?.  admin  ;div;
    ;div.z1.fixed.bottom0.left0.o7.b0.br2.bd2.bold.scroll-none.fc
      =style  "height: 50%; width: 80%;"
      =data-show  "$_debug"
      =style  hid
      ;div.grow.scroll-y
        ;+  (render-data-with-signals 'debug' (~(dip do data.file) #/~))
        ;div.pb20;
      ==
    ==
    ;+
      ?:  ?=  %.n  -.result
        ;div.p5.pb15.fc.g5.mono
          ;div: crash
          ;+  (render-tang p.result)
        ==
      (node-to-manx p.result)
  ==
++  render-to-sse
  |=  [sse-rid=@ta session-stem=stem session-query=query]
  ^+  cor
  =/  our=@p  (gut-p:d #/~/meta/our ~zod)
  =/  src=@p
    =/  req  (fall (get-data:d #/~/eyre/[ta/sse-rid]) (dip:d #/~/eyre/[ta/sse-rid]))
    (~(gut-p do req) /src ~zod)
  ::  render
  =/  result=(each node tang)
    (mule |.(~!(*node (get:feather-1-core our src data.file session-stem session-query))))
  =/  rendered=manx  (build-ui =(our src) result)
  ::  build and emit SSE
  =/  here=pith  (gut-pith:d #/~/meta/here /)
  =/  view-path=tape  (pate [%oxal here])
  =/  stem-path=tape  ?~(session-stem "" (pate session-stem))
  =/  qs=tape
    ?~  session-query  ""
    %+  welp  "?"
    %-  zing
    %+  join  "&"
    %+  turn  session-query
    |=  [k=@t v=tape]
    "{(trip k)}={v}"
  =/  target=tape  "{view-path}{stem-path}/{qs}"
  =/  sse-text=cord
    %+  datastar-response-body  ~
    ^-  (list datastar-fragment)
    :~  ["outer" ~ rendered]
        ["replace" `"base" ;base(href "{view-path}{stem-path}/");]
        :-  "outer"
        :-  `"#url-sync"
        ;div(id "url-sync", data-init "if(location.pathname+location.search!=='{target}')history.pushState(null,'','{target}')");
    ==
  (sse-body sse-rid sse-text)
::
::  refresh: render-to-sse for all (or filtered) connections
::
++  refresh
  |=  filter=(unit @ta)
  ^+  cor
  =/  sses  kid-list:(dit:d #/~/sse)
  |-
  ?~  sses  cor
  =/  [=iota =data]  i.sses
  ?>  ?=([%ta @] iota)
  =/  sse-rid=@ta  ta.iota
  =/  session-rid=@ta  (gut-ta:d #/~/sse/[ta/sse-rid]/session *@ta)
  ?.  ?|(?=(~ filter) =(u.filter session-rid))
    $(sses t.sses)
  =/  session-stem=stem  (gut-pith:d #/~/session/[ta/session-rid]/stem /)
  =/  session-query=query
    =/  qp  #/~/session/[ta/session-rid]/query
    (data-to-query (fall (get-data:d qp) (dip:d qp)))
  =.  cor  (render-to-sse sse-rid session-stem session-query)
  $(sses t.sses)
::
::  helpers
::
++  node-to-manx
  |=  =node
  ^-  manx
  %+  add-attribute  id+"feather-top"
  ?+    node  ;div: {(print-node node)}
    [%manx *]  manx.node
    [%tang *]  (render-tang tang.node)
    [%json *]  ;pre: {(trip (en:json:html json.node))}
  ==
::
++  query-to-data
  |=  =query
  ^-  data
  %-  ~(gas do *data)
  %+  turn  query
  |=  [k=@t v=tape]
  :-  #/[t/k]  t+(crip v)
::
++  data-to-query
  |=  =data
  ^-  query
  %+  turn  ~(kid-list do data)
  |=  [=iota d=^data]
  ?>  ?=([%t @] iota)
  :-  t.iota
  (print-node (fall leaf.d t+''))
::
++  dit
  |=  =pith
  ~(. do (dip:d pith))
--
