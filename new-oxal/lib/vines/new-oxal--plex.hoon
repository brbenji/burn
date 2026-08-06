::  /lib/vines/new-oxal--plex: live-island Hoon UI for burn
::
::    GET  /new-oxal/plex   skeleton with #goon-root + #status-live divs;
::                      datastar handshake re-fires the URL with
::                      datastar-request: true. SSE branch scries
::                      /x/goon, watches /goon
::                      and (when an active download exists)
::                      /goon/progress/<rid>. Single strand multiplexes
::                      both watches via take-fact-either.
::    POST /new-oxal/plex   form-encoded {path, blade, value?} → stab,
::                      poke %burn %goon-event.
::
::  Renders goon's $goad type directly. Article bodies stay parser-free
::  in the renderer so full-tree SSE morphs do not spin on parser work.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
/-  goon
/+  *vineio, *zozo, goon-goad-to-manx
=,  goon
::
=<
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
?:  =('POST' method.bowl)
  (handle-post bowl)
::
=/  is-ds=?  =((get-header:vio 'datastar-request') `'true')
?.  is-ds
  ::  SSR the actual goad tree on initial GET so the page paints with
  ::  real content. Datastar's data-init then re-fires the URL with
  ::  the datastar-request header to open the SSE channel.
  ;<  =goad  bind:m  (scry ,goad /gx/burn/goon/noun)
  =/  auth-target=(unit @t)
    ?:  =((~(gut by query.bowl) 'auth' '') 'required')
      (~(get by query.bowl) 'redirect')
    ~
  ;<  ~  bind:m  (send-html-payload:vio (skeleton goad src.bowl our.bowl auth-target))
  (pure:m !>(~))
::
;<  ~       bind:m  open-sse:vio
;<  =goad   bind:m
  (scry ,goad /gx/burn/goon/noun)
::
::  Initial GET already sent #goon-root. Keep the SSE open and remember
::  this goad's mug so immediate reconnect/watch redraws can skip the
::  expensive full-root Datastar morph when the tree is unchanged.
::
=/  goad-mug=@  (mug goad)
::
=/  rid=(unit @uv)  (find-active-rid goad)
=/  goon-wire=wire  /oxal-plex/goon
;<  ~  bind:m  (watch goon-wire [our.bowl %burn] /goon)
::
?~  rid
  (loop goon-wire ~ ~ `goad-mug ~ bowl)
=/  prog-wire=wire  /oxal-plex/progress/[(scot %uv u.rid)]
;<  ~  bind:m
  (watch prog-wire [our.bowl %burn] /goon/progress/[(scot %uv u.rid)])
