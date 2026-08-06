::  home: the admin UI and homepage for hawk
::
::    a raw-core view that provides the main data tree browser,
::    session management, SSE live updates, and all admin actions
::    (create, edit, delete, import/export, install/uninstall views).
::
::    uses datastar for reactive UI updates via SSE.
::
::    xx import-both is broken
::
!:
=/  debug=?  %.n
=>  |%
::  views whose source cannot be edited in the UI (edit in clay instead)
    ++  locked
      ^-  (list pith)
      :~  /
          /notepad
          /rss
          /docs
          /blog
      ==
    ++  is-locked
      |=  gaze=pith
      ^-  ?
      %+  lien  locked
      |=  b=pith
      ?~  b  =(b gaze)
      (~(is-ancestor th gaze) b)
    ::
    --
=;  machine
::
:-  %raw
^-  raw-core
|%
++  on-arvo
  |=  [=wire =sign-arvo =quest =file]
  ^-  (list change)
  out-change:(~(on-arvo machine quest file ~) wire sign-arvo)
::
++  on-http
  |=  [=http-req =quest =file]
  ^-  (list change)
  out-change:(~(on-http machine quest file ~) http-req)
::
++  cancel-http 
  |=  [rid=@ta =stem =quest =file]
  ^-  (list change)
  out-change:(~(cancel-http machine quest file ~) rid stem)
::
++  on-crash
  |=  [=tang =change =quest =file]
  out-change:(~(on-crash machine quest file ~) tang change)
::
++  on-change
  |=  [=prov =move =quest =file]
  ^-  (list card)
  out:(~(on-change machine quest file ~) prov move)
