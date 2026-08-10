::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  %burn — Hash-verified peer-to-peer media sharing (Plex producer)
::
::  Host: configures local Plex, proxies API requests for subscribers
::  via Ames. Subscriber: watches host, proxies API calls over Ames.
::  Integrates with Oxal views for the Hoon-native UI.
::
::  WHAT MAKES THIS PROJECT INTERESTING
::  -----------------------------------
::  Every byte of media transfer between ships goes through Ames/Mesa,
::  not HTTP — even when the path traverses NAT, even when "easier"
::  shortcuts (file-share's IP-from-peer-table HTTP fetch) exist. The
::  publisher (fogduc, behind residential NAT) and the subscriber (havdys,
::  Oracle Cloud, public hostname) form a tunneled-martian path: a
::  browser at havdys.howm.art reaches a Plex server on a Mac Mini behind
::  a residential router, with no port forwarding, no domain, no VPN —
::  just an Urbit identity pair.
::
::  The download path is built on the negative space of three Vere/Eyre
::  HTTP-runtime constraints, none of them documented anywhere else:
::    1. Empty-octs (`octs=[0 '']`) keepalive crashes Vere _http_hgen_send.
::    2. Vere closes a header-only response stream at ~46s of pre-body idle.
::    3. Vere also closes the same stream at ~46s of inter-body silence.
::  Three composable mitigations:
::    deferred-headers — open the response only when bytes are ready
::    octs-buffer + /dl-trickle — pace real chunk bytes every ~s15
::    stream-arrivals — sweep on inactivity, not age
::
::  The trickle slice formula `slice = buf × interval / runway` is
::  recomputed every emit, which makes the buffer drain exponentially
::  rather than linearly — half-life ≈ runway × 0.69. Set runway long
::  enough and the system tolerates hour-scale Mesa stalls automatically.
::
::  Browser-managed resume is supported through Range/206:
::  deferred-headers holds the 206 until the first resumed chunk arrives,
::  Content-Range carries the total size, and the subscriber trims any
::  already-owned prefix from the aligned host chunk before emitting.
::
::  Read more:
::    skills/Urbit/Knowledge/reference_eyre_no_response_idle_knob.md
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::
/-  burn, goon
/+  dbug, server, default-agent, burn-to-goad
::
|%
+$  card  card:agent:gall
++  first-chunk-size  `@ud`65.536             ::  64KB — instant Mesa transit, fires deferred header, keeps trickle alive while chunk-2 traverses
++  chunk-size        `@ud`15.728.640         ::  15MiB — smaller long-haul chunks for Vere/Caddy stability
::  Buffer-proportional trickle pace:
::    drain_rate = buffer / target-runway
::    slice = drain_rate * trickle-interval = buffer * interval / runway
::  At any moment, current buffer would take `target-runway` to drain.
::  Buffer grows during slow Mesa periods (residential ~10-15 KB/s effective)
::  and accelerates drain naturally; never goes empty under realistic
::  inter-chunk gaps (Ben's residential first-chunk = 11-15 min). Final-
::  chunk path uses (min chunk-size remaining) for max-drain dump after
::  Mesa stops — see /dl-trickle handler in on-arvo.
++  target-runway     `@dr`~h2                  ::  always keep 2h of trickle ahead
++  trickle-interval  `@dr`~s15                 ::  emit every 15s (3x margin under Vere's 45s response generator timer)
++  slice-fast        `@ud`131.072              ::  128KB — final-chunk max-drain only
++  thumb-prefetch-delay  `@dr`~s2              ::  pace thumbnail cache warmup to reduce loom pressure
++  thumb-prefetch-download-delay  `@dr`~m20    ::  don't prefetch art while a browser download is active
++  library-warmup-delay       `@dr`~s30        ::  background library warmup cadence: one metadata edge per tick
++  library-warmup-download-delay  `@dr`~m20    ::  don't compete with active downloads; try again later
++  library-warmup-busy-delay  `@dr`~s30       ::  metadata request already in flight; recheck soon
++  max-concurrent-downloads-global  `@ud`1     ::  demo cap: one active download globally; on-leave frees the slot immediately
::  L3 parallel-chunks window. Each download dispatches up to max-flows
::  concurrent %proxy-request pokes on distinct subscription wires
::  (/proxy-out/{host}/{rid}/{flow-id}). The original design rationale —
::  per-bone cwnd allocation in Mesa ("warm bones") — was disproven
::  2026-05-01 (Mesa keys cwnd on ship-ID, not bone-ID; debate synthesis
::  at MEMORY/WORK/20260501-144502_.../debate-synthesis.md). The N=4
::  configuration STILL measured 2.5x speedup same-machine, but the
::  source of that gain is unverified (likely pipelining / first-byte
::  latency reduction). v1 is compile-time constant; v2 may promote to
::  state field once a multi-pair test rules out residential ISP cap.
::
++  max-flows         `@ud`4                    ::  state+L3 parallel chunks per download
++  max-reserve       `@ud`1.073.741.824        :: 1GiB browser-side reserve; chunk arrivals blast only excess
::  Convenience: every "control plane" poke (library fetch, invitations,
::  thumb prefetch, error responses) rides flow-id 0. Naming the constant
::  rather than writing `\`@ud\`0` everywhere makes intent legible.
::
++  control-flow      `@ud`0
++  passcode         `@t`'burnmeacopy'
++  pass-cookie      `@t`'burn-pass'
++  stream-rh   `response-header:http`[200 ~[['content-type' 'video/mp4']]]
--
::
%-  agent:dbug
::
=|  =state:burn
::
^-  agent:gall
=<
|_  =bowl:gall
+*  this     .
    default  ~(. (default-agent this %|) bowl)
::
::  +on-init: bind Eyre path for burn
::
++  on-init
  ^-  (quip card _this)
  ~&  >  "burn: init"
  =.  proxy-timeout.state  ~m5
  :_  this
  :~  [%pass /eyre/connect %arvo %e %connect [~ /apps/burn] %burn]
  ==
::
::  +on-save: wrap state with epic version
::
++  on-save
  !>([state okay:burn])
::
::  +on-load: preserve state across reloads. State type is in flux;
::  any type-shape change requires |nuke %burn rather than migration.
::
++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  ~&  >  "burn: on-load — preserving state"
  =+  !<([old=state:burn epic=@ud] old-vase)
  [(inflate-io old now.bowl our.bowl) this(state old)]
::
::  +on-poke: handle actions and HTTP requests
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:default mark vase)
  ::
  ::  Canonical Hoon Native UI input event. Stab payload identifies
  ::  a goad node and an interaction kind; we translate to an existing
  ::  +$action and re-enter on-poke so all dispatch logic stays unified.
  ::
      %goon-event
    =/  =stab:goon  !<(stab:goon vase)
    =/  translated=(unit action:burn)
      (translate-stab-to-action stab state)
    ?~  translated
      ~&  >>>  "burn: unhandled goon-event {<stab>}"
      `this
    $(mark %burn-action, vase !>(u.translated))
  ::
  ::  Accept burn-action and noun (Oxal bridge)
  ::
      ?(%burn-action %noun)
    =/  act  !<(action:burn vase)
    ?-  -.act
    ::
    ::  HOST: configure local Plex server
    ::
        %set-host
      ~&  >  "burn: host set to {<url.plex-config.act>}"
      =/  cfg=plex-config:burn  plex-config.act
      ::  Upsert sources[our.bowl] so host library lives under our @p.
      =/  self-src=source-state:burn  (get-source state our.bowl)
      =.  state  (put-source state self-src)
      ::  Inline-fire sections fetch when both creds non-empty AND we
      ::  don't already have a sections cache. No Behn timer.
      =/  fetch-cards=(list card)
        ?:  ?|(=('' url.cfg) =('' token.cfg))  ~
        ?.  =(~ sections.self-src)  ~
        =/  fetch-url=@t  (cat 3 url.cfg '/library/sections')
        =/  hdrs=header-list:http  ~[['x-plex-token' token.cfg] ['accept' 'text/xml']]
        =/  req=request:http  [%'GET' fetch-url hdrs ~]
        ~&  >  "burn: %set-host triggering library-sections fetch"
        ~[[%pass /library-fetch %arvo %i %request req *outbound-config:iris]]
      =/  warm-cards=(list card)
        ?:  =(~ fetch-cards)
          ~[[%pass /library-warmup %arvo %b %wait (add now.bowl library-warmup-delay)]]
        ~
      :_  this(hosting.state `cfg)
      (welp ~[give-redraw] (weld warm-cards fetch-cards))
    ::
        %clear-host
      ~&  >  "burn: hosting cleared — dropping sources[our.bowl] library cache"
      :_  this(hosting.state ~, sources.state (~(del by sources.state) our.bowl))
      ~[give-redraw]
    ::
    ::  HOST: allow/deny subscribers
    ::
        %allow
      ~&  >  "burn: allowing {<ships.act>}"
      =/  new-allowed=(map ship guest-config:burn)
        %-  ~(gas by allowed.state)
        %+  murn  ships.act
        |=  =ship
        ?:  (~(has by allowed.state) ship)  ~
        `[ship '' '']
      :_  this(allowed.state new-allowed)
      ~[give-redraw]
    ::
        %deny
      ~&  >  "burn: denying {<ships.act>}"
      =/  new=(map ship guest-config:burn)  allowed.state
      =.  new
        =/  rem  ships.act
        |-
        ?~  rem  new
        $(rem t.rem, new (~(del by new) i.rem))
      :_  this(allowed.state new)
      ~[give-redraw]
    ::
    ::  HOST: guest identity management
    ::
        %set-guest
      ~&  >  "burn: set guest {<ship.act>} label={<label.act>}"
      =/  gc=guest-config:burn  [token.act label.act]
      :_  this(allowed.state (~(put by allowed.state) ship.act gc))
      ~[give-redraw]
    ::
        %remove-guest
      ~&  >  "burn: remove guest {<ship.act>}"
      :_  this(allowed.state (~(del by allowed.state) ship.act))
      ~[give-redraw]
    ::
    ::  HOST: send invitation over Ames
    ::
        %send-invitation
      ~&  >  "burn: sending invitation to {<ship.act>}"
      ?~  hosting.state
        ~&  >>>  "burn: must be hosting to send invitations"
        `this
      =/  new-allowed=(map ship guest-config:burn)
        ?:  (~(has by allowed.state) ship.act)
          allowed.state
        (~(put by allowed.state) ship.act ['' ''])
      :_  this(allowed.state new-allowed)
      :~  %-  proxy-poke
          :*  ship.act
              (sham eny.bowl)
              control-flow                            ::  L3 flow-id (one-shot poke; control plane stays on flow 0)
              %invitation-offer
              our.bowl
          ==
          give-redraw
      ==
    ::
    ::  SUBSCRIBER: accept invitation — auto-subscribe
    ::
        %accept-invitation
      ~&  >  "burn: accepting invitation from {<ship.act>}"
      =/  inv=(unit invitation:burn)
        (~(get by invitations.state) ship.act)
      ?~  inv
        ~&  >>>  "burn: no invitation from {<ship.act>}"
        `this
      =.  invitations.state
        (~(del by invitations.state) ship.act)
      =/  [cards=(list card) new-sources=(map ship source-state:burn)]
        (do-subscribe ship.act)
      =/  warm-card=card
        [%pass /library-warmup %arvo %b %wait (add now.bowl library-warmup-delay)]
      :_  this(sources.state new-sources)
      (welp ~[give-redraw warm-card] cards)
    ::
    ::  HOST: revoke invitation
    ::
        %revoke-invitation
      ~&  >  "burn: revoking invitation for {<ship.act>}"
      =.  allowed.state  (~(del by allowed.state) ship.act)
      :_  this
      ~[give-redraw]
    ::
    ::  SUBSCRIBER: receive invitation from host
    ::
        %invitation-offer
      ~&  >  "burn: received invitation from {<from.act>}"
      =/  inv=invitation:burn
        [from.act now.bowl %pending]
      =.  invitations.state
        (~(put by invitations.state) from.act inv)
      ~&  >  "burn: use :burn &burn-action [%accept-invitation {<from.act>}] to accept"
      :_  this
      ~[give-redraw]
    ::
    ::  SUBSCRIBER: subscribe / unsubscribe
    ::
        %subscribe
      ~&  >  "burn: subscribing to {<ship.act>}"
      =/  [cards=(list card) new-sources=(map ship source-state:burn)]
        (do-subscribe ship.act)
      =/  warm-card=card
        [%pass /library-warmup %arvo %b %wait (add now.bowl library-warmup-delay)]
      :_  this(sources.state new-sources)
      (welp ~[give-redraw warm-card] cards)
    ::
        %unsubscribe
      ~&  >  "burn: unsubscribing from {<ship.act>}"
      :_  this(sources.state (~(del by sources.state) ship.act))
      :~  [%pass /epic/(scot %p ship.act) %agent [ship.act %burn] %leave ~]
          give-redraw
      ==
    ::
    ::  FETCH: request library sections from Plex
    ::  Publisher: makes Iris call directly
    ::  Subscriber: sends proxy-request to host over Ames
    ::
        %fetch-sections
      ?^  hosting.state
        ::  Publisher path: fetch directly from local Plex.
        ::  Skip if token is empty — Plex without auth returns errors,
        ::  parse=0, which leaves library-sections=~, which makes the
        ::  next /goon watch self-poke another fetch — perpetual loop
        ::  on any open /new-oxal/plex tab. Gate stops the cycle until a
        ::  real token is configured via %set-host.
        =/  cfg=plex-config:burn  u.hosting.state
        ?:  =('' token.cfg)
          ~&  >>  "burn: skipping library fetch — no Plex token configured"
          `this
        =/  fetch-url=@t  (cat 3 url.cfg '/library/sections')
        =/  hdrs=header-list:http  ~[['x-plex-token' token.cfg] ['accept' 'text/xml']]
        =/  req=request:http  [%'GET' fetch-url hdrs ~]
        ~&  >  "burn: fetching library sections from {<url.cfg>}"
        :_  this
        :~  [%pass /library-fetch %arvo %i %request req *outbound-config:iris]
        ==
      ::  Subscriber path: proxy to first source over Ames
      =/  src-list=(list [ship source-state:burn])
        ~(tap by sources.state)
      ?~  src-list
        ~&  >>>  "burn: no sources to fetch from"
        `this
      =/  [host-ship=ship =source-state:burn]
        i.src-list
      =/  rid=@uv  (sham eny.bowl)
      ~&  >  "burn: requesting library sections from {<host-ship>}"
      =/  ifetch=internal-fetch:burn  [%library-sections '' now.bowl]
      =.  internal-pending.state
        (~(put by internal-pending.state) rid ifetch)
      :_  this
      :~  %-  proxy-poke
          :*  host-ship
              rid
              control-flow                            ::  L3 flow-id (control plane / library fetch — flow 0)
              %proxy-request
              host-ship
              rid
              %'GET'
              '/library/sections'
              ~
              ~
              control-flow                            ::  L3 flow-id payload (matches wire flow-id)
          ==
      ==
    ::
    ::  FETCH: request library items for a section
    ::  Publisher: Iris call to /library/sections/[key]/all
    ::  Subscriber: proxy-request to host
    ::
        %fetch-items
      =/  section-key=@t  key.act
      ?^  hosting.state
        ::  Publisher path: fetch directly from local Plex.
        =/  cfg=plex-config:burn  u.hosting.state
        ?:  =('' token.cfg)
          ~&  >>  "burn: skipping items fetch — no Plex token configured"
          `this
        =/  fetch-url=@t
          (cat 3 url.cfg (cat 3 '/library/sections/' (cat 3 section-key '/all')))
        =/  hdrs=header-list:http  ~[['x-plex-token' token.cfg] ['accept' 'text/xml']]
        =/  req=request:http  [%'GET' fetch-url hdrs ~]
        ~&  >  "burn: fetching items for section {<section-key>}"
        :_  this
        :~  [%pass /items-fetch/[section-key] %arvo %i %request req *outbound-config:iris]
        ==
      ::  Subscriber path: proxy to first source over Ames
      =/  src-list=(list [ship source-state:burn])
        ~(tap by sources.state)
      ?~  src-list
        ~&  >>>  "burn: no sources to fetch items from"
        `this
      =/  [host-ship=ship =source-state:burn]
        i.src-list
      =/  rid=@uv  (sham eny.bowl)
      ~&  >  "burn: requesting items for section {<section-key>} from {<host-ship>}"
      =/  ifetch=internal-fetch:burn  [%library-items section-key now.bowl]
      =.  internal-pending.state
        (~(put by internal-pending.state) rid ifetch)
      :_  this
      :~  %-  proxy-poke
          :*  host-ship
              rid
              control-flow                            ::  L3 flow-id (control plane / library fetch — flow 0)
              %proxy-request
              host-ship
              rid
              %'GET'
              (cat 3 '/library/sections/' (cat 3 section-key '/all'))
              ~
              ~
              control-flow                            ::  L3 flow-id payload (matches wire flow-id)
          ==
      ==
    ::
    ::  FETCH: request seasons for a show (state hierarchy)
    ::  Publisher: Iris call to /library/metadata/[rkey]/children
    ::  Subscriber: proxy-request to host
    ::
        %fetch-show-children
      =/  show-rkey=@t  rkey.act
      ?^  hosting.state
        =/  cfg=plex-config:burn  u.hosting.state
        =/  fetch-url=@t
          (cat 3 url.cfg (cat 3 '/library/metadata/' (cat 3 show-rkey '/children')))
        =/  hdrs=header-list:http  ~[['x-plex-token' token.cfg] ['accept' 'text/xml']]
        =/  req=request:http  [%'GET' fetch-url hdrs ~]
        ~&  >  "burn: fetching show children for rkey={<show-rkey>}"
        :_  this
        :~  [%pass /show-children-fetch/[show-rkey] %arvo %i %request req *outbound-config:iris]
        ==
      =/  src-list=(list [ship source-state:burn])
        ~(tap by sources.state)
      ?~  src-list
        ~&  >>>  "burn: no sources to fetch show children from"
        `this
      =/  [host-ship=ship =source-state:burn]
        i.src-list
      =/  rid=@uv  (sham eny.bowl)
      ~&  >  "burn: requesting show children rkey={<show-rkey>} from {<host-ship>}"
      =/  ifetch=internal-fetch:burn  [%show-children show-rkey now.bowl]
      =.  internal-pending.state
        (~(put by internal-pending.state) rid ifetch)
      :_  this
      :~  %-  proxy-poke
          :*  host-ship
              rid
              control-flow
              %proxy-request
              host-ship
              rid
              %'GET'
              (cat 3 '/library/metadata/' (cat 3 show-rkey '/children'))
              ~
              ~
              control-flow
          ==
      ==
    ::
    ::  FETCH: request episodes for a season (state hierarchy)
    ::
        %fetch-season-children
      =/  season-rkey=@t  rkey.act
      =/  selected-src=source-state:burn
        (get-source state (pick-host-ship state our.bowl))
      ?:  (~(has by episodes.selected-src) season-rkey)
        ::  Episodes already in state — skip the fetch, just redraw
        `this
      ?^  hosting.state
        =/  cfg=plex-config:burn  u.hosting.state
        =/  fetch-url=@t
          (cat 3 url.cfg (cat 3 '/library/metadata/' (cat 3 season-rkey '/children')))
        =/  hdrs=header-list:http  ~[['x-plex-token' token.cfg] ['accept' 'text/xml']]
        =/  req=request:http  [%'GET' fetch-url hdrs ~]
        ~&  >  "burn: fetching season children for rkey={<season-rkey>}"
        :_  this
        :~  [%pass /season-children-fetch/[season-rkey] %arvo %i %request req *outbound-config:iris]
        ==
      =/  src-list=(list [ship source-state:burn])
        ~(tap by sources.state)
      ?~  src-list
        ~&  >>>  "burn: no sources to fetch season children from"
        `this
      =/  [host-ship=ship =source-state:burn]
        i.src-list
      =/  rid=@uv  (sham eny.bowl)
      ~&  >  "burn: requesting season children rkey={<season-rkey>} from {<host-ship>}"
      =/  ifetch=internal-fetch:burn  [%season-children season-rkey now.bowl]
      =.  internal-pending.state
        (~(put by internal-pending.state) rid ifetch)
      :_  this
      :~  %-  proxy-poke
          :*  host-ship
              rid
              control-flow
              %proxy-request
              host-ship
              rid
              %'GET'
              (cat 3 '/library/metadata/' (cat 3 season-rkey '/children'))
              ~
              ~
              control-flow
        ==
      ==
    ::
    ::  FETCH: request albums for an artist (music hierarchy)
    ::
        %fetch-artist-children
      =/  artist-rkey=@t  rkey.act
      =/  selected-src=source-state:burn
        (get-source state (pick-host-ship state our.bowl))
      ?:  (~(has by seasons.selected-src) artist-rkey)
        `this
      ?^  hosting.state
        =/  cfg=plex-config:burn  u.hosting.state
        =/  fetch-url=@t
          (cat 3 url.cfg (cat 3 '/library/metadata/' (cat 3 artist-rkey '/children')))
        =/  hdrs=header-list:http  ~[['x-plex-token' token.cfg] ['accept' 'text/xml']]
        =/  req=request:http  [%'GET' fetch-url hdrs ~]
        ~&  >  "burn: fetching artist children for rkey={<artist-rkey>}"
        :_  this
        :~  [%pass /artist-children-fetch/[artist-rkey] %arvo %i %request req *outbound-config:iris]
        ==
      =/  src-list=(list [ship source-state:burn])
        ~(tap by sources.state)
      ?~  src-list
        ~&  >>>  "burn: no sources to fetch artist children from"
        `this
      =/  [host-ship=ship =source-state:burn]
        i.src-list
      =/  rid=@uv  (sham eny.bowl)
      ~&  >  "burn: requesting artist children rkey={<artist-rkey>} from {<host-ship>}"
      =/  ifetch=internal-fetch:burn  [%artist-children artist-rkey now.bowl]
      =.  internal-pending.state
        (~(put by internal-pending.state) rid ifetch)
      :_  this
      :~  %-  proxy-poke
          :*  host-ship
              rid
              control-flow
              %proxy-request
              host-ship
              rid
              %'GET'
              (cat 3 '/library/metadata/' (cat 3 artist-rkey '/children'))
              ~
              ~
              control-flow
          ==
      ==
    ::
    ::  FETCH: request tracks for an album (music hierarchy)
    ::
        %fetch-album-children
      =/  album-rkey=@t  rkey.act
      =/  selected-src=source-state:burn
        (get-source state (pick-host-ship state our.bowl))
      ?:  (~(has by episodes.selected-src) album-rkey)
        `this
      ?^  hosting.state
        =/  cfg=plex-config:burn  u.hosting.state
        =/  fetch-url=@t
          (cat 3 url.cfg (cat 3 '/library/metadata/' (cat 3 album-rkey '/children')))
        =/  hdrs=header-list:http  ~[['x-plex-token' token.cfg] ['accept' 'text/xml']]
        =/  req=request:http  [%'GET' fetch-url hdrs ~]
        ~&  >  "burn: fetching album children for rkey={<album-rkey>}"
        :_  this
        :~  [%pass /album-children-fetch/[album-rkey] %arvo %i %request req *outbound-config:iris]
        ==
      =/  src-list=(list [ship source-state:burn])
        ~(tap by sources.state)
      ?~  src-list
        ~&  >>>  "burn: no sources to fetch album children from"
        `this
      =/  [host-ship=ship =source-state:burn]
        i.src-list
      =/  rid=@uv  (sham eny.bowl)
      ~&  >  "burn: requesting album children rkey={<album-rkey>} from {<host-ship>}"
      =/  ifetch=internal-fetch:burn  [%album-children album-rkey now.bowl]
      =.  internal-pending.state
        (~(put by internal-pending.state) rid ifetch)
      :_  this
      :~  %-  proxy-poke
          :*  host-ship
              rid
              control-flow
              %proxy-request
              host-ship
              rid
              %'GET'
              (cat 3 '/library/metadata/' (cat 3 album-rkey '/children'))
              ~
              ~
              control-flow
          ==
      ==
    ::
    ::  CLEAR-STREAMS: nuke all in-flight subscriber download/stream
    ::  state. Use when zombies pile up and fogduc is drowning in
    ::  pre-fire requests for dead browser sessions.
    ::
    ::  Auth: host-only (src.bowl == our.bowl). Mirrors %clear-cache gate
    ::  pattern at line 520. Public viewers and subscribers cannot reap
    ::  the global stream slot; only the host running this burn instance.
    ::
        %clear-streams
      ?.  =(src.bowl our.bowl)
        ~&  >>>  "burn: clear-streams from non-host {<src.bowl>}, rejected"
        `this
      =/  rids=(list @uv)  ~(tap in ~(key by pending-streams.state))
      =/  kick-cards=(list card)
        %+  turn  rids
        |=  rid=@uv
        ^-  card
        =/  ss=stream-state:burn
          (~(got by pending-streams.state) rid)
        [%give %kick ~[/http-response/[eyre-id.ss]] ~]
      ~&  >  "burn: CLEAR-STREAMS reaped {<(lent rids)>} streams + buffers"
      =.  pending-streams.state  ~
      =.  octs-buffer.state  ~
      =.  deferred-headers.state  ~
      =.  stream-arrivals.state  ~
      ::  L3 parallel-chunks: nuke the per-rid parallel maps too.
      =.  reassembly.state  ~
      =.  final-seq.state  ~
      [[give-redraw kick-cards] this]
    ::
    ::  CANCEL-STREAM: reap one in-flight subscriber stream by rid. Atomic
    ::  cleanup via delete-stream. No-op (with slog) if rid is unknown.
    ::  Used by the goon UI's cancel button on /downloads/<rid>.
    ::
    ::  Auth: src.bowl must be either the host (our.bowl) or the stream's
    ::  initiator (recorded at creation in stream-state). Public viewers
    ::  cannot cancel someone else's download.
    ::
        %cancel-stream
      =/  ss=(unit stream-state:burn)
        (~(get by pending-streams.state) rid.act)
      ?~  ss
        ~&  >>  "burn: cancel-stream rid={<(short-id-uv rid.act)>} not found"
        `this
      ?.  ?|  =(src.bowl our.bowl)
              =(src.bowl initiator.u.ss)
          ==
        ~&  >>>  "burn: cancel-stream from {<src.bowl>} for rid={<(short-id-uv rid.act)>} rejected (not host or initiator {<initiator.u.ss>})"
        `this
      =/  kick-card=card
        [%give %kick ~[/http-response/[eyre-id.u.ss]] ~]
      ~&  >  "burn: CANCEL-STREAM rid={<(short-id-uv rid.act)>} by {<src.bowl>}"
      =.  state  (delete-stream state rid.act)
      [~[give-redraw kick-card] this]
    ::
    ::  CLEAR-CACHE: evict every Eyre cache entry burn has written.
    ::  Self-pokes only. Walks sources/items/seasons/episodes to derive
    ::  the same /apps/burn{thumb} URLs the cache-set sites wrote (lines
    ::  721, 781, 1640, 1666), emits %set-response url ~ per. Eyre's
    ::  native aeon counter increments on each call (eyre.hoon:3252),
    ::  Vere evicts from its serving cache. Also resets thumb-queue,
    ::  reaps any %thumb-prefetch internal-pending entries, then requeues
    ::  every current metadata-derived thumb URL so clear-cache is a real
    ::  refresh/warm operation rather than just an eviction. Any in-flight
    ::  response that lands after this is treated as an orphan by the
    ::  response handlers (no cache write) because the internal-pending
    ::  lookup will miss.
    ::
        %clear-cache
      ?.  =(src.bowl our.bowl)
        ~&  >>>  "burn: clear-cache from non-self {<src.bowl>}, rejected"
        `this
      =/  urls=(list @t)  (derive-all-cached-urls state)
      =/  cards=(list card)
        %+  turn  urls
        |=  u=@t
        ^-  card
        [%pass /cache %arvo %e %set-response u ~]
      ~&  >  "burn: CLEAR-CACHE evicting {<(lent cards)>} entries"
      =.  thumb-queue.state  ~
      =.  state  (reap-prefetch-pending state)
      =^  fresh=(list @t)  state  (enqueue-thumb-urls state urls)
      =^  prefetch-cards=(list card)  state  (dispatch-prefetches state bowl)
      ~&  >  "burn: CLEAR-CACHE requeued {<(lent fresh)>} thumbs ({<(lent thumb-queue.state)>} queued)"
      [(weld cards prefetch-cards) this]
    ::
    ::  HOST: handle proxy request from subscriber
    ::
        %proxy-request
      ?~  hosting.state
        ~&  >>>  "burn: proxy request but not hosting"
        `this
      =/  cfg=plex-config:burn  u.hosting.state
      =/  url-tape=tape  (trip url.act)
      ::  Subscriber sends full Eyre URL including /apps/burn prefix
      =/  dl-prefix=tape  "/apps/burn/download/"
      =/  dl-short=tape   "/download/"
      =/  dl-match=?
        ?|  =((scag (lent dl-prefix) url-tape) dl-prefix)
            =((scag (lent dl-short) url-tape) dl-short)
        ==
      =/  st-prefix=tape  "/apps/burn/stream/"
      =/  st-short=tape   "/stream/"
      =/  st-match=?
        ?|  =((scag (lent st-prefix) url-tape) st-prefix)
            =((scag (lent st-short) url-tape) st-short)
        ==
      =/  tok=(unit @t)
        =/  rt=(unit @t)
          %:  resolve-token
            src.bowl
            our.bowl
            cfg
            allowed.state
          ==
        ?:  ?=(^ rt)  rt
        ?:  ?&  ?|(dl-match st-match)
                (download-auth-ok src.bowl our.bowl %.n)
            ==
          `token.cfg
        ~
      ?~  tok
        ~&  >>>  "burn: proxy rejected from {<src.bowl>}"
        `this
      =/  guest-tok=@t  u.tok
      ?:  dl-match
        ::  Check if this is a subsequent Range request (Part URL already resolved)
        =/  stored-url=(unit @t)
          (~(get by pending.state) (scot %uv rid.act))
        ?^  stored-url
          ::  Subsequent chunk — use stored Part URL with Range header
          =/  full-url=@t  (cat 3 url.cfg u.stored-url)
          =/  req=request:http  [%'GET' full-url (range-only-headers headers.act) ~]
          ::  Extract seq from Range header — see extract-seq-from-range
          =/  seq=@ud  (extract-seq-from-range headers.act)
          ~&  >  "burn: download chunk {<+(seq)>} for {<src.bowl>} rid={<(short-id-uv rid.act)>} flow={<flow-id.act>} t={<now.bowl>}"
          :_  this
          :~  [%pass /download-proxy/(scot %p src.bowl)/(scot %uv rid.act)/(scot %ud seq)/(scot %ud flow-id.act) %arvo %i %request req *outbound-config:iris]
          ==
        ::  First request — fetch metadata to get Part key
        =/  rkey=tape
          ?:  =((scag (lent dl-prefix) url-tape) dl-prefix)
            (slag (lent dl-prefix) url-tape)
          (slag (lent dl-short) url-tape)
        =/  range-info=(unit [start=@ud end=(unit @ud)])
          (parse-range headers.act)
        =/  start-byte=@ud  ?~(range-info 0 start.u.range-info)
        =/  start-seq=@ud  (chunk-seq-for-byte start-byte)
        =/  meta-url=@t
          (crip "/library/metadata/{rkey}?X-Plex-Token={(trip guest-tok)}")
        =/  proxy-url=@t  (cat 3 url.cfg meta-url)
        =/  req=request:http  [%'GET' proxy-url ~ ~]
        ~&  >  "burn: download metadata for {<src.bowl>} rkey={<(crip rkey)>} rid={<(short-id-uv rid.act)>} start-byte={<start-byte>} start-seq={<start-seq>}"
        :_  this
        :~  [%pass /download-meta-proxy/(scot %p src.bowl)/(scot %uv rid.act)/(scot %ud start-seq)/(scot %ud start-byte) %arvo %i %request req *outbound-config:iris]
        ==
      ::  HOST: handle stream proxy-request from subscriber
      ?:  st-match
        ::  Check if this is a subsequent Range request (Part URL already resolved)
        =/  stored-url=(unit @t)
          (~(get by pending.state) (scot %uv rid.act))
        ?^  stored-url
          ::  Subsequent chunk — use stored Part URL with Range header
          =/  full-url=@t  (cat 3 url.cfg u.stored-url)
          =/  req=request:http  [%'GET' full-url (range-only-headers headers.act) ~]
          =/  seq=@ud  (extract-seq-from-range headers.act)
          ~&  >  "burn: stream chunk {<+(seq)>} for {<src.bowl>} rid={<(short-id-uv rid.act)>} flow={<flow-id.act>} t={<now.bowl>}"
          :_  this
          :~  [%pass /stream-proxy/(scot %p src.bowl)/(scot %uv rid.act)/(scot %ud seq)/(scot %ud flow-id.act) %arvo %i %request req *outbound-config:iris]
          ==
        ::  First request — fetch metadata to get Part key
        =/  rkey=tape
          ?:  =((scag (lent st-prefix) url-tape) st-prefix)
            (slag (lent st-prefix) url-tape)
          (slag (lent st-short) url-tape)
        =/  meta-url=@t
          (crip "/library/metadata/{rkey}?X-Plex-Token={(trip guest-tok)}")
        =/  proxy-url=@t  (cat 3 url.cfg meta-url)
        =/  req=request:http  [%'GET' proxy-url ~ ~]
        ~&  >  "burn: stream metadata for {<src.bowl>} rkey={<(crip rkey)>} rid={<(short-id-uv rid.act)>}"
        :_  this
        :~  [%pass /stream-meta-proxy/(scot %p src.bowl)/(scot %uv rid.act) %arvo %i %request req *outbound-config:iris]
        ==
      ::  Normal proxy — strip /apps/burn prefix, build URL and forward
      =/  clean-url=@t
        =/  ut=tape  (trip url.act)
        =/  pfx=tape  "/apps/burn"
        ?:  =((scag (lent pfx) ut) pfx)
          (crip (slag (lent pfx) ut))
        url.act
      ::  Thumbnail: transcode via Plex, cache in Eyre on response
      ?:  (is-thumb-url clean-url)
        =/  tc-url=@t  (thumb-transcode-url clean-url guest-tok)
        =/  proxy-url=@t  (cat 3 url.cfg tc-url)
        =/  req=request:http  [%'GET' proxy-url ~ ~]
        ~&  >  "burn: thumb fetch for {<src.bowl>} rid={<(short-id-uv rid.act)>}"
        =.  pending.state  (~(put by pending.state) (scot %uv rid.act) clean-url)
        :_  this
        :~  [%pass /thumb-proxy/(scot %p src.bowl)/(scot %uv rid.act) %arvo %i %request req *outbound-config:iris]
        ==
      =/  proxy-url=@t  (cat 3 url.cfg clean-url)
      =/  proxy-headers=header-list:http  (rewrite-headers headers.act guest-tok)
      =/  req=request:http  [method.act proxy-url proxy-headers body.act]
      ~&  >  "burn: proxying for {<src.bowl>} rid={<(short-id-uv rid.act)>}"
      :_  this
      :~  [%pass /proxy/(scot %p src.bowl)/(scot %uv rid.act) %arvo %i %request req *outbound-config:iris]
      ==
    ::
    ::  SUBSCRIBER: handle proxy response from host
    ::  Check internal-pending first (state-bound), then Eyre-bound.
    ::
    ::  L3 parallel-chunks: if this rid maps to an active stream, free the
    ::  flow that just errored so dispatch-flows can reuse the slot. This
    ::  is the recovery path for transient host iris failures (502/404/500
    ::  emitted from on-arvo download-proxy/stream-proxy arms). Without
    ::  this, every error permanently burns a flow slot and after max-flows
    ::  errors the stream hangs.
    ::
        %proxy-response
      ~&  >  "burn: proxy-response arrived from {<src.bowl>} rid={<(short-id-uv rid.act)>} status={<status.act>} flow={<flow-id.act>}"
      =/  ss-l3=(unit stream-state:burn)
        (~(get by pending-streams.state) rid.act)
      =?  pending-streams.state  ?=(^ ss-l3)
        =/  ent=(unit flow-state:burn)
          (~(get by flows.u.ss-l3) flow-id.act)
        ?~  ent  pending-streams.state
        ~&  >>>  "burn: freeing flow {<flow-id.act>} on rid={<(short-id-uv rid.act)>} after %proxy-response status={<status.act>}"
        (~(put by pending-streams.state) rid.act u.ss-l3(flows (~(put by flows.u.ss-l3) flow-id.act [%idle 0])))
      =/  ifetch=(unit internal-fetch:burn)
        (~(get by internal-pending.state) rid.act)
      ?^  ifetch
        ::  Internal fetch — route to state, not Eyre
        =.  internal-pending.state
          (~(del by internal-pending.state) rid.act)
        ~&  >  "burn: internal response rid={<(short-id-uv rid.act)>} tag={<tag.u.ifetch>}"
        ?+  tag.u.ifetch  `this
            %library-sections
          ?~  body.act
            ~&  >>>  "burn: library fetch response has no body"
            `this
          =/  sections=(list library-section:burn)
            (parse-library-sections q.u.body.act)
          ~&  >  "burn: parsed {<(lent sections)>} library sections via proxy from {<src.bowl>}"
          =/  src-entry=source-state:burn  (get-source state src.bowl)
          =.  state  (put-source state src-entry(sections sections))
          :_  this
          (welp ~[give-redraw] (eager-library-fetches state src.bowl our.bowl))
        ::
            %library-items
          ?~  body.act
            ~&  >>>  "burn: items fetch response has no body"
            `this
          =/  section-key=@t  key.u.ifetch
          =/  items=(list library-item:burn)
            (parse-library-items q.u.body.act section-key)
          ~&  >  "burn: parsed {<(lent items)>} items for section {<section-key>} via proxy from {<src.bowl>}"
          =/  src-entry=source-state:burn  (get-source state src.bowl)
          =.  state
            %+  put-source  state
            src-entry(items (~(put by items.src-entry) section-key items))
          =/  candidates=(list @t)
            (murn items |=(li=library-item:burn (thumb-to-cache-url thumb.li (library-item-kind:burn-to-goad type.li))))
          =^  fresh=(list @t)  state  (enqueue-thumb-urls state candidates)
          =^  prefetch-cards=(list card)  state  (dispatch-prefetches state bowl)
          ~&  >  "burn: queued {<(lent fresh)>} thumbs ({<(lent thumb-queue.state)>} now queued)"
          :_  this
          ;:  welp
            ~[give-redraw]
            (give-items section-key items)
            prefetch-cards
            (eager-library-fetches state src.bowl our.bowl)
          ==
        ::
            %thumb-prefetch
          ::  Subscriber-mode prefetch response. ifetch was looked up
          ::  via rid in the parent arm (line 661-666) and deleted from
          ::  internal-pending — so we know this response was tracked
          ::  (not orphaned by %clear-cache). Cache on 2xx, then pace
          ::  the next queued prefetch through Behn.
          =/  cache-url=@t  key.u.ifetch
          ?.  &(=(200 status.act) ?=(^ body.act))
            ~&  >>>  "burn: prefetch failed status={<status.act>} for {<cache-url>}"
            =/  next-cards=(list card)  (schedule-prefetch state now.bowl)
            [next-cards this]
          =/  rh-cache=response-header:http
            [200 ~[['content-type' 'image/jpeg'] ['cache-control' 'max-age=86400']]]
          =/  sp-cache=simple-payload:http  [rh-cache body.act]
          ~&  >  "burn: prefetch cached {<cache-url>} ({<p.u.body.act>}b), {<(lent thumb-queue.state)>} queued"
          =/  next-cards=(list card)  (schedule-prefetch state now.bowl)
          :_  this
          :-  [%pass /cache %arvo %e %set-response cache-url `[%.n %payload sp-cache]]
          next-cards
        ::
            %show-children
          ?~  body.act
            ~&  >>>  "burn: show-children fetch response has no body"
            `this
          =/  show-rkey=@t  key.u.ifetch
          =/  seasons=(list season-item:burn)
            (parse-show-children q.u.body.act)
          ~&  >  "burn: parsed {<(lent seasons)>} seasons for show {<show-rkey>} via proxy from {<src.bowl>}"
          =/  src-entry=source-state:burn  (get-source state src.bowl)
          =.  state
            %+  put-source  state
            src-entry(seasons (~(put by seasons.src-entry) show-rkey seasons))
          =/  candidates=(list @t)
            (murn seasons |=(s=season-item:burn (thumb-to-cache-url thumb.s %tall)))
          =^  fresh=(list @t)  state  (enqueue-thumb-urls state candidates)
          =^  prefetch-cards=(list card)  state  (dispatch-prefetches state bowl)
          ~&  >  "burn: queued {<(lent fresh)>} season thumbs ({<(lent thumb-queue.state)>} now queued)"
          :_  this
          ;:  welp
            ~[give-redraw]
            prefetch-cards
            (eager-library-fetches state src.bowl our.bowl)
          ==
        ::
            %season-children
          ?~  body.act
            ~&  >>>  "burn: season-children fetch response has no body"
            `this
          =/  season-rkey=@t  key.u.ifetch
          =/  episodes=(list episode-item:burn)
            (parse-season-children q.u.body.act)
          ~&  >  "burn: parsed {<(lent episodes)>} episodes for season {<season-rkey>} via proxy from {<src.bowl>}"
          =/  src-entry=source-state:burn  (get-source state src.bowl)
          =.  state
            %+  put-source  state
            src-entry(episodes (~(put by episodes.src-entry) season-rkey episodes))
          =/  candidates=(list @t)
            (murn episodes |=(e=episode-item:burn (thumb-to-cache-url thumb.e %wide)))
          =^  fresh=(list @t)  state  (enqueue-thumb-urls state candidates)
          =^  prefetch-cards=(list card)  state  (dispatch-prefetches state bowl)
          ~&  >  "burn: queued {<(lent fresh)>} episode thumbs ({<(lent thumb-queue.state)>} now queued)"
          :_  this
          ;:  welp
            ~[give-redraw]
            prefetch-cards
            (eager-library-fetches state src.bowl our.bowl)
          ==
        ::
            %artist-children
          ?~  body.act
            ~&  >>>  "burn: artist-children fetch response has no body"
            `this
          =/  artist-rkey=@t  key.u.ifetch
          =/  albums=(list season-item:burn)
            (parse-show-children q.u.body.act)
          ~&  >  "burn: parsed {<(lent albums)>} albums for artist {<artist-rkey>} via proxy from {<src.bowl>}"
          =/  src-entry=source-state:burn  (get-source state src.bowl)
          =.  state
            %+  put-source  state
            src-entry(seasons (~(put by seasons.src-entry) artist-rkey albums))
          =/  candidates=(list @t)
            (murn albums |=(a=season-item:burn (thumb-to-cache-url thumb.a %square)))
          =^  fresh=(list @t)  state  (enqueue-thumb-urls state candidates)
          =^  prefetch-cards=(list card)  state  (dispatch-prefetches state bowl)
          ~&  >  "burn: queued {<(lent fresh)>} album thumbs ({<(lent thumb-queue.state)>} now queued)"
          :_  this
          ;:  welp
            ~[give-redraw]
            prefetch-cards
            (eager-library-fetches state src.bowl our.bowl)
          ==
        ::
            %album-children
          ?~  body.act
            ~&  >>>  "burn: album-children fetch response has no body"
            `this
          =/  album-rkey=@t  key.u.ifetch
          =/  tracks=(list episode-item:burn)
            (parse-album-children q.u.body.act)
          ~&  >  "burn: parsed {<(lent tracks)>} tracks for album {<album-rkey>} via proxy from {<src.bowl>}"
          =/  src-entry=source-state:burn  (get-source state src.bowl)
          =.  state
            %+  put-source  state
            src-entry(episodes (~(put by episodes.src-entry) album-rkey tracks))
          =/  candidates=(list @t)
            (murn tracks |=(t=episode-item:burn (thumb-to-cache-url thumb.t %square)))
          =^  fresh=(list @t)  state  (enqueue-thumb-urls state candidates)
          =^  prefetch-cards=(list card)  state  (dispatch-prefetches state bowl)
          ~&  >  "burn: queued {<(lent fresh)>} track thumbs ({<(lent thumb-queue.state)>} now queued)"
          :_  this
          ;:  welp
            ~[give-redraw]
            prefetch-cards
            (eager-library-fetches state src.bowl our.bowl)
          ==
        ==
      ::  Eyre-bound proxy response
      =/  pe=(unit proxy-entry:burn)  (~(get by pending-proxies.state) rid.act)
      ?~  pe
        ::  Browser may cancel an <img> request before the host response
        ::  returns (SSE morph, navigation, reload, or HTTP timeout).
        ::  on-leave reaps pending-proxies so there is no Eyre client to
        ::  serve, but pending[rid] still records the original URL. If the
        ::  late response is a successful thumbnail, still populate Eyre's
        ::  cache so the next request is local instead of re-proxying.
        =/  rid-key=@t  (scot %uv rid.act)
        =/  late-url=(unit @t)  (~(get by pending.state) rid-key)
        =.  pending.state  (~(del by pending.state) rid-key)
        ?.  ?&  ?=(^ late-url)
                =(200 status.act)
                ?=(^ body.act)
                (is-thumb-url u.late-url)
            ==
          ~&  >>>  "burn: proxy response for unknown rid {<(short-id-uv rid.act)>}"
          `this
        =/  rh-cache=response-header:http
          [200 ~[['content-type' 'image/jpeg'] ['cache-control' 'max-age=86400']]]
        =/  sp-cache=simple-payload:http  [rh-cache body.act]
        ~&  >  "burn: late thumb cached {<u.late-url>} ({<p.u.body.act>}b)"
        :_  this
        :~  [%pass /cache %arvo %e %set-response u.late-url `[%.n %payload sp-cache]]
        ==
      =.  pending-proxies.state
        (~(del by pending-proxies.state) rid.act)
      ::  Look up original URL to check if thumbnail
      =/  rid-key=@t  (scot %uv rid.act)
      =/  orig-url=(unit @t)  (~(get by pending.state) rid-key)
      =.  pending.state  (~(del by pending.state) rid-key)
      ~&  >  "burn: proxy response rid={<(short-id-uv rid.act)>} status={<status.act>}"
      =/  rh=response-header:http  [status.act headers.act]
      =/  sp=simple-payload:http  [rh body.act]
      ::  If thumbnail response with body, cache in subscriber's Eyre
      =/  cache-cards=(list card)
        ?.  ?&  ?=(^ orig-url)
                =(200 status.act)
                ?=(^ body.act)
                (is-thumb-url u.orig-url)
            ==
          ~
        =/  rh-cache=response-header:http
          [200 ~[['content-type' 'image/jpeg'] ['cache-control' 'max-age=86400']]]
        =/  sp-cache=simple-payload:http  [rh-cache body.act]
        ~&  >  "burn: sub eyre-cached {<u.orig-url>} ({<p.u.body.act>}b)"
        :~  [%pass /cache %arvo %e %set-response u.orig-url `[%.n %payload sp-cache]]
        ==
      :_  this
      %+  weld  (give-simple-payload:app:server eyre-id.u.pe sp)
      cache-cards
    ::
    ::  SUBSCRIBER: handle chunked proxy response from host
    ::
        %proxy-chunk
      =/  ss=(unit stream-state:burn)
        (~(get by pending-streams.state) rid.act)
      =/  rh=response-header:http  [status.act headers.act]
      ?~  ss
        ::  First chunk — find pending-proxies entry. (Defensive path: this
        ::  branch fires when pending-streams was wiped but a chunk still
        ::  arrived. Normal download/stream flow pre-populates pending-streams
        ::  in the subscriber arms above, so chunks land in the subsequent
        ::  branch below. Defensive cleanup of any stale deferred-headers.)
        ::
        ::  L3 parallel-chunks: zombie guard. A chunk with seq>0 arriving when
        ::  pending-streams is empty means a parallel flow returned AFTER
        ::  delete-stream already reaped (final chunk drained, stream done,
        ::  but a slow flow with seq>final-seq is still in flight). The
        ::  pre-L3 defensive ctor below would synthesize a fresh stream-
        ::  state and emit bytes for a kicked Eyre id. Drop it.
        ?:  (gth seq.act 0)
          ~&  >>>  "burn: zombie chunk drop rid={<(short-id-uv rid.act)>} seq={<+(seq.act)>} flow={<flow-id.act>} (no pending-streams)"
          `this
        =/  pe=(unit proxy-entry:burn)
          (~(get by pending-proxies.state) rid.act)
        ?~  pe
          ~&  >>>  "burn: proxy-chunk for unknown rid {<(short-id-uv rid.act)>}"
          `this
        =/  eid=@ta  eyre-id.u.pe
        =/  orig-url=@t
          (fall (~(get by pending.state) (scot %uv rid.act)) '')
        =.  pending-proxies.state
          (~(del by pending-proxies.state) rid.act)
        =.  deferred-headers.state
          (~(del by deferred-headers.state) rid.act)
        ?:  has-more.act
          ::  Capture total file size from response headers — Content-Range
          ::  on 206, Content-Length on 200. Stays 0 if neither known
          ::  (chunked transfer encoding, etc.).
          =/  total=@ud  (extract-total-from-headers headers.act)
          =/  new-ss=stream-state:burn
            :*  eid
                src.bowl
                our.bowl             ::  initiator: defensive default (no proxy-entry initiator tracked yet — subscriber-path cancel-stream falls back to host-only)
                orig-url
                now.bowl             ::  started: stream acceptance time
                total
                p.data.act
                chunk-size
                0
                1
                %.y
                p.data.act           ::  emitted = bytes we just shipped
                ''                   ::  display-name (defensive — no metadata)
                empty-media-path     ::  media-path (defensive — no metadata)
                %$                   ::  container — unknown
                ~                    ::  L3 flows: ~ (defensive ctor; dispatch-flows will fill on next chunk)
            ==
          =.  pending-streams.state
            (~(put by pending-streams.state) rid.act new-ss)
          =.  stream-arrivals.state
            (~(put by stream-arrivals.state) rid.act now.bowl)
          =/  next-cards=(list card)
            (request-next-chunk rid.act src.bowl orig-url 1 total control-flow)
          :_  this
          :*  [%give %fact ~[/http-response/[eid]] %http-response-header !>(rh)]
              [%give %fact ~[/http-response/[eid]] %http-response-data !>((some `octs`data.act))]
              (give-progress-fact rid.act new-ss)
              ::  Defensive first-chunk path creates a stream-state; emit
              ::  the redraw so the live-strip wires up.
              give-redraw
              next-cards
          ==
        =.  pending.state
          (~(del by pending.state) (scot %uv rid.act))
        :_  this
        :~  [%give %fact ~[/http-response/[eid]] %http-response-header !>(rh)]
            [%give %fact ~[/http-response/[eid]] %http-response-data !>((some `octs`data.act))]
            ::  Single-chunk complete response — no stream-state to progress-fact;
            ::  the SSE subscriber (if any) won't have caught the strip up yet.
            [%give %kick ~[/http-response/[eid]] ~]
        ==
      ::  Subsequent chunk (also: the FIRST chunk for downloads/streams,
      ::  since their subscriber arms pre-populate pending-streams).
      ::
      ::  L3 parallel-chunks: chunks may arrive OUT OF ORDER under parallel
      ::  flows. Path forks on seq.act vs seq.st (next-emit-seq):
      ::    seq.act < seq.st: stale duplicate — drop
      ::    seq.act > seq.st: park in reassembly[rid][seq.act], dispatch-flows
      ::    seq.act = seq.st: in-order — apply through trickle pipeline,
      ::                      drain any contiguous parked chunks, dispatch-flows
      ::
      ::  TRICKLE-PACE: apply-one-chunk-into-stream stores chunk bytes in
      ::  octs-buffer, emits the deferred header on chunk-0 + FIRST slice
      ::  immediately, and schedules /dl-trickle when the buffer was empty.
      ::  Drained chunks reuse the same trickle pipeline so all the existing
      ::  buffer/runway invariants hold under parallel arrival.
      =/  st=stream-state:burn  u.ss
      =/  short-rid=@t  (short-id-uv rid.act)
      ::  Bug B fix: total-size.st is 0 until apply-one-chunk-into-stream
      ::  parses chunk 0's headers; mirror its captured-total derivation here
      ::  so the chunk RECEIVED slog prints the real M from the first chunk
      ::  instead of `chunk 1/0`.
      =/  captured-total=@ud
        ?:  &(=(0 seq.act) =(0 total-size.st))
          (extract-total-from-headers headers.act)
        total-size.st
      =/  m=@ud  (total-chunks captured-total)
      ~&  >  "burn: chunk RECEIVED rid={<short-rid>} chunk {<+(seq.act)>}/{<m>} bytes={<p.data.act>} flow={<flow-id.act>} more={<has-more.act>} t={<now.bowl>}"
      ::  L3: latch final-seq on FIRST observation of has-more=%.n.
      ::  Subsequent has-more=%.n observations leave the latch unchanged.
      =/  newly-final=?
        &(!has-more.act ?=(~ (~(get by final-seq.state) rid.act)))
      =?  final-seq.state  newly-final
        (~(put by final-seq.state) rid.act seq.act)
      ::  L3: free the flow that delivered this chunk (no-op if the flow
      ::  isn't tracked yet — e.g. chunk-0 arrives before dispatch-flows
      ::  has populated flows.st).
      =.  flows.st  (free-flow flows.st seq.act)
      ::  L3: when final-seq latches, idle every flow whose assigned seq
      ::  is past the final chunk. Those flows were dispatched speculatively
      ::  (max-flows-1 chunks ahead) before we knew where the file ended;
      ::  their pokes will return %proxy-response 502s for past-EOF Range
      ::  reads, which is harmless but they MUST be marked idle now or
      ::  pick-idle-flow keeps skipping them and dispatch-flows runs at
      ::  reduced parallelism (eventual hang once all slots speculate past
      ::  the end).
      =?  flows.st  newly-final
        %-  ~(run by flows.st)
        |=  fs=flow-state:burn
        ^-  flow-state:burn
        ?:  ?&  ?=(%in-flight status.fs)
                (gth seq.fs seq.act)
            ==
          [%idle 0]
        fs
      ::  Stale: lower seq than expected = duplicate or stale retransmit.
      ::  Drop after persisting the freed-flow update so the slot can be
      ::  reused by the next dispatch-flows tick. Also dispatch — we just
      ::  freed a flow and there may be more chunks to assign.
      ?:  (lth seq.act seq.st)
        ~&  >>>  "burn: chunk seq STALE rid={<short-rid>} expected {<+(seq.st)>}/{<m>} got {<+(seq.act)>}/{<m>} flow={<flow-id.act>} — dropped"
        =/  fseq=(unit @ud)  (~(get by final-seq.state) rid.act)
        =/  parked=(map @ud octs)
          (fall (~(get by reassembly.state) rid.act) ~)
        =/  [stale-cards=(list card) st-after=stream-state:burn]
          (dispatch-flows rid.act st fseq parked now.bowl)
        =.  pending-streams.state  (~(put by pending-streams.state) rid.act st-after)
        :_  this
        stale-cards
      ::  Out-of-order arrival under parallel flows: park in reassembly
      ::  and dispatch any newly-freed flow slots onto the next unassigned
      ::  chunk. Drain happens later, when next-emit-seq finally arrives.
      ?.  =(seq.act seq.st)
        =/  per-rid=(map @ud octs)
          (fall (~(get by reassembly.state) rid.act) ~)
        =.  per-rid  (~(put by per-rid) seq.act data.act)
        =.  reassembly.state
          (~(put by reassembly.state) rid.act per-rid)
        =/  fseq=(unit @ud)  (~(get by final-seq.state) rid.act)
        =/  [dispatch-cards=(list card) st-after=stream-state:burn]
          (dispatch-flows rid.act st fseq per-rid now.bowl)
        =.  pending-streams.state
          (~(put by pending-streams.state) rid.act st-after)
        ~&  >  "burn: chunk PARKED rid={<short-rid>} seq={<+(seq.act)>}/{<m>} flow={<flow-id.act>} (next-emit={<+(seq.st)>})"
        :_  this
        dispatch-cards
      ::  In-order arrival. Persist the freed-flow update on st BEFORE
      ::  applying the chunk so apply-one-chunk-into-stream sees the
      ::  current flows map (it re-reads pending-streams.s).
      ::
      ::  First-chunk download summary slogs (preserved from rev 40).
      ::  Apply this chunk through the trickle pipeline. apply persists
      ::  the updated stream-state into pending-streams; we don't need a
      ::  pre-write. Pass st directly (with free-flow already applied).
      =^  apply-cards  state
        %:  apply-one-chunk-into-stream
          state
          st
          rid.act
          seq.act
          data.act
          has-more.act
          status.act
          headers.act
          now.bowl
        ==
      ::  Drain any contiguously-parked chunks (seq.st now advanced one).
      =^  drain-cards  state
        (drain-reassembly-loop state rid.act now.bowl)
      ::  Dispatch new flows onto the freed slots (if stream still alive).
      =/  st-now=(unit stream-state:burn)
        (~(get by pending-streams.state) rid.act)
      ?~  st-now
        ::  Stream completed and was reaped during apply (empty-final-chunk).
        ~&  >  "burn: arm-exit rid={<short-rid>} chunk {<+(seq.act)>}/{<m>} (stream completed)"
        :_  this
        (weld (weld apply-cards drain-cards) ~[(give-status-fact state our.bowl)])
      =/  fseq=(unit @ud)  (~(get by final-seq.state) rid.act)
      =/  parked=(map @ud octs)
        (fall (~(get by reassembly.state) rid.act) ~)
      =/  [dispatch-cards=(list card) st-final=stream-state:burn]
        (dispatch-flows rid.act u.st-now fseq parked now.bowl)
      =.  pending-streams.state
        (~(put by pending-streams.state) rid.act st-final)
      ~&  >  "burn: arm-exit rid={<short-rid>} chunk {<+(seq.act)>}/{<m>} flow={<flow-id.act>} t={<now.bowl>}"
      :_  this
      ;:  weld
        apply-cards
        drain-cards
        dispatch-cards
        `(list card)`~[(give-status-fact state our.bowl)]
      ==
    ==
  ::
  ::  HTTP: handle incoming Eyre requests (minimal — no SPA)
  ::
      %handle-http-request
    =/  [eyre-id=@ta inbound-req=inbound-request:eyre]
      !<([@ta =inbound-request:eyre] vase)
    =/  req-url=@t  url.request.inbound-req
    =/  pass-pfx=tape  "/apps/burn/auth/passcode"
    ?:  =((scag (lent pass-pfx) (trip req-url)) pass-pfx)
      :_  this
      (handle-passcode-auth eyre-id inbound-req src.bowl)
    =/  raw-url=tape  (trip req-url)
    ::  HTTP response debugging cheatsheet. These local-only probes are
    ::  intentionally before the auth/download paths.
    ::
    ::    curl -v --raw http://127.0.0.1:80/apps/burn/debug-cl-same
    ::      200 + content-length=5; header and body cards returned together.
    ::
    ::    curl -v --raw http://127.0.0.1:80/apps/burn/debug-cl-later
    ::      200 + content-length=5; header now, body "hello" after 1s.
    ::
    ::    curl -v --raw http://127.0.0.1:80/apps/burn/debug-cl-206-same
    ::      206 + content-length=5 + content-range; header/body together.
    ::
    ::    curl -v --raw http://127.0.0.1:80/apps/burn/debug-cl-206-later
    ::      206 + content-length=5 + content-range; body after 1s.
    ::
    ::    curl -v --raw http://127.0.0.1:80/apps/burn/debug-idle-30
    ::    curl -v --raw http://127.0.0.1:80/apps/burn/debug-idle-46
    ::    curl -v --raw http://127.0.0.1:80/apps/burn/debug-idle-60
    ::      200 without content-length; header now, body after N seconds.
    ::      These test the real Vere/Eyre idle-close window.
    ::
    ?:  =("/apps/burn/debug-cl-same" raw-url)
      =/  body=octs  (as-octs:mimes:html 'hello')
      =/  rh=response-header:http
        [200 ~[['content-type' 'text/plain'] ['content-length' '5']]]
      ~&  >>>  "burn: DEBUG CL same eyre-id={<(short-id-ta eyre-id)>} header+data same return content-length=5 body=5"
      :_  this
      :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-header !>(rh)]
          [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>(`(unit octs)`(some body))]
          [%give %kick ~[/http-response/[eyre-id]] ~]
      ==
    ?:  =("/apps/burn/debug-cl-later" raw-url)
      =/  rh=response-header:http
        [200 ~[['content-type' 'text/plain'] ['content-length' '5']]]
      ~&  >>>  "burn: DEBUG CL later eyre-id={<(short-id-ta eyre-id)>} header now content-length=5 body in 1s"
      :_  this
      :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-header !>(rh)]
          [%pass /debug-cl-later/[eyre-id] %arvo %b %wait (add now.bowl ~s1)]
      ==
    ?:  =("/apps/burn/debug-cl-206-same" raw-url)
      =/  body=octs  (as-octs:mimes:html 'hello')
      =/  rh=response-header:http
        [206 ~[['content-type' 'text/plain'] ['content-length' '5'] ['content-range' 'bytes 0-4/5'] ['accept-ranges' 'bytes']]]
      ~&  >>>  "burn: DEBUG CL 206 same eyre-id={<(short-id-ta eyre-id)>} header+data same content-length=5 content-range=bytes 0-4/5"
      :_  this
      :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-header !>(rh)]
          [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>(`(unit octs)`(some body))]
          [%give %kick ~[/http-response/[eyre-id]] ~]
      ==
    ?:  =("/apps/burn/debug-cl-206-later" raw-url)
      =/  rh=response-header:http
        [206 ~[['content-type' 'text/plain'] ['content-length' '5'] ['content-range' 'bytes 0-4/5'] ['accept-ranges' 'bytes']]]
      ~&  >>>  "burn: DEBUG CL 206 later eyre-id={<(short-id-ta eyre-id)>} header now content-length=5 content-range=bytes 0-4/5 body in 1s"
      :_  this
      :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-header !>(rh)]
          [%pass /debug-cl-206-later/[eyre-id] %arvo %b %wait (add now.bowl ~s1)]
      ==
    ?:  =("/apps/burn/debug-idle-30" raw-url)
      =/  rh=response-header:http
        [200 ~[['content-type' 'text/plain']]]
      ~&  >>>  "burn: DEBUG idle-30 eyre-id={<(short-id-ta eyre-id)>} header now body in 30s"
      :_  this
      :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-header !>(rh)]
          [%pass /debug-idle-30/[eyre-id] %arvo %b %wait (add now.bowl ~s30)]
      ==
    ?:  =("/apps/burn/debug-idle-46" raw-url)
      =/  rh=response-header:http
        [200 ~[['content-type' 'text/plain']]]
      ~&  >>>  "burn: DEBUG idle-46 eyre-id={<(short-id-ta eyre-id)>} header now body in 46s"
      :_  this
      :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-header !>(rh)]
          [%pass /debug-idle-46/[eyre-id] %arvo %b %wait (add now.bowl ~s46)]
      ==
    ?:  =("/apps/burn/debug-idle-60" raw-url)
      =/  rh=response-header:http
        [200 ~[['content-type' 'text/plain']]]
      ~&  >>>  "burn: DEBUG idle-60 eyre-id={<(short-id-ta eyre-id)>} header now body in 60s"
      :_  this
      :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-header !>(rh)]
          [%pass /debug-idle-60/[eyre-id] %arvo %b %wait (add now.bowl ~s60)]
      ==
    =/  dl-web-pfx=tape  "/apps/burn/download/"
    =/  st-web-pfx=tape  "/apps/burn/stream/"
    =/  is-thumb=?
      (is-thumb-url req-url)
    =/  is-auth-media=?
      ?|  =((scag (lent dl-web-pfx) raw-url) dl-web-pfx)
          =((scag (lent st-web-pfx) raw-url) st-web-pfx)
      ==
    ::  HOST: proxy to local Plex server (strip /apps/burn prefix)
    ?^  hosting.state
      =/  auth-media-ok=?
        ?|  (download-auth-ok src.bowl our.bowl authenticated.inbound-req)
            (passcode-grant-ok src.bowl req-url request.inbound-req)
        ==
      =/  tok=(unit @t)
        =/  rt=(unit @t)
          (resolve-token src.bowl our.bowl u.hosting.state allowed.state)
        ?:  ?=(^ rt)  rt
        ::  Mirror of download/stream EAuth gate (:1088, :1184): a locally-
        ::  authenticated browser session has eyre-verified identity even
        ::  when src.bowl is not our.bowl (anonymous-session shape on
        ::  subresource fetches like <img> /thumb/). Grant host token.
        ?:  authenticated.inbound-req  `token.u.hosting.state
        ?:  is-thumb  `token.u.hosting.state
        ?:  ?&  is-auth-media
                auth-media-ok
            ==
          `token.u.hosting.state
        ~
      ?~  tok
        ?:  is-thumb
          ~&  >>>  "burn: AUTH-403 thumb src={<src.bowl>} our={<our.bowl>} url={<req-url>}"
          :_  this
          %+  give-simple-payload:app:server  eyre-id
          [[403 ~] ~]
        ?:  ?&  is-auth-media
                !auth-media-ok
            ==
          ~&  >  "burn: host media auth gate — bouncing {<req-url>} to new-oxal auth"
          :_  this
          (eauth-redirect eyre-id req-url)
        ~&  >>>  "burn: AUTH-403 src={<src.bowl>} our={<our.bowl>} auth={<authenticated.inbound-req>} url={<req-url>}"
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        [[403 ~] ~]
      =/  cfg=plex-config:burn  u.hosting.state
      =/  plex-path=@t
        =/  raw=tape  (trip req-url)
        =/  prefix=tape  "/apps/burn"
        ?:  (lth (lent raw) (lent prefix))  req-url
        ?.  =((scag (lent prefix) raw) prefix)  req-url
        (crip (slag (lent prefix) raw))
      ::  HOST download: /download/{rkey} → fetch metadata to get Part key
      =/  pp=tape  (trip plex-path)
      =/  dl-pfx=tape  "/download/"
      ?:  =((scag (lent dl-pfx) pp) dl-pfx)
        =/  rkey=tape  (slag (lent dl-pfx) pp)
        =/  meta-url=@t
          (crip "/library/metadata/{rkey}?X-Plex-Token={(trip u.tok)}")
        =/  proxy-url=@t  (cat 3 url.cfg meta-url)
        =/  req=request:http  [%'GET' proxy-url ~ ~]
        ~&  >  "burn: host download metadata rkey={<(crip rkey)>}"
        ::  Populate pending-streams so the live-strip wires up. Rid is
        ::  deterministic from eyre-id so the chunk-arrival handler
        ::  (download-host) can find this entry without an explicit
        ::  eyre-id→rid map. display-name comes from the library cache;
        ::  total-size is 0 until the first chunk's Content-Range arrives.
        =/  rid=@uv  (sham eyre-id)
        =/  path=media-path:burn
          (find-media-path (get-source state our.bowl) (crip rkey))
        =/  path-item=media-node-ref:burn  item.path
        =/  display-name=@t
          ?:  =('' label.path-item)  (crip "download-{rkey}")
          label.path-item
        =/  new-ss=stream-state:burn
          :*  eyre-id
              our.bowl             ::  host: we serve the bytes (we own the Plex link)
              src.bowl             ::  initiator: requesting browser session ship
              meta-url
              now.bowl             ::  started: canonical elapsed-time anchor
              0                    ::  total-size unknown until first chunk Content-Range
              0                    ::  received
              chunk-size
              0                    ::  start-byte
              0                    ::  seq
              %.n                  ::  sent-header
              0                    ::  emitted
              display-name
              path
              %$                   ::  container
              ~                    ::  flows
          ==
        =.  pending-streams.state
          (~(put by pending-streams.state) rid new-ss)
        =.  stream-arrivals.state
          (~(put by stream-arrivals.state) rid now.bowl)
        :_  this
        :~  [%pass /download-meta/[eyre-id] %arvo %i %request req *outbound-config:iris]
            ::  Redraw so the new-oxal vine's loop re-scries /x/burn/goon,
            ::  picks up the %downloads kid via find-active-rid, and opens
            ::  the /goon/progress/<rid> watch that drives the live strip.
            give-redraw
        ==
      ::  HOST stream: /stream/{rkey} → fetch metadata, redirect to Part URL
      =/  stream-pfx=tape  "/stream/"
      ?:  =((scag (lent stream-pfx) pp) stream-pfx)
        =/  rkey=tape  (slag (lent stream-pfx) pp)
        ?.  (levy rkey |=(c=@ &((gte c '0') (lte c '9'))))
          :_  this
          %+  give-simple-payload:app:server  eyre-id
          [[400 ~] ~]
        =/  meta-url=@t
          (crip "/library/metadata/{rkey}?X-Plex-Token={(trip u.tok)}")
        =/  proxy-url=@t  (cat 3 url.cfg meta-url)
        =/  req=request:http  [%'GET' proxy-url ~ ~]
        ~&  >  "burn: stream metadata rkey={<(crip rkey)>}"
        :_  this
        :~  [%pass /stream-meta/[eyre-id] %arvo %i %request req *outbound-config:iris]
        ==
      ::  Thumbnail: fetch transcoded from Plex, cache in Eyre
      ::  On first request, Eyre routes here. After caching, Eyre serves directly.
      ?:  (is-thumb-url plex-path)
        =/  tc-url=@t  (thumb-transcode-url plex-path u.tok)
        =/  proxy-url=@t  (cat 3 url.cfg tc-url)
        =/  req=request:http  [%'GET' proxy-url ~ ~]
        ~&  >  "burn: thumb request eyre-id={<eyre-id>} cache-key={<plex-path>}"
        =.  pending.state  (~(put by pending.state) eyre-id plex-path)
        :_  this
        :~  [%pass /thumb/[eyre-id] %arvo %i %request req *outbound-config:iris]
        ==
      ::  Normal proxy passthrough
      =/  proxy-url=@t  (cat 3 url.cfg plex-path)
      =/  proxy-headers=header-list:http
        (rewrite-headers header-list.request.inbound-req u.tok)
      =/  req=request:http
        [method.request.inbound-req proxy-url proxy-headers body.request.inbound-req]
      :_  this
      :~  [%pass /response/[eyre-id] %arvo %i %request req *outbound-config:iris]
      ==
    ::  SUBSCRIBER: proxy to host over Ames
    =/  src-list=(list [ship source-state:burn])
      ~(tap by sources.state)
    ?~  src-list
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      [[503 ~] ~]
    =/  [host-ship=ship =source-state:burn]
      i.src-list
    =/  rid=@uv  (sham eny.bowl)
    =/  old-req  request.inbound-req
    ::  SUBSCRIBER DOWNLOAD: defer %http-response-header until first chunk
    ::  arrives over Mesa, so the Vere-layer HTTP idle timer doesn't run
    ::  during slow first-chunk delivery (Option A — see
    ::  reference_eyre_no_response_idle_knob.md). Headers built here are
    ::  stored in deferred-headers; the %proxy-chunk handler emits them
    ::  when the first chunk lands. Range support: 206 + Content-Range
    ::  when Range present (asterisk-total — substituted with Plex's real
    ::  total at emit time); 200 + Accept-Ranges otherwise.
    =/  url-tape=tape  (trip url.old-req)
    =/  dl-pfx=tape  "/apps/burn/download/"
    ?:  =((scag (lent dl-pfx) url-tape) dl-pfx)
      ::  Browser auth gate: Eyre's inbound `authenticated` only means
      ::  %ours, not EAuth %real. Use src.bowl as the visible identity and
      ::  bounce anonymous comet-style guests to the new-oxal auth panel.
      ?.  ?|  (download-auth-ok src.bowl our.bowl authenticated.inbound-req)
              (passcode-grant-ok src.bowl url.old-req old-req)
          ==
        ~&  >  "burn: download auth gate — bouncing {<url.old-req>} to new-oxal auth"
        :_  this
        (eauth-redirect eyre-id url.old-req)
      =/  rkey=tape  (slag (lent dl-pfx) url-tape)
      =/  range-info=(unit [start=@ud end=(unit @ud)])
        (parse-range header-list.old-req)
      =/  start-byte=@ud  ?~(range-info 0 start.u.range-info)
      =/  start-seq=@ud  (chunk-seq-for-byte start-byte)
      =/  chunk-start=@ud  (chunk-start-for-seq start-seq)
      =/  chunk-end=@ud
        ?:  =(0 start-seq)  (sub first-chunk-size 1)
        (sub (add chunk-start chunk-size) 1)
      =/  hdr-range=(unit @t)  (get-header-ci 'range' header-list.old-req)
      =/  hdr-if-range=(unit @t)  (get-header-ci 'if-range' header-list.old-req)
      =/  hdr-cache=(unit @t)  (get-header-ci 'cache-control' header-list.old-req)
      =/  hdr-pragma=(unit @t)  (get-header-ci 'pragma' header-list.old-req)
      =/  active-same=@ud
        =/  stream-entries=(list [@uv stream-state:burn])
          ~(tap by pending-streams.state)
        =/  count=@ud  0
        |-
        ?~  stream-entries  count
        =/  ss=stream-state:burn  +.i.stream-entries
        ?:  ?&  =(src.bowl initiator.ss)
                =(url.old-req url.ss)
            ==
          $(stream-entries t.stream-entries, count +(count))
        $(stream-entries t.stream-entries)
      ::  Branch decision is logged per-outcome below (NEW / 409 / 503 /
      ::  identity-cleanup). Avoid an unconditional "downloading … rid=…"
      ::  slog here — the fresh sham rid is discarded on 409, and a pre-
      ::  decision slog confused the trace when browsers double-fetch.
      ~&  >  "burn: incoming download {<(crip rkey)>} eyre-id={<(short-id-ta eyre-id)>} range={<range-info>} requester={<src.bowl>}"
      ~&  >>>  "burn: download request headers rkey={<(crip rkey)>} range={<hdr-range>} if-range={<hdr-if-range>} cache={<hdr-cache>} pragma={<hdr-pragma>} active-same={<active-same>}"
      ::  state filename UX: build display-name from cached library
      ::  metadata; the actual Content-Disposition (with container ext)
      ::  is REBUILT at first-chunk arrival once we have Plex's Content-
      ::  Type header. Placeholder Content-Disposition has no extension —
      ::  it gets replaced before emit, so the browser only ever sees the
      ::  final, correct version.
      =/  dl-src=source-state:burn
        (get-source state host-ship)
      =/  path=media-path:burn
        (find-media-path dl-src (crip rkey))
      =/  path-item=media-node-ref:burn  item.path
      =/  display-name=@t
        ?:  =('' label.path-item)  (crip "download-{rkey}")
        label.path-item
      ::  Placeholder Content-Disposition — no extension yet; rebuilt at
      ::  first-chunk arrival via rebuild-content-disposition with the
      ::  container we infer from Plex's Content-Type.
      =/  placeholder-cd=@t
        =/  encoded=tape  (en-urlt:html (trip display-name))
        (crip "attachment; filename*=UTF-8''{encoded}")
      =/  base-headers=header-list:http
        :~  ['content-type' 'application/octet-stream']
            ['content-disposition' placeholder-cd]
            ['accept-ranges' 'bytes']
        ==
      =/  dl-rh=response-header:http
        ?~  range-info
          [200 base-headers]
        =/  cr-val=@t
          (crip "bytes {(a-co:co start-byte)}-*/*")
        [206 [['content-range' cr-val] base-headers]]
      ~&  >>>  "burn: download response plan rkey={<(crip rkey)>} status={<?~(range-info 200 206)>} start-byte={<start-byte>} start-seq={<start-seq>} chunk-start={<chunk-start>} chunk-end={<chunk-end>} content-length=none"
      ?.  (can-start-download state)
        ~&  >  "burn: download cap reached for {<src.bowl>} rkey={<(crip rkey)>} — 503"
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        :-  [503 ~[['retry-after' '30'] ['content-type' 'text/plain']]]
        `(unit octs)`(some (as-octt:mimes:html "Download slots full — try again in 30 seconds"))
      ~&  >  "burn: NEW download rkey={<(crip rkey)>} rid={<(short-id-uv rid)>} eyre-id={<(short-id-ta eyre-id)>} from {<host-ship>}"
      =/  new-ss=stream-state:burn
        :*  eyre-id
            host-ship
            src.bowl             ::  initiator: requester ship for auth gate on %cancel-stream
            url.old-req
            now.bowl             ::  started: canonical elapsed-time anchor
            0
            start-byte
            chunk-size
            start-byte
            start-seq
            %.n
            start-byte            ::  emitted (browser already has prefix bytes on resume)
            display-name         ::  raw title (encoded at Content-Disposition build time)
            path
            %$                   ::  container — unknown until first chunk's Content-Type
            ~                    ::  L3 flows: ~ (dispatch-flows fills on first-chunk arrival)
        ==
      =.  pending-streams.state
        (~(put by pending-streams.state) rid new-ss)
      =.  pending.state
        (~(put by pending.state) (scot %uv rid) url.old-req)
      =.  deferred-headers.state
        (~(put by deferred-headers.state) rid [eyre-id dl-rh])
      =.  stream-arrivals.state
        (~(put by stream-arrivals.state) rid now.bowl)
      :_  this
      :~  %-  proxy-poke
          :*  host-ship
              rid
              control-flow                            ::  L3: initial download request rides flow 0
              %proxy-request
              host-ship
              rid
              method.old-req
              url.old-req
              header-list.old-req
              body.old-req
              control-flow                            ::  L3: flow-id payload (matches wire flow-id)
          ==
          (give-status-fact state our.bowl)
          ::  Redraw triggers the new-oxal vine to re-scry /x/burn/goon
          ::  and pick up the new %downloads kid via find-active-rid,
          ::  which opens the /goon/progress/<rid> watch that drives the
          ::  live-strip's status-live morph. Without this, new mid-
          ::  session downloads never wire up.
          give-redraw
      ==
    ::  SUBSCRIBER STREAM: defer %http-response-header same as download.
    ::  Stream uses video/mp4 200 — no Content-Range substitution, but the
    ::  same deferral keeps the Vere idle timer from firing on slow Mesa.
    =/  st-pfx=tape  "/apps/burn/stream/"
    ?:  =((scag (lent st-pfx) url-tape) st-pfx)
      ::  Auth gate (mirror of download path).
      ?.  ?|  (download-auth-ok src.bowl our.bowl authenticated.inbound-req)
              (passcode-grant-ok src.bowl url.old-req old-req)
          ==
        ~&  >  "burn: stream auth gate — bouncing {<url.old-req>} to new-oxal auth"
        :_  this
        (eauth-redirect eyre-id url.old-req)
      =/  rkey=tape  (slag (lent st-pfx) url-tape)
      ~&  >  "burn: sub stream {<(crip rkey)>} to {<host-ship>} rid={<(short-id-uv rid)>} (header deferred)"
      =/  st-rh=response-header:http  stream-rh
      =/  new-ss=stream-state:burn
        :*  eyre-id
            host-ship
            src.bowl             ::  initiator: requester ship for auth gate on %cancel-stream
            url.old-req
            now.bowl             ::  started: canonical elapsed-time anchor
            0
            0
            chunk-size
            0                    ::  start-byte
            0
            %.n
            0                    ::  emitted
            ''                   ::  display-name (streams)
            empty-media-path     ::  media-path (streams have no hierarchy context)
            %$                   ::  container (streams use stream-rh content-type, not extension-based)
            ~                    ::  L3 flows: ~ (dispatch-flows fills on first-chunk arrival)
        ==
      =.  pending-streams.state
        (~(put by pending-streams.state) rid new-ss)
      =.  pending.state
        (~(put by pending.state) (scot %uv rid) url.old-req)
      =.  deferred-headers.state
        (~(put by deferred-headers.state) rid [eyre-id st-rh])
      =.  stream-arrivals.state
        (~(put by stream-arrivals.state) rid now.bowl)
      :_  this
      :~  %-  proxy-poke
          :*  host-ship
              rid
              control-flow                            ::  L3: initial stream request rides flow 0
              %proxy-request
              host-ship
              rid
              method.old-req
              url.old-req
              header-list.old-req
              body.old-req
              control-flow                            ::  L3: flow-id payload (matches wire flow-id)
          ==
          ::  Redraw so the live-strip wires up for new mid-session streams.
          give-redraw
      ==
    ::  Normal proxy (non-download, non-stream)
    ~&  >  "burn: proxying {<req-url>} to {<host-ship>} rid={<(short-id-uv rid)>}"
    =/  pe=proxy-entry:burn  [eyre-id now.bowl]
    =.  pending-proxies.state
      (~(put by pending-proxies.state) rid pe)
    =.  pending.state
      (~(put by pending.state) (scot %uv rid) req-url)
    :_  this
    ::  Poke host's burn over Ames
    :~  %-  proxy-poke
        :*  host-ship
            rid
            control-flow                              ::  L3: normal-proxy request rides flow 0
            %proxy-request
            host-ship
            rid
            method.old-req
            url.old-req
            header-list.old-req
            body.old-req
            control-flow                              ::  L3: flow-id payload (matches wire flow-id)
        ==
    ==
  ==
::
::  +on-arvo: handle Eyre binds, Iris responses, behn timers
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?+  sign-arvo  (on-arvo:default wire sign-arvo)
      [%eyre %bound *]
    `this
  ::
  ::  behn: proxy timeout sweep
  ::
      [%behn %wake *]
    ?:  ?=([%debug-cl-later @ ~] wire)
      =/  eid=@ta  i.t.wire
      =/  body=octs  (as-octs:mimes:html 'hello')
      ~&  >>>  "burn: DEBUG CL later eyre-id={<(short-id-ta eid)>} body now len=5"
      :_  this
      :~  [%give %fact ~[/http-response/[eid]] %http-response-data !>(`(unit octs)`(some body))]
          [%give %kick ~[/http-response/[eid]] ~]
      ==
    ?:  ?=([%debug-cl-206-later @ ~] wire)
      =/  eid=@ta  i.t.wire
      =/  body=octs  (as-octs:mimes:html 'hello')
      ~&  >>>  "burn: DEBUG CL 206 later eyre-id={<(short-id-ta eid)>} body now len=5"
      :_  this
      :~  [%give %fact ~[/http-response/[eid]] %http-response-data !>(`(unit octs)`(some body))]
          [%give %kick ~[/http-response/[eid]] ~]
      ==
    ?:  ?=([%debug-idle-30 @ ~] wire)
      =/  eid=@ta  i.t.wire
      =/  body=octs  (as-octs:mimes:html 'hello')
      ~&  >>>  "burn: DEBUG idle-30 eyre-id={<(short-id-ta eid)>} body now len=5"
      :_  this
      :~  [%give %fact ~[/http-response/[eid]] %http-response-data !>(`(unit octs)`(some body))]
          [%give %kick ~[/http-response/[eid]] ~]
      ==
    ?:  ?=([%debug-idle-46 @ ~] wire)
      =/  eid=@ta  i.t.wire
      =/  body=octs  (as-octs:mimes:html 'hello')
      ~&  >>>  "burn: DEBUG idle-46 eyre-id={<(short-id-ta eid)>} body now len=5"
      :_  this
      :~  [%give %fact ~[/http-response/[eid]] %http-response-data !>(`(unit octs)`(some body))]
          [%give %kick ~[/http-response/[eid]] ~]
      ==
    ?:  ?=([%debug-idle-60 @ ~] wire)
      =/  eid=@ta  i.t.wire
      =/  body=octs  (as-octs:mimes:html 'hello')
      ~&  >>>  "burn: DEBUG idle-60 eyre-id={<(short-id-ta eid)>} body now len=5"
      :_  this
      :~  [%give %fact ~[/http-response/[eid]] %http-response-data !>(`(unit octs)`(some body))]
          [%give %kick ~[/http-response/[eid]] ~]
      ==
    ::  dl-keepalive wires are absorbed as no-ops. Empty-octs keepalive
    ::  emits trigger Vere _http_hgen_send SIGSEGV; deferred-headers
    ::  and trickle-pace replaced this. Older in-flight wires from
    ::  pre-deferred-headers streams may still fire here.
    ?:  ?=([%dl-keepalive @ ~] wire)
      `this
    ::
    ::  /dl-trickle/{rid}: peel next slice from octs-buffer and emit a
    ::  %http-response-data card on a steady cadence so Vere's HTTP-
    ::  response idle timer doesn't fire between Mesa chunks. State-5.
    ::
    ?:  ?=([%dl-trickle @ ~] wire)
      =/  rid=@uv  (slav %uv i.t.wire)
      =/  ob=(unit buffered-chunk:burn)
        (~(get by octs-buffer.state) rid)
      ?~  ob  `this                          ::  orphan: rid was reaped
      =/  ss=(unit stream-state:burn)
        (~(get by pending-streams.state) rid)
      ?~  ss  `this                          ::  orphan: stream was reaped
      =/  eid=@ta  eyre-id.u.ss
      =/  remaining=@ud  (sub p.bytes.u.ob cursor.u.ob)
      ?:  =(0 remaining)
        ::  Buffer drained.
        ?.  final.u.ob
          ::  Drained-and-not-final: do NOT kick (would close 200 as
          ::  complete and prevent browser Range-resume). Do NOT
          ::  reschedule. Vere will idle-close at ~46s; browser sees
          ::  connection error and Range-resumes from received offset.
          ::  Drop just octs-buffer entry; pending-streams/arrivals stay
          ::  so a follow-up chunk arrival can re-buffer and continue.
          ~&  >>>  "burn: TRICKLE DRAINED rid={<(short-id-uv rid)>} final=%.n (no chunk arrived in time; Vere will idle-close)"
          =.  octs-buffer.state  (~(del by octs-buffer.state) rid)
          `this
        ::  Drained-and-final: clean shutdown via delete-stream.
        =.  state  (delete-stream state rid)
        =.  pending.state  (~(del by pending.state) (scot %uv rid))
        ~&  >  "burn: trickle drained-final rid={<(short-id-uv rid)>} eyre-id={<(short-id-ta eid)>} complete=cancel"
        :_  this
        :~  give-redraw
            [%give %kick ~[/http-response/[eid]] ~]
        ==
      ::  Two modes:
      ::  - final.u.ob = %.y  → max-drain (chunk-size/tick) — Mesa input has
      ::                       stopped, dump remaining buffer to browser ASAP.
      ::  - else              → two-mode reserve drain via slice-for.
      =/  use-slice=@ud
        ?:  final.u.ob  (min chunk-size remaining)
        (slice-for remaining target-runway)
      ?:  =(0 use-slice)
        ::  Sub-threshold drain (rare: buf < ~480 bytes): skip emit, just
        ::  reschedule. Better to let Vere idle-close at ~46s than ship a
        ::  zero-byte octs (SIGSEGVs Vere) or a 1-byte octs that doesn't
        ::  actually keep the browser alive.
        ~&  >  "burn: trickle SUB-THRESHOLD rid={<(short-id-uv rid)>} buf={<remaining>}b — skip emit, reschedule"
        :_  this
        :~  (schedule-trickle rid now.bowl)
        ==
      =/  peeled  (peel-slice u.ob use-slice)
      =/  slice=octs  -.peeled
      =/  bc=buffered-chunk:burn  +.peeled
      =.  octs-buffer.state
        (~(put by octs-buffer.state) rid bc)
      ::  state: track bytes-shipped-to-browser separately from
      ::  bytes-received-from-host. emitted is what the public progress
      ::  bar reads; received is upstream bookkeeping.
      =/  ss-post=stream-state:burn
        u.ss(emitted (add emitted.u.ss p.slice))
      =.  pending-streams.state
        (~(put by pending-streams.state) rid ss-post)
      ~&  >  "burn: trickle{?:(final.u.ob "-FINAL" "")} rid={<(short-id-uv rid)>} buf={<remaining>}b chunks={<seq.u.ss>} -> emit {<p.slice>}b emitted={<emitted.u.ss>}->{<emitted.ss-post>} rem={<(sub p.bytes.bc cursor.bc)>}b"
      :_  this
      :~  [%give %fact ~[/http-response/[eid]] %http-response-data !>(`(unit octs)`(some slice))]
          (give-progress-fact rid ss-post)
          (schedule-trickle rid now.bowl)
      ==
    ::  Auto-fetch: triggered by inflate-io timer
    ?:  =(/auto-fetch wire)
      =/  err  +>.sign-arvo
      ?^  err
        ~&  >>>  "burn: auto-fetch timer error"
        `this
      ?~  hosting.state
        ~&  >  "burn: auto-fetch skipped (not hosting)"
        `this
      =/  cfg=plex-config:burn  u.hosting.state
      ?:  =('' token.cfg)
        ~&  >>  "burn: auto-fetch skipped — no Plex token configured"
        `this
      ~&  >  "burn: auto-fetch triggered, fetching sections"
      =/  fetch-url=@t  (cat 3 url.cfg '/library/sections')
      =/  hdrs=header-list:http  ~[['x-plex-token' token.cfg] ['accept' 'text/xml']]
      =/  req=request:http  [%'GET' fetch-url hdrs ~]
      :_  this
      :~  [%pass /library-fetch %arvo %i %request req *outbound-config:iris]
      ==
    ::  Library warmup: one metadata edge per tick. If a download is active,
    ::  back off; chunk transfer has priority over library completion.
    ?:  =(/library-warmup wire)
      =/  err  +>.sign-arvo
      ?^  err
        ~&  >>>  "burn: library warmup timer error"
        `this
      ?:  (gth ~(wyt by pending-streams.state) 0)
        ~&  >  "burn: library warmup paused ({<~(wyt by pending-streams.state)>} active download), retrying in 20m"
        :_  this
        :~  [%pass /library-warmup %arvo %b %wait (add now.bowl library-warmup-download-delay)]
        ==
      ?:  (metadata-fetch-in-flight state)
        ~&  >  "burn: library warmup waiting for metadata response"
        :_  this
        :~  [%pass /library-warmup %arvo %b %wait (add now.bowl library-warmup-busy-delay)]
        ==
      =/  host-ship=ship  (pick-host-ship state our.bowl)
      =/  cards=(list card)  (eager-library-fetches state host-ship our.bowl)
      ?:  =(~ cards)
        ~&  >  "burn: library warmup complete"
        `this
      ~&  >  "burn: library warmup dispatched one metadata fetch"
      [cards this]
    ::  Route by wire: /proxy-sweep or /thumb-prefetch (wake-check only —
    ::  actual dispatch is synchronous via +dispatch-prefetches at enqueue
    ::  + response sites; this arm exists for inflate-io restart wake)
    ?:  =(/thumb-prefetch wire)
      =/  err  +>.sign-arvo
      ?^  err
        ~&  >>>  "burn: thumb prefetch timer error"
        `this
      ?:  ?|(=(~ thumb-queue.state) !=(0 ~(wyt in (inflight-urls state))))
        `this
      ?:  (gth ~(wyt by pending-streams.state) 0)
        ~&  >  "burn: prefetch paused ({<~(wyt by pending-streams.state)>} active download, {<(lent thumb-queue.state)>} queued), retrying in 20m"
        :_  this
        :~  [%pass /thumb-prefetch %arvo %b %wait (add now.bowl thumb-prefetch-download-delay)]
        ==
      =^  cards=(list card)  state  (dispatch-prefetches state bowl)
      ~&  >  "burn: prefetch wake dispatched {<(lent cards)>} ({<(lent thumb-queue.state)>} queued)"
      [cards this]
    ?.  =(/proxy-sweep wire)
      (on-arvo:default wire sign-arvo)
    =/  err  +>.sign-arvo
    ?^  err
      ~&  >>>  "burn: proxy sweep timer error"
      :_  this
      :~  [%pass /proxy-sweep %arvo %b %wait (add now.bowl (get-timeout state))]
      ==
    =/  timeout=@dr  (get-timeout state)
    =/  entries=(list [@uv proxy-entry:burn])
      ~(tap by pending-proxies.state)
    =/  stale=(list [@uv proxy-entry:burn])
      %+  skim  entries
      |=  [rid=@uv pe=proxy-entry:burn]
      ?:  (gth sent.pe now.bowl)  %.n
      (gte (sub now.bowl sent.pe) timeout)
    =.  pending-proxies.state
      =/  pp=(map @uv proxy-entry:burn)  pending-proxies.state
      |-
      ?~  stale  pp
      $(stale t.stale, pp (~(del by pp) -.i.stale))
    ::  A thumbnail prefetch rides internal-pending, not pending-proxies.
    ::  If the Ames poke is accepted but the host response never lands,
    ::  the serial prefetch queue otherwise deadlocks forever because
    ::  +dispatch-prefetches sees one in-flight URL and refuses to send
    ::  the next. Reap stale prefetches on the same sweep cadence.
    =/  ifetch-entries=(list [@uv internal-fetch:burn])
      ~(tap by internal-pending.state)
    =/  stale-prefetch=(list [@uv internal-fetch:burn])
      %+  skim  ifetch-entries
      |=  [rid=@uv ifetch=internal-fetch:burn]
      ?.  =(%thumb-prefetch tag.ifetch)  %.n
      ?:  (gth requested.ifetch now.bowl)  %.n
      (gte (sub now.bowl requested.ifetch) timeout)
    =.  internal-pending.state
      =/  ip=(map @uv internal-fetch:burn)  internal-pending.state
      |-
      ?~  stale-prefetch  ip
      $(stale-prefetch t.stale-prefetch, ip (~(del by ip) -.i.stale-prefetch))
    ::  Sweep stale pending-streams by INACTIVITY: reap when no chunk has
    ::  arrived for `stream-timeout` (24h). Decoupled from proxy-timeout —
    ::  active downloads run multi-GB across overnight windows (Kiki: 18h,
    ::  Hidden Fortress projected 24h); a 30min reap defeats the 2h trickle
    ::  runway and kills working transfers on any inter-chunk blip. 24h is
    ::  the safety-net floor: on-leave handles fast cleanup, sweep catches
    ::  the long tail. Activity is tracked in stream-arrivals (state
    ::  parallel map); ticked on ctor and on every %proxy-chunk arrival.
    ::  Missing-key fallback to now.bowl preserves the stream and slogs a
    ::  warning so orphans surface as bugs rather than silently mimicking
    ::  elapsed-time sweep.
    =/  stream-timeout=@dr  ~h24
    =/  stream-entries=(list [@uv stream-state:burn])
      ~(tap by pending-streams.state)
    ::  Inactivity-based reap: on-leave deletes immediately on browser
    ::  disconnect; the sweep catches silent drops (no on-leave fired).
    =/  stale-streams=(list [@uv stream-state:burn])
      %+  skim  stream-entries
      |=  [rid=@uv ss=stream-state:burn]
      =/  arr=(unit @da)  (~(get by stream-arrivals.state) rid)
      =/  last=@da
        ?~  arr
          ~&  >>>  "burn: sweep missing stream-arrivals for rid={<(short-id-uv rid)>} — preserving"
          now.bowl
        u.arr
      ?:  (gth last now.bowl)  %.n
      (gte (sub now.bowl last) stream-timeout)
    =.  state
      =/  s=state:burn  state
      |-
      ?~  stale-streams  s
      $(stale-streams t.stale-streams, s (delete-stream s -.i.stale-streams))
    =.  pending.state
      =/  pd=(map @t @t)  pending.state
      |-
      ?~  stale-streams  pd
      $(stale-streams t.stale-streams, pd (~(del by pd) (scot %uv -.i.stale-streams)))
    ~?  |((gth (lent stale) 0) (gth (lent stale-streams) 0) (gth (lent stale-prefetch) 0))
      "burn: sweep {<(lent stale)>} proxies, {<(lent stale-streams)>} streams, {<(lent stale-prefetch)>} prefetches"
    =/  proxy-cards=(list card)
      %-  zing
      %+  turn  stale
      |=  [rid=@uv pe=proxy-entry:burn]
      ^-  (list card)
      %+  give-simple-payload:app:server  eyre-id.pe
      [[504 ~] ~]
    =/  stream-cards=(list card)
      %-  zing
      %+  turn  stale-streams
      |=  [rid=@uv ss=stream-state:burn]
      ^-  (list card)
      =/  eid=@ta  eyre-id.ss
      ?:  sent-header.ss
        ::  Header was emitted; close the response cleanly with empty
        ::  trailing data + kick. Browser sees the body it already
        ::  received, capped by EOF.
        :~  [%give %fact ~[/http-response/[eid]] %http-response-data !>(*(unit octs))]
            [%give %kick ~[/http-response/[eid]] ~]
        ==
      ::  Header was deferred but no chunk ever arrived; emit a clean 504
      ::  so the browser sees a real error instead of a degenerate empty
      ::  response.
      =/  err-rh=response-header:http
        :-  504
        :~  ['content-type' 'text/plain; charset=utf-8']
            ['cache-control' 'no-store']
        ==
      =/  err-body=octs
        (as-octs:mimes:html 'burn: Mesa transport timed out before first chunk arrived. Try again later.')
      :~  [%give %fact ~[/http-response/[eid]] %http-response-header !>(err-rh)]
          [%give %fact ~[/http-response/[eid]] %http-response-data !>(`(unit octs)`(some err-body))]
          [%give %kick ~[/http-response/[eid]] ~]
      ==
    =/  response-cards=(list card)
      (weld proxy-cards stream-cards)
    =^  prefetch-cards=(list card)  state  (dispatch-prefetches state bowl)
    :-  (snoc (weld response-cards prefetch-cards) [%pass /proxy-sweep %arvo %b %wait (add now.bowl timeout)])
    this
  ::
  ::  Iris: HTTP response from local Plex proxy
  ::
      [%iris %http-response %finished *]
    =/  resp=client-response:iris  +:+:sign-arvo
    ?>  ?=(%finished -.resp)
    ?+  wire  (on-arvo:default wire sign-arvo)
    ::
    ::  PUBLISHER: library sections fetch result
    ::
        [%library-fetch ~]
      ?~  full-file.resp
        ~&  >>>  "burn: library fetch failed (no body)"
        `this
      =/  body=@t  q.data.u.full-file.resp
      =/  sections=(list library-section:burn)
        (parse-library-sections body)
      ~&  >  "burn: parsed {<(lent sections)>} library sections"
      =/  self-src=source-state:burn  (get-source state our.bowl)
      =.  state  (put-source state self-src(sections sections))
      :_  this
      (welp ~[give-redraw] (eager-library-fetches state our.bowl our.bowl))
    ::
    ::  PUBLISHER: library items fetch result
    ::
        [%items-fetch @ ~]
      =/  section-key=@t  `@t`(snag 1 `(list @ta)`wire)
      ?~  full-file.resp
        ~&  >>>  "burn: items fetch failed for section {<section-key>}"
        `this
      =/  body=@t  q.data.u.full-file.resp
      =/  items=(list library-item:burn)
        (parse-library-items body section-key)
      ~&  >  "burn: parsed {<(lent items)>} items for section {<section-key>}"
      =/  self-src=source-state:burn  (get-source state our.bowl)
      =.  state
        %+  put-source  state
        self-src(items (~(put by items.self-src) section-key items))
      =/  candidates=(list @t)
        (murn items |=(li=library-item:burn (thumb-to-cache-url thumb.li (library-item-kind:burn-to-goad type.li))))
      =^  fresh=(list @t)  state  (enqueue-thumb-urls state candidates)
      =^  prefetch-cards=(list card)  state  (dispatch-prefetches state bowl)
      ~&  >  "burn: queued {<(lent fresh)>} thumbs ({<(lent thumb-queue.state)>} now queued)"
      :_  this
      ;:  welp
        ~[give-redraw]
        (give-items section-key items)
        prefetch-cards
        (eager-library-fetches state our.bowl our.bowl)
      ==
    ::
    ::  PUBLISHER: show-children fetch result (state hierarchy)
    ::
        [%show-children-fetch @ ~]
      =/  show-rkey=@t  `@t`(snag 1 `(list @ta)`wire)
      ?~  full-file.resp
        ~&  >>>  "burn: show-children fetch failed for rkey {<show-rkey>}"
        `this
      =/  body=@t  q.data.u.full-file.resp
      =/  seasons=(list season-item:burn)
        (parse-show-children body)
      ~&  >  "burn: parsed {<(lent seasons)>} seasons for show {<show-rkey>}"
      =/  self-src=source-state:burn  (get-source state our.bowl)
      =.  state
        %+  put-source  state
        self-src(seasons (~(put by seasons.self-src) show-rkey seasons))
      =/  candidates=(list @t)
        (murn seasons |=(s=season-item:burn (thumb-to-cache-url thumb.s %tall)))
      =^  fresh=(list @t)  state  (enqueue-thumb-urls state candidates)
      =^  prefetch-cards=(list card)  state  (dispatch-prefetches state bowl)
      ~&  >  "burn: queued {<(lent fresh)>} season thumbs ({<(lent thumb-queue.state)>} now queued)"
      :_  this
      ;:  welp
        ~[give-redraw]
        prefetch-cards
        (eager-library-fetches state our.bowl our.bowl)
      ==
    ::
    ::  PUBLISHER: season-children fetch result (state hierarchy)
    ::
        [%season-children-fetch @ ~]
      =/  season-rkey=@t  `@t`(snag 1 `(list @ta)`wire)
      ?~  full-file.resp
        ~&  >>>  "burn: season-children fetch failed for rkey {<season-rkey>}"
        `this
      =/  body=@t  q.data.u.full-file.resp
      =/  episodes=(list episode-item:burn)
        (parse-season-children body)
      ~&  >  "burn: parsed {<(lent episodes)>} episodes for season {<season-rkey>}"
      =/  self-src=source-state:burn  (get-source state our.bowl)
      =.  state
        %+  put-source  state
        self-src(episodes (~(put by episodes.self-src) season-rkey episodes))
      =/  candidates=(list @t)
        (murn episodes |=(e=episode-item:burn (thumb-to-cache-url thumb.e %wide)))
      =^  fresh=(list @t)  state  (enqueue-thumb-urls state candidates)
      =^  prefetch-cards=(list card)  state  (dispatch-prefetches state bowl)
      ~&  >  "burn: queued {<(lent fresh)>} episode thumbs ({<(lent thumb-queue.state)>} now queued)"
      :_  this
      ;:  welp
        ~[give-redraw]
        prefetch-cards
        (eager-library-fetches state our.bowl our.bowl)
      ==
    ::
    ::  PUBLISHER: artist-children fetch result (albums)
    ::
        [%artist-children-fetch @ ~]
      =/  artist-rkey=@t  `@t`(snag 1 `(list @ta)`wire)
      ?~  full-file.resp
        ~&  >>>  "burn: artist-children fetch failed for rkey {<artist-rkey>}"
        `this
      =/  body=@t  q.data.u.full-file.resp
      =/  albums=(list season-item:burn)
        (parse-show-children body)
      ~&  >  "burn: parsed {<(lent albums)>} albums for artist {<artist-rkey>}"
      =/  self-src=source-state:burn  (get-source state our.bowl)
      =.  state
        %+  put-source  state
        self-src(seasons (~(put by seasons.self-src) artist-rkey albums))
      =/  candidates=(list @t)
        (murn albums |=(a=season-item:burn (thumb-to-cache-url thumb.a %square)))
      =^  fresh=(list @t)  state  (enqueue-thumb-urls state candidates)
      =^  prefetch-cards=(list card)  state  (dispatch-prefetches state bowl)
      ~&  >  "burn: queued {<(lent fresh)>} album thumbs ({<(lent thumb-queue.state)>} now queued)"
      :_  this
      ;:  welp
        ~[give-redraw]
        prefetch-cards
        (eager-library-fetches state our.bowl our.bowl)
      ==
    ::
    ::  PUBLISHER: album-children fetch result (tracks)
    ::
        [%album-children-fetch @ ~]
      =/  album-rkey=@t  `@t`(snag 1 `(list @ta)`wire)
      ?~  full-file.resp
        ~&  >>>  "burn: album-children fetch failed for rkey {<album-rkey>}"
        `this
      =/  body=@t  q.data.u.full-file.resp
      =/  tracks=(list episode-item:burn)
        (parse-album-children body)
      ~&  >  "burn: parsed {<(lent tracks)>} tracks for album {<album-rkey>}"
      =/  self-src=source-state:burn  (get-source state our.bowl)
      =.  state
        %+  put-source  state
        self-src(episodes (~(put by episodes.self-src) album-rkey tracks))
      =/  candidates=(list @t)
        (murn tracks |=(t=episode-item:burn (thumb-to-cache-url thumb.t %square)))
      =^  fresh=(list @t)  state  (enqueue-thumb-urls state candidates)
      =^  prefetch-cards=(list card)  state  (dispatch-prefetches state bowl)
      ~&  >  "burn: queued {<(lent fresh)>} track thumbs ({<(lent thumb-queue.state)>} now queued)"
      :_  this
      ;:  welp
        ~[give-redraw]
        prefetch-cards
        (eager-library-fetches state our.bowl our.bowl)
      ==
    ::
    ::  HOST: dynamic proxy pass through
    ::
        [%response @ ~]
      =/  eyre-id=@ta  (snag 1 `(list @ta)`wire)
      =/  resp-header=response-header:http  response-header.resp
      ?~  full-file.resp
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        [resp-header ~]
      =/  the-octs=octs  data.u.full-file.resp
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      [%_(resp-header headers (clean-response-headers headers.resp-header)) `the-octs]
    ::
    ::  HOST: thumbnail response (Eyre-direct) — serve + cache in Eyre
    ::
    ::  Status-aware: only 2xx is treated as a valid jpeg payload to
    ::  cache. Non-2xx (typically Plex 403 for episode stills with no
    ::  generated thumbnail) is forwarded with its real status and is
    ::  NOT Eyre-cached — so a future generation/retry can populate the
    ::  cache, and the browser can render its native broken-image
    ::  affordance instead of a 24h-cached corrupt jpeg.
    ::
        [%thumb @ ~]
      =/  eyre-id=@ta  (snag 1 `(list @ta)`wire)
      =/  cache-key=(unit @t)  (~(get by pending.state) eyre-id)
      =/  up-status=@ud  status-code.response-header.resp
      ~&  >  "burn: thumb response eyre-id={<eyre-id>} up-status={<up-status>} cache-key={<cache-key>}"
      =.  pending.state  (~(del by pending.state) eyre-id)
      ?~  full-file.resp
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        [[502 ~] ~]
      ?.  &((gte up-status 200) (lth up-status 300))
        ::  Short-TTL negative response so a missing-still doesn't
        ::  re-hit Plex on every SSE reconnect; Eyre long-cache is
        ::  intentionally NOT populated (see arm-doc above).
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        [[up-status ~[['cache-control' 'max-age=300']]] ~]
      =/  the-octs=octs  data.u.full-file.resp
      =/  rh=response-header:http
        [200 ~[['content-type' 'image/jpeg'] ['cache-control' 'max-age=86400']]]
      =/  sp=simple-payload:http  [rh `the-octs]
      ::  Serve to browser + cache in Eyre for future requests
      =/  serve-cards=(list card)
        (give-simple-payload:app:server eyre-id sp)
      =/  cache-cards=(list card)
        ?~  cache-key  ~
        =/  eyre-path=@t  (cat 3 '/apps/burn' u.cache-key)
        ~&  >  "burn: eyre-cached {<eyre-path>} ({<p.the-octs>}b)"
        :~  [%pass /cache %arvo %e %set-response eyre-path `[%.n %payload sp]]
        ==
      :_  this
      (weld serve-cards cache-cards)
    ::
    ::  HOST: background-prefetch thumbnail response (Iris-direct).
    ::  Mirrors [%thumb @ ~] caching policy but doesn't serve to a
    ::  browser — pure cache populate. Looks up URL via rid →
    ::  internal-pending; missing lookup means %clear-cache reaped
    ::  this in-flight (orphan) — skip cache write.
    ::
        [%host-thumb-prefetch @ ~]
      =/  rid=@uv  (slav %uv (snag 1 `(list @ta)`wire))
      =/  ifetch=(unit internal-fetch:burn)
        (~(get by internal-pending.state) rid)
      ?~  ifetch
        ~&  >>  "burn: host prefetch response orphaned (clear-cache?) rid={<(short-id-uv rid)>}"
        =/  next-cards=(list card)  (schedule-prefetch state now.bowl)
        [next-cards this]
      =.  internal-pending.state  (~(del by internal-pending.state) rid)
      =/  url=@t  key.u.ifetch
      =/  up-status=@ud  status-code.response-header.resp
      ?:  ?|  ?=(~ full-file.resp)
              (lth up-status 200)
              (gte up-status 300)
          ==
        ~&  >>>  "burn: host prefetch failed status={<up-status>} for {<url>}"
        =/  next-cards=(list card)  (schedule-prefetch state now.bowl)
        [next-cards this]
      =/  the-octs=octs  data.u.full-file.resp
      =/  rh=response-header:http
        [200 ~[['content-type' 'image/jpeg'] ['cache-control' 'max-age=86400']]]
      =/  sp=simple-payload:http  [rh `the-octs]
      ~&  >  "burn: host prefetch cached {<url>} ({<p.the-octs>}b), {<(lent thumb-queue.state)>} queued"
      =/  next-cards=(list card)  (schedule-prefetch state now.bowl)
      :_  this
      :-  [%pass /cache %arvo %e %set-response url `[%.n %payload sp]]
      next-cards
    ::
    ::  HOST: thumbnail response (Ames proxy) — forward to subscriber.
    ::
        [%thumb-proxy @ @ ~]
      =/  subscriber=ship  (slav %p (snag 1 `(list @ta)`wire))
      =/  rid=@uv  (slav %uv (snag 2 `(list @ta)`wire))
      =/  rid-key=@t  (scot %uv rid)
      ?~  full-file.resp
        =.  pending.state  (~(del by pending.state) rid-key)
        :_  this
        :~  [%pass /proxy-ret/(scot %p subscriber)/(scot %uv rid)/(scot %ud control-flow) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid 502 ~ ~ control-flow])]
        ==
      =/  body=octs  data.u.full-file.resp
      =/  up-status=@ud  status-code.response-header.resp
      =.  pending.state  (~(del by pending.state) rid-key)
      ?.  &((gte up-status 200) (lth up-status 300))
        ~&  >>>  "burn: thumb proxy failed status={<up-status>} for {<subscriber>} rid={<(short-id-uv rid)>}"
        :_  this
        :~  [%pass /proxy-ret/(scot %p subscriber)/(scot %uv rid)/(scot %ud control-flow) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid up-status ~ ~ control-flow])]
        ==
      ::  Forward to subscriber only. Do not also write host Eyre cache on
      ::  the Ames thumb proxy path; host direct prefetch/cache paths cover
      ::  host-local use and this avoids a duplicate large noun allocation.
      ~&  >  "burn: thumb return to {<subscriber>} rid={<(short-id-uv rid)>} size={<p.body>}b"
      =/  fwd-card=card
        [%pass /proxy-ret/(scot %p subscriber)/(scot %uv rid)/(scot %ud control-flow) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid 200 ~[['content-type' 'image/jpeg']] `body control-flow])]
      :_  this
      ~[fwd-card]
    ::
    ::  HOST: download metadata → extract Part key → fetch first chunk
    ::
        [%download-meta @ ~]
      =/  eyre-id=@ta  (snag 1 `(list @ta)`wire)
      ?~  full-file.resp
        ~&  >>>  "burn: download metadata fetch failed"
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        [[502 ~] ~]
      =/  body=@t  q.data.u.full-file.resp
      =/  part-key=@t  (extract-part-key body)
      =/  part-file=@t  (extract-part-file body)
      =/  part-container=@tas  (container-from-path part-file)
      =/  rid=@uv  (sham eyre-id)
      ?:  =('' part-key)
        ~&  >>>  "burn: no Part key found in metadata"
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        [[404 ~] ~]
      ?~  hosting.state
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        [[500 ~] ~]
      =/  cfg=plex-config:burn  u.hosting.state
      =/  part-url=@t
        (cat 3 part-key (crip "?X-Plex-Token={(trip token.cfg)}&download=1"))
      ::  Store Part URL keyed by eyre-id for subsequent chunks
      =.  pending.state
        (~(put by pending.state) eyre-id part-url)
      =?  pending.state  !=(%$ part-container)
        (~(put by pending.state) (stream-container-key rid) (crip (trip part-container)))
      ::  Fetch first chunk (tiny — see first-chunk-size)
      =/  full-url=@t  (cat 3 url.cfg part-url)
      =/  range-hdr=[@t @t]  ['range' (crip "bytes=0-{(a-co:co (sub first-chunk-size 1))}")]
      =/  req=request:http  [%'GET' full-url ~[range-hdr] ~]
      ~&  >  "burn: host download first chunk {<part-key>}"
      =/  pe=proxy-entry:burn  [eyre-id now.bowl]
      =.  pending-proxies.state
        (~(put by pending-proxies.state) rid pe)
      :_  this
      :~  [%pass /download-host/[eyre-id]/(scot %ud 0) %arvo %i %request req *outbound-config:iris]
      ==
    ::
    ::  HOST: stream metadata → extract Part key → fetch first Range chunk
    ::
        [%stream-meta @ ~]
      =/  eyre-id=@ta  (snag 1 `(list @ta)`wire)
      ?~  full-file.resp
        ~&  >>>  "burn: stream metadata fetch failed"
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        [[502 ~] ~]
      =/  body=@t  q.data.u.full-file.resp
      =/  part-key=@t  (extract-part-key body)
      ?:  =('' part-key)
        ~&  >>>  "burn: stream no Part key in metadata"
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        [[404 ~] ~]
      ?~  hosting.state
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        [[500 ~] ~]
      =/  cfg=plex-config:burn  u.hosting.state
      =/  part-url=@t
        (cat 3 part-key (crip "?X-Plex-Token={(trip token.cfg)}"))
      ::  Store Part URL keyed by eyre-id for subsequent chunks
      =.  pending.state
        (~(put by pending.state) eyre-id part-url)
      ::  Fetch first chunk (tiny — see first-chunk-size)
      =/  full-url=@t  (cat 3 url.cfg part-url)
      =/  range-hdr=[@t @t]  ['range' (crip "bytes=0-{(a-co:co (sub first-chunk-size 1))}")]
      =/  req=request:http  [%'GET' full-url ~[range-hdr] ~]
      ~&  >  "burn: host stream first chunk {<part-key>}"
      :_  this
      :~  [%pass /stream-host/[eyre-id]/(scot %ud 0) %arvo %i %request req *outbound-config:iris]
      ==
    ::
    ::  HOST: download chunk for local browser → stream via Eyre
    ::  Wire: /download-host/{eyre-id}/{seq}
    ::
        [%download-host @ @ ~]
      =/  eyre-id=@ta  (snag 1 `(list @ta)`wire)
      =/  seq=@ud  (slav %ud (snag 2 `(list @ta)`wire))
      =/  rid=@uv  (sham eyre-id)
      ?~  full-file.resp
        ~&  >>>  "burn: host download chunk failed seq={<seq>}"
        :_  this
        ^-  (list card)
        :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>(*(unit octs))]
            [%give %kick ~[/http-response/[eyre-id]] ~]
        ==
      =/  body=octs  data.u.full-file.resp
      =/  status=@ud  status-code.response-header.resp
      =/  has-more=?  =(206 status)
      ~&  >  "burn: host chunk seq={<seq>} size={<p.body>} more={<has-more>}"
      ::  Live-strip tick: advance pending-streams[rid] for the progress
      ::  fact emission. State-mutation is done via =. (always-on, not =?)
      ::  to avoid type-narrowing interactions with ?~ hosting.state
      ::  further down. If no entry exists for rid, the tick is a no-op
      ::  (state stays the same, no progress card emitted).
      =/  pre-ss=(unit stream-state:burn)
        (~(get by pending-streams.state) rid)
      =/  tick-cards=(list card)
        ?~  pre-ss  ~
        =/  total-now=@ud
          ?:  =(0 total-size.u.pre-ss)
            (fall (extract-cr-total headers.response-header.resp) p.body)
          total-size.u.pre-ss
        =/  ss-post=stream-state:burn
          %_  u.pre-ss
            received    (add received.u.pre-ss p.body)
            emitted     (add emitted.u.pre-ss p.body)
            seq         +(seq.u.pre-ss)
            total-size  total-now
            sent-header  %.y
          ==
        ~[(give-progress-fact rid ss-post)]
      =.  state
        ?~  pre-ss  state
        =/  total-now=@ud
          ?:  =(0 total-size.u.pre-ss)
            (fall (extract-cr-total headers.response-header.resp) p.body)
          total-size.u.pre-ss
        =/  ss-post=stream-state:burn
          %_  u.pre-ss
            received    (add received.u.pre-ss p.body)
            emitted     (add emitted.u.pre-ss p.body)
            seq         +(seq.u.pre-ss)
            total-size  total-now
            sent-header  %.y
          ==
        state(pending-streams (~(put by pending-streams.state) rid ss-post))
      ::  First chunk: send header (200 to browser) + data. Subsequent: data only.
      ?.  has-more
        ::  Final chunk (or single chunk) — emit data + kick. Cleanup
        ::  pending-streams now so /downloads drops the completed rid.
        =.  pending.state  (~(del by pending.state) eyre-id)
        =.  state  (delete-stream state rid)
        ?:  =(seq 0)
          =/  clean-hdrs=header-list:http
            (clean-response-headers headers.response-header.resp)
          ::  Always send 200 to browser — we're reassembling from Range chunks
          =/  rh=response-header:http  [200 clean-hdrs]
          :_  this
          %+  weld  tick-cards
          ^-  (list card)
          :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-header !>(rh)]
              [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>((some body))]
              give-redraw
              [%give %kick ~[/http-response/[eyre-id]] ~]
          ==
        :_  this
        %+  weld  tick-cards
        ^-  (list card)
        :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>((some body))]
            give-redraw
            [%give %kick ~[/http-response/[eyre-id]] ~]
        ==
      ::  More chunks — send data, fetch next Range
      =/  part-url=(unit @t)  (~(get by pending.state) eyre-id)
      ?~  part-url
        :_  this
        %+  weld  tick-cards
        ^-  (list card)
        :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>((some body))]
            [%give %kick ~[/http-response/[eyre-id]] ~]
        ==
      ?~  hosting.state
        :_  this
        %+  weld  tick-cards
        ^-  (list card)
        :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>((some body))]
            [%give %kick ~[/http-response/[eyre-id]] ~]
        ==
      =/  next-seq=@ud  +(seq)
      ::  Variable first-chunk: see request-next-chunk for the math.
      =/  start=@ud
        ?:  =(0 next-seq)  0
        (add first-chunk-size (mul (sub next-seq 1) chunk-size))
      =/  end=@ud
        ?:  =(0 next-seq)  (sub first-chunk-size 1)
        (sub (add start chunk-size) 1)
      =/  range-val=@t  (crip "bytes={(a-co:co start)}-{(a-co:co end)}")
      =/  next-url=@t  (cat 3 url.u.hosting.state u.part-url)
      =/  req=request:http  [%'GET' next-url ~[['range' range-val]] ~]
      ?:  =(seq 0)
        =/  clean-hdrs=header-list:http
          (clean-response-headers headers.response-header.resp)
        ::  Always send 200 to browser — we're reassembling from Range chunks
        =/  rh=response-header:http  [200 clean-hdrs]
        :_  this
        %+  weld  tick-cards
        ^-  (list card)
        :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-header !>(rh)]
            [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>((some body))]
            [%pass /download-host/[eyre-id]/(scot %ud next-seq) %arvo %i %request req *outbound-config:iris]
        ==
      :_  this
      %+  weld  tick-cards
      ^-  (list card)
      :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>((some body))]
          [%pass /download-host/[eyre-id]/(scot %ud next-seq) %arvo %i %request req *outbound-config:iris]
      ==
    ::
    ::  HOST: stream chunk for local browser → stream via Eyre
    ::  Wire: /stream-host/{eyre-id}/{seq}
    ::  Same as download-host but content-type: video/mp4, no content-disposition
    ::
        [%stream-host @ @ ~]
      =/  eyre-id=@ta  (snag 1 `(list @ta)`wire)
      =/  seq=@ud  (slav %ud (snag 2 `(list @ta)`wire))
      ?~  full-file.resp
        ~&  >>>  "burn: host stream chunk failed seq={<seq>}"
        :_  this
        :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>(*(unit octs))]
            [%give %kick ~[/http-response/[eyre-id]] ~]
        ==
      =/  body=octs  data.u.full-file.resp
      =/  status=@ud  status-code.response-header.resp
      =/  has-more=?  =(206 status)
      ~&  >  "burn: stream chunk seq={<seq>} size={<p.body>} more={<has-more>}"
      ::  First chunk: send header (200 + video/mp4) + data. Subsequent: data only.
      ?.  has-more
        ::  Final chunk (or single chunk) — send data, kick, clean up
        =.  pending.state  (~(del by pending.state) eyre-id)
        ?:  =(seq 0)
          =/  rh=response-header:http  stream-rh
          :_  this
          :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-header !>(rh)]
              [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>((some body))]
              [%give %kick ~[/http-response/[eyre-id]] ~]
          ==
        :_  this
        :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>((some body))]
            [%give %kick ~[/http-response/[eyre-id]] ~]
        ==
      ::  More chunks — send data, fetch next Range
      =/  part-url=(unit @t)  (~(get by pending.state) eyre-id)
      ?~  part-url
        :_  this
        :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>((some body))]
            [%give %kick ~[/http-response/[eyre-id]] ~]
        ==
      ?~  hosting.state
        :_  this
        :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>((some body))]
            [%give %kick ~[/http-response/[eyre-id]] ~]
        ==
      =/  next-seq=@ud  +(seq)
      ::  Variable first-chunk: see request-next-chunk for the math.
      =/  start=@ud
        ?:  =(0 next-seq)  0
        (add first-chunk-size (mul (sub next-seq 1) chunk-size))
      =/  end=@ud
        ?:  =(0 next-seq)  (sub first-chunk-size 1)
        (sub (add start chunk-size) 1)
      =/  range-val=@t  (crip "bytes={(a-co:co start)}-{(a-co:co end)}")
      =/  next-url=@t  (cat 3 url.u.hosting.state u.part-url)
      =/  req=request:http  [%'GET' next-url ~[['range' range-val]] ~]
      ?:  =(seq 0)
        =/  rh=response-header:http  stream-rh
        :_  this
        :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-header !>(rh)]
            [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>((some body))]
            [%pass /stream-host/[eyre-id]/(scot %ud next-seq) %arvo %i %request req *outbound-config:iris]
        ==
      :_  this
      :~  [%give %fact ~[/http-response/[eyre-id]] %http-response-data !>((some body))]
          [%pass /stream-host/[eyre-id]/(scot %ud next-seq) %arvo %i %request req *outbound-config:iris]
      ==
    ::
    ::  HOST: download metadata (Ames) → extract Part key → fetch first chunk
    ::
        [%download-meta-proxy @ @ @ @ ~]
      =/  subscriber=ship  (slav %p (snag 1 `(list @ta)`wire))
      =/  rid=@uv  (slav %uv (snag 2 `(list @ta)`wire))
      =/  start-seq=@ud  (slav %ud (snag 3 `(list @ta)`wire))
      =/  start-byte=@ud  (slav %ud (snag 4 `(list @ta)`wire))
      ?~  full-file.resp
        ~&  >>>  "burn: download metadata failed for {<subscriber>}"
        :_  this
        :~  [%pass /proxy-ret/(scot %p subscriber) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid 502 ~ ~ control-flow])]
        ==
      =/  body=@t  q.data.u.full-file.resp
      =/  part-key=@t  (extract-part-key body)
      =/  part-file=@t  (extract-part-file body)
      =/  part-container=@tas  (container-from-path part-file)
      ?:  =('' part-key)
        ~&  >>>  "burn: no Part key in metadata for {<subscriber>}"
        :_  this
        :~  [%pass /proxy-ret/(scot %p subscriber) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid 404 ~ ~ control-flow])]
        ==
      ?~  hosting.state
        :_  this
        :~  [%pass /proxy-ret/(scot %p subscriber) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid 500 ~ ~ control-flow])]
        ==
      =/  cfg=plex-config:burn  u.hosting.state
      ::  Store Part URL for subsequent Range requests from subscriber
      =/  part-url=@t
        (cat 3 part-key (crip "?X-Plex-Token={(trip token.cfg)}&download=1"))
      =.  pending.state
        (~(put by pending.state) (scot %uv rid) part-url)
      =?  pending.state  !=(%$ part-container)
        (~(put by pending.state) (stream-container-key rid) (crip (trip part-container)))
      ::  Fetch first chunk (tiny — see first-chunk-size). L3: meta-proxy
      ::  always rides flow 0 (the metadata fetch is one-shot and the first
      ::  chunk completes on flow 0; subsequent chunks land on whatever
      ::  flow-id the subscriber assigns).
      =/  full-url=@t  (cat 3 url.cfg part-url)
      =/  first-start=@ud  start-byte
      =/  first-end=@ud
        ?:  =(0 start-seq)  (sub first-chunk-size 1)
        (sub (add (chunk-start-for-seq start-seq) chunk-size) 1)
      =/  range-hdr=[@t @t]  ['range' (crip "bytes={(a-co:co first-start)}-{(a-co:co first-end)}")]
      =/  req=request:http  [%'GET' full-url ~[range-hdr] ~]
      ~&  >  "burn: download first chunk for {<subscriber>} {<part-key>} seq={<start-seq>} start-byte={<start-byte>} range={<range-hdr>}"
      :_  this
      :~  [%pass /download-proxy/(scot %p subscriber)/(scot %uv rid)/(scot %ud start-seq)/(scot %ud 0) %arvo %i %request req *outbound-config:iris]
      ==
    ::
    ::  HOST: stream metadata (Ames) → extract Part key → fetch first chunk
    ::  Same as download-meta-proxy but no download=1 param
    ::
        [%stream-meta-proxy @ @ ~]
      =/  subscriber=ship  (slav %p (snag 1 `(list @ta)`wire))
      =/  rid=@uv  (slav %uv (snag 2 `(list @ta)`wire))
      ?~  full-file.resp
        ~&  >>>  "burn: stream metadata failed for {<subscriber>}"
        :_  this
        :~  [%pass /proxy-ret/(scot %p subscriber) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid 502 ~ ~ control-flow])]
        ==
      =/  body=@t  q.data.u.full-file.resp
      =/  part-key=@t  (extract-part-key body)
      ?:  =('' part-key)
        ~&  >>>  "burn: no Part key in stream metadata for {<subscriber>}"
        :_  this
        :~  [%pass /proxy-ret/(scot %p subscriber) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid 404 ~ ~ control-flow])]
        ==
      ?~  hosting.state
        :_  this
        :~  [%pass /proxy-ret/(scot %p subscriber) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid 500 ~ ~ control-flow])]
        ==
      =/  cfg=plex-config:burn  u.hosting.state
      ::  Store Part URL for subsequent Range requests — no download=1
      =/  part-url=@t
        (cat 3 part-key (crip "?X-Plex-Token={(trip token.cfg)}"))
      =.  pending.state
        (~(put by pending.state) (scot %uv rid) part-url)
      ::  Fetch first chunk (tiny — see first-chunk-size)
      =/  full-url=@t  (cat 3 url.cfg part-url)
      =/  range-hdr=[@t @t]  ['range' (crip "bytes=0-{(a-co:co (sub first-chunk-size 1))}")]
      =/  req=request:http  [%'GET' full-url ~[range-hdr] ~]
      ~&  >  "burn: stream first chunk for {<subscriber>} {<part-key>}"
      :_  this
      :~  [%pass /stream-proxy/(scot %p subscriber)/(scot %uv rid)/(scot %ud 0)/(scot %ud 0) %arvo %i %request req *outbound-config:iris]
      ==
    ::
    ::  HOST: stream Range response → send %proxy-chunk to subscriber
    ::  Wire: /stream-proxy/{subscriber}/{rid}/{seq}/{flow-id}
    ::  Same as download-proxy — proxy-chunk handler on subscriber is generic.
    ::  L3 parallel-chunks: flow-id is recovered from the Iris fetch wire (Iris
    ::  responses preserve the original wire). The %proxy-chunk return rides
    ::  /proxy-ret/{sub}/{rid}/{flow-id} so the host gets a distinct bone
    ::  per flow and chunk arrivals don't queue behind one bone's cwnd.
    ::
        [%stream-proxy @ @ @ @ ~]
      =/  subscriber=ship  (slav %p (snag 1 `(list @ta)`wire))
      =/  rid=@uv  (slav %uv (snag 2 `(list @ta)`wire))
      =/  seq=@ud  (slav %ud (snag 3 `(list @ta)`wire))
      =/  flow-id=@ud  (slav %ud (snag 4 `(list @ta)`wire))
      ?~  full-file.resp
        ~&  >>>  "burn: stream chunk failed {<+(seq)>} rid={<(short-id-uv rid)>} flow={<flow-id>}"
        :_  this
        :~  [%pass /proxy-ret/(scot %p subscriber)/(scot %uv rid)/(scot %ud flow-id) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid 502 ~ ~ flow-id])]
        ==
      =/  body=octs  data.u.full-file.resp
      =/  status=@ud  status-code.response-header.resp
      ::  state belt-and-suspenders: 4xx/5xx upstream responses are
      ::  TERMINAL — discard the body (HTML error page from Plex would
      ::  otherwise stream as if it were file content; see download-31)
      ::  and signal end-of-stream via empty final chunk.
      =/  is-error=?  (gte status 400)
      =/  has-more=?
        (derive-has-more is-error status headers.response-header.resp)
      =/  outbound-body=octs  ?:(is-error *octs body)
      =/  cr-total=(unit @ud)  (extract-cr-total headers.response-header.resp)
      =/  m-host=@ud  ?~(cr-total 0 (total-chunks u.cr-total))
      ::  Bug C fix: was "stream chunk N/M ..." which read ambiguously as
      ::  fetched-from-Plex; this slog actually fires AFTER Iris response is
      ::  parsed and is the host's last action before emitting the chunk-act
      ::  poke to the subscriber. Renamed to EMIT for unambiguity.
      ~&  >  "burn: HOST EMIT stream chunk-act {<+(seq)>}/{<m-host>} size={<p.outbound-body>} status={<status>} more={<has-more>} rid={<(short-id-uv rid)>} →{<subscriber>} flow={<flow-id>} t={<now.bowl>}{?:(is-error " — TERMINAL, error body discarded" "")}"
      =/  stream-hdrs=header-list:http
        ?:(=(seq 0) ~[['content-type' 'video/mp4']] ~)
      =/  chunk-act=action:burn
        :*  %proxy-chunk
            rid
            seq
            outbound-body
            has-more
            ?:(=(seq 0) status 0)
            ?:(=(seq 0) stream-hdrs ~)
            flow-id                              ::  L3: which flow this chunk belongs to
        ==
      :_  this
      :~  [%pass /proxy-ret/(scot %p subscriber)/(scot %uv rid)/(scot %ud flow-id) %agent [subscriber %burn] %poke %burn-action !>(chunk-act)]
      ==
    ::
    ::  HOST: download Range response → send single %proxy-chunk to subscriber
    ::  Wire: /download-proxy/{subscriber}/{rid}/{seq}/{flow-id}
    ::  L3 parallel-chunks: flow-id recovered from the Iris fetch wire; return
    ::  poke rides /proxy-ret/{sub}/{rid}/{flow-id} so each flow allocates
    ::  its own host-side Mesa bone with independent per-bone cwnd.
    ::
        [%download-proxy @ @ @ @ ~]
      =/  subscriber=ship  (slav %p (snag 1 `(list @ta)`wire))
      =/  rid=@uv  (slav %uv (snag 2 `(list @ta)`wire))
      =/  seq=@ud  (slav %ud (snag 3 `(list @ta)`wire))
      =/  flow-id=@ud  (slav %ud (snag 4 `(list @ta)`wire))
      ?~  full-file.resp
        ~&  >>>  "burn: download chunk failed {<+(seq)>} rid={<(short-id-uv rid)>} flow={<flow-id>}"
        :_  this
        :~  [%pass /proxy-ret/(scot %p subscriber)/(scot %uv rid)/(scot %ud flow-id) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid 502 ~ ~ flow-id])]
        ==
      =/  body=octs  data.u.full-file.resp
      =/  status=@ud  status-code.response-header.resp
      =/  base-hdrs=header-list:http
        (clean-response-headers headers.response-header.resp)
      =/  container-hint=(unit @t)
        (~(get by pending.state) (stream-container-key rid))
      =/  clean-hdrs=header-list:http
        ?~  container-hint  base-hdrs
        [['x-burn-container' u.container-hint] base-hdrs]
      ::  state belt-and-suspenders: 4xx/5xx upstream responses are
      ::  TERMINAL — discard the body (HTML 416 error from Plex would
      ::  otherwise stream into the file as if it were chunk data, the
      ::  bug diagnosed in download-31) and signal end-of-stream via
      ::  empty final chunk. Subscriber's empty-final-chunk path closes
      ::  the browser connection cleanly.
      =/  is-error=?  (gte status 400)
      =/  has-more=?
        (derive-has-more is-error status headers.response-header.resp)
      =/  outbound-body=octs  ?:(is-error *octs body)
      =/  cr-total=(unit @ud)  (extract-cr-total headers.response-header.resp)
      =/  m-host=@ud  ?~(cr-total 0 (total-chunks u.cr-total))
      ::  Bug C fix: same renaming as the stream-proxy site above — this slog
      ::  fires after Iris response parsing and is the host's last action
      ::  before emitting the chunk-act poke. EMIT makes that unambiguous.
      ~&  >  "burn: HOST EMIT download chunk-act {<+(seq)>}/{<m-host>} size={<p.outbound-body>} status={<status>} more={<has-more>} rid={<(short-id-uv rid)>} →{<subscriber>} flow={<flow-id>} t={<now.bowl>}{?:(is-error " — TERMINAL, error body discarded" "")}"
      =/  chunk-act=action:burn
        :*  %proxy-chunk
            rid
            seq
            outbound-body
            has-more
            status
            clean-hdrs
            flow-id                              ::  L3: which flow this chunk belongs to
        ==
      :_  this
      :~  [%pass /proxy-ret/(scot %p subscriber)/(scot %uv rid)/(scot %ud flow-id) %agent [subscriber %burn] %poke %burn-action !>(chunk-act)]
      ==
    ::
    ::  HOST: proxy response → forward to subscriber over Ames
    ::
        [%proxy @ @ ~]
      =/  subscriber=ship  (slav %p (snag 1 `(list @ta)`wire))
      =/  rid=@uv  (slav %uv (snag 2 `(list @ta)`wire))
      ?~  full-file.resp
        :_  this
        :~  [%pass /proxy-ret/(scot %p subscriber)/(scot %uv rid)/(scot %ud control-flow) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid 502 ~ ~ control-flow])]
        ==
      =/  body=octs  data.u.full-file.resp
      =/  clean-hdrs=header-list:http
        (clean-response-headers headers.response-header.resp)
      ~&  >  "burn: proxy result for {<subscriber>} rid={<(short-id-uv rid)>} status={<status-code.response-header.resp>}"
      :_  this
      :~  [%pass /proxy-ret/(scot %p subscriber)/(scot %uv rid)/(scot %ud control-flow) %agent [subscriber %burn] %poke %burn-action !>(`action:burn`[%proxy-response rid status-code.response-header.resp clean-hdrs `body control-flow])]
      ==
    ==
  ==