(loop goon-wire `[u.rid prog-wire] ~ `goad-mug ~ bowl)
::
|%
::
::  +loop: take-fact on either /goon or active /goon/progress/<rid>;
::  re-scry on /goon, but only re-render + morph #goon-root when the
::  goad mug changed. Progress facts morph #status-live only. On rid
::  change, leave old progress watch and start a new one.
::
::  Idle keep-alive: a Behn timer races the fact-take so quiet
::  periods (no /goon facts) still produce SSE traffic, otherwise
::  the browser hits its read timeout and reconnects — spawning
::  a fresh strand per reconnect. Only one pending timer at a time:
::  re-arm on entry when wake-at=~, preserve when wake-at=^.
::
++  loop
  |=  $:  goon-wire=wire
          prog=(unit [rid=@uv =wire])
          last-dl=(unit [rid=@uv payload=progress-payload])
          last-goad-mug=(unit @)
          wake-at=(unit @da)
          =http-bowl
      ==
  =/  m  (strand ,vase)
  ^-  form:m
  =/  vio  ~(. server http-bowl)
  ;<  next-wake=(unit @da)  bind:m  (arm-keepalive wake-at)
  ;<  res=fact-result  bind:m  (take-fact-either goon-wire prog)
  ?-  -.res
      %goon
    ;<  =goad  bind:m
      (scry ,goad /gx/burn/goon/noun)
    =/  goad-mug=@  (mug goad)
    =/  same-goad=?
      ?~  last-goad-mug
        %.n
      =(goad-mug u.last-goad-mug)
    ?:  same-goad
      =/  next-rid=(unit @uv)  (find-active-rid goad)
      =/  next-prog=(unit [rid=@uv =wire])
        ?~  next-rid  ~
        `[u.next-rid /oxal-plex/progress/[(scot %uv u.next-rid)]]
      ;<  ~  bind:m  (maybe-clear-status-strip prog next-rid http-bowl)
      ;<  ~  bind:m  (sync-progress-sub prog next-prog http-bowl)
      (loop goon-wire next-prog last-dl `goad-mug next-wake http-bowl)
    ;<  ~  bind:m  (morph:vio (render-frozen goad last-dl src.http-bowl our.http-bowl))
    =/  next-rid=(unit @uv)  (find-active-rid goad)
    =/  next-prog=(unit [rid=@uv =wire])
      ?~  next-rid  ~
      `[u.next-rid /oxal-plex/progress/[(scot %uv u.next-rid)]]
    ;<  ~  bind:m  (maybe-clear-status-strip prog next-rid http-bowl)
    ;<  ~  bind:m  (sync-progress-sub prog next-prog http-bowl)
    (loop goon-wire next-prog last-dl `goad-mug next-wake http-bowl)
  ::
      %progress
    ?~  prog  (loop goon-wire ~ last-dl last-goad-mug next-wake http-bowl)
    ;<  ~  bind:m
      %-  morph:vio
      (render-status-live rid.u.prog payload.res src.http-bowl our.http-bowl)
    (loop goon-wire prog `[rid.u.prog payload.res] last-goad-mug next-wake http-bowl)
  ::
      %prog-kick
    ;<  ~  bind:m  (morph:vio empty-status-live)
    (loop goon-wire ~ ~ last-goad-mug next-wake http-bowl)
  ::
      %wake
    ;<  ~  bind:m  keep-alive:vio
    (loop goon-wire prog last-dl last-goad-mug ~ http-bowl)
  ==
::
::  +arm-keepalive: schedule a Behn wake ~s10 from now if no timer
::  is pending; otherwise reuse the existing one. Returns the new
::  wake-at the loop should thread forward.
::
++  arm-keepalive
  |=  wake-at=(unit @da)
  =/  m  (strand ,(unit @da))
  ^-  form:m
  ?^  wake-at  (pure:m wake-at)
  ;<  now=@da  bind:m  get-time
  =/  until=@da  (add now ~s10)
  ;<  ~  bind:m  (send-wait until)
  (pure:m `until)
::
::  +sync-progress-sub: leave the old progress watch (if any) and start
::  the new one (if any). Idempotent for unchanged rids.
::
++  sync-progress-sub
  |=  [old=(unit [rid=@uv =wire]) new=(unit [rid=@uv =wire]) =http-bowl]
  =/  m  (strand ,~)
  ^-  form:m
  ?:  =(old new)  (pure:m ~)
  =/  leave-cards=(list card:agent:gall)
    ?~  old  ~
    ~[[%pass watch+wire.u.old %agent [our.http-bowl %burn] %leave ~]]
  =/  watch-cards=(list card:agent:gall)
    ?~  new  ~
    :~  :*  %pass  watch+wire.u.new
            %agent  [our.http-bowl %burn]
            %watch  /goon/progress/[(scot %uv rid.u.new)]
        ==
    ==
  ;<  ~  bind:m  (send-raw-cards (weld leave-cards watch-cards))
  (pure:m ~)
::
::  +maybe-clear-status-strip: morph an empty #status-live ONLY when an
::  active download just ended (prev=^, next=~). All other transitions
::  (none→none, ongoing, new arrival) are no-ops here; new arrivals will
::  emit their own progress fact and morph live status normally.
::
++  maybe-clear-status-strip
  |=  $:  prev=(unit [rid=@uv =wire])
          next=(unit @uv)
          =http-bowl
      ==
  =/  m  (strand ,~)
  ^-  form:m
  =/  vio  ~(. server http-bowl)
  ?:  ?|  ?=(~ prev)
          ?=(^ next)
      ==
    (pure:m ~)
  ;<  ~  bind:m  (morph:vio empty-status-live)
  (pure:m ~)
::
::  +empty-status-live: the empty strip. CSS #status-live:empty rule
::  collapses it to zero height; morphing this clears any previous payload.
::
++  empty-status-live
  ^-  manx
  %+  add-attribute  ['data-goon-path' "/downloads"]
  %+  add-attribute  ['data-goon' "root-section"]
  ;div#status-live;