--
::
::
::  machine: the door that holds state and processes events
::
|_  [=quest =file cards=(list card)]
+*  f  ~(. fe file)                                       ::  file engine
    d  ~(. do data.file)                                   ::  data engine
    ui  (~(dit do data.file) #/~/ui)                       ::  UI state subtree
++  cor   .
++  out   (flop cards)                                     ::  finalize all cards
++  out-change                                             ::  finalize %hawk cards only
  %-  flop
  ^-  (list change)
  %+  murn  cards
  |=  =card
  ^-  (unit change)
  ?:  ?=  [%hawk *]  card  `card
  ~
::
++  abet  :-  (flop cards)  file                           ::  finalize cards+file
++  emit  |=  =card  cor(cards [card cards])               ::  emit one card
++  emil  |=  caz=(list card)  cor(cards (welp (flop caz) cards))
::
::
::::  SSE session management
::
::  send keepalive pings to all active SSE connections
++  give-sse-keep-alives
  ^-  [num-conn=@ _cor]
  =/  conns  kid-list:(dit:d #/~/sse/session)
  :-  (lent conns)
  ~?  debug  send-keep-alives+(lent conns)
  =|  out=(list card)
  |-
  ?~  conns  (emil out)
  =/  [=node *]  i.conns
  ?.  ?=([%ta *] node)
    $(conns t.conns)
  =/  rid  ta.node
  =.  out  [(sse-keep-alive rid) out]
  $(conns t.conns)
::
::  check and schedule the next heartbeat timer
++  pulse
  ~?  debug  %pulse
  =/  last=@da  (gut-da:d #/~/sse/heartbeat now.quest)
  ?:  (gth last now.quest)  cor
  =/  next=@da  (add now.quest sse-keep-alive-interval)
  =.  cards  :_  cards
    :*  %hawk  /set-heartbeat
      #/~/sse/heartbeat  %ins
      da+next
    ==
  cor
::
::  re-render all active SSE sessions and push updates.
::  caches renders by session id to avoid duplicate work.
++  rebuild-sessions
  ^+  cor
  =/  sses  kid-list:(dit:d #/~/sse/session)
  ~?  debug  rebuild-ui+(lent sses)
  =|  out=(list card)
  ::
  :: so we don't have to recompute the same thing twice
  :: if it's open in multiple tabs
  ::
  =|  cash=(map sid=term manx)
  |-
  ?~  sses  (emil out)
  =/  [=node =data]  i.sses
  =/  rid=@ta
    ?>  ?=  [%ta @]  node
    ta.node
  =/  sid=@tas  (~(got-tas do data) /)
  =?  cash  !(~(has by cash) sid)
    %+  ~(put by cash)  sid
    (render / (get-session sid))
  =.  out  :_  out
    %^  datastar-sse  rid  ~
    :~
      :+  "outer"  `"#main"  (~(got by cash) sid)
    ==
  $(sses t.sses)
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^+  cor
  ?+  route=((pole iota) wire)
      ~&  >>>  unhandled-on-arvo/route
      cor
    [[%n ~] %heartbeat ~]  pulse
    ::
    [%cancel-keen rest=*]
      =/  =stem  rest.route
      ?~  puth=(get-pith:d stem)  cor  :: XX time should have been canceled
      =/  =pith  u.puth
      %-  emit
      [%hawk /keen-cancel stem %ins pith+[%unknown (tail pith)]]
    ::
    [%keen rest=*]
      ?>  ?=([%ames %sage *] sign-arvo)
      =/  =sage:mess:ames  sage.sign-arvo
      =/  stem  rest.route
      %-  emil
      =-
        :~
          [%hawk /keen-rep stem %ins [%data -]]
        ==
      ?~  q.sage
        (~(put do *data) / %empty)
      ?~  dut=((soft data) q.q.sage)
        (~(put do *data) / %not-data)
      u.dut
  ==
::
++  on-crash
  |=  [=tang %hawk =wire =stem =action] 
  ^+  cor
  ~&  %home-crash
  ?:  ?&
        ?=  %install  -.action
        ?=  [%http [%ta @] @ *]  wire
      ==
    =/  rid=@ta  +13:wire
    =/  sid=@tas  +14.wire
    ~&  install-error/[rid sid]
    %-  emit
    [%hawk #/crash/[ta/rid] (welp #/~/ui/[sid]/install-error stem) %ins tang+tang]
  ~_  (collapse-tang tang)
  ~|  %wtf-unhandled
  ~|  wire/wire
  ~|  stem/stem
  ~|  -.action
  !!
::
::
::::  change handler
::
++  on-change
  |=  [=prov =wire =stem =action]
  ^+  cor
  ::
  ::  change is not from us, just rebuild
  ::
  ?:  ?|  ?=  %.n  -.prov
          ?=  ^    p.prov
      ==
    =.  cor  rebuild-sessions
    cor
  ::
  =/  stem  `pith`stem
  ?+    route=((pole iota) wire)
      ~|  unknown-route/[(pate route) (pate stem) <-.action>]
      !!
    ::
    [%no-op rest=*]
      cor
    ::
    [%keen-cancel rest=*]
      rebuild-sessions
    ::
    [%keen-rep rest=*]
      rebuild-sessions
    ::
    [%crash rid=[%ta @] ~]
      =.  cor  rebuild-sessions
      ~&  home-crash-on-change/rid.route
      %-  emil
      (empty-payload-cards ta.rid.route)
    ::
    [%set-heartbeat ~]
      =^  num-connections=@  cor  give-sse-keep-alives
      ?:  =(0 num-connections)  cor
      %-  emit
      [%pass #/~/heartbeat %arvo %b %wait (got-da:d #/~/sse/heartbeat)]
    ::
    [%http rid=[%ta @] sid=@tas han=*]
      =/  rid  ta.rid.route
      ?+    han=((pole iota) han.route)
          ~|  unknown-http-handler/(pate han)
          !!
        ::
        [~]  cor  :: no-op
        ::
        [%login rest=*]
          %-  emil
          %+  payload-cards  rid
          %+  redirect-payload  307
          (~(as-cord href #/~/login ~) / ["redirect" (pate (welp #/oxal rest.han))] ~)
        ::
        [%static rest=*]
          =/  sid=@tas  (gut-tas:d #/~/ui/current-session %default)
          %-  emil
          %+  html-payload-cards  rid
          %+  wrap  "oxal"  (render / (get-session sid))
        ::
        [%export where=*]
          =/  where=pith  where.han
          %-  emil
          %^    resource-payload-cards
              rid  ~
          :-  'application/hawk'
          %-  jam
          :-
            %+  murn  tap:d:(dit:f where)
            |=  [=pith =node]
            ?^  (find #/~ pith)  ~  :: don't export #/~ namespaces
            `[pith node]
          ~
        ::
        [%mime where=*]
          =/  where=pith  where.han
          =/  =mime
            %+  ~(gut-mime do data.file)  where
            :-  /text/plain  [4 'none']
          =/  ct  (crip +:(spud p.mime))
          %-  emil
          %^  resource-payload-cards  rid  ~
          [ct q.q.mime]
        ::
        [%bounce rest=*]
          ?+    line=((pole iota) rest.han)
              ::
              ::  fallback
              ::
              %-  emil
              %+  payload-cards  rid
              %^  feather-1-payload  "not found"
                ~
              ;div.wf.hf.fc.ac.jc.g3
                ;div: not found
                ;div: {(pate rest.han)}
                ;div: go away
              ==
            ::
            [[%n ~] %manifest ~]
              %-  emil
              %^    resource-payload-cards
                  rid
                ~
              :-  'application/json'
              '''
              {
                "name": "hawk",
                "short_name": "hawk",
                "description": "programmable interface",
                "start_url": "/oxal/~/pwa/",
                "scope": "/oxal/~/pwa/",
                "display": "standalone",
                "id": "/oxal/~/pwa/",
                "background_color": "#000000",
                "categories": ["productivity", "developer"],
                "theme_color": "#000000",
                "icons": [
                  {
                    "src": "https://nyc3.digitaloceanspaces.com/drain/hawk-assets/2024.2.09..14.26.28-hawk.png",
                    "sizes": "256x256",
                    "type": "image/png",
                    "purpose": "maskable"
                  },
                  {
                    "src": "https://nyc3.digitaloceanspaces.com/drain/hawk-assets/2024.2.09..14.26.28-hawk.png",
                    "sizes": "256x256",
                    "type": "image/png",
                    "purpose": "any"
                  }
                ]
              }
              '''
            ::
          ==
        ::
        [%open-connection ~]   (emit (sse-open rid))
        [%close-connection ~]  cor
        ::
        [%refresh ~]
          =.  cor  rebuild-sessions
          %-  emil
          (empty-payload-cards rid)
        ::
        [%keen *]
          =/  keen  ((pole iota) (got-pith:d stem))
          ?>  ?=  [%loading shi=[%p @p] cas=[%ud @ud] car=@tas spu=*]  keen
          =/  =spur
            :*  %g  %x  (scot %ud ud.cas.keen)  %oxal
                %$  (scot %ud 1)
                (pout (welp spu.keen #/[car.keen]))
            ==
          =.  cor  rebuild-sessions
          %-  emil
          :-  [%pass [%keen stem] %keen %.n [p.shi.keen spur]]
          :-  [%pass [%cancel-keen stem] %arvo %b %wait (add now.quest ~s10)]
          (empty-payload-cards rid)
        ::
        [%bind were=*]
          %-  emil
          (empty-payload-cards rid)
      ==
    ::
  ==
::
++  is-stem-visible
  =|  pax=pith
  |=  [sid=@tas =stem]
  ^-  ?
  =/  zoom=pith  (~(gut-pith do data.file) #/~/ui/[sid] /)
  =/  opens
    %-  ~(dip do data.file)
    (welp #/~/ui/[sid]/open-kids zoom)
  |-
  ?~  stem  %.y
  ?~  pax
    ::
    ::  the first segment after the zoom
    ::  is always considered open
    ::
    %=  $
      pax    (snoc `pith`pax i.stem)
      stem   t.stem
      opens  (~(dip do opens) #/[i.stem])
    ==
  ?.  (~(gut-f do opens) / |)  %.n
  %=  $
    pax    (snoc pax i.stem)
    stem   t.stem
    opens  (~(dip do opens) #/[i.stem])
  ==
::
++  current-sessions
  ^-  (set @tas)
  %-  silt
  %+  turn  kid-list:(~(dit do data.file) #/~/sse/session)
  |=  [rid=node =data]
  (~(got-tas do data) /)
::
++  cancel-http
  |=  [rid=@ta stem]
  ^+  cor
  ?~  (get:d #/~/sse/session/[ta/rid])  cor
  ~?  debug  [%sse-cleanup rid]
  %-  emil
  :~
    [%hawk #/http/[ta/rid]/close-connection #/~/sse/session/[ta/rid] %lop ~]
  ==
::
::
::::  HTTP request handler
::
::  XX catch crashes and display error in the correct spot
++  on-http
  |=  =http-req
  ^+  cor
  =*  r  ~(. req quest http-req)
  =/  signals  signals.r
  =*  s  ~(. by signals)
  =*  b  ~(. by form-encoded-body:r)
  =*  p  ~(. by pams.http-req)
  ::
  =/  rid  rid.http-req
  ::
  ::
  ::  where: action location
  ::
  =/  where=pith
    %-  fall  :_  /
    %-  mole  |.
    (cord-to-pith (got:p 'where'))
  ::
  ::  sid: session-id
  ::
  =/  sid=@tas  (gut:p 'session' 'default')
  =/  haxn
    |=  [=wire =stem =action]
    [%hawk (welp #/http/[ta/rid]/[sid] wire) stem action]
  =/  bounce  |.
    %-  emit
    [%hawk (welp #/http/[ta/rid]/[sid]/bounce stem.http-req) #/~/bounce %del ~]
  ::
  =*  h  ~(. href [%oxal here.quest] ["session" (trip sid)]~)
  ::
  ::
  =*  render-args  |.  [where (get-session sid)]
  ::
  ::  get value from body or query if not in body
  ::
  =/  val
    |=  key=@t
    %+  gut:b  key
    ?^  x=(get:p key)  u.x
    ~|  no-request-key/key
    !!
  ::
  |^
    ?:  is-datastar:r
      datastar-routes
    static-routes
  ::
::  static-routes: non-datastar requests (full page loads, exports, imports)
  ++  static-routes
    ^+  cor
    ?+    route=((pole iota) route.r)  ~|(not-found-static/(pout route) !!)
      ::
      [%get * %$ [%n ~] %manifest ~]  $:bounce
      ::
      [%get [%f %.n] *]
        %-  emit
        [%hawk (welp #/http/[ta/rid]/[sid]/login where) #/~ %del ~]
      ::
      [%get [%f %.y] %export *]
        %-  emit
        [%hawk (welp #/http/[ta/rid]/[sid]/export where) #/~ %del ~]
      ::
      [%post [%f %.y] %import-data *]
        =/  dat=@  +:(need body.http-req)
        =/  hue  (cue dat)
        =/  =bonds  (bonds -.hue)
        %-  %-  slog
            :-  'oxal: import data'
            %+  turn  bonds
            |=  [=pith =node]
            leaf+"{(pate pith)}  {(print-aura node)}"
        =/  new  (~(gas do *data) bonds)
        ::
        %-  emit
        %^  haxn  /refresh
          where
        [%ins [%data new]]
      ::
      [%post [%f %.y] %import-both *]
        =/  dat=@  +:(need body.http-req)
        =/  hue  (cue dat)
        =/  =bonds  (bonds -.hue)
        ::
        %-  (slog %import-code-and-data ~)
        ::
        %-  emil
        :-  [%hawk /import-data where %ins [%data (~(gas do *data) bonds)]]
        %+  welp
          ^-  (list card)
          %+  murn
            %-  (list (pair pith *))
            +.hue
          |=  [pax=pith x=*]
          ~
        %+  redirect:r  303
        (as-cord:h / ~)
      ::
      ::
      [%post [%f %.y] %upload-mime *]
        =/  =mite  content-type-mite:r
        =/  =octs  (need body.http-req)
        =/  =node  [%mime mite octs]
        %-  emil
        :~  %^  haxn  /refresh
              where
            [%ins node]
        ==
      ::
      [%get [%f %.y] %mime ~]
        %-  emit
        [%hawk (welp #/http/[ta/rid]/[sid]/mime where) #/~ %del ~]
      ::
      ::
      ::  PWA hack
      ::
      [%get [%f %.y] %$ [%n ~] %pwa ~]
        %-  emit
        [%hawk #/http/[ta/rid]/[sid]/static #/~/ui/current-session %ins sid]
      ::
      [%get [%f %.y] %$ ~]
        %-  emit
        [%hawk #/http/[ta/rid]/[sid]/static #/~/ui/current-session %ins sid]
      ::
      [%get [%f %.y] %$ *]  $:bounce
    ==
  ::
::  datastar-routes: SSE/reactive UI requests (open connection,
  ::  tree manipulation, navigation, install/uninstall, etc.)
  ++  datastar-routes
    ^+  cor
    ?+    route=((pole iota) route.r)
        ~|  not-found-dynamic/(pout route)
        !!
      ::
      [%get [%f %.y] %open-connection ~]
        =.  cor
          %-  emit
          %^  haxn  /open-connection
            #/~/sse/session/[ta/rid]
          [%ins sid]
        pulse
      ::
      [%post [%f %.y] %set-ui ~]
        =/  key=@tas  (val 'key')
        =/  val=node  (cord-to-node (val 'val'))
        %-  emit
        %^  haxn  /refresh
          (welp #/~/ui/[sid]/[key] where)
        [%ins val]
      ::
      [%post [%f %.y] %set-ui-global ~]
        =/  key=@tas  (val 'key')
        =/  val=node  (cord-to-node (val 'val'))
        %-  emit
        %^  haxn  /refresh
          #/~/ui/[sid]/[key]
        [%ins val]
      ::
      ::
      [%post [%f %.y] %unset-ui-global ~]
        =/  key=@tas  (val 'key')
        %-  emit
        %^  haxn  /refresh
          #/~/ui/[sid]/[key]
        [%del ~]
      ::
      [%post [%f %.y] %open-kids ~]
        %-  emit
        %^  haxn  /refresh
          (welp #/~/ui/[sid]/open-kids where)
        [%ins f+%.y]
      ::
      [%post [%f %.y] %close-kids ~]
        %-  emit
        %^  haxn  /refresh
          (welp #/~/ui/[sid]/open-kids where)
        [%ins f+%.n]
      ::
      [%post [%f %.y] %open-node ~]
        %-  emit
        %^  haxn  /refresh
          (welp #/~/ui/[sid]/leaf-mode where)
        [%ins %node]
      ::
      [%post [%f %.y] %close-node ~]
        %-  emit
        %^  haxn  /refresh
          (welp #/~/ui/[sid]/leaf-mode where)
        [%del ~]
      ::
      [%post [%f %.y] %open-view ~]
        %-  emit
        %^  haxn  /refresh
          (welp #/~/ui/[sid]/leaf-mode where)
        [%ins %view]
      ::
      [%post [%f %.y] %close-view ~]
        %-  emit
        %^  haxn  /refresh
          (welp #/~/ui/[sid]/leaf-mode where)
        [%del ~]
      ::
      [%post [%f %.y] %view-mode ~]
        %-  emit
        %^  haxn  /refresh
          (welp #/~/ui/[sid]/view-mode where)
        [%ins (val 'mode')]
      ::
      [%get [%f %.y] %change-zoom ~]
        =/  zoom=pith  (cord-to-pith (val 'zoom'))
        %-  emil
        :~
          %^  haxn  /
            #/~/ui/[sid]/zoom
          [%ins pith+zoom]
        ::
          %^  haxn  /refresh
            #/~/ui/[sid]/cursor
          [%ins pith+[%left zoom]]
        ==
      ::
      [%post [%f %.y] %del *]
        =/  =pith  (cord-to-pith (gut:b 'pith' (gut:p 'pith' '/')))
        %-  emit
        %^  haxn  /refresh
          (welp where pith)
        [%del ~]
      ::
      [%post [%f %.y] %lop *]
        =/  =pith  (cord-to-pith (val 'pith'))
        %-  emit
        %^  haxn  /refresh
          (welp where pith)
        [%lop ~]
      ::
      [%post [%f %.y] %nic *]
        =/  =pith  (cord-to-pith (val 'pith'))
        %-  emit
        %^  haxn  /refresh
          (welp where pith)
        [%nic ~]
      ::
      [%post [%f %.y] %mov *]
        =/  to=pith  (cord-to-pith (got:b 'to'))
        =/  from=pith  (tail (got-pith:ui #/[sid]/cursor))
        %-  emil
        :~  %^  haxn  /         to    [%ins (got:d from)]
            %^  haxn  /refresh  from  [%del ~]
        ==
      ::
      [%post [%f %.y] %cop *]
        =/  to=pith  (cord-to-pith (got:b 'to'))
        =/  sub=data  (dip:d where)
        %-  emit
        %^  haxn  /refresh  to  [%ins [%data sub]]
      ::
      [%post [%f %.y] %hop *]
        =/  to=pith  (cord-to-pith (got:b 'to'))
        =/  =node  (got:d where)
        %-  emil
        :~  %^  haxn  /refresh  to  [%ins node]
            %^  haxn  /refresh  where  [%del ~]
        ==
      ::
      [%post [%f %.y] %dup *]
        =/  to=pith  (cord-to-pith (got:b 'to'))
        =/  =node  (got:d where)
        %-  emit
        %^  haxn  /refresh  to  [%ins node]
      ::
      [%post [%f %.y] %bind *]
        ::
        %-  emit
        %^  haxn  /refresh
          where
        =-  [%bind -]
        =/  =bound  *bound
        %=  bound
          leaf
            ?.  .=  `'on'  (get:b 'leaf-bound')   ~
            :-  ~
            :-
              =+  (gut:b 'leaf-auth' '')
              ?.  ((sane %tas) -)  ~
              ?~  -  ~
              `-
            .=  `'on'  (get:b 'leaf-past')
          kids
            ?.  .=  `'on'  (get:b 'kids-bound')   ~
            :-  ~
            :-
              =+  (gut:b 'kids-auth' '')
              ?.  ((sane %tas) -)  ~
              ?~  -  ~
              `-
            .=  `'on'  (get:b 'kids-past')
          cone
            ?.  .=  `'on'  (get:b 'cone-bound')   ~
            :-  ~
            :-
              =+  (gut:b 'cone-auth' '')
              ?.  ((sane %tas) -)  ~
              ?~  -  ~
              `-
            .=  `'on'  (get:b 'cone-past')
        ==
      ::
      [%post [%f %.y] %keen *]
        =/  =pith      (cord-to-pith (got:b 'pith'))
        =/  ship=@p    (slav %p (got:b 'ship'))
        =/  cas        (slav %ud (got:b 'case'))
        =/  spu        (cord-to-pith (got:b 'spur'))
        =/  car=@tas   (got:b 'care')
        %-  emit
        %^  haxn  (welp #/keen where)
          (welp where pith)
        [%ins pith+(welp #/loading/[p/ship]/[ud/cas]/[car] spu)]
      ::
      [%post [%f %.y] %sprout rest=*]
        %-  emil
        :~
          [%hawk /no-op/open-editor (welp #/~/ui/[sid]/editor where) %ins f+&]
          [%hawk /no-op/open-editor (welp #/~/ui/[sid]/kids where) %ins f+&]
          [%hawk /no-op/open-view #/~/ui/[sid]/open-view %ins pith+where]
        ::
          %^  haxn  /refresh
            where
          [%install default-view]
        ==
      ::
      [%post [%f %.y] %clear-install-error rest=*]
        %-  emit
        %^  haxn  /refresh
          (welp #/~/ui/[sid]/install-error where)
        [%del ~]
      ::
      [%post [%f %.y] %install rest=*]
        =/  source  (got:b 'code')
        %-  emil
        :~
          [%hawk /no-op/clear-install-error (welp #/~/ui/[sid]/install-error where) %del ~]
        ::
          %^  haxn  /refresh
            where
          [%install source]
        ==
      ::
      [%post [%f %.y] %uninstall rest=*]
        ~&  uninstall/where
        %-  emit
        %^  haxn  /refresh
          where
        [%uninstall ~]
      ::
      [%post [%f %.y] %make-node *]
        =/  aura=@tas  (val 'aura')
        =/  pax=pith   (cord-to-pith (gut:b 'pith' '/'))
        =/  txt=@t     (got:b 'node')
        =/  =node
          ?+  aura  ~|  no-make-node-handler/aura  !!
            %tas
              ?>  ((sane %tas) txt)
              txt
            %ud  (cord-to-node txt)
            %t   t+txt
            %p   (cord-to-node txt)
            %da  (cord-to-node txt)
            %dr  (cord-to-node txt)
            %f   f+=(txt 'on')
            %pith  (cord-to-node txt)
          ==
        ?.  =((print-aura node) (trip aura))
          ~|  invalid-node/[aura node]
          !!
        %-  emil
        %+  welp
          ::
          ::  open kids from where to (welp where pith)
          ::
          =|  pix=pith
          =|  out=(list change)
          |-
          ^+  out
          ?~  pax  out
          =.  out  :_  out
            %^  haxn  /
              (welp #/~/ui/[sid]/open-kids (welp where pix))
            [%ins f+%.y]
          $(pax t.pax, pix (snoc pix i.pax))
        :~
          %^  haxn  /refresh
            (welp where pax)
          [%ins node]
        ==
      ::
      [%post [%f %.y] %make *]
        =/  node-src
          %-  fix-newlines
          (got:b 'node')
        =/  node
          !<  node
          (slap !>(..zuse) (ream node-src))
        =/  pax=pith  (cord-to-pith (gut:b 'pith' '/'))
        %-  emil
        %+  welp
          ::
          ::  open kids from where to (welp where pith)
          ::
          =|  pix=pith
          =|  out=(list change)
          |-
          ^+  out
          ?~  pax  out
          =.  out  :_  out
            %^  haxn  /
              (welp #/~/ui/[sid]/open-kids (welp where pix))
            [%ins f+%.y]
          $(pax t.pax, pix (snoc pix i.pax))
        :~
          %^  haxn  /refresh
            (welp where pax)
          [%ins node]
        ==
    ==
  --
::
::::  rendering
::
::  get a session's UI state and data for rendering
++  get-session
  |=  sid=@tas
  =/  ui-tree    (dip:ui #/[sid])
  =/  zoom=pith  (gut-pith:ui #/[sid]/zoom /)
  :*  sid
      ui-tree
      zoom
      (dips:f zoom)
  ==
::  the main render door: produces the admin UI for a given session.
::  curs = cursor position within the zoomed subtree.
::  zoom = the root of the currently visible subtree.
++  render
  =|  sug=(unit iota)
  |_  [curs=pith sid=@tas ui-tree=data zoom=pith =^file]
  +*  f   ~(. fe file)                                    ::  file engine
      h   ~(. href [%oxal here.quest] ["session" (trip sid)]~)
      ui  ~(. do ui-tree)                                 ::  UI state
  ++  $
    %+  add-attribute  :-  'data-on:keydown__window'
      "if (evt.key == 'k' && (evt.metaKey || evt.ctrlKey)) \{ evt.preventDefault(); $goto = !$goto }"
    ;div#main.fc.scroll-none.hf.mono
      =data-signals  "\{'_axns': '', '_split': 40, '_dragging': false}"
      =data-init  "$loaded ? '' : ".
                   "$loaded = true; ".
                   "{(data-get:h / ["action" "open-connection"]~)};"
      ;+  part-header
      ;+  part-goto-overlay
      ;*
      ?:  is-full
        ::
        ::  fullscreen single
        ::
        =/  ov=pith  (fall open-view /)
        ;=
          ;+
            %*  fullscreen  inside-view
              zoom  ov
              file  (dips:f (slag zepth ov))
            ==
        ==
      ::
      =;  =manx
        ;=
          ;div.fc.grow.relative.z1.scroll-none
            ;+  manx
          ==
        ==
      ::
      ::  tree view
      ::
      =/  ov=(unit pith)  open-view
      =/  has-right-side
        ?!
        ?|  ?=  ~  ov
            ?&
              (~(is-ancestor th where) u.ov)
              !=(u.ov where)
            ==
        ==
      %^  add-class-if  has-right-side  "has-right"
      ;div.grow.fr.bbh.scroll-none
        =data-style_cursor          "$_dragging ? 'col-resize' : ''"
        ;div.fc.scroll-none.grow.home-left
          =data-style  "\{'flex-basis': $_split + '%'}"
          ;div.px3.fc.grow.relative.scroll-y-always.scroll-x-none.z1
            ;+  level
            ;div.shrink-none(style "height:75vh");
          ==
          ;+
            ?:  =(~ cursor)  ;div;
            =/  cur-curs=pith  (slag zepth (slag 1 `pith`cursor))
            %=  part-actions
              sug   ~
              curs  cur-curs
              file  (dips:f cur-curs)
            ==
        ==
        ;+
        ?.  has-right-side  ;/  ""
        ;div.b2.fc.af.js.divider.bc7.bdl1
          ;+
            %+  add-attribute  :-  'data-on:pointerup__window'  "$_dragging = false"
            %+  add-attribute  :-  'data-on:pointermove__window'
                      "if ($_dragging) \{ ".
                      "  var r = el.parentNode.parentNode.getBoundingClientRect(); ".
                      "  const x = evt.clientX; ".
                      "  const w = r.width || 1; ".
                      "  $_split = Math.max(20, Math.min(80, 100 * (x - r.left) / w)); ".
                      "}"
            %+  add-attribute  :-  'data-on:contextmenu'  "evt.preventDefault();"
            %+  add-attribute  :-  'data-on:pointerdown__prevent'  "$_dragging = true; el.parentElement.setPointerCapture(evt.pointerId);"
            %+  add-attribute  :-  'data-class:grabber'  "!$_dragging"
            ;div.grow.p-3.fc.ac.jc
              =data-class_b4  "$_dragging"
              ; ⠿
            ==
          ::
          ;+
            =/  action  ?:  is-full  "unset-ui-global"  "set-ui-global"
            ;button.py6.b3.o8.bold.hover.fc.ac.jc.bdt1
              =data-on_click  (dp action+action key+"full" val+".y" ~)
              =data-indicator  "_loadfull{nid}"
              =data-class_pulse  "$_loadfull{nid}"
              ; ‹
            ==
          ::
          ;button.py6.b3.o8.bold.hover.fc.ac.jc.bdt1
            =data-on_click  (dp action+"unset-ui-global" key+"open-view" ~)
            =data-indicator  "_loadunselect{nid}"
            =data-class_pulse  "$_loadunselect{nid}"
            ; ›
          ==
        ==
        ::
        ;+  ?.  has-right-side  ;div;
        ;div.fc.scroll-none.grow.home-right
          =data-style  "\{'flex-basis': (100 - $_split) + '%', 'pointer-events': $_dragging ? 'none' : ''}"
          ;+
            %*  $  inside-view
              sug   ~
              zoom  (need ov)
              file  (dips:f (slag zepth (need ov)))
            ==
        ==
      ==
      ;div#spin-hint.fr.fs-2.f8.bdt1.bc10.shrink-none.scroll-none
        =data-ignore-morph  ""
        =data-init  "$loaded ? '' : ".
                     "$loaded = true; ".
                     "openSpinHint(el);"
        ;div#spin-hint-count.p2.pb4.bdr1: 0
        ;div#spin-hint-text.p2.pb4.grow.scroll-none.nowrap.ellipsis: ...
      ==
    ==
  ::
  ++  dp
    |=  =(list [term tape])
    %+  data-post:h  /
    :-  ["where" pate-where]
    %+  turn  list 
    |=  [=term =tape]
    [(trip term) tape]
  ::
  ++  fp
    |=  =(list [term tape])
    %+  form-post:h  /
    :-  ["where" pate-where]
    %+  turn  list 
    |=  [=term =tape]
    [(trip term) tape]
  ::
  ++  cursor        ~+  (fall (get-pith:ui /cursor) /)
  ++  open-view     ~+  (get-pith:ui /open-view)
  ++  is-full       ~+  (fall (get-f:ui /full) %.n)
  ::
  ++  pate-curs    ~+  (pate curs)
  ++  where        ~+  (welp zoom curs)
  ++  nid          ~+  (uid where)
  ++  pate-zoom    ~+  (pate zoom)
  ++  pate-where   ~+  (pate where)
  ++  zepth        ~+  (lent zoom)
  ++  depth        ~+  (lent curs)
  ++  float-style  ~+
    "position: sticky; ".
    "z-index: {<(sub 100 depth)>}; ".
    "top: {<(mul depth 22)>}px; "
  ::
  ++  gui
    |=  =term
    ^-  node
    ?^  x=(get:ui [term where])  u.x
    f+|
  ++  guib
    |=  =term
    =(f+& (gui term))
  ++  leaf-open   ~+  =(cursor [%right where])
  ++  kids-open   ~+  ?~  curs  %.y  (guib %kids)
  ++  has-view    ~+  &(?=(^ leaf.code.file) ?=(^ source.u.leaf.code.file))
  ++  is-bound    ~+  ?&
                        ?=  ^  leaf.code.file
                        ?|
                          ?=  ^  leaf.bound.u.leaf.code.file
                          ?=  ^  kids.bound.u.leaf.code.file
                          ?=  ^  cone.bound.u.leaf.code.file
                        ==
                      ==
  ++  has-kids    ~+  |(?=(^ kids.data.file) ?=(^ kids.code.file))
  ++  has-below   ~+  |(?=(^ kids.data.file) ?=(^ kids.code.file) ?=(^ leaf.code.file))
  ++  has-node    ~+  ?=(^ leaf.data.file)
  ::
  ++  leaf-mode  ~+  `(unit @tas)`(get-tas:ui (welp /leaf-mode `pith`where))
  ++  view-mode  ~+  (gut-tas:ui (welp /view-mode `pith`where) %iframe)
  ::
  ++  level
    =/  show-kids  ?:  kids-open  "true"  "false"
    ;div.fr.af.shrink-none.wf
      =id  "lvl{nid}"
      =style  "--border-color: var(--b2);"
      =data-signals  "\{".
                     "  '_{nid}kids': {show-kids}, ".
                     "  '_{nid}inside': '', ".
                     "}"
      ;+  toggle-kids
      ;div.fc.grow.w1      :: w1 is a css hack
        ;+  part-row
        ;+  ?.  leaf-open    ;/  ""  inside-leaf
        ;+  part-kids
      ==
    ==
  ::
  ++  part-row
    =/  left-active  =(cursor [%left where])
    =/  right-active  =(cursor [%right where])
    =/  active  |(left-active right-active)
    ;div.bdb1.fc.shrink-none(style float-style)
      ;div.fr.g1.b0.shrink-none
        =id  "row{nid}"
        ::
        ;+
          ?.  has-view  ;/  ""
          =/  is-open  =(open-view `where)
          ?:  &(!is-open !active)  ;/  ""
          =/  action
            ?.  is-open  (dp action+"set-ui-global" key+"open-view" val+(pate where) ~)
            (dp action+"unset-ui-global" key+"open-view" ~)
          ;button.p-2.b-3.hover.br2.scroll-none.shrink-none.tl
            =data-on_click  action
            =data-indicator  "_loadzoom{nid}"
            =data-class_pulse  "$_loadzoom{nid}"
            ;-  ?:  is-open  "x"  "→"
          ==
        ::
        ;+
          =/  action  
            ?.  left-active  (dp action+"set-ui-global" key+"cursor" val+(pate [%left where]) ~)
            (dp action+"unset-ui-global" key+"cursor" ~)
          %^  add-class-if  left-active  "active"
          %+  add-class  ?:(active "b2" "b0")
          %^  add-class-if  has-view  "f-3"
          ;button.p-2.hover.shrink-none.tl.br2.scroll-none
            =data-on_click  action
            =data-indicator  "_loadleft{nid}"
            =data-class_pulse  "$_loadleft{nid}"
            ;+  ?~  sug  ;span: /
                (span-iota u.sug)
            ;+  indicators
          ==
        ::
        ;+
          =/  action  
            ?.  right-active  (dp action+"set-ui-global" key+"cursor" val+(pate [%right where]) ~)
            (dp action+"unset-ui-global" key+"cursor" ~)
          %^  add-class-if  right-active  "active"
          %+  add-class  ?:(active "b2" "b0")
          ;button.p2.hover.br2.scroll-none.grow.shrink-1.tl
            =data-on_click  action
            =data-indicator  "_loadrightcursor{nid}"
            =data-class_pulse  "$_loadrightcursor{nid}"
            ;*  one-line-summary
          ==
        ::
        ;+
          =/  active  ?|  =(cursor [%left where])
                          =(cursor [%right where])
                      ==
          ?.  active  ;/  ""
          ?~  curs    ;/  ""
          =/  url=tape  (as-tape:h / ~[["zoom" (pate where)] ["action" "change-zoom"]])
          ;button.p-2.b-4.hover.br2.scroll-none.shrink-1.tl
            =data-on_click  "@get('{url}')"
            =data-indicator  "_loadzoom{nid}"
            =data-class_pulse  "$_loadzoom{nid}"
            ; ⟡
          ==
        ::
      ==
    ==
  ::
  ++  indicators
    ;span
      ;+  ?.  has-view  ;/  ""  ;span.o6.f-3.ml3: •
      ;+  ?.  is-bound  ;/  ""  ;span.o6.f-2.ml3: •
    ==
  ::
  ++  part-kids
    %+  add-attribute  id+"kids{nid}"
    ?.  has-kids   ;div;
    ?.  kids-open  ;div;
    ;div.pb3
      ;*
      %+  murn  kid-list:f
      |=  [=iota =_file]
      ?:  ?=([%n ~] iota)  ~
      :-  ~
      =/  w=pith  (snoc curs iota)
      %=  level
        sug  `iota
        curs  w
        file  file
      ==
    ==
  ::
  ++  toggle-kids
    ?:  =(~ curs)  ;div;
    ?:  !has-kids
      ;div.p-h.o3.fc.js.ac.shrink-none: •
    =/  action  ?:  kids-open  "close-kids"  "open-kids"
    ;button.b0.hover.fc.ac.js.shrink-none.br2.bc9
      =data-on_click  (dp action+"set-ui" key+"kids" val+(scow %f !kids-open) ~)
      =data-indicator  "_loadtogglekids{nid}"
      =data-class_pulse  "$_loadtogglekids{nid}"
      ;span.p-h.f7.b0.br2.relative.fc.ac.bold
        =style  float-style
        ;-  ?:  kids-open  "-"  "+"
        ;+  ?.  kids-open  ;/  ""
        %+  add-class
          ?:  has-below  "bottom-half-line"
          ""
        ;span.absolute.top0.bottom0;
      ==
      ;+  ?.  &(kids-open has-below)  ;span;
        ;span.grow.gradient-line-bottom;
    ==
  ::
  ++  one-line-summary
    ^-  marl
    ?~  x=leaf.data.file
      ;=
        ;span.px2.o2: ~
      ==
    ;=
      ;span.scroll-none.grow.o5.fs-2
        ;-  ?@  u.x  <u.x>
            (print-aura u.x)
        ;-  ":"
      ==
      ;span.scroll-none.nowrap.o7
        ;-  (print-node u.x)
      ==
    ==
  ::
  +$  menu-item
    $:  symbol=tape
        title=(unit tape)
        visible=?
        $=  purpose
        $%  [%post-confirm question=tape post-to=tape]
            [%post post-to=tape]
            [%more items=(list menu-item)]
            [%custom =manx]
            [%inline ~]
            [%sep ~]
            [%break ~]
        ==
    ==
  ::
  ++  render-menu
    |=  [dir=?(%up %down) the-menu=(list menu-item)]
    =/  down  =(dir %down)
    ^-  manx
    =/  lay  ""
    |-
    =/  nid  (uid [lay where])
    %^  add-class-if  !=("" lay)  ?:(down "bblr2" "btlr2")
    ;div.fc.scroll-none.shrink-none
      ;*  =;  =marl  ?:  down  marl  (flop marl)
      ;=
        ;div.frw.ac.p2.b1.bd1
          ;*
          %+  murn  the-menu
          |=  menu-item
          ?.  visible  ~
          :-  ~
          %+  add-attribute  title+(fall title symbol)
          ?-  -.purpose
            %sep  ;div.grow;
            %break  ;div.grow(style "flex-basis: 100%;");
            %inline
              ;span.fs-1.f7.mx1.p2
                ;-  symbol
              ==
            ?(%more %custom)
              ;button.b1.br2.hover.p3.focus
                =data-on_click  "$_menu{nid} = ($_menu{nid} == '{symbol}') ? '' : '{symbol}'"
                =data-class_toggled  "$_menu{nid} == '{symbol}'"
                ;-  symbol
                ;span.o6.ml1: {?:(down "▾" "▴")}
              ==
            %post
              =/  click  ?:  =("" post-to.purpose)  "alert('nyi')"  post-to.purpose
              =/  nad  (uid lay symbol)
              ;button.b1.br2.hover.p3.bold.f2.focus
                =data-on_click  click
                =data-indicator  "_postaxn{nad}"
                =data-class_pulse  "$_postaxn{nad}"
                ;-  symbol
              ==
            %post-confirm
              =/  click  ?:  =("" post-to.purpose)  "alert('nyi')"  post-to.purpose
              =/  nad  (uid lay symbol)
              ;button.p3.b1.br2.hover.bold.f4.focus
                =data-on_click  "if (confirm('{question.purpose}')) {click}"
                =data-indicator  "_postaxn{nad}"
                =data-class_pulse  "$_postaxn{nad}"
                ;-  symbol
              == 
          ==
        ==
        ;div.fc.ml4.scroll-none
          ;*
          %+  murn  the-menu
          |=  menu-item
          ?.  visible  ~
          ?+  -.purpose  ~
            %more
              :-  ~
              ;div
                =data-show  "$_menu{nid} == '{symbol}'"
                =style  hid
                ;+  ^$(lay symbol, the-menu items.purpose)
              ==
            %custom
              :-  ~
              ;div.bd1.scroll-none.grow.fc
                =data-show  "$_menu{nid} == '{symbol}'"
                =style  hid
                ;+
                %+  add-class  "scroll-none"
                manx.purpose
              ==
          ==
        ==
      ==
    ==
  ::
  ++  part-actions
    |^
      =/  where=pith  where
      ^-  manx
      %+  render-menu  %up
      ^-  (list menu-item)
      :~
        ::
        ^-  menu-item
        :*  ?:(is-bound "bind •" "bind")  `"bind"
            &  %custom  menu-bind
        ==
        ::
        ^-  menu-item
        :*  "keen"  `"remote scry"
          &  %custom  menu-keen
        ==
        ::
        ^-  menu-item
        :*  "copy"  `"copy"
            &  %more
          :~  ["subtree" ~ & %custom (menu-dest-form "cop")]
              ["leaf" ~ has-node %custom (menu-dest-form "dup")]
          ==
        ==
        ::
        ^-  menu-item
        :*  "move"  `"move"
            &  %more
          :~  ["subtree" ~ & %custom (menu-dest-form "mov")]
              ["leaf" ~ has-node %custom (menu-dest-form "hop")]
          ==
        ==
        ::
        ^-  menu-item
        :*  "delete"  `"delete"
            |(has-node &(has-kids ?=(^ where)))
            %more
          :~  ["leaf" ~ has-node %post-confirm "delete leaf?" (dp action+"del" pith+"/" ~)]
              ["subtree" ~ &(has-kids ?=(^ where)) %post-confirm "delete subtree?" (dp action+"lop" pith+"/" ~)]
              ["trim-kids" ~ &(has-kids ?=(^ where)) %post-confirm "delete kids, keep self?" (dp action+"nic" pith+"/" ~)]
          ==
        ==
        ::
        ^-  menu-item
        :*  "export"  ~
            &
            %custom
              =/  filename
               ;:  welp
                 +:(scow %p our.quest)
                 "__"
                 ::
                 ::  xx maybe encode the entire path, not just last segement
                 ::
                 ?~(where "root" (print-node (rear where)))
                 "__"
                 unix-timestamp
                 ".hawk-0"
               == 
              ;a.p-3.b1.hover.grow.fr.ac.jc
                =href  (as-tape:h / ~[["action" "export"] ["where" pate-where]])
                =download  filename
                ; export
              ==
        ==
        ::
        ^-  menu-item
        :*  "import"  ~
            &
            %custom
              ;div.fr
                ;*
                %+  turn
                  :~  :: ["import code+data" "import-both"]
                      ["import data" "import-data"]
                  ==
                |=  [label=tape action=tape]
                ;form.grow.fc
                  =method  "post"
                  =action  "?action={action}&where={pate-where}"
                  =onsubmit  "mimeFormUpload(event);"
                  ;input.hidden
                    =id  action
                    =name  "file"
                    =type  "file"
                    =required  ""
                    =accept  ".hawk-0"
                    =oninput  "this.closest('form').requestSubmit();"
                    ;
                  ==
                  ;input.hidden
                    =name  "zoom"
                    =value  pate-zoom
                    ;
                  ==
                  ;button.br2.bd1.p-3.b1.hover.fr.ac.jc
                    =type  "button"
                    =onclick  "document.getElementById('{action}').click()"
                    ;-  label
                  ==
                ==
              ==
        ==
        ::
        ^-  menu-item
        :*  "download"  ~
            has-node
            %custom
              ;a.p-3.b1.hover.grow.fr.ac.jc
                =href  (as-tape:h / ~[["action" "mime"] ["where" pate-where]])
                =download  ""
                ; download
              ==
        ==
        ::
        ::
        ^-  menu-item
        :*  "install"  `"create code overlay"
            !has-view
            %post
              (dp action+"sprout" ~)
        ==
        ::
        ^-  menu-item
        :*  "uninstall"  `"remove code overlay"
            &(has-view !(is-locked where))
            %post-confirm  "uninstall {pate-where}?"
              (dp action+"uninstall" ~)
        ==
        ::
        ^-  menu-item
        :*  ""  ~  &  %sep  ~  ==
        ::
        ^-  menu-item
        :*  "help"  `"help"
            &
            %post
              (dp action+"set-ui-global" key+"open-view" val+"/docs" ~)
        ==
      ==
    ::
    ++  menu-bind
      =/  =view  (fall leaf.code.file *view)
      ;form.fc.bbv
        =data-on_submit  (fp action+"bind" ~)
        ;div.fc.g5.py5.px3
          ;*
          =/  lef  leaf.bound.view
          =/  kis  kids.bound.view
          =/  con  cone.bound.view
          ::
          =/  dlef=claf  (fall leaf.bound.view *claf)
          =/  dkis=claf  (fall kids.bound.view *claf)
          =/  dcon=claf  (fall cone.bound.view *claf)
          ::
          %+  turn  ~["leaf" "kids" "cone"]
          |=  label=tape
          ;div.frw.g3.ac.grow.fs-2
            ;span.bold.f6: {label}
            ;label.fc.g2.ac
              ;span: bound?
              ;+
              %^    add-attribute-if
                  ?:  =(label "leaf")  ?=(^ lef)
                  ?:  =(label "kids")  ?=(^ kis)
                  ?:  =(label "cone")  ?=(^ con)
                  !!
                checked+""
              ;input
                =type  "checkbox"
                =name  "{label}-bound"
                =data-bind  "_{label}bound{nid}"
                ;*  ~
              ==
            ==
            ;div.fr.g2
              ;label.fr.g2.ac.jc
                ;span(data-class_o4 "!$_{label}bound{nid}"): auth
                ;+
                =/  val
                  ?:  =(label "leaf")  (trip (fall auth.dlef %$))
                  ?:  =(label "kids")  (trip (fall auth.dkis %$))
                  ?:  =(label "cone")  (trip (fall auth.dcon %$))
                  !!
                ;input.br2.bd1.p2
                  =placeholder  "empty = public"
                  =name  "{label}-auth"
                  =value  val
                  =data-attr_disabled  "!$_{label}bound{nid}"
                  ;*  ~
                ==
              ==
              ;label.fc.g2.ac.jc
                ;span(data-class_o4 "!$_{label}bound{nid}"): past?
                ;+
                %^    add-attribute-if
                    ?:  =(label "leaf")  &(?=(^ lef) past.u.lef)
                    ?:  =(label "kids")  &(?=(^ kis) past.u.kis)
                    ?:  =(label "cone")  &(?=(^ con) past.u.con)
                    !!
                  checked+""
                ;input
                  =type  "checkbox"
                  =name  "{label}-past"
                  =data-attr_disabled  "!$_{label}bound{nid}"
                  ;*  ~
                ==
              ==
            ==
          ==
        ==
        ;div.f-1.p3
          ; warning: only public bindings work
          ;br;
          ; and tombstone-ing is not implemented
        ==
        ;button.p3.b2.hover
          ; save
        ==
      ==
    ::
    ++  menu-keen
      ;form.fc.bbv
        =data-on_submit  (fp action+"keen" ~)
        ;input.p3.grow
          =name  "pith"
          =required  ""
          =placeholder  "/subpath"
          =autocomplete  "off"
          =spellcheck  "false"
          ;*  ~
        ==
        ;input.p3
          =name  "ship"
          =required  ""
          =placeholder  "~zod"
          =autocomplete  "off"
          =spellcheck  "false"
          ;*  ~
        ==
        ;div.fr.af.bbh
          ;span.p2.fs-2.fc.ac.jc.f7.b2: /g/x
          ;input.p3.w12
            =name  "case"
            =type  "number"
            =min  "0"
            =step  "1"
            =required  ""
            =placeholder  "1"
            =autocomplete  "off"
            =spellcheck  "false"
            ;*  ~
          ==
          ;span.p2.fs-1.fc.ac.jc.f7.b2.grow: /oxal//1
        ==
        ;input.p3.grow
          =name  "spur"
          =required  ""
          =placeholder  "/remote/path"
          =autocomplete  "off"
          =spellcheck  "false"
          ;*  ~
        ==
        ;span.fr.ac.g4.p4
          ;label.fr.g2.ac
            ;input
              =required  ""
              =type  "radio"
              =name  "care"
              =value  "leaf"
              ;*  ~
            ==
            ;span: %leaf
          ==
          ;label.fr.g2.ac
            ;input
              =required  ""
              =type  "radio"
              =name  "care"
              =value  "kids"
              ;*  ~
            ==
            ;span: %kids
          ==
          ;label.fr.g2.ac
            ;input
              =required  ""
              =type  "radio"
              =name  "care"
              =value  "cone"
              ;*  ~
            ==
            ;span: %cone
          ==
        ==
        ;button.p3.b2.hover
          ; keen
        ==
      ==
    ::
    ++  menu-dest-form
      |=  act=tape
      ;form.fc.bbv
        =data-on_submit  (fp action+act ~)
        ;div.fr.ac
          ;input.p3.grow.mono
            =placeholder  "/dest/path"
            =autocomplete  "off"
            =spellcheck  "false"
            =required  ""
            =name  "to"
            ;*  ~
          ==
          ;button.p-3.b2.bdl1.hover: ok
        ==
      ==
    --
  ::
  ++  form-node-make-any
    ^-  manx
    %+  render-menu  %down
    ^-  (list menu-item)
    :~
      :*  "tas"  `"term (symbol)"
          &  %custom  (form-node-make %tas |)
      ==
      :*  "ud"  `"unsigned decimal"
          &  %custom  (form-node-make %ud |)
      ==
      :*  "p"  `"identity"
          &  %custom  (form-node-make %p |)
      ==
      :*  "f"  `"loobean"
          &  %custom  (form-node-make %f |)
      ==
      :*  "da"  `"absolute date"
          &  %custom  (form-node-make %da |)
      ==
      :*  "dr"  `"relative date"
          &  %custom  (form-node-make %dr |)
      ==
      :*  "t"  `"text cord"
          &  %custom  (form-node-make %t |)
      ==
      :*  "pith"  `"tree location"
          &  %custom  (form-node-make %pith |)
      ==
      :*  "mime"  `"earth file"
          &  %custom  (form-node-make %mime |)
      ==
    ==
  ::
  ++  form-node-make
    |=  [aura=term below=?]
    ^-  manx
    ?:  =(aura %mime)
      ;form.fc.bbv
        =method  "post"
        =action  (as-tape:h / ~[["action" "upload-mime"] ["where" pate-where]])
        =onsubmit  "mimeFormUpload(event);"
        ;+  (input-mime ~)
      ==
    ;form.fc.bbv
      =data-on_submit  (fp action+"make-node" aura+(trip aura) ~)
      ;+
      ?.  below  ;/  ""
      ;input.p3
        =placeholder  "/where"
        =required  ""
        =name  "pith"
        =autocomplete  "off"
        =spellcheck  "false"
        ;
      ==
      ;+
      ?+  aura  ;div.p2: unknown aura {<aura>}
        %tas   (input-tas ~)
        %ud    (input-ud ~)
        %p     (input-p ~)
        %t     (input-t ~)
        %da    (input-da ~)
        %dr    (input-dr ~)
        %f     (input-f ~)
        %pith  (input-pith ~)
      ==
    ==
  ++  form-node-edit
    |=  =node
    =/  aura  (print-aura node)
    ?:  ?=([%mime *] node)
      ;form.fc.grow.scroll-none
        =method  "post"
        =action  (as-tape:h / ~[["action" "upload-mime"] ["where" pate-where]])
        =onsubmit  "mimeFormUpload(event);"
        ;+  (input-mime `mime.node)
      ==
    ;form.fc.grow.scroll-none
      =data-on_submit  (fp action+"make-node" aura+aura ~)
      ;+
      ?@  node  ;div.p3: no @tas editor yet
      ?+  -.node  ;div.p3: no editor {<-.node>}
        %ud    (input-ud `ud.node)
        %t     (input-t `t.node)
        %tang  (input-tang `tang.node)
        %manx  (input-manx `manx.node)
      ==
    ==
  ::
  ++  input-mime
    |=  =(unit mime)
    ;div.fc.grow.scroll-none
      ;+
      ?~  unit  ;div;
      =/  [=mite @ d=@]  u.unit
      =/  mime-src  (as-tape:h / ~[["action" "mime"] ["where" pate-where]])
      ;div.fc
        ;div.fr.ac.g3.p3
          ;span.f5: {<mite>}
          ;span.f7: {<p.q.u.unit>} bytes
          ;a.b1.hover.br2.p2
            =href  mime-src
            =download  ""
            ; download
          ==
        ==
        ;+
        ?+  mite  ;div;
          [%image *]
            ;img.contain(style "max-height: 20vh;")
              =src  mime-src
              ;*  ~
            ==
          ::
          [%audio *]
            ;audio(controls "")
              ;source(src mime-src, type "audio/mpeg");
            ==
        ==
      ==
      ;input.hidden
        =id  "mime-upload{nid}"
        =name  "file"
        =type  "file"
        =oninput  "this.closest('form').requestSubmit();"
        ;
      ==
      ;button.p-2.br2.b1.hover.tc
        =type  "button"
        =onclick  "document.getElementById('mime-upload{nid}').click()"
        =data-class_pulse  "$_loadformmime"
        ;  {?~(unit "upload" "replace")}
      ==
    ==

  ::
  ++  input-manx
    |=  =(unit manx)
    ^-  manx
    ?~  unit
      ;div.p3: not available
    =/  htm=tape  (en-xml:html u.unit)
    =/  b64=tape  (trip (en:base64:mimes:html (met 3 (crip htm)) (crip htm)))
    =/  src=tape  "data:text/html;base64,{b64}"
    ;div.grow.scroll-y
      ;iframe.wf.hf.grow.bn
        =sandbox  ""
        =src  src
        ;
      ==
    ==
  ::
  ++  input-tang
    |=  =(unit tang)
    =/  =tang  (fall unit ~)
    ;div
      ;+  (render-tang tang)
    ==
  ::
  ++  input-tas
    |=  =(unit @tas)
    ;div.fr.af
      ;input.w1.grow.p3.focus
        =type  "text"
        =required  ""
        =placeholder  "term (no leading %)"
        =autocomplete  "off"
        =spellcheck  "false"
        =value  ?~(unit "" (trip u.unit))
        =name  "node"
        ;*  ~
      ==
      ;button.p-3.b2.bdl1.hover.focus: ✔
    ==
  ::
  ++  input-t
    |=  =(unit @t)
    ;div.fc.bbv.grow.scroll-none
      ;feather-text-editor.grow
        =placeholder  "text"
        =autocomplete  "off"
        =spellcheck  "false"
        =placeholder  "@t"
        =required  ""
        =name  "node"
        ;-  (trip (fall unit ''))
      ==
      ;button.fr.b2.hover.focus
        ;div.p3.bdr1.f6: %t
        ;div.p3.grow: ✔
      ==
    ==
  ::
  ++  input-f
    |=  =(unit ?)
    ;div.fr.af.g5
      ;label.fr.g2.ac.ml4
        ;+  %^  add-attribute-if  &(?=(^ unit) u.unit)  checked+""
        ;input.p3.fs-1.focus
          =type  "radio"
          =name  "node"
          =required  ""
          ;*  ~
        ==
        ;span: %.y
      ==
      ;label.fr.g2.ac
        ;+  %^  add-attribute-if  &(?=(^ unit) !u.unit)  checked+""
        ;input.p3.fs-1.focus
          =type  "radio"
          =name  "node"
          =required  ""
          ;*  ~
        ==
        ;span: %.n
      ==
      ;button.p-3.b2.bdl1.hover.focus.grow: ✔
    ==
  ::
  ++  input-dr
    |=  =(unit @dr)
    ;div.fr.af
      ;input.w1.grow.p3
        =type  "text"
        =required  ""
        =placeholder  "~s15"
        =autocomplete  "off"
        =spellcheck  "false"
        =value  ?~(unit "" (dane dr+u.unit))
        =name  "node"
        ;*  ~
      ==
      ;button.p-3.b2.bdl1.hover: ✔
    ==
  ::
  ++  input-da
    |=  =(unit @da)
    ;div.fr.af
      ;input.w1.grow.p3
        =type  "text"
        =required  ""
        =placeholder  "~2000.1.1..15.12.05"
        =autocomplete  "off"
        =spellcheck  "false"
        =value  ?~(unit "" (dane da+u.unit))
        =name  "node"
        ;*  ~
      ==
      ;button.p-3.b2.bdl1.hover: ✔
    ==
  ::
  ++  input-ud
    |=  =(unit @ud)
    ;div.fr
      ;input.p3.w1.grow.focus
        =placeholder  "unsigned decimal"
        =autocomplete  "off"
        =spellcheck  "false"
        =required  ""
        =name  "node"
        =value  ?~(unit "" (scow %ud u.unit))
        ;*  ~
      ==
      ;button.p-3.b2.bdl1.hover.focus: ✔
    ==
  ::
  ++  input-p
    |=  =(unit @p)
    ;div.fr
      ;input.p3.w1.grow
        =placeholder  "@p identity"
        =autocomplete  "off"
        =spellcheck  "false"
        =required  ""
        =value  ?~(unit "" (scow %ud u.unit))
        =name  "node"
        ;*  ~
      ==
      ;button.p-3.b2.bdl1.hover: ✔
    ==
  ::
  ++  input-pith
    |=  =(unit pith)
    ;div.fr
      ;input.p3.w1.grow
        =placeholder  "/some/pith"
        =autocomplete  "off"
        =spellcheck  "false"
        =required  ""
        =value  ?~(unit "" (pate u.unit))
        =name  "node"
        ;*  ~
      ==
      ;button.p-3.b2.bdl1.hover: ✔
    ==
  ::
  ++  inside-leaf
    ^-  manx
    ;div.scroll-none.fc.grow.bd2.br2.ml6.my3
      =style  "max-height: 44vh;"
      ;+
      ?:  has-node
        (inside-node (need leaf.data.file))
      form-node-make-any
    ==
  ::
  ++  inside-node
    |_  =node
    ++  $
      ^-  manx
      ;div.fc.grow.bbv.scroll-none
        =id  "node{nid}"
        ;+  form-delete
        ;+  (form-node-edit node)
      ==
    ::
    ++  form-delete
      %+  add-attribute  :-  'data-on:click'
        (data-post:h / ~[["where" pate-where] ["pith" "/"] ["action" "del"]])
      ;button.p2.b1.hover
        ; delete
      ==
    ++  form-edit
      |^
        ;form.grow.fc.bbv.scroll-none
          =id  "leaf-editor"
          =data-on_submit  (form-post:h / ~[["where" pate-where] ["action" "make"]])
          =data-indicator  "_loadmakeleaf{nid}"
          ;div.p2.mono.f5
            ;-  "%"
            ;-  (print-aura node)
          ==
          ;+
            ?~  txt=(print-strict node)
              ?+    node
                  ;div.grow.fc.ac.jc.p2.mono
                    =id  "leaf-editor-text-{nid}"
                    ; no printer
                  ==
                ::
                [%mime *]
                  =/  [=mite @ d=@]  mime.node
                  ;div.fc.g4.grow.hf.contain.p3.ac.jc.scroll-none
                    ;div: {<mite>}
                    ;+
                    ?+  mite  ;div: unknown mite {<(pave mite)>}
                      [%image *]
                        ;img.contain.hf
                          =src  (as-tape:h / ~[["action" "mime"] ["where" pate-where]])
                          ;*  ~
                        ==
                      ::
                      [%audio *]
                        ;audio(controls "")
                          ;source
                            =src  (as-tape:h / ~[["action" "mime"] ["where" pate-where]])
                            =type  "audio/mpeg"
                            ;
                          ==
                        ==
                    ==
                  ==
              ==
            ;div.fc.grow.scroll-none
              ;+  (editor u.txt)
              ;button.loader.p4.b1.hover.fr.ac.jc.mono.f5
                =data-class_pulse  "$_loadmakeleaf{nid}"
                ; save
              ==
            ==
          ::
        ==
      ++  editor
        |=  txt=tape
        ;feather-text-editor.grow
          =id  "leaf-editor-text-{nid}"
          =style  "min-height: 222px;"
          =placeholder  "leaf"
          =required  ""
          =auto-indent  ""
          =name  "node"
          ;-  txt
        ==
      --
    --
  ::
  ++  homepage
    ;div.grow.fc.p5.g5
      ;div.grow.frw.g5.as
        ;*
        %+  murn  kid-list:c:f
        |=  [=iota =code]
        ?~  leaf.code  ~
        :-  ~
        ;a.p5.br3.bd1.b2.hover
          =href  "/oxal/{(print-node iota)}"
          =target  "_blank"
          ;-  (print-node iota)
        ==
      ==
      ;div.p4.br3.bd1.bc-2.o5.f-2.fc.g3
        ;p: under construction
        ;p: manually export any data you consider important
        ;p: otherwise it may get wiped
      ==
    ==
  ::
  ++  inside-view
    |%
    ++  $
      =/  edi  (guib %editor)
      ?~  (source:c:f /)  ;/  ""
      ;div.fc.af.scroll-none.grow.bbv
        ;+  view-toggles
        ;+  viewer
        ;+  ?.  (guib %editor)  ;/  ""  editor
      ==
    ::
    ++  fullscreen
      ;div.grow.fc.scroll-none.bbv
        ;+  view-toggles
        ;div.grow.fr.scroll-none.bbh
          ;+  viewer
          ;+  ?.  (guib %editor)  ;/  ""  editor
        ==
      ==
    ::
    ++  standalone-url  ~+  (~(as-tape href [%oxal here.quest] ~) (fall open-view /) ~)
    ::
    ++  view-toggles
      ;div.fr.g2.af.f6.shrink-0.shrink-none.b1
        ;div.grow;
        ;a.p-3.shrink-none.b1.br2.hover
          =href  standalone-url
          =target  "_blank"
          ;span
            ; ➚
          ==
        ==
        ;+  %^  add-class-if  (guib %editor)  "toggled"
        ;button.p-3.b1.br2.hover
          =data-on_click  (dp action+"set-ui" key+"editor" val+(scow %f !(guib %editor)) ~)
          =data-indicator  "_loadedit{nid}"
          =data-class_pulse  "$_loadedit{nid}"
          ; ͳ
        ==
        ;+
          ?.  is-full  ;/  ""
          ;button.px4.b3.o8.bold.hover.fc.ac.jc.bdt1
            =data-on_click  (dp action+"unset-ui-global" key+"full" val+".y" ~)
            =data-indicator  "_loadfull{nid}"
            =data-class_pulse  "$_loadfull{nid}"
            ; ×
          ==
      ==
    ::
    ++  viewer
      ?:  =(open-view `/)
        ;div.grow.b1.shrink-1.basis-half
          ;+  homepage
        ==
      ;iframe.grow.fc.shrink-1.m0.basis-half
        =src  standalone-url
        =id  "iframe{nid}{(uid source:(fall leaf.code.file *view))}"
        ;*  ~
      ==
    ::
    ++  editor
      =/  txt=tape
        %-  trip
        %+  fall
          =<  source
          (fall leaf.code.file *view)
        ''
      ;div.grow.scroll-none.fc
        =style  "flex-basis: 50%;" 
        =id  "code{nid}"
        ;div.fc.grow.scroll-none.mono.bbv
          ;+
            ?~  tung=(get-tang:ui (welp /install-error `pith`where))
              ;/  ""
            ;div.hf.shrink-none.grow.fc
              =style  "max-height: 190px;"
              ;div.scroll-y-always
                ;+  (render-tang u.tung)
              ==
              ;button.p3.b1.hover.bdt1
                =data-on_click  (dp action+"clear-install-error" ~)
                ; revert
              ==
            ==
          ;+
            ?:  (is-locked where)
            ;div.fc.mono.grow.scroll-none.bbv
              ;a.fr.jb.ac.p2.b0.hover
                =target  "_blank"
                =href  "/hawk-clay/hawk"
                ;div.f-2.o7: locked
                ;div.underline
                  ; edit in clay
                ==
              ==
              ;div.grow.scroll-y-always.scroll-x-always.f5
                ;div.p4.pb15.mono.pre
                  ;-  txt
                ==
              ==
            ==
          ;form.fc.grow.scroll-none.bbv
            =data-indicator  "_loadsavecode"
            =data-on_submit  (form-post:h / ~[["action" "install"] ["where" pate-where]])
            ;feather-text-editor.grow
              =id  "codeed{(uid where)}"
              =auto-indent  ""
              =name  "code"
              ;-  txt
            ==
            ;button.p4.b1.hover.loader.tc.fr.ac.jc
              =data-class_pulse  "$_loadsavecode"
              ; install
            ==
          ==
        ==
      ==
    ::
    --
  ::
  ++  span-iota
    |=  =iota
    ^-  manx
    ?@  iota
      ;span: {(trip iota)}
    ;span
      ;span.f7.fs-2.mr1: {(print-aura iota)}
      ;span: {(print-node iota)}
    ==
  ::
  ++  part-header
    ;header.fr.af.bdb1.bc7
      ;div.grow.fr.af
        ::
        ;*
        =|  pax=pith
        =|  sug=(unit iota)
        =|  out=marl
        |-
        ^-  marl
        =/  nid  (uid %header pax)
        =.  out  :_  out
          =/  label
            ?~  sug  "/"
            (print-node u.sug)
          %+  add-class
            ?~  pax  "p-4"
            "py4 px3"
          %+  datastar-link  (as-tape:h / ~[["zoom" (pate pax)] ["action" "change-zoom"]])
          ;a.b0.hover.loader.lh1
            =data-indicator  "_loadheader{nid}"
            =data-class_pulse  "$_loadheader{nid}"
            ;+
            ?~  sug  ;span: /
            (span-iota u.sug)
            ::
            ;+
            ?~  pax  ;/  ""
            ;span.f8
              ;-  "/"
            ==
          ==
        ?~  zoom  (flop out)
        %=  $
          pax  (snoc pax i.zoom)
          sug  `i.zoom
          zoom  t.zoom
        ==
        ::
        ;button.grow.b0.hover.lh1.fr.ac.je.bold
          =style  "min-width: 30px;"
          =data-on_click  "$goto = true;"
          =data-class_pulse  "$_loadgoto"
          ;span.mr3.fs1: ⌕
        ==
        ::
        ;+  ?:  =(open-view `/)  ;/  ""
        ;button.px4.fr.ac.jc.b0.bold.hover
          =data-indicator  "_loadhome{nid}"
          =data-class_pulse  "$_loadhome{nid}"
          =data-on_click  (dp action+"set-ui-global" key+"open-view" val+"/" ~)
          ; ⌂
        ==
      ==
    ==
  ::
  ++  part-goto-overlay
    =/  paths=(list pith)
      %+  murn  kid-list:f
      |=  [=iota *]
      ?:  ?=([%n ~] iota)  ~
      `(welp zoom /[iota])
    ;div.absolute.top0.left0.wf.hf.z2.fc
      =data-show  "$goto"
      =style  hid
      ;div.goto-backdrop.fc.grow.relative.ac
        =data-on_click  "if (evt.target === evt.currentTarget) $goto = false"
        ;div.fc.br2.bd1.sh2.z3.o10.goto-box
          ;form.fc.shrink-none
            =data-on_submit  "{(form-get:h / ["action" "change-zoom"]~)}; $goto = false;"
            =data-indicator  "_loadgoto"
            ;input#goto.goto-input.p-3.b2.lh1.m0.block.wf.fs2
              =placeholder  "go to path..."
              =name  "zoom"
              =value  pate-zoom
              =data-bind  "_gotoq"
              =spellcheck  "false"
              =autocomplete  "off"
              =data-on_keydown  "if (evt.key == 'Escape') \{ evt.preventDefault(); $goto = false }"
              =data-effect  "if ($goto) \{ el.focus(); el.setSelectionRange(999, 999) }"
              ;
            ==
            ;button.hidden;
          ==
          ;div.fc.scroll-y.goto-results
            ;*
            %+  turn  paths
            |=  =pith
            =/  p=tape  (pate pith)
            =/  url=tape  (as-tape:h / ~[["zoom" p] ["action" "change-zoom"]])
            ;a.goto-item.b0.p-3.lh1.hover.block.bdb1
              =href  url
              =data-on_click  "evt.preventDefault(); $goto = false; @get('{url}');"
              =data-show  "'{p}'.includes($_gotoq || '/')"
              ;-  p
            ==
          ==
        ==
      ==
    ==
  --
::
++  unix-timestamp
  =/  y  (yore now.quest)
  ;:  welp
    (a-co:co y.y)
    "_"
    (y-co:co m.y)
    "_"
    (y-co:co d.t.y)
    "_"
    (y-co:co h.t.y)
    (y-co:co m.t.y)
    (y-co:co s.t.y)
  ==
::
++  page-crash
  |=  =tang
  ;div.page.fc.g6
    ;strong.fs3: crash!
    ;div.scroll-x.scroll-y.p3.br2.bd1.max-h20
      ;+  (render-tang tang)
    ==
    ;a.br1.bd1.p-2.block.wfc
      =href  "/oxal"
      ; home
    ==
  ==
::
++  wrap
  |=  [title=tape =manx]
  ;html
    ;head
      ;title:(-title)
      ;meta(charset "UTF-8");
      ;meta(name "viewport", content "width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no");
      ;link(rel "stylesheet", href "/new-oxal-init/feather/1/style");
      ;link(rel "icon", href "https://em-content.zobj.net/source/huawei/442/alien-monster_1f47e.png");
      ;link(rel "manifest", href "/oxal/~/manifest");
      ;script(type "module", src "/new-oxal-init/feather/1/text-editor");
      ;script(type "module", src "/new-oxal-init/feather/1/datastar-new");
      ;script(type "module", src "/new-oxal-init/feather/1/datastar-inspector");
      ;script
        ;-  %-  trip
        '''
        var lastSpinHint = '';
        async function openSpinHint(el) {
          const controller = new AbortController();
          // optional: expose a way to stop the stream elsewhere
          window.stopSseStream = () => controller.abort();
          const res = await fetch('/~_~/spin', {
            method: 'GET',
            headers: {
              'Accept': 'text/event-stream'
            },
            signal: controller.signal,
          });
          if (!res.ok || !res.body) {
            console.error('SSE connection failed:', res.status, res.statusText);
            return;
          }
          const reader = res.body.getReader();
          const decoder = new TextDecoder('utf-8');
          let buffer = '';
          try {
            while (true) {
              const { value, done } = await reader.read();
              if (done) break;
              // Decode this chunk and add to the buffer
              buffer += decoder.decode(value, { stream: true });
              // Process complete lines
              let lines = buffer.split('\n');
              buffer = lines.pop(); // keep last partial line (if any) for next chunk
              for (const line of lines) {
                // SSE comments / empty lines
                if (!line || line.startsWith(':')) continue;
                // Basic SSE "data:" handling
                if (line.startsWith('data:')) {
                  const data = line.slice(5).trimStart(); // remove "data:" prefix
                  if (data === '/root') {}
                  else if (data === lastSpinHint) {
                    let count = el.querySelector('#spin-hint-count');
                    count.textContent = parseInt(count.textContent) + 1;
                    count.style.opacity = '100%';
                  } else {
                    let text = el.querySelector('#spin-hint-text');
                    let count = el.querySelector('#spin-hint-count');
                    text.textContent = data;
                    lastSpinHint = data;
                    count.textContent = '0';
                    count.style.opacity = '0%'; 
                  }
                }
              }
            }
          } catch (err) {
            if (err.name === 'AbortError') {
              console.log('SSE stream aborted');
            } else {
              console.error('Error reading SSE stream:', err);
            }
          }
        }
        async function mimeFormUpload(e) {
          e.preventDefault();
          const input = e.target.querySelector('input[type=file]');
          const file = input.files[0];
          if (!file) {
            alert("Choose a file first");
            return;
          }
          // 512 KB limit
          const MAX_SIZE = 512 * 1024;
          if (file.size > MAX_SIZE) {
            alert(`larger than 512kb: ${(file.size / 1024).toFixed(1)}kb`);
            window.location.reload();
            return;
          }
          const res = await fetch(e.target.action, {
            method: 'POST',
            headers: {
              'Content-Type': file.type || 'application/octet-stream'
            },
            body: file
          });
          if (res.status == 200) {
            window.location.reload();
          } else {
            alert(`error: ${res.status}`)
            window.location.reload();
          }
        }
        '''
      ==
      ;style
        ;-  %-  trip
        '''
        :root, body {
          overflow: hidden;
        }
        .p-h {
          padding: var(--s2) 6px;
        }
        :root {
          --line-color: var(--f7);
          --line-width: 1.5px;
        }
        .full-line {
          background: linear-gradient(
            to top,
            var(--line-color) 0%,
            var(--line-color) 100%
          );
          width: var(--line-width);
          flex-shrink: 0;
        }
        .bottom-half-line {
          background: linear-gradient(
            to bottom,
            transparent 0%,
            transparent 50%,
            var(--line-color) 51%,
            var(--line-color) 100%
          );
          width: var(--line-width);
          flex-shrink: 0;
        }
        .top-half-line {
          background: linear-gradient(
            to top,
            transparent 0%,
            transparent 50%,
            var(--line-color) 51%,
            var(--line-color) 100%
          );
          width: var(--line-width);
          flex-shrink: 0;
        }
        .gradient-line-top {
          background: linear-gradient(
            to top,
            var(--line-color) 10%,
            transparent 90%
          );
          width: var(--line-width);
          flex-shrink: 0;
        }
        .gradient-line-bottom {
          background: linear-gradient(
            to bottom,
            var(--line-color) 0%,
            var(--line-color) calc(100% - var(--s5)),
            transparent calc(100% - var(--s3))
          );
          width: var(--line-width);
          flex-shrink: 0;
        }
        .goto-backdrop {
          background: rgba(0,0,0,0.3);
          backdrop-filter: blur(2px);
          -webkit-backdrop-filter: blur(2px);
          padding-top: 15vh;
          align-items: center;
        }
        .goto-box {
          width: 90%;
          max-width: 520px;
          max-height: min(400px, 60vh);
          background: var(--b1);
          overflow: hidden;
        }
        .goto-input {
          border: none;
          border-bottom: 1px solid var(--border-color);
          border-radius: 0;
          outline: none;
        }
        .goto-input:focus {
          outline: none;
        }
        .goto-results {
          overflow-y: auto;
        }
        .goto-item {
          text-decoration: none;
          color: var(--f3);
          border-bottom-color: var(--b2);
        }
        .goto-item:last-child {
          border-bottom: none;
        }
        .goto-item:hover {
          background: var(--b2);
        }
        @media (max-width: 700px) {
          .has-right > .home-left {
            display: none !important;
          }
          .has-right > .home-right {
            flex-basis: 100% !important;
          }
          .home-left {
            flex-basis: 100% !important;
          }
          .divider {
            display: none !important;
          }
        }
        '''
      ==
    ==
    ;body.b0
      ;+  manx
      :: ;datastar-inspector;
    ==
  ==
--