::
::  +on-watch: handle subscriptions
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+    path  (on-watch:default path)
  ::
  ::  Public download status fact channel. Subscriber receives current
  ::  snapshot immediately, then a fresh snapshot on every state mutation
  ::  (download start, chunk arrival, disconnect). See sur/burn
  ::  +$status-snapshot and ++build-status-snapshot.
  ::
      [%status ~]
    ~&  >  "burn: /status sub from {<src.bowl>}"
    :_  this
    :~  [%give %fact ~ %noun !>(`status-snapshot:burn`(build-status-snapshot state our.bowl))]
    ==
  ::
      [%http-response *]
    `this
  ::
  ::  Library items subscription — hold until data arrives, then give fact
  ::
      [%library %items *]
    ?.  ?=([@ ~] t.t.path)
      ~&  >>>  "burn: bad items subscription path"
      `this
    =/  section-key=@t  `@t`i.t.t.path
    ~&  >  "burn: items sub for section {<section-key>} from {<src.bowl>}"
    =/  self-src=source-state:burn  (get-source state our.bowl)
    ?.  (~(has by items.self-src) section-key)
      ~&  >  "burn: holding items sub for {<section-key>}"
      `this
    =/  items=(list library-item:burn)
      (need (~(get by items.self-src) section-key))
    ~&  >  "burn: giving cached {<(lent items)>} items"
    :_  this
    :~  [%give %fact ~ %noun !>(items)]
        [%give %kick ~ `src.bowl]
    ==
  ::
  ::  Epic: protocol version negotiation
  ::
      [%burn %epic ~]
    ~&  >  "burn: epic requested by {<src.bowl>}"
    :_  this
    :~  [%give %fact ~ %noun !>(okay:burn)]
    ==
  ::
  ::  Canonical Hoon Native UI watch. Subscriber receives %goon-redraw
  ::  facts (just notification; renderer re-scries /x/goon). Watch start
  ::  also kicks eager fetches for any unloaded library structure so the
  ::  tree fills in without per-node expand actions.
  ::
      [%goon ~]
    ~&  >  "burn: /goon watch from {<src.bowl>}"
    :_  this
    =/  host-ship=ship  (pick-host-ship state our.bowl)
    (welp ~[give-redraw] (eager-library-fetches state host-ship our.bowl))
  ::
  ::  Live-island per-chunk progress. Gives current snapshot immediately
  ::  on subscribe if the stream is active, so late subscribers (page
  ::  reload mid-download) see the strip without waiting for next chunk.
  ::
      [%goon %progress @ ~]
    ~&  >  "burn: /goon/progress/{<i.t.t.path>} watch from {<src.bowl>}"
    =/  rid=@uv  (slav %uv i.t.t.path)
    =/  ss=(unit stream-state:burn)
      (~(get by pending-streams.state) rid)
    ?~  ss  `this
    :_  this
    ~[(give-progress-fact rid u.ss)]
  ==
::
::  +on-agent: handle responses from remote agents
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+  wire  (on-agent:default wire sign)
  ::
  ::  EPIC: version check response from remote host
  ::
      [%epic @ ~]
    =/  remote-ship=ship  (slav %p (snag 1 `(list @ta)`wire))
    ?+  -.sign  (on-agent:default wire sign)
    ::
        %fact
      =/  remote-epic=@ud  ;;(@ud q.q.cage.sign)
      ?.  =(remote-epic okay:burn)
        ~&  >>>  "burn: {<remote-ship>} at epic {<remote-epic>}, we're at {<okay:burn>}"
        =/  src=(unit source-state:burn)  (~(get by sources.state) remote-ship)
        ?~  src  `this
        `this(sources.state (~(put by sources.state) remote-ship u.src(saga %mismatch)))
      ~&  >  "burn: {<remote-ship>} epic matches"
      =/  src=(unit source-state:burn)  (~(get by sources.state) remote-ship)
      ?~  src  `this
      `this(sources.state (~(put by sources.state) remote-ship u.src(saga %ok)))
    ::
        %watch-ack
      ?~  p.sign
        ~&  >  "burn: epic watch ack from {<remote-ship>}"
        `this
      ~&  >>>  "burn: epic watch nack from {<remote-ship>}"
      `this(sources.state (~(del by sources.state) remote-ship))
    ::
        %kick
      ~&  >  "burn: re-watching epic for {<remote-ship>}"
      :_  this
      :~  [%pass /epic/(scot %p remote-ship) %agent [remote-ship %burn] %watch /burn/epic]
      ==
    ==
  ::
  ::  PROXY: poke-ack from proxy request/response delivery.
  ::  L3 parallel-chunks: proxy-out wire is now 4-segment /proxy-out/{ship}/{rid}/{flow-id}.
  ::
      [%proxy-out @ @ @ ~]
    ?+  -.sign  (on-agent:default wire sign)
        %poke-ack
      ?~  p.sign  `this
      =/  rid=@uv  (slav %uv (snag 2 `(list @ta)`wire))
      =/  flow-id=@ud  (slav %ud (snag 3 `(list @ta)`wire))
      ::  Free the flow that just nacked so dispatch-flows can reuse it.
      =/  ss=(unit stream-state:burn)
        (~(get by pending-streams.state) rid)
      =?  pending-streams.state  ?=(^ ss)
        =/  ent=(unit flow-state:burn)  (~(get by flows.u.ss) flow-id)
        ?~  ent  pending-streams.state
        (~(put by pending-streams.state) rid u.ss(flows (~(put by flows.u.ss) flow-id [%idle 0])))
      =/  ifetch=(unit internal-fetch:burn)
        (~(get by internal-pending.state) rid)
      ?^  ifetch
        ~&  >>>  "burn: proxy nack for internal rid {<(short-id-uv rid)>} tag={<tag.u.ifetch>} flow={<flow-id>}"
        =.  internal-pending.state  (~(del by internal-pending.state) rid)
        ?:  =(%thumb-prefetch tag.u.ifetch)
          =/  next-cards=(list card)  (schedule-prefetch state now.bowl)
          [next-cards this]
        `this
      =/  pe=(unit proxy-entry:burn)  (~(get by pending-proxies.state) rid)
      ?~  pe
        ~&  >>>  "burn: proxy nack for unknown rid {<(short-id-uv rid)>} flow={<flow-id>}"
        `this
      ~&  >>>  "burn: proxy nack from host, returning 502"
      =.  pending-proxies.state
        (~(del by pending-proxies.state) rid)
      :_  this
      %+  give-simple-payload:app:server  eyre-id.u.pe
      [[502 ~] ~]
    ==
  ::
  ::  L3 parallel-chunks: 4-segment proxy-ret poke-ack (host→sub chunk path).
  ::
      [%proxy-ret @ @ @ ~]
    ?+  -.sign  (on-agent:default wire sign)
        %poke-ack
      ?~  p.sign  `this
      =/  rid=@uv  (slav %uv (snag 2 `(list @ta)`wire))
      =/  flow-id=@ud  (slav %ud (snag 3 `(list @ta)`wire))
      ~&  >>>  "burn: proxy-ret poke nack rid={<(short-id-uv rid)>} flow={<flow-id>}"
      `this
    ==
  ::
  ::  Legacy 2-segment proxy-ret (control-plane error responses still ride this).
  ::
      [%proxy-ret @ ~]
    ?+  -.sign  (on-agent:default wire sign)
        %poke-ack
      ?~  p.sign  `this
      ~&  >>>  "burn: proxy-ret poke nack (legacy 2-seg wire)"
      `this
    ==
  ==