::
::  +take-fact-either: matches a fact on either the goon wire or the
::  active progress wire (if any), and matches kicks on the progress
::  wire. Discriminates on the wire to dispatch the right branch.
::
::  Live-strip snapshot payload — enriched from burn's +give-progress-fact.
::  All fields needed for the 4-entity render arrive in one fact, no per-tick
::  scry required. Static fields (display-name, initiator, host, total,
::  chunks, chunk-size) repeat each tick. Changing fields are emitted,
::  received, seq.
::
+$  progress-payload
  $:  emitted=@ud
      received=@ud
      total=@ud
      started=@da
      seq=@ud
      chunks=@ud
      chunk-size=@ud
      container=@tas
      display-name=@t
      item-kind=@tas
      item-label=@t
      item-thumb-url=@t
      item-thumb-width=@ud
      item-thumb-height=@ud
      context-label=@t
      context-thumb-url=@t
      context-thumb-width=@ud
      context-thumb-height=@ud
      initiator=@p
      host=@p
      breadcrumb=@t
      item-index=@t
  ==
::
+$  fact-result
  $%  [%goon =cage]
      [%progress payload=progress-payload]
      [%prog-kick ~]
      [%wake ~]
  ==
::
++  take-fact-either
  |=  [goon-wire=wire prog=(unit [rid=@uv =wire])]
  =/  m  (strand ,fact-result)
  ^-  form:m
  |=  tin=strand-input:strand
  ?+  in.tin  `[%skip ~]
      ~  `[%wait ~]
      [~ %agent * %fact *]
    =*  w  wire.u.in.tin
    ?:  =(watch+goon-wire w)
      `[%done %goon cage.sign.u.in.tin]
    ?~  prog  `[%skip ~]
    ?:  =(watch+wire.u.prog w)
      =/  pl=progress-payload  ;;(progress-payload q.q.cage.sign.u.in.tin)
      `[%done %progress pl]
    `[%skip ~]
  ::
      [~ %agent * %kick *]
    ?~  prog  `[%skip ~]
    ?.  =(watch+wire.u.prog wire.u.in.tin)  `[%skip ~]
    `[%done %prog-kick ~]
  ::
      [~ %sign [%wait @ ~] %behn %wake *]
    `[%done %wake ~]
  ==
::
::  +find-active-rid: walk goad children for %downloads node, return
::  first child's iota parsed as @uv. Single-slot v1 simplification.
::
++  find-active-rid
  |=  =goad
  ^-  (unit @uv)
  =/  kids=(list ^goad)  +>.goad
  =/  dl=(unit ^goad)
    |-
    ?~  kids  ~
    ::  iota is $@(@t (pair aura @)); the %downloads kid's iota is the
    ::  atom %downloads, not a cell. Atom literal pattern, not cell.
    ?:  ?=(%downloads -.i.kids)  `i.kids
    $(kids t.kids)
  ?~  dl  ~
  =/  dl-kids=(list ^goad)  +>.u.dl
  ?~  dl-kids  ~
  =/  =iota  -.i.dl-kids
  ?@  iota  `(slav %uv iota)
  ~
::
::  +render-frozen: structural body morphed into #goon-root.
::  data-goon="root" wires up the keyboard nav at /new-oxal-init/goon-oxal/1/nav.
::
++  render-frozen
  |=  $:  =goad
          last-dl=(unit [rid=@uv payload=progress-payload])
          viewer=@p
          ours=@p
      ==
  ^-  manx
  =/  active-rid=(unit @uv)  (find-active-rid goad)
  =/  w=manx  (goad-to-manx:goon-goad-to-manx goad)
  =/  is-auth=?  ?|(=(viewer ours) !=(%pawn (clan:title viewer)))
  =/  header-manx=manx  (render-header is-auth viewer)
  =/  dl-manx=manx
    ?~  active-rid
      empty-status-live
    ?:  ?|  ?=(~ last-dl)
            !=(rid.u.last-dl u.active-rid)
        ==
        empty-status-live
    (render-status-live rid.u.last-dl payload.u.last-dl viewer ours)
  ;stack#goon-root
    =class  "wf"
    =data-goon  "root"
    ;*  [header-manx dl-manx c.w]
  ==
