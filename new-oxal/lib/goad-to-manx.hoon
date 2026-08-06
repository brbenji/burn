::  /lib/goad-to-manx.hoon — goad-shaped data tree → manx (HTML)
::
::  Renders a goad-shaped data tree into manx with data-goon-* attributes.
::  Attribute contract: see ATTRIBUTE-CONTRACT.md.
::
::  Usage from a vine:
::    /+  *vineio, *zozo, goad-to-manx
::    ;<  =data  bind:m  (scry ,data /gx/new-oxal/data/(scot %p our.bowl)/poots/noun)
::    =/  =manx  (render-tree:goad-to-manx %root data 0 ~)
::    (send-html-payload:vio page-with-manx)
::
/+  *zozo
::
|%
::  render-tree: goad data tree → manx
::
::  v8 — attribute contract edition
::  - Emits data-goon-children count on branch nodes
::  - Emits data-goon-homogeneous on detected collections
::  - Emits data-goon="node" on all traversable elements
::  - Filters framework metadata (~, edit, act, hint)
::
++  render-tree
  |=  [=iota =data depth=@ud ancestors=(list tape)]
  ^-  manx
  =/  d  ~(. do data)
  =/  dep=tape  (scow %ud (min depth 3))
  =/  label-class=tape
    ?:  =(0 depth)  "f0 fs5 bold lh1"
    ?:  =(1 depth)  "f0 fs4 bold lh2 bdb1 pb2"
    ?:  =(2 depth)  "f0 fs1 bold"
    "f2 fs-2 bold"
  =/  lab=tape
    ?:  ?=(%$ iota)  ""
    (node-summary iota)
  ::  val: full-text leaf flat (used for branch heading detection / lede).
  ::  node-to-tape avoids zozo node-summary's 50-byte truncation on long titles.
  =/  val=tape
    ?~  leaf.data  ""
    (node-to-tape u.leaf.data)
  ::  filter out ~/ framework metadata, /edit, /act, /hint, /info attrs
  ?:  |(=(lab "~") =(lab "edit") =(lab "act") =(lab "hint") =(lab "info"))
    ;span;
  =/  all-kids  kid-list:d
  ::  count real (non-metadata) children for data-goon-children attr
  =/  real-kid-count=@ud
    =/  rk  all-kids
    =/  cnt=@ud  0
    |-
    ?~  rk  cnt
    ?:  ?=(%$ -.i.rk)  $(rk t.rk)
    =/  rl=tape  (node-summary -.i.rk)
    ?:  |(=(rl "~") =(rl "edit") =(rl "act") =(rl "hint") =(rl "info"))
      $(rk t.rk)
    $(rk t.rk, cnt +(cnt))
  =/  children-attr=tape  (scow %ud real-kid-count)
  =/  has-edit=?
    =/  ek  all-kids
    |-
    ?~  ek  %.n
    ?:  ?=(%$ -.i.ek)  $(ek t.ek)
    ?:  =("edit" (node-summary -.i.ek))  %.y
    $(ek t.ek)
  ::  See ATTRIBUTE-CONTRACT.md "Hint — renderer upgrades" for the term
  ::  taxonomy. hint-terms collects every term tape from every /hint child;
  ::  the four flags below scan it once each.
  =/  hint-terms=(list tape)
    =/  hk  all-kids
    =/  acc=(list tape)  ~
    |-  ^-  (list tape)
    ?~  hk  acc
    ?:  ?=(%$ -.i.hk)  $(hk t.hk)
    ?.  =("hint" (node-summary -.i.hk))  $(hk t.hk)
    =/  hint-d  ~(. do +.i.hk)
    =/  hint-kids  kid-list:hint-d
    =/  new-acc=(list tape)
      =/  ik  hint-kids
      =/  inner-acc=(list tape)  acc
      |-  ^-  (list tape)
      ?~  ik  inner-acc
      ?:  ?=(%$ -.i.ik)  $(ik t.ik)
      =/  term=tape  (node-summary -.i.ik)
      $(ik t.ik, inner-acc [term inner-acc])
    $(hk t.hk, acc new-acc)
  =/  has-image-term=?
    =/  ts  hint-terms
    |-  ^-  ?
    ?~  ts  %.n
    ?:  =(i.ts "image")  %.y
    $(ts t.ts)
  =/  has-image-role=?
    =/  ts  hint-terms
    |-  ^-  ?
    ?~  ts  %.n
    ?:  |(=(i.ts "poster") =(i.ts "avatar") =(i.ts "banner") =(i.ts "cover") =(i.ts "album"))
      %.y
    $(ts t.ts)
  =/  has-hint-image=?  ?|(has-image-term has-image-role)
  =/  has-player-term=?
    =/  ts  hint-terms
    |-  ^-  ?
    ?~  ts  %.n
    ?:  =(i.ts "player")  %.y
    $(ts t.ts)
  =/  hint-protocol=tape
    =/  ts  hint-terms
    |-  ^-  tape
    ?~  ts  ""
    ?:  |(=(i.ts "dash") =(i.ts "hls") =(i.ts "preview"))
      i.ts
    $(ts t.ts)
  =/  has-hint-player=?  ?|(has-player-term !=(hint-protocol ""))
  ::  /info reading: when a branch has an /info reserved child, extract its
  ::  leaf as the body slot. Mirrors %info formal goad attr per
  ::  GOON-PROTOCOL.md and ATTRIBUTE-CONTRACT.md "Info — body text".
  ::  Output side emits data-goon="description" (the existing body-slot class
  ::  with the 5lh CSS clamp). node-to-tape returns full text, escaping the
  ::  50-byte node-summary cap. Subtree /info falls back to "" here; Layer 0
  ::  generic stack render of /info subtrees is deferred.
  ::
  =/  info-text=tape
    =/  ik  all-kids
    |-  ^-  tape
    ?~  ik  ""
    ?:  ?=(%$ -.i.ik)  $(ik t.ik)
    ?.  =("info" (node-summary -.i.ik))  $(ik t.ik)
    =/  info-data=_data  +.i.ik
    ?~  leaf.info-data  ""
    (node-to-tape u.leaf.info-data)
  ::  description element built once, spliced into branch outputs after
  ::  the heading and before clean-kids. Empty marl when no /info child.
  =/  info-marl=marl
    ?:  =(info-text "")  ~
    =/  info-elem=manx  ;p(data-goon "description"): {info-text}
    ~[info-elem]
  =/  act-buttons=marl
    =/  ak  all-kids
    |-
    ?~  ak  ~
    ?:  ?=(%$ -.i.ak)  $(ak t.ak)
    ?.  =("act" (node-summary -.i.ak))  $(ak t.ak)
    =/  act-d  ~(. do +.i.ak)
    =/  act-kids  kid-list:act-d
    =/  section=tape
      ?:  (lth depth 2)  ""
      (snag 1 ancestors)
    =/  btns  act-kids
    |-  ^-  marl
    ?~  btns  ~
    =/  act-name=tape
      ?:  ?=(%$ -.i.btns)  ""
      (node-summary -.i.btns)
    :_  $(btns t.btns)
    ?:  =(act-name "delete")
      ;form(data-goon "form", method "post", action "?action={act-name}")
        ;input(type "hidden", name "section", value section);
        ;input(type "hidden", name "target", value lab);
        ;button(data-goon "action-destructive", class "p-2 br2 bd1 b-1 f-1 fs-2 bold", type "submit"): {act-name}
      ==
    ;form(data-goon "form", method "post", action "?action={act-name}")
      ;input(type "hidden", name "section", value section);
      ;input(type "hidden", name "target", value lab);
      ;button(data-goon "action", class "p-2 br2 bd1 b2 f1 fs-2 bold", type "submit"): {act-name}
    ==
  ::  Dynamically wrap action buttons. If there is only 1 button,
  ::  remove the cluster wrapper so the user doesn't have to double-drill.
  =/  action-container=marl
    ?:  =(0 (lent act-buttons))  ~
    ?:  =(1 (lent act-buttons))  act-buttons
    :~  ;cluster(data-goon "actions", class "pt2 bdt1")
          ;*  act-buttons
        ==
    ==
  ::
  =/  kid-manxes=marl
    %+  turn  all-kids
    |=  [i=^iota dd=_data]
    (render-tree i dd +(depth) (snoc ancestors lab))
  ::  Promote media-bearing kids to the top of the kid stack — a /movie
  ::  branch with poster + year renders the poster first regardless of
  ::  where /poster sorts among siblings by iota order.
  =/  is-media-kid
    |=  kid-data=_data
    ^-  ?
    ::  a %mime leaf with image/audio/video category counts as media
    ::  without needing a /hint child — self-describing.
    =/  leaf-mime-media=?
      ?~  leaf.kid-data  %.n
      =/  ln  u.leaf.kid-data
      ?.  ?=([%mime *] ln)  %.n
      ?=(^ (mime-category p.mime.ln))
    ?:  leaf-mime-media  %.y
    =/  kd  ~(. do kid-data)
    =/  kk  kid-list:kd
    |-  ^-  ?
    ?~  kk  %.n
    ?:  ?=(%$ -.i.kk)  $(kk t.kk)
    ?.  =("hint" (node-summary -.i.kk))  $(kk t.kk)
    =/  hint-d  ~(. do +.i.kk)
    =/  hint-kids  kid-list:hint-d
    =/  found=?
      =/  ik  hint-kids
      |-  ^-  ?
      ?~  ik  %.n
      ?:  ?=(%$ -.i.ik)  $(ik t.ik)
      =/  term=tape  (node-summary -.i.ik)
      ?:  ?|  =(term "image")
              =(term "poster")
              =(term "avatar")
              =(term "banner")
              =(term "cover")
              =(term "album")
              =(term "player")
              =(term "dash")
              =(term "hls")
              =(term "preview")
          ==
        %.y
      $(ik t.ik)
    ?:  found  %.y
    $(kk t.kk)
  =/  media-flags=(list ?)
    %+  turn  all-kids
    |=  [i=^iota dd=_data]
    ^-  ?
    ?:  ?=(%$ i)  %.n
    =/  rl=tape  (node-summary i)
    ?:  |(=(rl "~") =(rl "edit") =(rl "act") =(rl "hint") =(rl "info"))
      %.n
    (is-media-kid dd)
  =/  partition=[media=marl other=marl]
    =/  km  kid-manxes
    =/  mf  media-flags
    |-  ^-  [media=marl other=marl]
    ?~  km  [~ ~]
    ?~  mf  [~ ~]
    =/  rest  $(km t.km, mf t.mf)
    ?:  ?=([%span ~] g.i.km)  rest
    ?:  i.mf  [[i.km media.rest] other.rest]
    [media.rest [i.km other.rest]]
  =/  media-marl=marl      media.partition
  =/  non-media-marl=marl  other.partition
  ::  clean-kids retained for the leaf-path empty-check guard below.
  =/  clean-kids=marl  (weld media-marl non-media-marl)
  ::  Cards with media use Every Layout's sidebar directly; data-goon stays
  ::  focused on navigation/state roles.
  =/  has-media-kid=?  (lien media-flags |=(f=? f))
  ::  no label, no value: just stack children
  ?:  &(=(lab "") =(val ""))
    ;stack(data-goon "collection", data-goon-children children-attr)
      ;*  clean-kids
    ==
  ::  LEAF: no children AND no /info body — render as field.
  ::  Without the info-text guard, a node whose only child is /info would
  ::  fall through to leaf rendering (clean-kids is empty after the entry
  ::  guard filters /info to ;span;), losing the description body slot.
  ?:  ?&  ?=(~ clean-kids)
          =(info-text "")
      ==
    =/  section=tape
      ?:  (lth depth 2)  ""
      (snag 1 ancestors)
    =/  target=tape
      ?:  (lth depth 3)  ""
      (snag 2 ancestors)
    ::  no leaf value: label only
    ?~  leaf.data
      ;p(data-goon "label", data-goon-depth dep, class label-class): {lab}
    =/  nod  u.leaf.data
    ::  %mime image/audio/video: emit inline media via data: URL.
    ::  Unknown mime types fall through to the type-tag dispatch
    ::  below, which renders them as a "mime: TYPE (N bytes)" span
    ::  rather than an element with a broken src.
    =/  mime-render=(unit manx)
      ?.  ?=([%mime *] nod)  ~
      =/  cat  (mime-category p.mime.nod)
      ?~  cat  ~
      =/  m   mime.nod
      =/  mtyp=tape  (trip (en-mite:mimes:html p.m))
      =/  b64=tape  (trip (en:base64:mimes:html q.m))
      =/  data-url=tape  :(weld "data:" mtyp ";base64," b64)
      =/  rendered=manx
        ?-  u.cat
            %image
          ;p(data-goon "node", data-goon-children "0")
            ;strong(data-goon "label", class "f2 bold"): {lab}:
            ;shape
              =data-goon  "image"
              =intrinsic  ""
              ;img(src data-url, alt lab);
            ==
          ==
        ::
            %audio
          ;p(data-goon "node", data-goon-children "0")
            ;strong(data-goon "label", class "f2 bold"): {lab}:
            ;audio(data-goon "player", class "wf mwf", controls "", src data-url);
          ==
        ::
            %video
          ;p(data-goon "node", data-goon-children "0")
            ;strong(data-goon "label", class "f2 bold"): {lab}:
            ;video(data-goon "player", class "wf mwf br2 bd1 b1", style "max-width: 24rem; aspect-ratio: 16 / 9;", controls "", src data-url);
          ==
        ==
      `rendered
    ?^  mime-render  u.mime-render
    ::  hint/image: render as intrinsic media. The source image determines
    ::  the displayed ratio; goon only marks the wrapper as a nav leaf.
    ?:  has-hint-image
      ;div(data-goon "node", data-goon-children "0")
        ;strong(data-goon "label", class "f2 bold"): {lab}:
        ;shape
          =data-goon  "image"
          =intrinsic  ""
          ;img(src val, alt lab);
        ==
      ==
    ::  hint/player: render as <video> with controls. `val` is the full URL.
    ::  <video> is a superset element; modern browsers play audio sources
    ::  inside it correctly. Three branches because we don't want blank
    ::  data-goon-protocol="" leaking when no protocol hint is present.
    ::  %preview adds autoplay/muted/loop for thumbnail-style previews.
    ?:  has-hint-player
      ?:  =(hint-protocol "preview")
        ;div(data-goon "node", data-goon-children "0")
          ;strong(data-goon "label", class "f2 bold"): {lab}:
          ;video(data-goon "player", class "wf mwf br2 bd1 b1", style "max-width: 24rem; aspect-ratio: 16 / 9;", controls "", autoplay "", muted "", loop "", data-goon-protocol "preview", src val);
        ==
      ?:  =(hint-protocol "")
        ;div(data-goon "node", data-goon-children "0")
          ;strong(data-goon "label", class "f2 bold"): {lab}:
          ;video(data-goon "player", class "wf mwf br2 bd1 b1", style "max-width: 24rem; aspect-ratio: 16 / 9;", controls "", src val);
        ==
      ;div(data-goon "node", data-goon-children "0")
        ;strong(data-goon "label", class "f2 bold"): {lab}:
        ;video(data-goon "player", class "wf mwf br2 bd1 b1", style "max-width: 24rem; aspect-ratio: 16 / 9;", controls "", data-goon-protocol hint-protocol, src val);
      ==
    ::  editable field: render as form with input. `val` already holds full text.
    ?:  has-edit
      ;form(data-goon "form", method "post", action "?action=edit")
        ;input(type "hidden", name "section", value section);
        ;input(type "hidden", name "target", value target);
        ;input(type "hidden", name "field", value lab);
        ;cluster
          ;strong(data-goon "label", class "f2 bold"): {lab}:
          ;input(data-goon "field", class "p-2 br2 bd1 b0 f1 fs-1", type "text", name "value", value val);
          ;button(data-goon "action", class "p-2 br2 bd1 b2 f1 fs-2 bold", type "submit"): Save
        ==
      ==
    ::  TYPE-TAG DISPATCH on -.u.leaf.data
    ::  Compute (data-goon class, value text, is-url?) per leaf type, then
    ::  assemble once below. URL detection on %t cords is the single
    ::  string-content exception (Hoon has no URL aura).
    ::
    =/  vparts=[vcls=tape vtxt=tape vurl=?]
      ::  bare term iota: render as text value
      ?@  nod  ["value" (trip nod) %.n]
      ::  %t cord: handled separately so URL detection can live here as the
      ::  single string-content exception (Hoon has no URL aura)
      ?:  ?=([%t @] nod)
        =/  txt=tape  (trip t.nod)
        ?:  ?&  (gte (lent txt) 8)
                |(=("https://" (scag 8 txt)) =("http://" (scag 7 txt)))
            ==
          ["link" txt %.y]
        ["value" txt %.n]
      ::  every other typed leaf: dispatch on the type tag.
      ::  Numeric/date/ship/ip arms mirror zero.hoon's print-aota table; if
      ::  that helper is ever exposed at this scope, collapse these to one
      ::  default that delegates. For now, inline so the value-class column
      ::  (value-ship/value-date/etc.) lives in one place.
      ?+    -.nod  ["value" (node-summary nod) %.n]
          %ta  ["value" (trip ta.nod) %.n]
          %p   ["value-ship" (scow %p p.nod) %.n]
          %q   ["value-ship" (scow %q q.nod) %.n]
          %da  ["value-date" (scow %da da.nod) %.n]
          %dr  ["value-duration" (scow %dr dr.nod) %.n]
          %f   ?:(f.nod ["value-yes" "yes" %.n] ["value-no" "no" %.n])
          %n   ["value" "—" %.n]
          ::  unknown %mime: image/audio/video already short-circuited above.
          %mime  ["value" :(weld "mime: " (trip (en-mite:mimes:html p.mime.nod)) " (" (scow %ud p.q.mime.nod) " bytes)") %.n]
          ?(%ud %ui %ux %uv %uw %ub %uc)  ["value" (node-summary nod) %.n]
          ?(%si %sd %sx %sb %sc %sv %sw)  ["value" (node-summary nod) %.n]
          ?(%rs %rd %rh %rq)              ["value" (node-summary nod) %.n]
          ?(%if %is)                      ["value" (node-summary nod) %.n]
      ==
    =/  value-class=tape
      ?:  =(vcls.vparts "value-ship")  "f-4 mono fs-1"
      ?:  |(=(vcls.vparts "value-date") =(vcls.vparts "value-duration"))  "f2 mono fs-1"
      ?:  =(vcls.vparts "value-yes")  "f-3 bold"
      ?:  =(vcls.vparts "value-no")  "f3"
      "f2"
    ::  assemble: <a> for URLs, <span data-goon=class> otherwise
    ?:  vurl.vparts
      ;p(data-goon "node", data-goon-children "0")
        ;strong(data-goon "label", class "f2 bold"): {lab}:
        ;a(data-goon "link", class "underline f-4", href vtxt.vparts, target "_blank"): {" "}{vtxt.vparts}
      ==
    ;p(data-goon "node", data-goon-children "0")
      ;strong(data-goon "label", class "f2 bold"): {lab}:
      ;span(data-goon vcls.vparts, class value-class): {" "}{vtxt.vparts}
    ==
  ::  heading: prefer leaf value (lede) over iota key for branch nodes
  =/  hed=tape  ?:(=(val "") lab val)
  ::  Phase 2(f) palm refactor: media-bearing cards compose as
  ::  Sidebar+Cluster (Every Layout primitives) — sidebar handles the
  ::  poster|metadata responsive switch intrinsically (character-based
  ::  threshold, no @media/@container), cluster spans full card width
  ::  for actions whether sidebar is horizontal or wrapped vertical.
  ::
  ::  Check if this node is explicitly tagged as a card by the backend
  =/  is-card=?
    =/  kk  all-kids
    |-  ^-  ?
    ?~  kk  %.n
    ?:  ?=(%$ -.i.kk)  $(kk t.kk)
    ?.  =("key" (node-summary -.i.kk))  $(kk t.kk)
    =/  key-data=_data  +.i.kk
    ?~  leaf.key-data  %.n
    =("library-item" (node-to-tape u.leaf.key-data))
  ::
  ::  BRANCH: Render as a card ONLY if it is a true library item.
  ?:  is-card
    ?:  has-media-kid
      =/  meta-marl=marl  (weld info-marl non-media-marl)
      =/  meta-stack=manx
        ?:  =(hed "")
          ;stack
            ;*  meta-marl
          ==
        ;stack
          ;h3(data-goon "label", data-goon-depth dep, class label-class): {hed}
          ;*  meta-marl
        ==
      ;box(data-goon "card", data-goon-depth dep, data-goon-children children-attr, class "b1 bd1 br3")
        ;stack
          ;sidebar
            =style  "--side-width: 12rem; --content-min: 30ch; --space: var(--el-s0);"
            ;stack
              ;*  media-marl
            ==
            ;+  meta-stack
          ==
          ;*  action-container
        ==
      ==
    ?:  =(hed "")
      ;box(data-goon "card", data-goon-depth dep, data-goon-children children-attr, class "b1 bd1 br3")
        ;stack
          ;*  info-marl
          ;*  clean-kids
          ;*  action-container
        ==
      ==
    ;box(data-goon "card", data-goon-depth dep, data-goon-children children-attr, class "b1 bd1 br3")
      ;stack
        ;h3(data-goon "label", data-goon-depth dep, class label-class): {hed}
        ;*  info-marl
        ;*  clean-kids
        ;*  action-container
      ==
    ==
  ::  BRANCH at depth 1: section with heading
  ?:  =(depth 1)
    ::  check homogeneity for grid detection
    =/  use-grid=?
      =/  first-n=@ud  0
      =/  count=@ud  0
      =/  matched=?  %.y
      =/  rem  all-kids
      |-
      ?~  rem
        &(matched (gth count 1) (gth first-n 0))
      =/  ri=^iota  -.i.rem
      =/  rd=_data  +.i.rem
      ?:  ?=(%$ ri)
        $(rem t.rem)
      =/  rl=tape  (node-summary ri)
      ?:  |(=(rl "~") =(rl "edit") =(rl "act") =(rl "hint") =(rl "info"))
        $(rem t.rem)
      =/  rd-door  ~(. do rd)
      =/  gkids  kid-list:rd-door
      =/  real-n=@ud  0
      =/  gk  gkids
      |-  ^-  ?
      ?~  gk
        =/  n  real-n
        ?:  =(count 0)
          ^$(rem t.rem, first-n n, count 1)
        ^$(rem t.rem, count +(count), matched &(matched =(first-n n)))
      =/  grl=tape
        ?:  ?=(%$ -.i.gk)  ""
        (node-summary -.i.gk)
      ?:  |(=(grl "~") =(grl "edit") =(grl "act") =(grl "hint") =(grl "info"))
        $(gk t.gk)
      $(gk t.gk, real-n +(real-n))
    ::  homogeneous attr for CSS/JS palm detection
    =/  homo-attrs=marl
      ?:  use-grid
        ~[;attr(data-goon-homogeneous "");]
      ~
    ?:  =(hed "")
      ?:  use-grid
        ;stack
          ;*  info-marl
          ;grid(data-goon "collection", data-goon-children children-attr, data-goon-homogeneous "")
            ;*  clean-kids
          ==
        ==
      ;stack(data-goon "collection", data-goon-children children-attr)
        ;*  info-marl
        ;*  clean-kids
      ==
    ?:  use-grid
      ;stack(data-goon-children children-attr)
        ;h2(data-goon "label", data-goon-depth "1", class "f0 fs4 bold lh2 bdb1 pb2"): {hed}
        ;*  info-marl
        ;grid(data-goon "collection", data-goon-homogeneous "")
          ;*  clean-kids
        ==
      ==
    ;stack(data-goon-children children-attr)
      ;h2(data-goon "label", data-goon-depth "1", class "f0 fs4 bold lh2 bdb1 pb2"): {hed}
      ;*  info-marl
      ;*  clean-kids
    ==
  ::  BRANCH at depth 0: root stack
  ?:  =(depth 0)
    ;stack(data-goon "root", data-goon-depth "0", data-goon-nav "dormant", data-goon-children children-attr)
      ;*  info-marl
      ;*  clean-kids
    ==
  ::  deeper: stack with heading
  ?:  =(hed "")
    ;stack(data-goon "collection", data-goon-children children-attr)
      ;*  info-marl
      ;*  clean-kids
    ==
  ;stack(data-goon "collection", data-goon-children children-attr)
    ;h2(data-goon "label", class label-class): {hed}
    ;*  info-marl
    ;*  clean-kids
  ==
::  node-to-tape: full-text extraction from a leaf node.
::
::  Use INSTEAD of node-summary for any user-visible cord/knot. zozo's
::  node-summary is a 50-byte-capped display helper; this returns the
::  full text via `trip` for %t and %ta.
::
::  Lifted from views/rss-palm.hoon. Falls back to node-summary for any
::  other type tag — that's the right move for numerics, ships, dates
::  whose printed forms ARE the canonical display.
::
++  node-to-tape
  |=  nod=node
  ^-  tape
  ?@  nod  (trip nod)
  ?+  -.nod  (node-summary nod)
    %t   (trip t.nod)
    %ta  (trip ta.nod)
  ==
::  ~ signals "fall back to text" — caller routes unknown types through
::  the type-tag dispatch instead of emitting a broken <img>/<audio>/<video>.
::
++  mime-category
  |=  mt=mite
  ^-  (unit ?(%image %audio %video))
  ?~  mt  ~
  ?+  i.mt  ~
    %image  `%image
    %audio  `%audio
    %video  `%video
  ==
--