::
::  +on-leave: handle subscription departures
::
++  on-leave
  |=  =path
  ^-  (quip card _this)
  ?.  ?=([%http-response @ ~] path)
    `this
  =/  eid=@ta  i.t.path
  ~&  >  "burn: on-leave for eyre-id {<(short-id-ta eid)>}"
  =/  entries=(list [@uv proxy-entry:burn])
    ~(tap by pending-proxies.state)
  =/  match=(unit @uv)
    |-
    ?~  entries  ~
    ?:  =(eid eyre-id.+.i.entries)
      `-.i.entries
    $(entries t.entries)
  ?~  match
    =/  stream-entries=(list [@uv stream-state:burn])
      ~(tap by pending-streams.state)
    =/  stream-match=(unit @uv)
      |-
      ?~  stream-entries  ~
      ?:  =(eid eyre-id.+.i.stream-entries)
        `-.i.stream-entries
      $(stream-entries t.stream-entries)
    ?~  stream-match
      `this
    ::  Post-neuter: every disconnect is terminal. Delete the stream
    ::  immediately — frees the cap slot for the next visitor (demo:
    ::  global cap = 1).
    =/  rid=@uv  u.stream-match
    =/  ss=(unit stream-state:burn)
      (~(get by pending-streams.state) rid)
    =/  ob=(unit buffered-chunk:burn)
      (~(get by octs-buffer.state) rid)
    =/  arr=(unit @da)
      (~(get by stream-arrivals.state) rid)
    ~&  >>>  "burn: on-leave stream rid={<(short-id-uv rid)>} eyre-id={<(short-id-ta eid)>} emitted={<?~(ss 0 emitted.u.ss)>} received={<?~(ss 0 received.u.ss)>} total={<?~(ss 0 total-size.u.ss)>} seq={<?~(ss 0 seq.u.ss)>} sent-header={<?~(ss %.n sent-header.u.ss)>}"
    ~&  >>>  "burn: on-leave buffer rid={<(short-id-uv rid)>} remaining={<?~(ob 0 (sub p.bytes.u.ob cursor.u.ob))>} final={<?~(ob %.n final.u.ob)>} last-arrival={<arr>} now={<now.bowl>}"
    ~&  >  "burn: on-leave delete rid={<(short-id-uv rid)>}"
    =.  state  (delete-stream state rid)
    :_  this
    ~[(give-status-fact state our.bowl)]
  =.  pending-proxies.state
    (~(del by pending-proxies.state) u.match)
  =.  state  (delete-stream state u.match)
  :_  this
  ~[(give-status-fact state our.bowl)]
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  ~
    ::  /x/status — summary for Oxal view
    ::
      [%x %status ~]
    =/  hosting-status=@t
      ?~  hosting.state  'not-hosting'
      (cat 3 'hosting:' url.u.hosting.state)
    =/  sources-count=@ud  ~(wyt by sources.state)
    =/  allowed-count=@ud  ~(wyt by allowed.state)
    =/  invitations-count=@ud  ~(wyt by invitations.state)
    =/  pending-count=@ud  ~(wyt by pending-proxies.state)
    ``noun+!>([hosting-status sources-count allowed-count invitations-count pending-count])
    ::  /x/hosting — hosting config
    ::
      [%x %hosting ~]
    ``noun+!>(hosting.state)
    ::  /x/sources — subscribed sources
    ::
      [%x %sources ~]
    ``noun+!>(sources.state)
    ::  /x/allowed — allowed subscribers
    ::
      [%x %allowed ~]
    ``noun+!>(allowed.state)
    ::  /x/invitations — pending invitations
    ::
      [%x %invitations ~]
    ``noun+!>(invitations.state)
    ::  /x/library/sections — cached library section metadata (host's own; sources[our.bowl])
    ::  TODO next-run: redesign as /x/library/<ship>/sections so scry is ship-aware.
    ::
      [%x %library %sections ~]
    ``noun+!>(sections:(get-source state our.bowl))
    ::  /x/library/items — all cached items by section (host's own)
    ::
      [%x %library %items ~]
    ``noun+!>(items:(get-source state our.bowl))
    ::  /x/library/items/[key] — cached items for one section (host's own)
    ::
      [%x %library %items *]
    ?.  ?=([@ ~] t.t.t.path)
      ~
    ``noun+!>((fall (~(get by items:(get-source state our.bowl)) `@t`i.t.t.t.path) ~))
    ::  /x/goon — canonical Hoon Native UI goad tree
    ::
      [%x %goon ~]
    =/  host-ship=ship  (pick-host-ship state our.bowl)
    ``noun+!>(`goad:goon`(to-goad:burn-to-goad state host-ship))
  ==
++  on-fail   on-fail:default
--
::
::  Helper core
::
|%
::
::  +get-source: read source-state for a ship; returns bunt entry
::  for that ship if absent (sections/items/seasons/episodes empty).
::  Lets reader code uniformly do `sections:(get-source state ship)`
::  whether the entry exists yet or not.
::
++  get-source
  |=  [s=state:burn =ship]
  ^-  source-state:burn
  =/  existing=(unit source-state:burn)  (~(get by sources.s) ship)
  ?^  existing  u.existing
  [ship %ok ~ ~ ~ ~]
::
::  +put-source: write source-state for a ship into sources map.
::
++  put-source
  |=  [s=state:burn src=source-state:burn]
  ^-  state:burn
  s(sources (~(put by sources.s) ship.src src))
::
::  +pick-host-ship: which ship's library does /library render?
::    - If we're hosting → our own (sources[our.bowl])
::    - Else → first subscribed source. Single-source fallback;
::      multi-source surfaces will be /library/<ship>/... in a
::      next-run scry redesign.
::    - No subscriptions either → our.bowl (renders empty)
::
++  pick-host-ship
  |=  [s=state:burn our=ship]
  ^-  ship
  ?^  hosting.s  our
  =/  others=(list ship)  ~(tap in (~(del in ~(key by sources.s)) our))
  ?~  others  our
  i.others
::
::  +inflate-io: true up all pending IO based on current state
::
++  inflate-io
  |=  [=state:burn now=@da our=ship]
  ^-  (list card)
  ~&  >  "burn: inflate-io"
  =/  cards=(list card)
    :~  [%pass /eyre/connect %arvo %e %connect [~ /apps/burn] %burn]
        [%pass /proxy-sweep %arvo %b %wait (add now (get-timeout state))]
    ==
  ::  Re-establish epic watches for all sources
  =/  src-list=(list [=ship =source-state:burn])
    ~(tap by sources.state)
  =/  epic-cards=(list card)
    %+  turn  src-list
    |=  [=ship =source-state:burn]
    [%pass /epic/(scot %p ship) %agent [ship %burn] %watch /burn/epic]
  ::  Restart thumb prefetch via single behn wake — the wake handler at
  ::  /thumb-prefetch in on-arvo calls +dispatch-prefetches to start
  ::  serial dispatch. Reap any ghost %thumb-prefetch internal-pending
  ::  entries first — Iris/Ames responses for pre-reload fetches are
  ::  lost; the new dispatch starts from scratch.
  =.  state  (reap-prefetch-pending state)
  =/  prefetch-cards=(list card)
    ?~  thumb-queue.state  ~
    ~&  >  "burn: restarting prefetch ({<(lent thumb-queue.state)>} queued)"
    :~  [%pass /thumb-prefetch %arvo %b %wait (add now ~s1)]
    ==
  ::  Schedule one generic library warmup tick. It will walk sections, items,
  ::  show/artist children, and season/album children one metadata edge at a
  ::  time, backing off while downloads are active.
  =/  warmup-cards=(list card)
    ?.  ?|  ?=(^ hosting.state)
            !=(~ (~(del by sources.state) our))
        ==
      ~
    ~&  >  "burn: scheduling library warmup in 3s"
    :~  [%pass /library-warmup %arvo %b %wait (add now ~s3)]
    ==
  :(weld epic-cards prefetch-cards warmup-cards cards)
::
::  +resolve-token: select correct Plex token
::
++  resolve-token
  |=  [requester=@p our=@p =plex-config:burn allowed=(map ship guest-config:burn)]
  ^-  (unit @t)
  ?:  =(requester our)
    `token.plex-config
  =/  gc=(unit guest-config:burn)  (~(get by allowed) requester)
  ?~  gc  ~
  ?:  =('' token.u.gc)
    `token.plex-config
  `token.u.gc
::
::  +download-auth-ok: browser-facing download/stream gate.
::
::  Eyre's inbound `authenticated` flag is only %.y for %ours. EAuth
::  %real requests arrive with src.bowl set to the visitor's @p, but
::  authenticated remains %.n. Agents do not receive the identity tag, so
::  anonymous guests are detected by the %pawn/comet identity shape.
::
++  download-auth-ok
  |=  [requester=@p our=@p authenticated=?]
  ^-  ?
  ?|  authenticated
      =(requester our)
      !=(%pawn (clan:title requester))
  ==
::
::  +passcode-grant-ok: stateless per-download passcode grant.
::
::  The passcode POST mints a short-lived cookie whose value is a hash of
::  passcode + requester fingerprint + exact media URL. The later GET only
::  passes if the same browser session requests the same media URL.
::
++  passcode-grant-ok
  |=  [requester=@p media-url=@t request=request:http]
  ^-  ?
  ?.  (passcode-target-ok media-url)  %.n
  =/  grant=(unit @t)  (request-cookie pass-cookie request)
  ?~  grant  %.n
  =(u.grant (passcode-grant requester media-url))
::
++  passcode-target-ok
  |=  url=@t
  ^-  ?
  =/  path=tape  (trip (strip-query url))
  ?|  (tape-starts "/apps/burn/download/" path)
      (tape-starts "/apps/burn/stream/" path)
  ==
::
++  passcode-grant
  |=  [requester=@p media-url=@t]
  ^-  @t
  (scot %uv (shax (jam [passcode requester media-url])))
::
++  passcode-cookie-header
  |=  [requester=@p media-url=@t]
  ^-  [@t @t]
  =/  cookie-path=tape  (trip (strip-query media-url))
  =/  grant-tape=tape  (trip (passcode-grant requester media-url))
  :-  'set-cookie'
  (crip "{(trip pass-cookie)}={grant-tape}; Max-Age=60; Path={cookie-path}; HttpOnly; SameSite=Lax")
::
++  passcode-form
  |=  =inbound-request:eyre
  ^-  (map @t @t)
  ?~  body.request.inbound-request  ~
  %-  fall  :_  ~
  %-  mole  |.
  (malt (rash q.u.body.request.inbound-request yquy:de-purl:html))
::
++  request-cookie
  |=  [name=@t request=request:http]
  ^-  (unit @t)
  =/  cookie-header=@t
    %+  roll  header-list.request
    |=  [[key=@t value=@t] c=@t]
    ?.  =(key 'cookie')
      c
    (cat 3 (cat 3 c ?~(c 0 '; ')) value)
  ?~  cookies=(rush cookie-header cock:de-purl:html)
    ~
  (get-header:http name u.cookies)
::
++  strip-query
  |=  url=@t
  ^-  @t
  (crip (take-before-query (trip url)))
::
++  take-before-query
  |=  chars=tape
  ^-  tape
  ?~  chars  ~
  ?:  =('?' i.chars)  ~
  [i.chars $(chars t.chars)]
::
++  tape-starts
  |=  [prefix=tape value=tape]
  ^-  ?
  =((scag (lent prefix) value) prefix)
::
::  +is-hidden-media-artifact: Plex can index macOS AppleDouble sidecar
::  files from non-HFS volumes as if they were media. Drop those rows at
::  parse time so the UI never offers a bogus download.
::
++  is-hidden-media-artifact
  |=  [title=@t part-file=@t]
  ^-  ?
  ?|  (tape-starts "._" (trip title))
      =('.DS_Store' title)
      ?=(^ (find "/._" (trip part-file)))
      ?=(^ (find "/.DS_Store" (trip part-file)))
  ==
::
::  +handle-passcode-auth: validate the code and redirect back to the
::  requested media URL with a one-download cookie grant. new-oxal renders
::  the form; Burn only verifies and enforces the grant.
::
++  handle-passcode-auth
  |=  [eyre-id=@ta =inbound-request:eyre requester=@p]
  ^-  (list card)
  ?.  =('POST' method.request.inbound-request)
    %+  give-simple-payload:app:server  eyre-id
    [[405 ~[['allow' 'POST'] ['cache-control' 'no-store']]] ~]
  =/  form=(map @t @t)  (passcode-form inbound-request)
  =/  code=@t  (~(gut by form) 'code' '')
  =/  redirect=@t  (~(gut by form) 'redirect' '/new-oxal/plex')
  ?.  (passcode-target-ok redirect)
    %+  give-simple-payload:app:server  eyre-id
    [[400 ~[['cache-control' 'no-store'] ['content-type' 'text/plain']]] `(unit octs)`(some (as-octt:mimes:html "invalid download target"))]
  ?.  =(code passcode)
    =/  retry=@t
      (crip "/new-oxal/plex?auth=required&error=passcode&redirect={(en-urlt:html (trip redirect))}")
    %+  give-simple-payload:app:server  eyre-id
    [[303 ~[['location' retry] ['cache-control' 'no-store']]] ~]
  %+  give-simple-payload:app:server  eyre-id
  :-  :-  303
      :~  ['location' redirect]
          ['cache-control' 'no-store']
          (passcode-cookie-header requester redirect)
      ==
  `(unit octs)`~
::
::  +clean-response-headers: strip hop-by-hop headers
::
++  clean-response-headers
  |=  headers=header-list:http
  ^-  header-list:http
  %+  skip  headers
  |=  [key=@t value=@t]
  =/  k  (crip (cass (trip key)))
  ?|  =(k 'content-length')
      =(k 'connection')
      =(k 'keep-alive')
      =(k 'transfer-encoding')
      =(k 'accept-ranges')
  ==
::
++  range-only-headers
  |=  headers=header-list:http
  ^-  header-list:http
  =/  rng=(unit @t)  (get-header-ci 'range' headers)
  ?~  rng  ~
  ~[['range' u.rng]]
::
::  +is-thumb-url: detect if a URL path is a thumbnail request
::  Matches paths containing /thumb/ (e.g. /library/metadata/2246/thumb/1775550344)
::
++  is-thumb-url
  |=  url=@t
  ^-  ?
  !=(~ (find "/thumb/" (trip url)))
::
::  +thumb-transcode-url: rewrite a thumb path to use Plex transcode endpoint.
::  Reads optional ?w=&h= query hints emitted by burn-to-goad's +poster-child
::  (per aspect-kind: tall=200x300, wide=320x180, square=300x300). Defaults
::  preserve legacy 200x300 behavior for callers without hints.
::
++  thumb-transcode-url
  |=  [plex-path=@t tok=@t]
  ^-  @t
  =/  pp=tape  (trip plex-path)
  =/  q-idx=(unit @ud)  (find "?" pp)
  =/  base=tape  ?~(q-idx pp (scag u.q-idx pp))
  =/  qs=tape   ?~(q-idx "" (slag +(u.q-idx) pp))
  =/  w=@ud  (parse-int-param qs "w" 200)
  =/  h=@ud  (parse-int-param qs "h" 300)
  =/  ws=tape  (trip (scot %ud w))
  =/  hs=tape  (trip (scot %ud h))
  (crip "/photo/:/transcode?url={base}&width={ws}&height={hs}&X-Plex-Token={(trip tok)}")
::
::  +parse-int-param: read a single integer query param by key from a
::  query-string fragment (no leading "?"). Returns `default` if the
::  key is absent or the value is not a positive integer.
::
++  parse-int-param
  |=  [qs=tape key=tape default=@ud]
  ^-  @ud
  =/  needle=tape  (weld key "=")
  =/  idx=(unit @ud)  (find needle qs)
  ?~  idx  default
  =/  after=tape  (slag (add u.idx (lent needle)) qs)
  =/  end=@ud
    =/  amp=(unit @ud)  (find "&" after)
    ?~  amp  (lent after)
    u.amp
  =/  num-tape=tape  (scag end after)
  =/  parsed=(unit @ud)  (rush (crip num-tape) dem)
  ?~(parsed default u.parsed)
::
::  +slice-for: proportional reserve drain. At any moment, the current
::  browser-side reserve would take `runway` to drain at this cadence.
::  Chunk-arrival overflow is handled separately by max-reserve; this arm
::  stays simple and predictable.
::
::  - buf == 0  → 0 (caller must guard drained-buffer branch)
::  - else      → buf * interval / runway (half-life ≈ runway × 0.693)
::
::  No max(1,…) floor: Vere SIGSEGV protection lives at the /dl-trickle
::  caller, which guards use-slice == 0 and skips the fact emit.
::
++  slice-for
  |=  [buf=@ud runway=@dr]
  ^-  @ud
  ?:  =(0 buf)  0
  (div (mul buf `@ud`trickle-interval) `@ud`runway)
::
::  +schedule-trickle: build the /dl-trickle behn %wait card for `rid`,
::  firing trickle-interval from `now`. Single source of truth for wire
::  path and timer math. Used at proxy-chunk subsequent-branch (gated on
::  prior-buffer-empty) and at /dl-trickle handler self-reschedule.
::  Behn does NOT dedupe by wire — callers must gate to avoid stacking.
::  See memory/feedback_behn_same_wire_stacks.md.
::
++  schedule-trickle
  |=  [rid=@uv now=@da]
  ^-  card
  [%pass /dl-trickle/(scot %uv rid) %arvo %b %wait (add now trickle-interval)]
::
::  +can-start-download: global concurrency gate. Returns %.y if a new
::  stream may enter pending-streams. Queue-on-cap is intentionally not
::  implemented (would need a notification system to revive timed-out
::  browser requests).
::
++  can-start-download
  |=  s=state:burn
  ^-  ?
  (lth ~(wyt by pending-streams.s) max-concurrent-downloads-global)
::
::  +delete-stream: atomic cleanup of all per-rid stream tracking maps.
::  Single audit point — every del-by-rid site routes through here so
::  stream-arrivals can never orphan from pending-streams.
::
++  delete-stream
  |=  [s=state:burn rid=@uv]
  ^-  state:burn
  %_  s
    pending-streams       (~(del by pending-streams.s) rid)
    pending               (~(del by pending.s) (stream-container-key rid))
    deferred-headers      (~(del by deferred-headers.s) rid)
    octs-buffer           (~(del by octs-buffer.s) rid)
    stream-arrivals       (~(del by stream-arrivals.s) rid)
    reassembly            (~(del by reassembly.s) rid)        ::  L3 parallel-chunks
    final-seq             (~(del by final-seq.s) rid)         ::  L3 parallel-chunks
  ==
::
++  stream-container-key
  |=  rid=@uv
  ^-  @t
  (cat 3 (scot %uv rid) '/container')
::
::  +build-status-snapshot: project pending-streams onto the public
::  status shape. Publisher is the host's @p so the snapshot is forward-
::  compat for multi-host observers. See sur/burn.hoon +$status-entry.
::
++  build-status-snapshot
  |=  [s=state:burn our=ship]
  ^-  status-snapshot:burn
  =/  entries=(list [@uv stream-state:burn])
    ~(tap by pending-streams.s)
  %+  turn  entries
  |=  [rid=@uv ss=stream-state:burn]
  ^-  status-entry:burn
  =/  last=@da  (fall (~(get by stream-arrivals.s) rid) `@da`0)
  :*  display-name.ss
      our
      started.ss
      emitted.ss
      total-size.ss
      container.ss
      last
  ==
::
::  +give-status-fact: broadcast snapshot to all /status subscribers.
::  Call at every site that mutates pending-streams (GET arm new
::  download, apply-one-chunk-into-stream, on-leave delete-stream).
::
++  give-status-fact
  |=  [s=state:burn our=ship]
  ^-  card
  [%give %fact ~[/status] %noun !>(`status-snapshot:burn`(build-status-snapshot s our))]
::
::  +give-redraw: canonical Hoon Native UI redraw notification card.
::  Append to any state-mutation site that changes the goad tree shape.
::  Body is a bare noun — per goon README the renderer just re-scries
::  /x/goon on receipt; payload content is irrelevant.
::
++  give-redraw
  ^-  card
  [%give %fact ~[/goon] %goon-redraw !>(~)]
::
::  +give-progress-fact: sibling to give-redraw — chunk traffic flows
::  here so /goon subscribers don't re-render every chunk arrival.
::
::  Payload carries enough for the live-strip 4-entity render in one shot
::  — the renderer doesn't need a separate scry per tick. Per-stream
::  STATIC fields (display-name, initiator, host, total, chunks,
::  chunk-size) repeat on every tick; the cost is negligible vs the
::  byte stream the fact tracks. CHANGING fields are emitted, received,
::  seq. chunks=total-chunks(total-size), or 0 if total is unknown.
::
++  media-art-url
  |=  art=(unit media-art:burn)
  ^-  @t
  ?~  art  ''
  url.u.art
::
++  media-art-width
  |=  art=(unit media-art:burn)
  ^-  @ud
  ?~  art  0
  width.u.art
::
++  media-art-height
  |=  art=(unit media-art:burn)
  ^-  @ud
  ?~  art  0
  height.u.art
::
++  media-context-node
  |=  path=media-path:burn
  ^-  (unit media-node-ref:burn)
  ?~  ancestors.path  ~
  `i.ancestors.path
::
++  join-labels
  |=  labels=(list @t)
  ^-  @t
  ?~  labels  ''
  ?~  t.labels  i.labels
  (crip "{(trip i.labels)} - {(trip $(labels t.labels))}")
::
++  media-breadcrumb
  |=  path=media-path:burn
  ^-  @t
  %-  join-labels
  %+  turn  ancestors.path
  |=  node=media-node-ref:burn
  label.node
::
++  give-progress-fact
  |=  [rid=@uv ss=stream-state:burn]
  ^-  card
  =/  chunks-total=@ud
    (total-chunks total-size.ss)
  =/  path=media-path:burn  media-path.ss
  =/  item-node=media-node-ref:burn  item.path
  =/  context-node=(unit media-node-ref:burn)  (media-context-node path)
  =/  context-art=(unit media-art:burn)
    ?~  context-node  ~
    art.u.context-node
  =/  context-label=@t
    ?~  context-node  ''
    label.u.context-node
  =/  payload
    :*  emitted=emitted.ss
        received=received.ss
        total=total-size.ss
        started=started.ss
        seq=seq.ss
        chunks=chunks-total
        chunk-size=chunk-size
        container=container.ss
        display-name=display-name.ss
        item-kind=kind.item-node
        item-label=label.item-node
        item-thumb-url=(media-art-url art.item-node)
        item-thumb-width=(media-art-width art.item-node)
        item-thumb-height=(media-art-height art.item-node)
        context-label=context-label
        context-thumb-url=(media-art-url context-art)
        context-thumb-width=(media-art-width context-art)
        context-thumb-height=(media-art-height context-art)
        initiator=initiator.ss
        host=host.ss
        breadcrumb=(media-breadcrumb path)
        item-index=index.item-node
    ==
  [%give %fact ~[/goon/progress/[(scot %uv rid)]] %noun !>(payload)]
::
::  +translate-stab-to-action: map a canonical Hoon UI stab to an
::  existing +$action. Returns ~ for unhandled paths/blades; on-poke
::  slogs and no-ops on ~. Settings/hosting edits read state to
::  preserve the unedited field of plex-config.
::
++  translate-stab-to-action
  |=  [=stab:goon s=state:burn]
  ^-  (unit action:burn)
  =*  blade  q.stab
  =/  =path  p.stab
  ?+  path  ~
      [%settings %hosting %url ~]
    ?.  ?=([%edit *] blade)  ~
    =/  new-url=@t  (iota-to-cord iota.blade)
    =/  cur-token=@t  ?~(hosting.s '' token.u.hosting.s)
    `[%set-host [new-url cur-token]]
  ::
      [%settings %hosting %token ~]
    ?.  ?=([%edit *] blade)  ~
    =/  new-token=@t  (iota-to-cord iota.blade)
    =/  cur-url=@t  ?~(hosting.s default-plex-url:burn url.u.hosting.s)
    `[%set-host [cur-url new-token]]
  ::
      [%settings %allowed @ ~]
    ::  Two shapes share this path:
    ::    /settings/allowed/<ship>  + %act %deny  → %deny ~[ship]
    ::    /settings/allowed/new     + %add iota   → %send-invitation ship
    ::  %send-invitation does the allowed-map upsert itself AND emits the
    ::  cross-ship %invitation-offer poke. Bare %allow stays available for
    ::  explicit no-notify pre-authorization from dojo.
    ::  ?+ matches first arm by shape, so they MUST be merged here —
    ::  splitting into two arms shadows the second.
    ?:  ?=([%add *] blade)
      =/  cord=@t  (iota-to-cord iota.blade)
      =/  ushp=(unit ship)  (slaw %p cord)
      ?~  ushp  ~
      `[%send-invitation u.ushp]
    ?.  ?=([%act %deny] blade)  ~
    =/  ushp=(unit ship)  (slaw %p i.t.t.path)
    ?~  ushp  ~
    `[%deny ~[u.ushp]]
  ::
      [%downloads @ ~]
    ?.  ?=([%act %cancel] blade)  ~
    =/  parsed=(unit @)  (slaw %uv i.t.path)
    ?~  parsed  ~
    `[%cancel-stream `@uv`u.parsed]
  ::
  ::  /downloads + %act %clear-streams → %clear-streams. Live-strip
  ::  "clear all" button on the host's own session. Auth gate at the
  ::  action handler rejects non-host src.bowl.
  ::
      [%downloads ~]
    ?.  ?=([%act %clear-streams] blade)  ~
    `[%clear-streams ~]
  ::
      [%settings %invitations @ ~]
    ?.  ?=([%act %accept] blade)  ~
    =/  parsed=(unit @)  (slaw %p i.t.t.path)
    ?~  parsed  ~
    `[%accept-invitation `ship`u.parsed]
  ::
  ::  /library/sections/<key>/items + %act %load
  ::  → %fetch-items. Public goon intent is "load"; internal action
  ::  stays Plex-specific.
  ::
      [%library %sections @ %items ~]
    ?.  ?=([%act %load] blade)  ~
    =/  section-key=@t  `@t`i.t.t.path
    `[%fetch-items section-key]
  ::
  ::  /library/sections/<key>/items/<rkey> + %act %load
  ::  → %fetch-show-children, %fetch-artist-children, or
  ::  %fetch-album-children depending on cached Plex item type.
  ::
      [%library %sections @ %items @ ~]
    ?.  ?=([%act %load] blade)  ~
    =/  rkey=@t  `@t`i.t.t.t.t.path
    =/  item-type=@t
      =/  srcs=(list [ship source-state:burn])  ~(tap by sources.s)
      |-
      ?~  srcs  ''
      =/  src-entry=source-state:burn  +.i.srcs
      =/  found=(unit library-item:burn)
        (find-library-item-by-rkey items.src-entry rkey)
      ?^  found  type.u.found
      $(srcs t.srcs)
    ?+  item-type  `[%fetch-show-children rkey]
      %'artist'  `[%fetch-artist-children rkey]
      %'album'   `[%fetch-album-children rkey]
      %'show'    `[%fetch-show-children rkey]
    ==
  ::
  ::  /library/sections/<key>/items/<artist-rkey>/albums/<album-rkey>
  ::  + %act %load → %fetch-album-children.
  ::
      [%library %sections @ %items @ %albums @ ~]
    ?.  ?=([%act %load] blade)  ~
    =/  album-rkey=@t  `@t`i.t.t.t.t.t.t.path
    `[%fetch-album-children album-rkey]
  ::
  ::  /library/sections/<key>/items/<rkey>/seasons/<srkey> + %act %load
  ::  → %fetch-season-children. Fires when the plex vine's seasons-as-
  ::  buttons UI POSTs a "load this season's episodes" request. The act
  ::  term is public goon intent; burn's internal action remains fetch-
  ::  season-children because that describes the Plex implementation.
  ::
      [%library %sections @ %items @ %seasons @ ~]
    ?.  ?=([%act %load] blade)  ~
    =/  season-rkey=@t  `@t`i.t.t.t.t.t.t.path
    `[%fetch-season-children season-rkey]
  ==
::
::  +iota-to-cord: extract a cord from an iota for %edit/%add payloads.
::  The vine sends user-typed strings as bare cords — the head case of
::  iota — but accept both forms.
::
++  iota-to-cord
  |=  =iota:goon
  ^-  @t
  ?@  iota  iota
  `@t`q.iota
::
::  +thumb-to-cache-url: thumb path + aspect kind → full Eyre cache key,
::  including the ?w=&h= query string the renderer emits on <img> src
::  (so prefetch and browser request use the same key). Returns ~ for
::  empty input.
::
++  thumb-to-cache-url
  |=  [thumb=@t kind=@tas]
  ^-  (unit @t)
  ?:  =('' thumb)  ~
  `(poster-url:burn-to-goad thumb kind)
::
::  +walk-thumbs: walk a source-state's items/seasons/episodes,
::  return every non-empty thumb URL in the same shape the renderer
::  emits (so cache-clear hits every key the browser ever asks for).
::  Item kind comes from type via +library-item-kind:burn-to-goad;
::  seasons are always %tall; episodes are always %wide.
::
++  walk-thumbs
  |=  src=source-state:burn
  ^-  (list @t)
  =/  item-urls=(list @t)
    %-  zing
    %+  turn  ~(tap by items.src)
    |=  [k=@t lst=(list library-item:burn)]
    %+  murn  lst
    |=  it=library-item:burn
    (thumb-to-cache-url thumb.it (library-item-kind:burn-to-goad type.it))
  =/  season-urls=(list @t)
    %-  zing
    %+  turn  ~(tap by seasons.src)
    |=  [k=@t lst=(list season-item:burn)]
    (murn lst |=(s=season-item:burn (thumb-to-cache-url thumb.s %tall)))
  =/  episode-urls=(list @t)
    %-  zing
    %+  turn  ~(tap by episodes.src)
    |=  [k=@t lst=(list episode-item:burn)]
    (murn lst |=(e=episode-item:burn (thumb-to-cache-url thumb.e %wide)))
  ;:  weld  item-urls  season-urls  episode-urls  ==
::
::  +reap-prefetch-pending: drop every %thumb-prefetch entry from
::  internal-pending. Shared by %clear-cache (intentional reset) and
::  +inflate-io (ghost-cleanup on reload).
::
++  reap-prefetch-pending
  |=  s=state:burn
  ^-  state:burn
  =.  internal-pending.s
    %-  malt
    %+  skip  ~(tap by internal-pending.s)
    |=  [rid=@uv =internal-fetch:burn]
    =(%thumb-prefetch tag.internal-fetch)
  s
::
::  +inflight-urls: the set of URLs currently in flight for thumbnail
::  prefetch. Derived from internal-pending entries tagged
::  %thumb-prefetch; no parallel state map required. Used by
::  +enqueue-thumb-urls for dedupe and by +dispatch-prefetches for
::  the "is anything already in flight?" guard.
::
++  inflight-urls
  |=  s=state:burn
  ^-  (set @t)
  %-  silt
  %+  murn  ~(tap by internal-pending.s)
  |=  [rid=@uv =internal-fetch:burn]
  ?.  =(%thumb-prefetch tag.internal-fetch)  ~
  `key.internal-fetch
::
::  +schedule-prefetch: pace cache warmup by asking Behn to wake the
::  dispatcher after a short delay. Keeps the queue serial while avoiding
::  immediate response->request churn across Ames and Eyre cache writes.
::
++  schedule-prefetch
  |=  [s=state:burn now=@da]
  ^-  (list card)
  ?:  ?|(=(~ thumb-queue.s) !=(0 ~(wyt in (inflight-urls s))))  ~
  ?:  (gth ~(wyt by pending-streams.s) 0)
    :~  [%pass /thumb-prefetch %arvo %b %wait (add now thumb-prefetch-download-delay)]
    ==
  :~  [%pass /thumb-prefetch %arvo %b %wait (add now thumb-prefetch-delay)]
  ==
::
::  +enqueue-thumb-urls: dedupe candidate URLs against thumb-queue +
::  any URL already in flight; weld the surviving fresh URLs onto the
::  queue. Returns the fresh list + updated state.
::
++  enqueue-thumb-urls
  |=  [s=state:burn candidates=(list @t)]
  ^-  [(list @t) state:burn]
  =/  q-set=(set @t)  (silt thumb-queue.s)
  =/  in-flight=(set @t)  (inflight-urls s)
  =/  fresh=(list @t)
    %+  skim  candidates
    |=  u=@t
    ?&  !=('' u)
        !(~(has in q-set) u)
        !(~(has in in-flight) u)
    ==
  =.  thumb-queue.s  (weld thumb-queue.s fresh)
  [fresh s]
::
::  +dispatch-prefetches: fire ONE thumbnail prefetch if (a) nothing
::  is currently in flight and (b) the queue is non-empty. Serial
::  dispatch — Plex localhost RTT (~50-200ms) is the throughput floor,
::  much faster than the prior behn-paced 1/sec. HOST path: Iris GET.
::  SUBSCRIBER path: proxy-poke to first source ship over Ames.
::
++  dispatch-prefetches
  |=  [s=state:burn =bowl:gall]
  ^-  [(list card) state:burn]
  ?.  =(0 ~(wyt in (inflight-urls s)))  [~ s]
  ?:  =(0 (lent thumb-queue.s))  [~ s]
  ?:  (gth ~(wyt by pending-streams.s) 0)
    :_  s
    :~  [%pass /thumb-prefetch %arvo %b %wait (add now.bowl thumb-prefetch-download-delay)]
    ==
  ::  Hoist invariants out of the URL-drop loop.
  =/  hosting-cfg=(unit plex-config:burn)  hosting.s
  =/  src-list=(list [ship source-state:burn])  ~(tap by sources.s)
  |-  ^-  [(list card) state:burn]
  =/  url=@t  (snag 0 thumb-queue.s)
  =.  thumb-queue.s  (slag 1 thumb-queue.s)
  ?^  hosting-cfg
    ?:  =('' token.u.hosting-cfg)  $
    =/  plex-path=@t
      =/  ut=tape  (trip url)
      =/  pfx=tape  "/apps/burn"
      ?:  =((scag (lent pfx) ut) pfx)
        (crip (slag (lent pfx) ut))
      url
    =/  tc-url=@t  (thumb-transcode-url plex-path token.u.hosting-cfg)
    =/  proxy-url=@t  (cat 3 url.u.hosting-cfg tc-url)
    =/  req=request:http  [%'GET' proxy-url ~ ~]
    =/  rid=@uv  (sham (jam [url now.bowl eny.bowl]))
    =.  internal-pending.s
      (~(put by internal-pending.s) rid [%thumb-prefetch url now.bowl])
    :_  s
    :~  [%pass /host-thumb-prefetch/(scot %uv rid) %arvo %i %request req *outbound-config:iris]
    ==
  ?:  =(0 (lent src-list))  $
  =/  [host-ship=ship =source-state:burn]  (snag 0 src-list)
  =/  rid=@uv  (sham (jam [url now.bowl eny.bowl]))
  =.  internal-pending.s
    (~(put by internal-pending.s) rid [%thumb-prefetch url now.bowl])
  :_  s
  :~  %-  proxy-poke
      :*  host-ship  rid  control-flow
          %proxy-request  host-ship  rid  %'GET'  url  ~  ~  control-flow
      ==
  ==
::
::  +derive-all-cached-urls: walk every source's items/seasons/episodes,
::  build the same /apps/burn{thumb} URLs that the cache-set sites wrote.
::  Mirror of the enqueue construction at line 676. Used by %clear-cache
::  to enumerate eviction targets without tracking a written-urls set.
::
++  derive-all-cached-urls
  |=  s=state:burn
  ^-  (list @t)
  %-  zing
  %+  turn  ~(tap by sources.s)
  |=  [host-ship=ship src=source-state:burn]
  (walk-thumbs src)
::
::  +metadata-fetch-in-flight: true if any non-thumbnail internal metadata
::  request is outstanding. Thumbnail prefetch is already serial and paced;
::  it should not block metadata warmup.
::
++  metadata-fetch-in-flight
  |=  s=state:burn
  ^-  ?
  =/  entries=(list [@uv internal-fetch:burn])  ~(tap by internal-pending.s)
  |-
  ?~  entries  %.n
  =/  ifetch=internal-fetch:burn  +.i.entries
  ?:  =(%thumb-prefetch tag.ifetch)
    $(entries t.entries)
  %.y
::
::  +next-warmup-action: choose one missing metadata edge from the generic
::  media tree. Plex stores TV and music in concrete maps, but the warmup
::  policy is the same for both: root collection, parent container, child
::  items. One action per pass keeps parser and thumbnail cache pressure low.
::
++  next-warmup-action
  |=  src=source-state:burn
  ^-  (unit action:burn)
  ?:  =(~ sections.src)
    `[%fetch-sections ~]
  ::  Fetch section item lists first.
  =/  missing-section=(unit @t)
    =/  secs=(list library-section:burn)  sections.src
    |-
    ?~  secs  ~
    ?:  (~(has by items.src) key.i.secs)
      $(secs t.secs)
    `key.i.secs
  ?^  missing-section
    `[%fetch-items u.missing-section]
  ::  Fetch show seasons and artist albums.
  =/  root-action=(unit action:burn)
    =/  item-pairs=(list [@t (list library-item:burn)])  ~(tap by items.src)
    |-
    ?~  item-pairs  ~
    =/  item-list=(list library-item:burn)  +.i.item-pairs
    =/  found=(unit action:burn)
      |-
      ?~  item-list  ~
      =/  li=library-item:burn  i.item-list
      ?.  ?|  =('show' type.li)
              =('artist' type.li)
          ==
        $(item-list t.item-list)
      ?:  (~(has by seasons.src) rating-key.li)
        $(item-list t.item-list)
      ?:  =('artist' type.li)
        `[%fetch-artist-children rating-key.li]
      `[%fetch-show-children rating-key.li]
    ?~  found
      $(item-pairs t.item-pairs)
    found
  ?^  root-action
    root-action
  ::  Fetch season episodes and album tracks.
  =/  child-action=(unit action:burn)
    =/  season-pairs=(list [@t (list season-item:burn)])  ~(tap by seasons.src)
    |-
    ?~  season-pairs  ~
    =/  root-rkey=@t  -.i.season-pairs
    =/  maybe-root=(unit library-item:burn)
      (find-library-item-by-rkey items.src root-rkey)
    =/  is-music=?
      ?~  maybe-root  %.n
      =('artist' type.u.maybe-root)
    =/  season-list=(list season-item:burn)  +.i.season-pairs
    =/  found=(unit action:burn)
      |-
      ?~  season-list  ~
      =/  si=season-item:burn  i.season-list
      ?:  (~(has by episodes.src) rating-key.si)
        $(season-list t.season-list)
      ?:  is-music
        `[%fetch-album-children rating-key.si]
      `[%fetch-season-children rating-key.si]
    ?~  found
      $(season-pairs t.season-pairs)
    found
  child-action
::
::  +eager-library-fetches: idempotent metadata warmup. Emits at most one
::  existing %fetch-* self-poke per pass; response handlers call this again
::  after storing each level, so the tree fills in gradually without a large
::  parser burst.
::
++  eager-library-fetches
  |=  [s=state:burn host-ship=ship our=ship]
  ^-  (list card)
  =/  src=source-state:burn  (get-source s host-ship)
  =/  poke-self
    |=  =action:burn
    ^-  card
    [%pass /goon-eager %agent [our %burn] %poke %burn-action !>(action)]
  ::  Skip the no-op self-poke when neither publisher nor subscriber path
  ::  can fetch.
  =/  publisher-can-fetch=?
    ?&(?=(^ hosting.s) !=('' token.u.hosting.s))
  =/  subscriber-can-fetch=?
    !=(~ (~(del by sources.s) our))
  ?.  ?|(publisher-can-fetch subscriber-can-fetch)
    ~
  ?:  (gth ~(wyt by pending-streams.s) 0)
    ~
  ?:  (metadata-fetch-in-flight s)
    ~
  =/  next=(unit action:burn)  (next-warmup-action src)
  ?~  next  ~
  ~[(poke-self u.next)]
::
::  +pick-idle-flow: lowest-numbered idle flow-id in [0, cap). Caller
::  passes cap (≤ max-flows) so wave-1 dispatch can start with fewer
::  flows and ramp once first arrivals land — see dispatch-flows.
::  Returns ~ if all flows in [0, cap) are %in-flight. Lowest-first
::  means slot reuse is deterministic, which keeps slog tracing readable.
::
++  pick-idle-flow
  |=  [flows=(map @ud flow-state:burn) cap=@ud]
  ^-  (unit @ud)
  =/  i=@ud  0
  |-
  ?:  =(i cap)  ~
  =/  fs=(unit flow-state:burn)  (~(get by flows) i)
  ?~  fs  `i                                                  ::  unallocated = idle
  ?:  ?=(%idle status.u.fs)  `i
  $(i +(i))
::
::  +free-flow: find the flow currently assigned to chunk-seq and mark
::  it %idle. Used by on-poke %proxy-chunk after a chunk arrives — the
::  flow that fetched it is now available to take a new assignment.
::
++  free-flow
  |=  [flows=(map @ud flow-state:burn) chunk-seq=@ud]
  ^-  (map @ud flow-state:burn)
  =/  entries=(list [@ud flow-state:burn])  ~(tap by flows)
  =/  matched=(unit @ud)
    |-
    ?~  entries  ~
    ?:  ?&  ?=(%in-flight status.+.i.entries)
            =(seq.+.i.entries chunk-seq)
        ==
      `-.i.entries
    $(entries t.entries)
  ?~  matched  flows
  (~(put by flows) u.matched [%idle 0])
::
::  +next-unassigned-seq: highest seq currently in-flight (+1), or 0 if
::  no flow is in-flight. Used as the cursor for dispatch-flows.
::
++  next-unassigned-seq
  |=  flows=(map @ud flow-state:burn)
  ^-  @ud
  %-  ~(rep by flows)
  |=  [[fid=@ud fs=flow-state:burn] acc=@ud]
  ?:  ?=(%in-flight status.fs)
    (max acc +(seq.fs))
  acc
::
::  +dispatch-flows: greedy assignment of unassigned chunks to idle
::  flows for a single rid. Returns updated stream-state (flows mutated)
::  and a list of pokes (one per newly-assigned flow). Stops when:
::    (a) no idle flow remains
::    (b) next-unassigned-seq has reached total-chunks (computed from
::        total-size — once the cursor passes the last chunk, no more
::        Range requests should issue: see request-next-chunk EOF gate)
::    (c) final-seq is populated and next-unassigned-seq exceeds it
::
::  Cursor is derived live from `flows` (max in-flight seq + 1, falling
::  back to seq.ss). flows is the source of truth for "what's in flight",
::  so we never store a separate counter that could drift.
::
++  dispatch-flows
  |=  $:  rid=@uv
          ss=stream-state:burn
          fseq=(unit @ud)                                     ::  final-seq[rid] if known
          parked=(map @ud octs)                               ::  Bug A: reassembly[rid] — chunks already received but not yet emitted
          now=@da
      ==
  ^-  [(list card) stream-state:burn]
  =/  total-chunks-here=@ud  (total-chunks total-size.ss)
  ::  Bug A fix: out-of-order final-chunk arrival used to trigger a
  ::  re-fetch — the just-delivered chunk had been parked in reassembly
  ::  and free-flow had marked its slot %idle, so the next dispatch
  ::  computed cursor=N (= u.fseq), the `gth cursor u.fseq` termination
  ::  check returned %.n, and the idle slot was reassigned to seq=N.
  ::  Including the parked map's max key in the cursor floor makes
  ::  reassembled chunks count as "already in play" alongside in-flight
  ::  flows, so the cursor advances past final-seq and termination fires.
  =/  parked-floor=@ud
    ?:  =(0 ~(wyt by parked))  0
    =/  highest=@ud
      %-  ~(rep by parked)
      |=  [[k=@ud v=octs] acc=@ud]
      (max acc k)
    +(highest)
  ::  B1: cap concurrent flows at 2 during wave 1, ramp to max-flows once
  ::  any subsequent chunk has applied. Reduces wave-1 reassembly pile-up
  ::  while letting natural flow-speed ranking establish.
  =/  wave-cap=@ud
    ?:  (lte seq.ss 1)  2
    max-flows
  =|  cards=(list card)
  =/  cur-ss=stream-state:burn  ss
  |-
  =/  idle=(unit @ud)  (pick-idle-flow flows.cur-ss wave-cap)
  ?~  idle  [cards cur-ss]
  =/  cursor=@ud  (next-unassigned-seq flows.cur-ss)
  =.  cursor  (max cursor seq.cur-ss)
  =.  cursor  (max cursor parked-floor)
  ::  Termination: total-chunks known and we've assigned them all
  ?:  &(!=(0 total-chunks-here) (gte cursor total-chunks-here))
    [cards cur-ss]
  ::  Termination: final-seq latched and we've assigned past it
  ?:  ?&  ?=(^ fseq)
          (gth cursor u.fseq)
      ==
    [cards cur-ss]
  ::  Assign idle flow to cursor
  =/  new-fs=flow-state:burn  [%in-flight cursor]
  =.  flows.cur-ss  (~(put by flows.cur-ss) u.idle new-fs)
  =/  poke-cards=(list card)
    (request-next-chunk rid host.cur-ss url.cur-ss cursor total-size.cur-ss u.idle)
  ::  request-next-chunk SUPPRESSED returns ~ when start>=total. If that
  ::  fires we should NOT keep the flow in-flight (it never sent a poke).
  ?~  poke-cards
    =.  flows.cur-ss  (~(put by flows.cur-ss) u.idle [%idle 0])
    [cards cur-ss]
  =.  cards  (weld cards poke-cards)
  $
::
::  +apply-one-chunk-into-stream: process one IN-ORDER chunk through the
::  octs-buffer + trickle pipeline. Returns updated state and cards.
::  Headers/status are processed only when this is the live first chunk
::  (seq=0 carries deferred-header + Content-Range + container detection);
::  drained chunks always have seq>=1 (chunk 0 is never parked because it
::  always arrives in-order — flows>=1 are not dispatched until chunk 0
::  returns) so passing chunk-headers=~ chunk-status=0 is harmless for
::  drained chunks.
::
::  Body is the in-order chunk-application logic factored out of the
::  original on-poke %proxy-chunk subsequent-chunk branch (lines ~865-1003
::  pre-L3) so it can be invoked from BOTH the live in-order arrival
::  path AND the reassembly drain loop.
::
++  apply-one-chunk-into-stream
  |=  $:  s=state:burn
          st=stream-state:burn
          rid=@uv
          chunk-seq=@ud
          chunk-data=octs
          chunk-has-more=?
          chunk-status=@ud
          chunk-headers=header-list:http
          now=@da
      ==
  ^-  [(list card) state:burn]
  =/  eid=@ta  eyre-id.st
  =/  short-rid=@t  (short-id-uv rid)
  =/  captured-total=@ud
    ?:  =(0 total-size.st)
      (extract-total-from-headers chunk-headers)
    total-size.st
  =/  captured-container=@tas
    ?:  ?&  !sent-header.st
            =(%$ container.st)
        ==
      =/  from-bytes=@tas  (container-from-bytes chunk-data)
      ?:  !=(%$ from-bytes)
        from-bytes
      (container-from-headers chunk-headers)
    container.st
  =/  m=@ud  (total-chunks captured-total)
  =/  chunk-start=@ud  (chunk-start-for-seq chunk-seq)
  =/  trim-prefix=@ud
    ?:  ?&  !sent-header.st
            (gth start-byte.st chunk-start)
            (lth start-byte.st (add chunk-start p.chunk-data))
        ==
      (sub start-byte.st chunk-start)
    0
  =/  emit-data=octs
    ?:  =(0 trim-prefix)
      chunk-data
    =/  emit-len=@ud  (sub p.chunk-data trim-prefix)
    [emit-len (rsh [3 trim-prefix] q.chunk-data)]
  ~?  (gth trim-prefix 0)
    "burn: RESUME TRIM rid={<short-rid>} chunk {<+(chunk-seq)>}/{<m>} start-byte={<start-byte.st>} chunk-start={<chunk-start>} drop={<trim-prefix>} emit={<p.emit-data>}b"
  ~&  >  "burn: APPLY rid={<short-rid>} chunk {<+(chunk-seq)>}/{<m>} bytes={<p.emit-data>} raw={<p.chunk-data>} total={<captured-total>}b more={<chunk-has-more>}"
  ::  First-emitted-chunk download summary: one slog per stream surfacing
  ::  container, total size, and total chunk count. On resume this may be
  ::  a non-zero chunk containing start-byte.st.
  ~?  &(!sent-header.st (gth captured-total 0))
    "burn: download starting rid={<short-rid>} name={<display-name.st>} container={<captured-container>} size={<captured-total>}b chunks={<m>}"
  ~?  &(!sent-header.st =(0 captured-total))
    "burn: download starting rid={<short-rid>} name={<display-name.st>} container={<captured-container>} size=? chunks=?"
  ::  Deferred-header substitution. For normal downloads this fires on
  ::  chunk 0; for resumed downloads it fires on the first aligned chunk
  ::  that contains start-byte.st.
  =/  deferred=(unit [eyre-id=@ta dl-rh=response-header:http])
    (~(get by deferred-headers.s) rid)
  =/  header-cards=(list card)
    ?~  deferred  ~
    =/  total-z=(unit @ud)  (extract-cr-total chunk-headers)
    =/  rh-with-total=response-header:http
      ?~  total-z  dl-rh.u.deferred
      (substitute-cr-span dl-rh.u.deferred start-byte.st u.total-z)
    =/  effective-rh=response-header:http
      (rebuild-content-disposition rh-with-total display-name.st captured-container)
    ~&  >>>  "burn: EYRE HEADER rid={<short-rid>} eyre-id={<(short-id-ta eid)>} src=deferred-header status={<status-code.effective-rh>} start-data=~ complete=%.n"
    ~[[%give %fact ~[/http-response/[eid]] %http-response-header !>(effective-rh)]]
  =?  deferred-headers.s  ?=(^ deferred)
    (~(del by deferred-headers.s) rid)
  =/  existing=(unit buffered-chunk:burn)
    (~(get by octs-buffer.s) rid)
  ::  Empty-body guard: never emit zero-byte octs (Vere SIGSEGV).
  ?:  =(0 p.emit-data)
    ?:  chunk-has-more
      ~&  >>>  "burn: empty mid-stream chunk rid={<short-rid>} — ignored"
      [header-cards s]
    ::  Empty final chunk — if existing buffer has bytes, mark final and
    ::  let trickle drain + kick. Otherwise close immediately.
    ?~  existing
      ::  Let subscribers complete the bar before delete-stream kicks.
      =/  final-progress=card
        (give-progress-fact rid st(total-size captured-total))
      =.  s  (delete-stream s rid)
      =.  pending.s  (~(del by pending.s) (scot %uv rid))
      ~&  >>>  "burn: EYRE KICK rid={<short-rid>} eyre-id={<(short-id-ta eid)>} src=empty-final-no-buffer data=~ complete=cancel"
      =/  kick-card=card  [%give %kick ~[/http-response/[eid]] ~]
      [(weld header-cards `(list card)`~[final-progress give-redraw kick-card]) s]
    ~&  >  "burn: empty final, existing buffer remains rid={<short-rid>} — mark final (chain in flight)"
    =.  octs-buffer.s
      (~(put by octs-buffer.s) rid u.existing(final %.y))
    [header-cards s]
  ::  Append: combined-bytes = remainder of prior (if any) + new chunk.
  =/  combined=octs
    ?~  existing  `octs`emit-data
    =/  remaining=@ud  (sub p.bytes.u.existing cursor.u.existing)
    ?:  =(0 remaining)  `octs`emit-data
    =/  prior-rest=octs
      [remaining (rsh [3 cursor.u.existing] q.bytes.u.existing)]
    [(add p.prior-rest p.emit-data) (can 3 ~[[p.prior-rest q.prior-rest] [p.emit-data q.emit-data]])]
  ~&  >  "burn: APPEND rid={<short-rid>} chunk {<+(chunk-seq)>}/{<m>} buffer now {<p.combined>}b (was {<?~(existing 0 (sub p.bytes.u.existing cursor.u.existing))>}b, +{<p.emit-data>}b new)"
  =/  fresh-bc=buffered-chunk:burn
    [combined 0 !chunk-has-more]
  =/  immediate-slice=@ud
    ?:  (gth p.combined max-reserve)
      (sub p.combined max-reserve)
    ?~  existing
      (slice-for p.combined target-runway)
    0
  =^  first-slice=octs  fresh-bc
    (peel-slice fresh-bc immediate-slice)
  =.  octs-buffer.s
    (~(put by octs-buffer.s) rid fresh-bc)
  =/  post-ss=stream-state:burn
    %_  st
      received     (add received.st p.emit-data)
      emitted      (add emitted.st p.first-slice)
      seq          +(seq.st)
      sent-header  %.y
      total-size   captured-total
      container    captured-container
    ==
  =.  pending-streams.s
    (~(put by pending-streams.s) rid post-ss)
  =.  stream-arrivals.s
    (~(put by stream-arrivals.s) rid now)
  =/  first-slice-card=(list card)
    ?:  =(0 p.first-slice)
      ~
    ~&  >  "burn: first-slice rid={<short-rid>} buffer={<p.combined>}b max={<max-reserve>}b -> emit {<p.first-slice>}b emitted={<emitted.st>}->{<emitted.post-ss>} rem={<(sub p.bytes.fresh-bc cursor.fresh-bc)>}b"
    ~[[%give %fact ~[/http-response/[eid]] %http-response-data !>(`(unit octs)`(some first-slice))]]
  ::  Schedule trickle ONLY if octs-buffer was empty before this chunk
  ::  arrived. Gate on prior-buffer-empty so behn same-wire %wait cards
  ::  don't multiplex (feedback_behn_same_wire_stacks).
  =/  trickle-cards=(list card)
    ?~  existing  ~[(schedule-trickle rid now)]
    ~
  =/  progress-card=(list card)
    ~[(give-progress-fact rid post-ss)]
  :_  s
  ;:  weld
    header-cards
    first-slice-card
    trickle-cards
    progress-card
  ==
::
::  +drain-reassembly-loop: pop in-order chunks from reassembly[rid] and
::  apply each through apply-one-chunk-into-stream. Stops when the
::  reassembly map has no entry for the current next-emit-seq.
::
::  Drained chunks have empty headers/status (seq>=1 invariant — chunk 0
::  is never parked because it always arrives before any flow-id>0 fires).
::
++  drain-reassembly-loop
  |=  $:  s=state:burn
          rid=@uv
          now=@da
      ==
  ^-  [(list card) state:burn]
  =|  cards=(list card)
  |-
  ::  Re-read stream-state and reassembly[rid] each iteration: apply may
  ::  delete-stream (empty-final-chunk path) and we must respect that;
  ::  reassembly[rid] is mutated each pop. Two lookups per drained chunk
  ::  is acceptable — drains are bounded by max-flows.
  =/  st-u=(unit stream-state:burn)  (~(get by pending-streams.s) rid)
  ?~  st-u  [cards s]
  =/  rmap=(map @ud octs)  (fall (~(get by reassembly.s) rid) ~)
  =/  next=(unit octs)  (~(get by rmap) seq.u.st-u)
  ?~  next  [cards s]
  =.  rmap  (~(del by rmap) seq.u.st-u)
  =.  reassembly.s
    ?:  =(~ rmap)  (~(del by reassembly.s) rid)
    (~(put by reassembly.s) rid rmap)
  ::  Parked chunk's has-more derived from final-seq[rid]: this chunk is
  ::  final iff its seq matches the latched final-seq.
  =/  fseq=(unit @ud)  (~(get by final-seq.s) rid)
  =/  is-final=?  ?&(?=(^ fseq) =(seq.u.st-u u.fseq))
  =^  one-cards  s
    (apply-one-chunk-into-stream s u.st-u rid seq.u.st-u u.next !is-final 0 ~ now)
  =.  cards  (weld cards one-cards)
  $
::
::  +peel-slice: extract next slice of `len` bytes from buffered-chunk.
::  Returns [slice updated-buffer]. Slice length is min(len, remaining);
::  callers must guard on drained state (cursor >= p.bytes) to avoid
::  emitting zero-byte octs (Vere _http_hgen_send SIGSEGV trigger).
::
++  peel-slice
  |=  [bc=buffered-chunk:burn len=@ud]
  ^-  [octs buffered-chunk:burn]
  =/  take=@ud  (min len (sub p.bytes.bc cursor.bc))
  =/  slice=octs  [take (cut 3 [cursor.bc take] q.bytes.bc)]
  [slice bc(cursor (add cursor.bc take))]
::
::  +short-tail: last 5 chars of a tape, or the whole tape if shorter.
::  Shared body of short-id-uv + short-id-ta.
::
++  short-tail
  |=  full=tape
  ^-  @t
  =/  len=@ud  (lent full)
  ?:  (lte len 5)  (crip full)
  (crip (slag (sub len 5) full))
::
::  +short-id-uv: truncate @uv rid to last 5 chars for slog readability.
::  Full @uv printout (e.g. 0v7.leknb.ub7nf.jojil.po7uj.g27j5) overwhelms
::  log-scanning when many sites print it across one download. Collisions
::  on last 5 chars are vanishingly rare in practice.
::
++  short-id-uv
  |=  id=@uv
  ^-  @t
  (short-tail (trip (scot %uv id)))
::
::  +short-id-ta: truncate @ta eyre-id to last 5 chars for slog readability.
::  Full eyre-id (e.g. ~.~.eyre_0v2.0ds4b.0peaj.2lv4k.3gq0v.l77no) is too
::  long to scan; last 5 chars suffice as a session-local identifier.
::
++  short-id-ta
  |=  id=@ta
  ^-  @t
  (short-tail (trip id))
::
::  +total-chunks: ceiling chunk count for a download of `total` bytes,
::  accounting for the variable first chunk (first-chunk-size at seq=0,
::  chunk-size at seq>=1). Returns 0 when total=0 (chunked transfer-
::  encoding from host, no Content-Length). Callers tolerate `chunk N/0`
::  in slogs until captured-total fires on first-chunk arrival.
::
++  total-chunks
  |=  total=@ud
  ^-  @ud
  ?:  =(0 total)  0
  ?:  (lte total first-chunk-size)  1
  =/  rest=@ud  (sub total first-chunk-size)
  =/  full=@ud  (div rest chunk-size)
  =/  rem=@ud  (mod rest chunk-size)
  ?:  =(0 rem)  +(full)
  +(+(full))
::
::  +chunk-seq-for-byte: map a file byte offset to the internal chunk seq
::  that contains it. Mirrors request-next-chunk's variable first-chunk
::  layout: seq 0 is [0, first-chunk-size), seq N>=1 starts after that.
::
++  chunk-seq-for-byte
  |=  byte=@ud
  ^-  @ud
  ?:  (lth byte first-chunk-size)  0
  +((div (sub byte first-chunk-size) chunk-size))
::
::  +chunk-start-for-seq: inverse of chunk-seq-for-byte for aligned host
::  Range fetches. Browser resume may request a non-aligned byte; we fetch
::  the containing aligned chunk from Plex and trim the prefix before
::  emitting to Eyre.
::
++  chunk-start-for-seq
  |=  seq=@ud
  ^-  @ud
  ?:  =(0 seq)  0
  (add first-chunk-size (mul (sub seq 1) chunk-size))
::
::  +request-next-chunk: subscriber sends next Range proxy-request.
::  state correctness gate: if total-size is known (non-zero) and the
::  next chunk's start byte is already at or past total, return empty
::  list — DO NOT issue the Range request. This is what prevents the
::  416 + HTML body write-through bug observed in download-31, where
::  the agent kept requesting Range bytes past EOF and Plex's HTML
::  error response got streamed into the file as if it were chunk data.
::
++  request-next-chunk
  |=  [rid=@uv host=ship url=@t next-seq=@ud total-size=@ud flow-id=@ud]
  ^-  (list card)
  ::  Variable first-chunk: seq 0 starts at byte 0; seq N≥1 starts at
  ::  first-chunk-size + (N-1)*chunk-size. Inverse of chunk-seq-for-byte.
  =/  start=@ud  (chunk-start-for-seq next-seq)
  ::  state: refuse Range requests past EOF when total is known.
  ?:  &(!=(0 total-size) (gte start total-size))
    ~&  >  "burn: request-next-chunk SUPPRESSED rid={<(short-id-uv rid)>} flow={<flow-id>} start={<start>} total={<total-size>} (would 416)"
    ~
  =/  end=@ud
    ?:  =(0 next-seq)  (sub first-chunk-size 1)
    (sub (add start chunk-size) 1)
  =/  range-val=@t
    (crip "{(a-co:co start)}-{(a-co:co end)}")
  =/  range-hdr=[@t @t]  ['range' (cat 3 'bytes=' range-val)]
  ~&  >  "burn: dispatch rid={<(short-id-uv rid)>} flow={<flow-id>} seq={<next-seq>}"
  :~  %-  proxy-poke
      :*  host
          rid
          flow-id
          %proxy-request
          host
          rid
          %'GET'
          url
          ~[range-hdr]
          ~
          flow-id
      ==
  ==
::
::  +proxy-poke: build a poke card for proxy communication
::  L3 parallel-chunks: wire includes flow-id so Ames allocates a distinct
::  bone per (ship, rid, flow-id) triple — each bone has its own cwnd.
::
++  proxy-poke
  |=  [=ship rid=@uv flow-id=@ud act=action:burn]
  ^-  card
  [%pass /proxy-out/(scot %p ship)/(scot %uv rid)/(scot %ud flow-id) %agent [ship %burn] %poke %burn-action !>(act)]
::
::  +do-subscribe: subscribe to a remote host's plex
::
++  do-subscribe
  |=  [=ship]
  ^-  [(list card) (map ^ship source-state:burn)]
  =/  src=source-state:burn  [ship %pending ~ ~ ~ ~]
  =/  cards=(list card)
    :~  [%pass /epic/(scot %p ship) %agent [ship %burn] %watch /burn/epic]
    ==
  =?  cards  (~(has by sources.state) ship)
    :*  [%pass /epic/(scot %p ship) %agent [ship %burn] %leave ~]
        cards
    ==
  [cards (~(put by sources.state) ship src)]
::
::  +rewrite-headers: inject Plex auth token, clean headers
::
++  rewrite-headers
  |=  [headers=header-list:http fallback-token=@t]
  ^-  header-list:http
  =/  browser-token=@t
    =/  found=@t  ''
    |-
    ?~  headers  found
    ?:  =('x-plex-token' (crip (cass (trip key:(head headers)))))
      value:(head headers)
    $(headers +.headers)
  =/  tok=@t  ?:((gth (met 3 browser-token) 0) browser-token fallback-token)
  ::  Add token header, strip hop-by-hop
  =/  cleaned=header-list:http
    %+  skip  headers
    |=  [k=@t v=@t]
    =/  lk  (crip (cass (trip k)))
    ?|  =(lk 'host')
        =(lk 'connection')
        =(lk 'keep-alive')
        =(lk 'transfer-encoding')
    ==
  [['x-plex-token' tok] cleaned]
::
::  +find-attr: find attribute value by name in a manx attribute list
::
++  find-attr
  |=  [name=@tas attrs=mart]
  ^-  @t
  ?~  attrs  ''
  ?:  =(name n.i.attrs)  (crip v.i.attrs)
  $(attrs t.attrs)
::
::  +cap-text: source-side cap on parsed text fields. Plex summaries can
::  exceed 4KB; left unchecked they bloat the SSE goad payload and morph
::  cost. CSS clamps the display but doesn't reduce transport. Cap at
::  1000 bytes at parse time, then CSS handles visual truncation.
::
++  cap-text
  |=  raw=@t
  ^-  @t
  (crip (scag 1.000 (trip raw)))
::
::  +collect-genre: top-2 Plex Genre children joined with ' · '. Plex
::  emits <Genre tag="Drama"/> child elements; first two by document
::  order are usually the canonical ones. Empty cord if no Genre kids.
::
++  collect-genre
  |=  kids=(list manx)
  ^-  @t
  =/  tags=(list @t)
    %+  murn  kids
    |=  =manx
    ^-  (unit @t)
    ?.  =('Genre' n.g.manx)  ~
    =/  tag=@t  (find-attr 'tag' a.g.manx)
    ?:  =('' tag)  ~
    `tag
  =/  top  (scag 2 tags)
  ?~  top  ''
  ?~  t.top  i.top
  (rap 3 i.top ' · ' i.t.top ~)
::
::  +get-header-ci: case-insensitive header lookup
::  get-header:http compares keys verbatim; HTTP/1.1 spec is case-insensitive.
::
++  get-header-ci
  |=  [k=@t hdrs=header-list:http]
  ^-  (unit @t)
  =/  lk=@t  (crip (cass (trip k)))
  |-
  ?~  hdrs  ~
  ?:  =(lk (crip (cass (trip key.i.hdrs))))
    `value.i.hdrs
  $(hdrs t.hdrs)
::
::  +parse-range: crash-safe Range header parser
::  Returns ~ if Range absent, malformed, or unparseable.
::  Returns [start end] otherwise; end=~ for open-ended bytes=N-
::
++  parse-range
  |=  headers=header-list:http
  ^-  (unit [start=@ud end=(unit @ud)])
  =/  raw=(unit @t)  (get-header-ci 'range' headers)
  ?~  raw  ~
  =/  val=tape  (trip u.raw)
  =/  eq-pos=(unit @ud)  (find "=" val)
  ?~  eq-pos  ~
  =/  after=tape  (slag +(u.eq-pos) val)
  =/  dash-pos=(unit @ud)  (find "-" after)
  ?~  dash-pos  ~
  =/  start-tape=tape  (scag u.dash-pos after)
  =/  end-tape=tape  (slag +(u.dash-pos) after)
  =/  start-u=(unit @ud)  (rush (crip start-tape) dem)
  ?~  start-u  ~
  =/  end-u=(unit @ud)  (rush (crip end-tape) dem)
  `[u.start-u end-u]
::
::  +extract-seq-from-range: chunk sequence from Range header
::
++  extract-seq-from-range
  |=  headers=header-list:http
  ^-  @ud
  =/  r  (parse-range headers)
  ?~  r  0
  ::  Browser resume requests may start inside an internal chunk. Return
  ::  the containing aligned seq; the subscriber trims the already-owned
  ::  prefix before emitting to Eyre.
  (chunk-seq-for-byte start.u.r)
::
::  +extract-cr-total: pull total Z from a Content-Range header value.
::  Plex returns 'bytes A-B/Z' on 206 responses; we want Z so we can
::  forward the real total to the browser. Returns ~ if header absent,
::  malformed, or total is the asterisk literal.
::
++  extract-cr-total
  |=  hdrs=header-list:http
  ^-  (unit @ud)
  =/  cr=(unit @t)  (get-header-ci 'content-range' hdrs)
  ?~  cr  ~
  =/  val=tape  (trip u.cr)
  =/  slash-pos=(unit @ud)  (find "/" val)
  ?~  slash-pos  ~
  =/  z-tape=tape  (slag +(u.slash-pos) val)
  ?:  =(z-tape "*")  ~
  (rush (crip z-tape) dem)
::
::  +extract-cr-end: pull end byte B from a Content-Range header value.
::  Plex returns 'bytes A-B/Z' on 206 responses; B is the last byte
::  position (0-indexed, inclusive). Used with extract-cr-total to
::  detect the final chunk: cumulative position B+1 == Z means we just
::  shipped the last byte and must force has-more=%.n. Without this,
::  Plex's persistent 206 status keeps the subscriber in slow drain.
::  Returns ~ if header absent, malformed, or end position unparseable.
::
++  extract-cr-end
  |=  hdrs=header-list:http
  ^-  (unit @ud)
  =/  cr=(unit @t)  (get-header-ci 'content-range' hdrs)
  ?~  cr  ~
  =/  val=tape  (trip u.cr)
  =/  dash-pos=(unit @ud)  (find "-" val)
  ?~  dash-pos  ~
  =/  slash-pos=(unit @ud)  (find "/" val)
  ?~  slash-pos  ~
  ?:  (gte +(u.dash-pos) u.slash-pos)  ~
  =/  end-tape=tape
    (swag [+(u.dash-pos) (sub u.slash-pos +(u.dash-pos))] val)
  (rush (crip end-tape) dem)
::
::  +derive-has-more: compute has-more for a host-proxy chunk emit.
::  4xx/5xx upstream is terminal (body discarded by caller). Otherwise:
::  Plex returns 206 even on the final byte of a Range response, so
::  status alone can't tell us when to close. Parse Content-Range
::  end+1 == total to detect the last chunk and force has-more=%.n.
::  Without this, subscriber's trickle stays in slow runway-paced
::  drain (~260 KB / 30s) instead of fast final-drain. Falls through
::  to =(206 status) when CR header is absent or malformed.
::
++  derive-has-more
  |=  [is-error=? status=@ud hdrs=header-list:http]
  ^-  ?
  ?:  is-error  %.n
  =/  cr-end=(unit @ud)    (extract-cr-end hdrs)
  =/  cr-total=(unit @ud)  (extract-cr-total hdrs)
  =/  is-final=?
    ?&  ?=(^ cr-end)
        ?=(^ cr-total)
        =(+(u.cr-end) u.cr-total)
    ==
  ?:  is-final  %.n
  =(206 status)
::
::  +find-library-item-by-rkey: walk items-by-section to find a library
::  item by its rating-key. Used at download-request time to build a
::  human-friendly Content-Disposition filename from the cached library
::  metadata (no extra round-trip to host or Plex). Returns ~ if rkey
::  isn't in the cache (unsynced library, browser-typed URL, etc.).
::
++  find-library-item-by-rkey
  |=  [items-map=(map @t (list library-item:burn)) rkey=@t]
  ^-  (unit library-item:burn)
  =/  all-items=(list library-item:burn)
    (zing ~(val by items-map))
  =/  match=(list library-item:burn)
    %+  skim  all-items
    |=  li=library-item:burn
    =(rkey rating-key.li)
  ?~  match  ~
  `i.match
::
::  +scan-ep-list: find first episode in list matching rkey.
::
++  scan-ep-list
  |=  [eps=(list episode-item:burn) rkey=@t]
  ^-  (unit episode-item:burn)
  |-
  ?~  eps  ~
  ?:  =(rkey rating-key.i.eps)  `i.eps
  $(eps t.eps)
::
::  +scan-season-list: find first season in list matching season-rkey.
::
++  scan-season-list
  |=  [seas=(list season-item:burn) season-rkey=@t]
  ^-  (unit season-item:burn)
  |-
  ?~  seas  ~
  ?:  =(season-rkey rating-key.i.seas)  `i.seas
  $(seas t.seas)
::
::  +art-dims: canonical Plex thumbnail variant dimensions. The URL and
::  these dimensions travel together so renderers can use ;shape[intrinsic]
::  and avoid re-inferring art shape from container, media kind, or query
::  strings.
::
++  art-dims
  |=  kind=@tas
  ^-  [width=@ud height=@ud]
  ?+  kind  [200 300]
    %wide    [320 180]
    %square  [300 300]
  ==
::
++  media-art-from-thumb
  |=  [thumb=@t kind=@tas]
  ^-  (unit media-art:burn)
  ?:  =('' thumb)  ~
  =/  dims=[width=@ud height=@ud]  (art-dims kind)
  =/  url=(unit @t)  (thumb-to-cache-url thumb kind)
  ?~  url  ~
  %-  some
  ^-  media-art:burn
  [url=u.url width=width.dims height=height.dims]
::
++  media-kind-from-library-type
  |=  type=@t
  ^-  @tas
  ?:  =('movie' type)   %movie
  ?:  =('show' type)    %show
  ?:  =('artist' type)  %artist
  ?:  =('album' type)   %album
  ?:  =('track' type)   %track
  %unknown
::
++  media-node
  |=  [kind=@tas label=@t thumb=@t art-kind=@tas index=@t]
  ^-  media-node-ref:burn
  :*  kind
      label
      (media-art-from-thumb thumb art-kind)
      index
  ==
::
++  empty-media-path
  ^-  media-path:burn
  :-  ~
  (media-node %unknown '' '' %tall '')
::
++  media-path-from-library-item
  |=  it=library-item:burn
  ^-  media-path:burn
  =/  label=@t
    ?:  =('' year.it)  title.it
    (crip "{(trip title.it)} ({(trip year.it)})")
  =/  kind=@tas  (media-kind-from-library-type type.it)
  =/  art-kind=@tas  (library-item-kind:burn-to-goad type.it)
  :-  ~
  (media-node kind label thumb.it art-kind '')
::
::  +find-media-path: look up a downloadable rkey as a generic path.
::  Today the cache still stores Plex's show→season→episode structure,
::  with albums/tracks reusing the season/episode molds. This arm keeps
::  those implementation details from leaking into stream/progress state.
::
++  find-media-path
  |=  [src=source-state:burn rkey=@t]
  ^-  media-path:burn
  =/  li=(unit library-item:burn)
    (find-library-item-by-rkey items.src rkey)
  ?^  li
    (media-path-from-library-item u.li)
  ::  Step 1: walk child-item map (season/album rkey → episode/track list)
  =/  ep-pairs=(list [@t (list episode-item:burn)])
    ~(tap by episodes.src)
  =/  ep-result=(unit [srk=@t ep=episode-item:burn])
    |-
    ?~  ep-pairs  ~
    =/  srk=@t  -.i.ep-pairs
    =/  eps=(list episode-item:burn)  +.i.ep-pairs
    =/  found=(unit episode-item:burn)
      |-
      ?~  eps  ~
      ?:  =(rkey rating-key.i.eps)  `i.eps
      $(eps t.eps)
    ?~  found  $(ep-pairs t.ep-pairs)
    `[srk u.found]
  ?~  ep-result  empty-media-path
  =/  parent-rkey=@t  srk.u.ep-result
  =/  ep=episode-item:burn  ep.u.ep-result
  ::  Step 2: walk parent map (show/artist rkey → season/album list)
  =/  season-pairs=(list [@t (list season-item:burn)])
    ~(tap by seasons.src)
  =/  season-result=(unit [root-rkey=@t season=season-item:burn])
    |-
    ?~  season-pairs  ~
    =/  root-rkey=@t  -.i.season-pairs
    =/  seas=(list season-item:burn)  +.i.season-pairs
    =/  found=(unit season-item:burn)
      |-
      ?~  seas  ~
      ?:  =(parent-rkey rating-key.i.seas)  `i.seas
      $(seas t.seas)
    ?~  found  $(season-pairs t.season-pairs)
    `[root-rkey u.found]
  ?~  season-result
    :-  ~
    (media-node %unknown title.ep thumb.ep %wide index.ep)
  =/  root-rkey=@t  root-rkey.u.season-result
  =/  parent=season-item:burn  season.u.season-result
  =/  maybe-root=(unit library-item:burn)
    ?:  =('' root-rkey)  ~
    (find-library-item-by-rkey items.src root-rkey)
  =/  is-music=?
    ?~  maybe-root  %.n
    =('artist' type.u.maybe-root)
  =/  root-node=(unit media-node-ref:burn)
    ?~  maybe-root  ~
    =/  root-kind=@tas  (media-kind-from-library-type type.u.maybe-root)
    =/  root-art=@tas  (library-item-kind:burn-to-goad type.u.maybe-root)
    `(media-node root-kind title.u.maybe-root thumb.u.maybe-root root-art '')
  =/  parent-kind=@tas  ?:(is-music %album %season)
  =/  parent-art=@tas  ?:(is-music %square %tall)
  =/  item-kind=@tas  ?:(is-music %track %episode)
  =/  item-art=@tas  ?:(is-music %square %wide)
  =/  parent-node=media-node-ref:burn
    (media-node parent-kind title.parent thumb.parent parent-art index.parent)
  =/  item-node=media-node-ref:burn
    (media-node item-kind title.ep thumb.ep item-art index.ep)
  =/  ancestors=(list media-node-ref:burn)
    ?~  root-node
      ~[parent-node]
    ~[u.root-node parent-node]
  [ancestors item-node]
::
::  +container-from-extension: normalize a file extension to the @tas value
::  used for browser-facing Content-Disposition suffixes.
::
++  container-from-extension
  |=  ext=@t
  ^-  @tas
  =/  e=@t  (crip (cass (trip ext)))
  ?+  e  %$
    %'mkv'   %mkv
    %'mp4'   %mp4
    %'m4v'   %m4v
    %'avi'   %avi
    %'webm'  %webm
    %'mov'   %mov
    %'mp3'   %mp3
    %'flac'  %flac
    %'ogg'   %ogg
    %'oga'   %oga
    %'m4a'   %m4a
    %'aac'   %aac
    %'wav'   %wav
    %'aif'   %aif
    %'aiff'  %aiff
    %'aifc'  %aifc
  ==
::
::  +container-from-path: get the suffix after the last '.' in a Plex Part
::  file path. '/' resets the candidate so dots in directories don't count.
::
++  container-from-path
  |=  path=@t
  ^-  @tas
  =/  chars=tape  (trip path)
  =/  ext=(unit tape)  ~
  =/  ext-tape=tape
    |-
    ?~  chars
      ?~(ext "" u.ext)
    =/  c=@tD  i.chars
    ?:  =("/" ~[c])
      $(chars t.chars, ext ~)
    ?:  =("." ~[c])
      $(chars t.chars, ext (some ""))
    ?~  ext
      $(chars t.chars)
    $(chars t.chars, ext (some (weld u.ext ~[c])))
  ?:  =(0 (lent ext-tape))
    %$
  (container-from-extension (crip ext-tape))
::
::  +container-from-content-type: map Plex's Content-Type header to a
::  container extension. Returns %$ (empty @tas) when the type is unknown.
::
++  container-from-content-type
  |=  ct=(unit @t)
  ^-  @tas
  ?~  ct  %$
  ::  Strip any "; charset=..." parameters before matching
  =/  v=tape  (trip u.ct)
  =/  semi=(unit @ud)  (find ";" v)
  =/  base=tape  ?~(semi v (scag u.semi v))
  =/  base-cord=@t  (crip (cass base))
  ?+  base-cord  %$
    %'video/x-matroska'  %mkv
    %'video/mp4'         %mp4
    %'video/avi'         %avi
    %'video/x-msvideo'   %avi
    %'video/webm'        %webm
    %'video/quicktime'   %mov
    %'audio/mpeg'        %mp3
    %'audio/mp3'         %mp3
    %'audio/flac'        %flac
    %'audio/x-flac'      %flac
    %'audio/ogg'         %ogg
    %'audio/mp4'         %m4a
    %'audio/x-m4a'       %m4a
    %'audio/aac'         %aac
    %'audio/wav'         %wav
    %'audio/x-wav'       %wav
    %'audio/aiff'        %aiff
    %'audio/x-aiff'      %aiff
    %'audio/aifc'        %aifc
    %'audio/x-aifc'      %aifc
    %'application/aiff'   %aiff
    %'application/x-aiff'  %aiff
    %'application/aifc'   %aifc
    %'application/x-aifc'  %aifc
  ==
::
::  +octs-starts: byte-prefix test for tiny container magic sniffing.
::
++  octs-starts
  |=  [data=octs prefix=@t]
  ^-  ?
  =/  pref=octs  (as-octs:mimes:html prefix)
  ?&  !(gth p.pref p.data)
      =((cut 3 [0 p.pref] q.data) q.pref)
  ==
::
::  +container-from-bytes: identify exact containers from first bytes when
::  headers are ambiguous. AIFF-C often arrives as Content-Type audio/x-aiff,
::  but the file magic distinguishes FORM....AIFC from FORM....AIFF.
::
++  container-from-bytes
  |=  data=octs
  ^-  @tas
  ?:  (lth p.data 12)  %$
  ?.  (octs-starts data 'FORM')  %$
  =/  form-type=@  (cut 3 [8 4] q.data)
  =/  aifc=octs  (as-octs:mimes:html 'AIFC')
  =/  aiff=octs  (as-octs:mimes:html 'AIFF')
  ?:  =(form-type q.aifc)  %aifc
  ?:  =(form-type q.aiff)  %aiff
  %$
::
::  +container-from-headers: prefer the %burn extension hint derived from
::  Plex metadata's Part file path, then fall back to Content-Type. Plex's
::  audio Content-Type can be too broad (`audio/x-aiff`) for AIFC/sowt files,
::  while the Part file suffix is the name users expect the browser to save.
::
++  container-from-headers
  |=  hdrs=header-list:http
  ^-  @tas
  =/  hint=(unit @t)  (get-header-ci 'x-burn-container' hdrs)
  =/  from-hint=@tas
    ?~  hint  %$
    (container-from-extension u.hint)
  ?:  !=(%$ from-hint)
    from-hint
  =/  from-type=@tas
    (container-from-content-type (get-header-ci 'content-type' hdrs))
  ?:  !=(%$ from-type)
    from-type
  %$
::
::  +rebuild-content-disposition: replace any existing Content-Disposition
::  in `rh` with one built from `display-name` + optional `container`,
::  using RFC 5987 / 6266 percent-encoded UTF-8 syntax. Browsers decode
::  this back to the original characters (apostrophes, parens, Unicode);
::  no hand-rolled sanitization needed. en-urlt:html does the encoding.
::  Used at first-chunk arrival to apply the container we discovered
::  from Plex's Content-Type, replacing the placeholder header that
::  was stored in deferred-headers at request initiation.
::
++  rebuild-content-disposition
  |=  [rh=response-header:http display-name=@t container=@tas]
  ^-  response-header:http
  =/  filtered=header-list:http
    %+  skip  headers.rh
    |=  [k=@t v=@t]
    =('content-disposition' (crip (cass (trip k))))
  =/  encoded=tape  (en-urlt:html (trip display-name))
  =/  filename-with-ext=tape
    ?:  =(%$ container)  encoded
    "{encoded}.{(trip container)}"
  =/  cd-val=@t
    (crip "attachment; filename*=UTF-8''{filename-with-ext}")
  rh(headers ['content-disposition'^cd-val filtered])
::
::  +extract-total-from-headers: get total file size from response headers.
::  Tries Content-Range total first (206 partial responses from Plex),
::  falls back to Content-Length (200 full responses). Returns 0 if
::  neither present (chunked transfer-encoding, etc.). state uses
::  this on first %proxy-chunk arrival to populate stream-state.total-
::  size — the correctness gate that prevents off-the-end-of-file Range
::  requests that produce 416 + HTML body write-through.
::
++  extract-total-from-headers
  |=  hdrs=header-list:http
  ^-  @ud
  =/  cr=(unit @ud)  (extract-cr-total hdrs)
  ?^  cr  u.cr
  =/  cl=(unit @t)  (get-header-ci 'content-length' hdrs)
  ?~  cl  0
  =/  parsed=(unit @ud)  (rush u.cl dem)
  ?~  parsed  0
  u.parsed
::
::  +substitute-cr-total: rewrite a Content-Range header value's total
::  field (everything after the '/') to a concrete @ud, leaving status
::  and other headers unchanged. If the response-header has no
::  Content-Range, returns rh unchanged. Used to forward Plex's real
::  total to the browser at deferred-header emit time.
::
++  substitute-cr-total
  |=  [rh=response-header:http total=@ud]
  ^-  response-header:http
  =/  hdrs=header-list:http  headers.rh
  =/  new-hdrs=header-list:http
    %+  turn  hdrs
    |=  [k=@t v=@t]
    ?.  =('content-range' (crip (cass (trip k))))
      [k v]
    =/  val=tape  (trip v)
    =/  slash-pos=(unit @ud)  (find "/" val)
    ?~  slash-pos  [k v]
    =/  prefix=tape  (scag +(u.slash-pos) val)
    [k (crip (weld prefix (a-co:co total)))]
  rh(headers new-hdrs)
::
::  +substitute-cr-span: rewrite a browser-facing Content-Range to the
::  exact resumed span once Plex's real total is known. We initially store
::  a placeholder because the download header is deferred until the first
::  host chunk arrives. For Range resume, the bytes we emit start exactly at
::  `start`, and the response continues to EOF, so the final byte is total-1.
::
++  substitute-cr-span
  |=  [rh=response-header:http start=@ud total=@ud]
  ^-  response-header:http
  ?.  =(206 status-code.rh)  rh
  ?:  =(0 total)  rh
  =/  end=@ud  (sub total 1)
  =/  cr-val=@t
    (crip "bytes {(a-co:co start)}-{(a-co:co end)}/{(a-co:co total)}")
  =/  filtered=header-list:http
    %+  skip  headers.rh
    |=  [k=@t v=@t]
    =('content-range' (crip (cass (trip k))))
  rh(headers [['content-range' cr-val] filtered])
::
::  +eauth-redirect: 302 cards bouncing an unauthenticated request to the
::  new-oxal auth panel, preserving the original URL as ?redirect= so
::  post-auth lands back. Used by both subscriber download and stream gates.
::
++  eauth-redirect
  |=  [eyre-id=@ta original-url=@t]
  ^-  (list card)
  =/  redirect-url=@t
    (crip "/new-oxal/plex?auth=required&redirect={(en-urlt:html (trip original-url))}")
  %+  give-simple-payload:app:server  eyre-id
  :-  [302 ~[['location' redirect-url] ['cache-control' 'no-store']]]
  `(unit octs)`~
::
::  +inject-content-length: ensure the response-header has exactly one
::  Content-Length entry set to `total`. Filters any existing CL header
::  (case-insensitive) then prepends a new one.
::
::    PARKED: NOT CURRENTLY CALLED. Vere's pkg/urbit/vere/io/http.c
::    (~lines 703-705) clobbers any agent-supplied content-length when
::    the %start event has no inline body (which our streaming pattern
::    always uses). The clobbered value is the size of the inline body,
::    i.e. 0 for our case — yielding `Content-Length: 0` on the wire and
::    a zero-byte response to the browser. Helper preserved for the day
::    Vere is patched to honor agent's content-length value.
::
++  inject-content-length
  |=  [rh=response-header:http total=@ud]
  ^-  response-header:http
  =/  filtered=header-list:http
    %+  skip  headers.rh
    |=  [k=@t v=@t]
    =('content-length' (crip (cass (trip k))))
  =/  cl-val=@t  (crip (a-co:co total))
  rh(headers [['content-length' cl-val] filtered])
::
::  +extract-part-key: find the Part download key from Plex metadata XML
::  Walks <Video><Media><Part key="..."> to get download URL path
::
++  extract-part-key
  |=  body=@t
  ^-  @t
  =/  xml=(unit manx)
    (de-xml:html body)
  ?~  xml  ''
  (find-part-in-manx u.xml)
::
++  extract-part-file
  |=  body=@t
  ^-  @t
  =/  xml=(unit manx)
    (de-xml:html body)
  ?~  xml  ''
  (find-part-file-in-manx u.xml)
::
::  +find-part-in-manx: recursive tree walk for Part element
::
++  find-part-in-manx
  |=  mx=manx
  ^-  @t
  ?:  =('Part' n.g.mx)
    (find-attr 'key' a.g.mx)
  =/  kids=(list manx)  c.mx
  |-
  ?~  kids  ''
  =/  result=@t  (find-part-in-manx i.kids)
  ?.(=('' result) result $(kids t.kids))
::
::  +find-part-size-in-manx: recursive tree walk for first Part size.
::
++  find-part-size-in-manx
  |=  mx=manx
  ^-  @t
  ?:  =('Part' n.g.mx)
    (find-attr 'size' a.g.mx)
  =/  kids=(list manx)  c.mx
  |-
  ?~  kids  ''
  =/  result=@t  (find-part-size-in-manx i.kids)
  ?.(=('' result) result $(kids t.kids))
::
::  +find-part-file-in-manx: recursive tree walk for first Part file path.
::
++  find-part-file-in-manx
  |=  mx=manx
  ^-  @t
  ?:  =('Part' n.g.mx)
    (find-attr 'file' a.g.mx)
  =/  kids=(list manx)  c.mx
  |-
  ?~  kids  ''
  =/  result=@t  (find-part-file-in-manx i.kids)
  ?.(=('' result) result $(kids t.kids))
::
::  +parse-library-sections: extract sections from Plex XML response
::  Uses de-xml:html to parse, then walks manx tree for Directory elements
::
++  parse-library-sections
  |=  body=@t
  ^-  (list library-section:burn)
  =/  xml=(unit manx)
    (de-xml:html body)
  ?~  xml
    ~&  >>>  "burn: XML parse failed"
    ~
  =/  kids=(list manx)  c.u.xml
  %+  murn  kids
  |=  =manx
  ^-  (unit library-section:burn)
  ?.  =('Directory' n.g.manx)  ~
  =/  key=@t    (find-attr 'key' a.g.manx)
  =/  title=@t  (find-attr 'title' a.g.manx)
  =/  type=@t   (find-attr 'type' a.g.manx)
  ?:  |(=('' key) =('' title))  ~
  ::  Filter section types we don't surface. TODO: replace with a
  ::  host-pref shared-section-types allowlist when hosting config grows
  ::  per-type share toggles.
  ?:  =('photo' type)  ~
  `[key title type]
::
::  +parse-library-items: extract items from Plex XML response
::  Handles both Video (movies) and Directory (TV shows) elements
::
++  parse-library-items
  |=  [body=@t section-type=@t]
  ^-  (list library-item:burn)
  =/  xml=(unit manx)
    (de-xml:html body)
  ?~  xml
    ~&  >>>  "burn: items XML parse failed"
    ~
  =/  kids=(list manx)  c.u.xml
  %+  murn  kids
  |=  =manx
  ^-  (unit library-item:burn)
  =/  attrs=mart  a.g.manx
  ?.  ?|  =('Video' n.g.manx)
          =('Directory' n.g.manx)
          =('Track' n.g.manx)
      ==
    ~
  =/  rk=@t       (find-attr 'ratingKey' attrs)
  =/  ttl=@t      (find-attr 'title' attrs)
  =/  yr=@t       (find-attr 'year' attrs)
  =/  rt=@t       (find-attr 'rating' attrs)
  =/  dur=@t      (find-attr 'duration' attrs)
  =/  vc=@t       (find-attr 'viewCount' attrs)
  =/  thm0=@t     (find-attr 'thumb' attrs)
  =/  thm1=@t     ?:  !=('' thm0)  thm0  (find-attr 'parentThumb' attrs)
  =/  thm=@t      ?:  !=('' thm1)  thm1  (find-attr 'grandparentThumb' attrs)
  =/  smry=@t     (cap-text (find-attr 'summary' attrs))
  =/  tagln=@t    (cap-text (find-attr 'tagline' attrs))
  =/  gnr=@t      (cap-text (collect-genre c.manx))
  =/  sz=@t       (find-part-size-in-manx manx)
  =/  part-file=@t  (find-part-file-in-manx manx)
  ::  Prefer Plex's per-item type attr ('movie', 'show', 'artist',
  ::  'album', etc) when present so music sections classify correctly
  ::  for the renderer's aspect-kind dispatch. Fall back to manx-name
  ::  heuristic for older Plex responses that don't carry type.
  =/  raw-type=@t  (find-attr 'type' attrs)
  =/  item-type=@t
    ?.  =('' raw-type)  raw-type
    ?:  =('Video' n.g.manx)  'movie'
    ?:  =('Track' n.g.manx)  'track'
    'show'
  ?:  (is-hidden-media-artifact ttl part-file)  ~
  ?:  =('' rk)  ~
  :-  ~
  :*  rk
      ttl
      yr
      item-type
      rt
      thm
      (gth (met 3 vc) 0)
      dur
      smry
      gnr
      tagln
      sz
  ==
::
::  +parse-show-children: extract seasons from Plex /library/metadata/<rkey>/children
::  XML response. Top-level Directory entries are seasons.
::
++  parse-show-children
  |=  body=@t
  ^-  (list season-item:burn)
  =/  xml=(unit manx)
    (de-xml:html body)
  ?~  xml
    ~&  >>>  "burn: show-children XML parse failed"
    ~
  =/  kids=(list manx)  c.u.xml
  %+  murn  kids
  |=  =manx
  ^-  (unit season-item:burn)
  =/  attrs=mart  a.g.manx
  ?.  =('Directory' n.g.manx)  ~
  =/  rk=@t     (find-attr 'ratingKey' attrs)
  =/  ttl=@t    (find-attr 'title' attrs)
  =/  idx=@t    (find-attr 'index' attrs)
  =/  thm0=@t   (find-attr 'thumb' attrs)
  =/  thm1=@t   ?:  !=('' thm0)  thm0  (find-attr 'parentThumb' attrs)
  =/  thm=@t    ?:  !=('' thm1)  thm1  (find-attr 'grandparentThumb' attrs)
  =/  smry=@t   (cap-text (find-attr 'summary' attrs))
  ?:  =('' rk)  ~
  `[rk ttl idx thm smry]
::
::  +parse-season-children: extract episodes from Plex /library/metadata/<rkey>/children
::  XML response. Top-level Video entries are episodes.
::
++  parse-season-children
  |=  body=@t
  ^-  (list episode-item:burn)
  =/  xml=(unit manx)
    (de-xml:html body)
  ?~  xml
    ~&  >>>  "burn: season-children XML parse failed"
    ~
  =/  kids=(list manx)  c.u.xml
  %+  murn  kids
  |=  =manx
  ^-  (unit episode-item:burn)
  =/  attrs=mart  a.g.manx
  ?.  =('Video' n.g.manx)  ~
  =/  rk=@t     (find-attr 'ratingKey' attrs)
  =/  ttl=@t    (find-attr 'title' attrs)
  =/  idx=@t    (find-attr 'index' attrs)
  =/  thm=@t    (find-attr 'thumb' attrs)
  =/  dur=@t    (find-attr 'duration' attrs)
  =/  vc=@t     (find-attr 'viewCount' attrs)
  =/  smry=@t   (cap-text (find-attr 'summary' attrs))
  =/  sz=@t     (find-part-size-in-manx manx)
  =/  part-file=@t  (find-part-file-in-manx manx)
  ?:  (is-hidden-media-artifact ttl part-file)  ~
  ?:  =('' rk)  ~
  `[rk ttl idx thm dur (gth (met 3 vc) 0) smry sz]
::
::  +parse-album-children: extract tracks from Plex
::  /library/metadata/<album-rkey>/children XML response.
::
++  parse-album-children
  |=  body=@t
  ^-  (list episode-item:burn)
  =/  xml=(unit manx)
    (de-xml:html body)
  ?~  xml
    ~&  >>>  "burn: album-children XML parse failed"
    ~
  =/  kids=(list manx)  c.u.xml
  %+  murn  kids
  |=  =manx
  ^-  (unit episode-item:burn)
  =/  attrs=mart  a.g.manx
  ?.  ?|  =('Track' n.g.manx)
          =('Video' n.g.manx)
      ==
    ~
  =/  rk=@t     (find-attr 'ratingKey' attrs)
  =/  ttl=@t    (find-attr 'title' attrs)
  =/  idx=@t    (find-attr 'index' attrs)
  =/  thm0=@t   (find-attr 'thumb' attrs)
  =/  thm1=@t   ?:  !=('' thm0)  thm0  (find-attr 'parentThumb' attrs)
  =/  thm=@t    ?:  !=('' thm1)  thm1  (find-attr 'grandparentThumb' attrs)
  =/  dur=@t    (find-attr 'duration' attrs)
  =/  vc=@t     (find-attr 'viewCount' attrs)
  =/  smry=@t   (cap-text (find-attr 'summary' attrs))
  =/  sz=@t     (find-part-size-in-manx manx)
  ?:  =('' rk)  ~
  `[rk ttl idx thm dur (gth (met 3 vc) 0) smry sz]
::
::  +give-items: give items fact to subscribers and kick
::
++  give-items
  |=  [section-key=@t items=(list library-item:burn)]
  ^-  (list card)
  =/  sub-path=path  /library/items/[section-key]
  ~&  >  "burn: giving {<(lent items)>} items on {<sub-path>}"
  :~  [%give %fact ~[sub-path] %noun !>(items)]
      [%give %kick ~[sub-path] ~]
  ==
::
::  +get-timeout: effective proxy timeout (default ~m5 if unset)
::
++  get-timeout
  |=  =state:burn
  ^-  @dr
  ?:(=(0 proxy-timeout.state) ~m5 proxy-timeout.state)
--