::
::  +render-header: root-level navigable page header. Its children are
::  the nord bird link and the auth control; Library/Settings remain
::  siblings at the root level.
::
++  render-header
  |=  [is-auth=? viewer=@p]
  ^-  manx
  =/  identity=tape  ?:(is-auth (weld "hello " (short-ship viewer)) (weld "guest " (short-ship viewer)))
  ;cluster
    =data-goon  "header"
    =data-goon-children  "2"
    =data-goon-prefer-child  "form,auth,link"
    =style  "--space: var(--el-s0); justify-content: space-between; align-items: start;"
    ;stack
      =style  "--space: var(--el-s-4);"
      ;h1(class "f0 fs5 bold lh1"): Plex-share
      ;a
        =href  "https://bird.howm.art"
        =class  "f-4 hover"
        =data-goon  "link"
        =data-goon-children  "0"
        =data-goon-interact  "link"
        ; by nord bird
      ==
    ==
    ;stack
      =style  "--space: var(--el-s-2); align-items: flex-end;"
      ;+  (render-eauth-login is-auth viewer)
      ;p(class "f1 fs-1"): {identity}
    ==
  ==
::
::  +render-status-live: live "downloading" strip morphed into #status-live.
::
::  Four-entity pipeline visualization (plex / proxy / relay / <ship>) per
::  design in MEMORY/WORK/20260531-181024_downloading-as-top-of-page-live-strip/.
::  Vine emits the structure + the static data attrs; CSS handles bars'
::  width via inline style data, animation @keyframes for ames-chunks
::  + chevrons, and the appear/collapse via #status-live:empty rule.
::  nav.js owns bytes/sec computation and ames-chunk-tick animation
::  triggering, both keyed off the data-* attrs in this fragment.
::
::  viewer is the authenticated browser session's ship (src.http-bowl).
::  ours is the ship serving the page (our.http-bowl) — for host-only
::  cancel detection. host comes from payload, initiator from payload.
::
++  render-status-live
  |=  [rid=@uv payload=progress-payload viewer=@p ours=@p]
  ^-  manx
  =/  total=@ud  total.payload
  =/  emitted=@ud  emitted.payload
  =/  received=@ud  received.payload
  =/  in-flight=@ud  ?:((gth emitted received) 0 (sub received emitted))
  ::  is-completed: total known AND every byte shipped. Triggers the
  ::  data-completed=true attr (animations halt, title/stats swap).
  =/  is-completed=?  &((gth total 0) =(emitted total))
  =/  pct-text=tape
    ?:  =(0 total)  "—"
    "{(a-co:co (div (mul emitted 100) total))}%"
  =/  ship-pct-num=@ud
    ?:  =(0 total)  0
    (div (mul emitted 100) total)
  =/  relay-pct-num=@ud
    ?:  =(0 total)  0
    (div (mul in-flight 100) total)
  =/  bytes-fmt=tape  (format-bytes emitted)
  =/  total-fmt=tape  (format-bytes total)
  =/  buffered-fmt=tape  (format-bytes received)
  =/  chunk-size-fmt=tape
    ?:  =(0 chunk-size.payload)  "?"
    ?:  =(0 (mod chunk-size.payload 1.048.576))
      "{(a-co:co (div chunk-size.payload 1.048.576))}MB"
    (format-bytes chunk-size.payload)
  =/  rid-tape=tape  (trip (scot %uv rid))
  =/  viewer-tape=tape  (short-ship initiator.payload)
  =/  is-host=?  =(viewer ours)
  =/  is-initiator=?  =(viewer initiator.payload)
  =/  may-cancel=?  &(!is-completed ?|(is-host is-initiator))
  =/  may-clear=?  is-host
  =/  status-phrase=tape  ?:(is-completed "finished downloading" "downloading")
  =/  header-text=tape  "{viewer-tape} is {status-phrase}"
  =/  bytes-pair=tape  "{bytes-fmt} / {total-fmt}"
  =/  chunk-now=@ud
    ?:  =(0 chunks.payload)  seq.payload
    ?:  (gth seq.payload chunks.payload)  chunks.payload
    seq.payload
  =/  chunks-text=tape
    "{(a-co:co chunk-now)}/{(a-co:co chunks.payload)} {chunk-size-fmt} chunks"
  =/  btn-count=@ud  (add ?:(may-cancel 1 0) ?:(may-clear 1 0))
  =/  btn-count-tape=tape  (a-co:co btn-count)
  ::  title-text: append the item index with kind-aware wording.
  =/  title-text=tape
    ?:  =('' item-index.payload)
      (trip display-name.payload)
    ?:  =(%episode item-kind.payload)
      "{(trip display-name.payload)} (Ep {(trip item-index.payload)})"
    ?:  =(%track item-kind.payload)
      "{(trip display-name.payload)} (Track {(trip item-index.payload)})"
    "{(trip display-name.payload)} ({(trip item-index.payload)})"
  =/  breadcrumb-tape=tape  (trip breadcrumb.payload)
  =/  has-breadcrumb=?  !=('' breadcrumb-tape)
  =/  has-context-thumb=?  !=('' context-thumb-url.payload)
  =/  base-actions=manx
    ;cluster.burn-strip-actions
      =data-goon  "actions"
      =style  "--space: var(--s3);"
      ;*  ?.  may-cancel  ~  ~[(render-strip-cancel-form rid-tape)]
      ;*  ?.  may-clear   ~  ~[(render-strip-clear-form ~)]
    ==
  =/  actions-manx=manx
    ?:  (gth btn-count 0)
      %+  add-attribute  ['data-goon-children' btn-count-tape]
      %+  add-attribute  ['data-goon-skip-single' "true"]
      base-actions
    base-actions
  =/  cover-d=[w=tape h=tape]
    ?:  ?|(=(0 item-thumb-width.payload) =(0 item-thumb-height.payload))
      ["200" "300"]
    [(a-co:co item-thumb-width.payload) (a-co:co item-thumb-height.payload)]
  =/  context-d=[w=tape h=tape]
    ?:  ?|(=(0 context-thumb-width.payload) =(0 context-thumb-height.payload))
      ["80" "120"]
    [(a-co:co context-thumb-width.payload) (a-co:co context-thumb-height.payload)]
  =/  base=manx
    ;div#status-live
      =data-goon  "root-section"
      =data-goon-children  "0"
      =data-goon-prefer-child  "actions,form"
      =data-goon-path  "/downloads"
      =data-rid  rid-tape
      =data-seq  (trip (scot %ud seq.payload))
      =data-emitted  (trip (scot %ud emitted))
      =data-received  (trip (scot %ud received))
      =data-total  (trip (scot %ud total))
      =data-started  (trip (scot %da started.payload))
      =class  "burn-strip"
      ;lane
        =style  "--max: 64rem; --gutters: 1rem;"
        ;stack
          =style  "--space: var(--s4);"
          ;h3.burn-strip-header: {header-text}
          ;cluster.burn-strip-cover-row
            =style  "--space: var(--s4);"
            ;*  ?:  =('' item-thumb-url.payload)  ~
                :~  ;cluster.burn-strip-art
                      =style  "--space: var(--s2); --align: stretch;"
                      ;*  ?.  has-context-thumb  ~
                        :~  ;shape.burn-context-thumb
                              =intrinsic  ""
                              ;img(src "{(trip context-thumb-url.payload)}", alt (trip context-label.payload), decoding "async", width w.context-d, height h.context-d);
                            ==
                        ==
                      ;shape.burn-main-thumb
                        =intrinsic  ""
                        ;img.burn-ship-cover(src "{(trip item-thumb-url.payload)}", alt (trip display-name.payload), decoding "async", width w.cover-d, height h.cover-d);
                      ==
                    ==
                ==
            ;stack.burn-strip-title
              =style  "--space: var(--s-2);"
              ;span.burn-strip-item: {title-text}
              ;*  ?.  has-breadcrumb  ~
                :~  ;span.burn-strip-breadcrumb: {breadcrumb-tape}
                ==
            ==
            ;stack.burn-strip-stats
              =style  "--space: var(--s-2);"
              ;span.burn-strip-bytes: {bytes-pair}
              ;span.burn-strip-elapsed;
            ==
          ==
          ;switcher.burn-strip-pipe
            =style  "--threshold: 36rem; --space: var(--s4);"
            ;box.burn-group.burn-group-local.b1.br3
              =style  "--padding: var(--s4);"
              ;cluster
                =style  "--space: var(--el-s-2); --align: center; --justify: center;"
                ;stack.burn-entity.burn-plex.bd2.br2
                  =style  "--space: var(--el-s-5); align-items: flex-start;"
                  ;span.burn-entity-name: plex
                  ;span.burn-entity-name: server
                ==
                ;div.burn-segment.burn-segment-line;
                ;stack.burn-entity.burn-proxy
                  =style  "--space: var(--s2); align-items: center;"
                  ;span.burn-entity-name: proxy
                  ;span.burn-entity-sub: requesting
                  ;span.burn-entity-dot;
                ==
              ==
            ==
            ;div.burn-segment.burn-segment-ames
              ;span.burn-segment-label: ames
              ;div.burn-ames-chunks;
            ==
            ;box.burn-group.burn-group-relay.b1.br3
              =style  "--padding: var(--s4);"
              ;stack.burn-entity.burn-relay
                =style  "--space: var(--s2); align-items: center;"
                ;span.burn-entity-name: relay
                ;span.burn-entity-sub: {chunks-text}
                ;div.burn-bar
                  =style  "--burn-bar-pct: {(a-co:co relay-pct-num)};"
                  ;div.burn-bar-fill;
                ==
              ==
            ==
            ;div.burn-segment.burn-segment-trickle
              ;div.burn-chevrons;
            ==
            ;box.burn-group.burn-group-ship.b1.br3
              =style  "--padding: var(--s4);"
              ;stack.burn-entity.burn-ship
                =style  "--space: var(--s2); align-items: center;"
                ;span.burn-entity-name: browser
                ;span.burn-ship-pct: {pct-text}
                ;div.burn-bar
                  =style  "--burn-bar-pct: {(a-co:co ship-pct-num)};"
                  ;div.burn-bar-fill;
                ==
              ==
            ==
          ==
          ;+  actions-manx
        ==
      ==
    ==
  =/  base2=manx
    ?:  (gth btn-count 0)
      (add-attribute ['data-goon-children' "1"] base)
    base
  ?.  is-completed  base2
  (add-attribute ['data-completed' "true"] base2)
