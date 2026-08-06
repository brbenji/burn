::  /app/burn-tui.hoon — TUI host agent for burn
::
::  Bridges burn's goad surface to a %tui-frame fact stream over
::  Eyre SSE for the xterm.js renderer at /new-oxal/plex-tui. The agent is
::  intentionally thin post-T10: all nav state (focus, scroll, editing
::  draft) and all keystroke handling live in the browser. The agent's
::  sole job is to render a fresh %tui-frame whenever burn's tree
::  changes, deduping bursts via the pending-redraw flag.
::
::  Pipeline (output):
::    /tui watch:    scry goad → walk-frame → emit %tui-frame fact.
::    on-init:       subscribe burn /goon for %goon-redraw triggers.
::    on-agent:      on %goon-redraw, schedule a single Behn /redraw wake
::                   (Behn does not dedupe same-wire waits — see
::                   feedback_behn_same_wire_stacks.md — so we gate on
::                   pending-redraw and let the wake see the latest goad).
::    on-arvo:       wake fires, clear pending-redraw, emit one frame.
::
/-  goon, *tui-engine
/+  ghs=goad-to-homunculus-sail, default-agent, dbug
=,  goon
::
|%
+$  state-0  [%0 ~]
+$  state-1  [%1 focus=path]
+$  state-2  [%2 focus=path editing=(unit [at=path draft=tape])]
+$  state-3
  [%3 focus=path editing=(unit [at=path draft=tape]) pending-redraw=?]
+$  state-4  [%4 pending-redraw=?]
+$  state-old  $%(state-0 state-1 state-2 state-3 state-4)
+$  card  card:agent:gall
--
::
%-  agent:dbug
=|  state-4
=*  state  -
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
    hc    ~(. +> bowl)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  :~  :*  %pass  /burn-redraw  %agent
          [our.bowl %burn]  %watch  /goon
      ==
  ==
::
++  on-save  !>(state)
::
++  on-load
  |=  =vase
  ^-  (quip card _this)
  =/  old=state-old  !<(state-old vase)
  ::  Always clear pending-redraw on reload. The flag gates fact processing
  ::  while a Behn /redraw wake is in flight; reloads invalidate any pending
  ::  wake (Behn timers survive but the agent has just rebuilt its state
  ::  machine), so leaving it stuck at %.y silently no-ops every subsequent
  ::  fact and the UI freezes. Discovered 2026-05-13.
  =/  new-state=state-4  [%4 pending-redraw=%.n]
  ::  Idempotent re-subscribe to burn /goon. on-init only fires at
  ::  first install; reloads (or upstream restarts) can drop the watch
  ::  without us noticing. Leave-then-watch on every on-load guarantees
  ::  exactly one live subscription per reload.
  :_  this(state new-state)
  :~  [%pass /burn-redraw %agent [our.bowl %burn] %leave ~]
      :*  %pass  /burn-redraw  %agent
          [our.bowl %burn]  %watch  /goon
      ==
  ==
::
++  on-poke  on-poke:def
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?.  ?=([%tui ~] path)  (on-watch:def path)
  :_  this
  :~  [%give %fact ~ %tui-frame !>(render-frame:hc)]
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    wire  (on-agent:def wire sign)
      [%burn-redraw ~]
    ?-    -.sign
        %poke-ack    `this
        %watch-ack
      ?~  p.sign  `this
      ::  Watch nacked — typically because burn was mid-restart when our
      ::  re-watch landed (post-|nuke kick → immediate %watch arrives at
      ::  no-running-agent). Schedule a Behn retry; on-arvo /burn-redraw-retry
      ::  will leave-then-watch with fresh ducts.
      ~&  >>>  "burn-tui: /goon watch nacked → retrying in ~s5"
      :_  this
      :~  [%pass /burn-redraw-retry %arvo %b %wait (add now.bowl ~s5)]
      ==
        %kick
      :_  this
      :~  :*  %pass  /burn-redraw  %agent
              [our.bowl %burn]  %watch  /goon
          ==
      ==
        %fact
      ?.  =(%goon-redraw p.cage.sign)  `this
      ::  Defer the frame emit to the next Arvo event (same-event
      ::  .^(%gx …) reads pre-mutation burn state). Dedupe:
      ::  if a /redraw wait is already pending, do nothing — its
      ::  wake will see the latest burn state and emit one
      ::  frame covering N stacked redraws.
      ?:  pending-redraw  `this
      :_  this(pending-redraw %.y)
      :~  [%pass /redraw %arvo %b %wait now.bowl]
      ==
    ==
  ==
::
++  on-leave  on-leave:def
++  on-peek   on-peek:def
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?+  wire  (on-arvo:def wire sign-arvo)
      [%redraw ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ~?  >  &  "burn-tui: deferred goon-redraw → emit tui-frame"
    :_  this(pending-redraw %.n)
    :~  [%give %fact ~[/tui] %tui-frame !>(render-frame:hc)]
    ==
  ::
      [%burn-redraw-retry ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ~&  >  "burn-tui: retrying /goon watch on burn"
    :_  this
    :~  [%pass /burn-redraw %agent [our.bowl %burn] %leave ~]
        :*  %pass  /burn-redraw  %agent
            [our.bowl %burn]  %watch  /goon
        ==
    ==
  ==
++  on-fail   on-fail:def
--
::
::  Helper core — non-agent arms.
::
|_  =bowl:gall
::
::  +scry-goad: cross-desk scry of burn's /x/goon. Note that the
::  %gx care prepends %x to the path arg; do NOT include /x/.
::
++  scry-goad
  ^-  goad
  .^(goad %gx /(scot %p our.bowl)/burn/(scot %da now.bowl)/goon/noun)
::
::  +render-frame: scry the live goad and walk it into a tui-frame.
::  authored-width=80 is a hint to JS; the renderer re-truncates locally.
::
++  render-frame
  ^-  tui-frame
  =/  =goad  scry-goad
  =/  rows=(list tui-row)  (walk-frame:ghs goad ~ ~ 0)
  :*  rows=rows
      authored-width=`@ud`80
      total-height=(lent rows)
  ==
--