::
::  +render-strip-cancel-form: live-strip "cancel" form for downloader+host.
::  data-on:submit must be emitted via add-attribute since Sail @tas names
::  can't carry the `:` separator (feedback_datastar_on_plugin_colon_syntax).
::
++  render-strip-cancel-form
  |=  rid-tape=tape
  ^-  manx
  =/  form-id=tape  "plex-form-cancel-{rid-tape}"
  %+  add-attribute  :-  'data-on:submit'
    "@post(location.pathname, \{contentType: 'form'})"
  ;form
    =id  form-id
    =data-goon  "form"
    =data-goon-children  "0"
    =class  "burn-strip-action burn-strip-cancel"
    ;input(type "hidden", name "path", value (weld "/downloads/" rid-tape));
    ;input(type "hidden", name "blade", value "act");
    ;input(type "hidden", name "value", value "cancel");
    ;button(type "submit", data-goon "action-destructive"): cancel
  ==
::
::  +render-strip-clear-form: live-strip "clear all" form, host-only.
::  Same colon-attribute caveat as the cancel form.
::
++  render-strip-clear-form
  |=  ~
  ^-  manx
  =/  form-id=tape  "plex-form-clear-streams"
  %+  add-attribute  :-  'data-on:submit'
    "@post(location.pathname, \{contentType: 'form'})"
  ;form
    =id  form-id
    =data-goon  "form"
    =data-goon-children  "0"
    =class  "burn-strip-action burn-strip-clear"
    ;input(type "hidden", name "path", value "/downloads");
    ;input(type "hidden", name "blade", value "act");
    ;input(type "hidden", name "value", value "clear-streams");
    ;button(type "submit", data-goon "action-destructive"): clear all
  ==
::
::  +format-bytes: human-readable byte size — "1.2 GB", "340 MB", "8.0 KB".
::  Three-decimal precision for the magnitude, picks the largest unit
::  that keeps the number under 1024.
::
++  format-bytes
  |=  n=@ud
  ^-  tape
  =/  kb=@ud  1.024
  =/  mb=@ud  (mul kb kb)
  =/  gb=@ud  (mul mb kb)
  ?:  (gte n gb)
    =/  whole=@ud  (div n gb)
    =/  frac=@ud  (div (mul (mod n gb) 10) gb)
    "{(a-co:co whole)}.{(a-co:co frac)} GB"
  ?:  (gte n mb)
    =/  whole=@ud  (div n mb)
    =/  frac=@ud  (div (mul (mod n mb) 10) mb)
    "{(a-co:co whole)}.{(a-co:co frac)} MB"
  ?:  (gte n kb)
    =/  whole=@ud  (div n kb)
    =/  frac=@ud  (div (mul (mod n kb) 10) kb)
    "{(a-co:co whole)}.{(a-co:co frac)} KB"
  "{(a-co:co n)} B"
::
::  +skeleton: initial page. Datastar's data-init re-fires the URL
::  with the datastar-request header so the SSE branch runs.
::
++  skeleton
  |=  [=goad viewer=@p ours=@p auth-target=(unit @t)]
  ^-  manx
  =/  is-auth=?  ?|(=(viewer ours) !=(%pawn (clan:title viewer)))
  ;html
    ;head
      ;meta(charset "UTF-8");
      ;meta
        =name  "viewport"
        =content  "width=device-width, initial-scale=1"
        ;*  ~
      ==
      ;title: plex — Hoon Native UI
      ;link(rel "stylesheet", href "/new-oxal-init/feather/1/style");
      ;link(rel "stylesheet", href "/new-oxal-init/every-layout/1/style");
      ;link(rel "stylesheet", href "/new-oxal-init/goon-oxal/1/style");
      ;script(type "module", src "/new-oxal-init/feather/1/datastar");
      ;script(src "/new-oxal-init/goon-oxal/1/nav", defer "");
    ==
    ;body.p5
      =data-init  "@get(location.pathname)"
      =data-burn-authenticated  ?:(is-auth "true" "false")
      ;stack
        ;+  (render-passcode-modal auth-target)
        ;+  (render-frozen goad ~ viewer ours)
      ==
    ==
  ==
::
::  +render-eauth-login: always-visible EAuth control. Eyre owns the
::  approval page; successful login returns to /new-oxal/plex.
::
++  render-eauth-login
  |=  [is-auth=? viewer=@p]
  ^-  manx
  ?:  is-auth
    (render-logout-link ~)
  ;form(method "POST", action "/~/login")
    =data-goon  "form"
    =data-goon-children  "2"
    ;input(type "hidden", name "redirect", value "/new-oxal/plex");
    ;input(type "hidden", name "eauth", value "");
    ;cluster
      =style  "--space: var(--el-s-2); align-items: center;"
      ;span
        =data-goon  "edit-field"
        =data-goon-children  "0"
        =data-goon-interact  "edit"
        ;input(data-goon "field", class "p-2 br2 bd1 b0 f1 fs-1", type "text", name "name", placeholder "~sampel-palnet", autocomplete "username", required "");
      ==
      ;span
        =data-goon  "edit-save"
        =data-goon-children  "0"
        =data-goon-interact  "action"
        ;button(data-goon "action", class "p-2 br2 bd1 b2 f1 fs-2 bold", type "submit"): login
        ==
      ==
  ==
::
++  render-logout-link
  |=  ~
  ^-  manx
  ;a
    =href  "/~/logout?redirect=/new-oxal/plex"
    =class  "inline-block p-2 br2 bd1 b2 f1 fs-2 bold"
    =data-goon  "auth"
    =data-goon-children  "0"
    =data-goon-interact  "link"
    ; logout
  ==
::
::  +render-passcode-modal: hidden by default. nav.js opens it instantly
::  for unauthenticated download clicks; auth-target opens it as a fallback
::  when Burn redirects a direct protected media request here.
::
++  render-passcode-modal
  |=  auth-target=(unit @t)
  ^-  manx
  =/  redirect-tape=tape  ?~(auth-target "" (trip u.auth-target))
  =/  modal-class=tape  ?~(auth-target "burn-pass-modal" "burn-pass-modal is-open")
  ;div#burn-pass-modal
    =class  modal-class
    =data-burn-modal  "passcode"
    =aria-hidden  ?~(auth-target "true" "false")
    ;div(class "burn-pass-backdrop fixed top0 left0 right0 bottom0 b10 o6 z-top", data-burn-pass-close "true");
    ;imposter(fixed "", contain "")
      =class  "z-top"
      ;box
        =class  "relative p4 bd1 br3 b1"
        ;cluster(style "justify-content: flex-end")
          ;box.bd1.br2.b1
            =style  "--padding: 0;"
            ;button
              =type  "button"
              =class  "br2 b2 f1"
              =style  "min-inline-size: 1rem; min-block-size: 1rem;"
              =data-burn-pass-close  "true"
              =aria-label  "Close"
              ; x
            ==
          ==
        ==
        ;lane(style "padding-inline-start: 1rem; padding-inline-end: 1rem")
          ;stack(style "--space: var(--el-s0)")
            ;p: Please enter the passcode here, or login, to download.

            ;i.o5: Not just anyone can have these.
            ;form(method "POST", action "/apps/burn/auth/passcode")
              =data-goon  "form"
              =data-goon-children  "2"
              ;input#burn-pass-redirect(type "hidden", name "redirect", value redirect-tape);
              ;cluster
                =style  "--space: var(--el-s-2); align-items: end;"
                ;span
                  =data-goon  "edit-field"
                  =data-goon-children  "0"
                  =data-goon-interact  "edit"
                  ;input#burn-pass-code(data-goon "field", class "p-2 br2 bd1 b0 f1 fs-1", name "code", placeholder "", autocomplete "off", required "");
                ==
                ;span
                  =data-goon  "edit-save"
                  =data-goon-children  "0"
                  =data-goon-interact  "action"
                  ;button(data-goon "action", type "submit", class "winter p-2 br2 bd1 b2 f1 fs-2 bold"): Continue
                ==
              ==
            ==
          ==
        ==
      ==
    ==
  ==
::
++  short-ship
  |=  who=@p
  ^-  tape
  =/  full=tape  (scow %p who)
  ?.  =(%pawn (clan:title who))  full
  =/  body=tape  (slag 1 full)
  =/  first=tape  (take-until '-' body)
  =/  last=tape   (last-after '-' body)
  ['~' (weld first ['_' last])]
::
++  take-until
  |=  [needle=@ chars=tape]
  ^-  tape
  ?~  chars  ~
  ?:  =(needle i.chars)  ~
  [i.chars $(chars t.chars)]
::
++  last-after
  |=  [needle=@ chars=tape]
  ^-  tape
  ?~  chars  ~
  ?:  =(needle i.chars)
    =/  rest=tape  $(chars t.chars)
    ?:  =(~ rest)  t.chars
    rest
  $(chars t.chars)
::
::  +handle-post: form-encoded body → stab → poke %burn %goon-event.
::  Required fields: path (e.g. /settings/hosting/url), blade (%edit |
::  %act | %add). value carries the iota for %edit/%add or the term for
::  %act. Default falls through to %edit so a bare path edit works.
::
++  handle-post
  |=  =http-bowl
  =/  m  (strand ,vase)
  ^-  form:m
  =/  vio  ~(. server http-bowl)
  =/  body=(map @t @t)  formencoded-body:vio
  =/  path-cord=@t  (~(gut by body) 'path' '')
  =/  blade-cord=@t  (~(gut by body) 'blade' '')
  =/  value-cord=@t  (~(gut by body) 'value' '')
  =/  =path  (rash path-cord stap)
  =/  =blade
    ?+  blade-cord  [%edit value-cord]
      %edit   [%edit value-cord]
      %add    [%add value-cord]
      %act    [%act `term`(slav %tas value-cord)]
    ==
  =/  =stab  [path blade]
  ::  Poke burn (NOT the vine's host agent oxal). poke-our:vio
  ::  routes to dap (oxal) and would land as %bad-poke %goon-event.
  ;<  ~  bind:m  (poke [our.http-bowl %burn] %goon-event !>(stab))
  ::  204 No Content with no content-type — Datastar inspects the
  ::  response's Content-Type and only acts on `text/html` (runs
  ::  datastar-patch-elements) or `application/json` (runs
  ::  datastar-patch-signals). Anything else is a no-op, which is
  ::  what we want: the actual UI update arrives via the separate
  ::  /goon SSE channel (loop arm scries + morphs #goon-root
  ::  whenever burn publishes), NOT via this POST response.
  ;<  ~  bind:m  (send-simple-payload:vio [204 ~] ~)
  (pure:m !>(~))
--
