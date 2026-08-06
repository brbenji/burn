::  /lib/goon-goad-to-manx.hoon — shared helpers for goon $goad renderers
::
::  Owns generic $goad inspection, path/id helpers, slot helpers, recursive
::  goad rendering, and shared goon form affordances. App-specific live
::  islands stay in the calling vine.
::::
/-  goon
/+  *zozo
=,  goon
|%
::
::  +iota-to-knot: render a goon iota as a knot path segment.
::
++  iota-to-knot
  |=  =iota
  ^-  @ta
  ?@  iota  iota
  (scot p.iota q.iota)
::
::  +path-to-id: converts a stab path to a safe HTML id attribute
::  (e.g. /library/sections/1 -> -library-sections-1).
::
++  path-to-id
  |=  p=^path
  ^-  tape
  =/  raw=tape  (trip (spat p))
  %+  turn  raw
  |=  c=@tD
  ?:(=('/' c) '-' c)
::
::  Attr readers.
::
++  attr-lede
  |=  [attrs=(list attr) =iota]
  ^-  tape
  |-  ^-  tape
  ?~  attrs
    ?@  iota  (trip iota)
    "?"
  ?:  ?=(%lede -.i.attrs)  (trip p.i.attrs)
  $(attrs t.attrs)
::
++  attr-info
  |=  attrs=(list attr)
  ^-  (unit @t)
  ?~  attrs  ~
  ?:  ?=(%info -.i.attrs)  `p.i.attrs
  $(attrs t.attrs)
::
++  attr-has-edit
  |=  attrs=(list attr)
  ^-  ?
  ?~  attrs  %.n
  ?:  ?=(%edit -.i.attrs)  %.y
  $(attrs t.attrs)
::
++  attr-value
  |=  attrs=(list attr)
  ^-  (unit @t)
  ?~  attrs  ~
  ?:  ?=(%value -.i.attrs)
    =*  io  p.i.attrs
    ?@  io  `io
    `(scot p.io q.io)
  $(attrs t.attrs)
::
++  render-udon
  |=  body=@t
  ^-  manx
  ::  Keep this hot path parser-free. The markdown parser can dominate
  ::  full-tree SSE renders for long article bodies; Feather's pre-wrap
  ::  preserves the authored paragraph rhythm without invoking it.
  ;div(class "goon-article-body f3 lh5 pre-wrap"): {(trip body)}
::
++  attr-edit-cur
  |=  [attrs=(list attr) =iota]
  ^-  (unit @t)
  =/  has-edit=?  (attr-has-edit attrs)
  ?.  has-edit  ~
  =/  val=(unit @t)  (attr-value attrs)
  ?^  val  val
  ?@  iota  `iota
  `(scot p.iota q.iota)
::
++  attr-acts
  |=  attrs=(list attr)
  ^-  (list act)
  ?~  attrs  ~
  ?:  ?=(%act -.i.attrs)  p.i.attrs
  $(attrs t.attrs)
::
++  partition-act
  |=  [want=term acts=(list act)]
  ^-  [match=(unit act) rest=(list act)]
  =|  acc=(list act)
  =/  found=(unit act)  ~
  =/  as  acts
  |-  ^-  [(unit act) (list act)]
  ?~  as  [found (flop acc)]
  ?:  =(want p.i.as)
    ?:  ?=(~ found)
      $(as t.as, found `i.as)
    $(as t.as)
  $(as t.as, acc [i.as acc])
::
++  attr-has-add
  |=  attrs=(list attr)
  ^-  ?
  ?~  attrs  %.n
  ?:  ?=(%add -.i.attrs)  %.y
  $(attrs t.attrs)
::
++  attr-has-lede
  |=  attrs=(list attr)
  ^-  ?
  ?~  attrs  %.n
  ?:  ?=(%lede -.i.attrs)  %.y
  $(attrs t.attrs)
::
::  Slot partition helpers.
::
++  partition-by-iota
  |=  [want=@tas kids=(list goad)]
  ^-  [match=(unit goad) rest=(list goad)]
  =|  acc=(list goad)
  =/  found=(unit goad)  ~
  =/  ks  kids
  |-  ^-  [(unit goad) (list goad)]
  ?~  ks  [found (flop acc)]
  =/  ki  -.i.ks
  ?:  ?&  ?=(~ found)
          ?&(?=(@ ki) =(want `@tas`ki))
      ==
    $(ks t.ks, found `i.ks)
  $(ks t.ks, acc [i.ks acc])
::
++  partition-poster
  |=  kids=(list goad)
  ^-  [poster=(unit goad) rest=(list goad)]
  =+  parts=(partition-by-iota %poster kids)
  [match.parts rest.parts]
::
++  partition-summary
  |=  kids=(list goad)
  ^-  [summary=(unit goad) rest=(list goad)]
  =+  parts=(partition-by-iota %summary kids)
  [match.parts rest.parts]
::
++  partition-tagline
  |=  kids=(list goad)
  ^-  [tagline=(unit goad) rest=(list goad)]
  =+  parts=(partition-by-iota %tagline kids)
  [match.parts rest.parts]
::
++  partition-download
  |=  kids=(list goad)
  ^-  [download=(unit goad) rest=(list goad)]
  =+  parts=(partition-by-iota %download kids)
  [match.parts rest.parts]
::
::  Native action payloads pair a normal goon %act with a same-named child
::  whose %value carries renderer-native data. Example: %act %download plus
::  child %download value "/apps/burn/download/..." lets the web renderer
::  choose <a download>, while other renderers may keep the plain event.
::
++  partition-action-payload
  |=  [name=@tas acts=(list act) kids=(list goad)]
  ^-  [action=(unit act) payload=(unit goad) rest-acts=(list act) rest-kids=(list goad)]
  =+  ap=(partition-act name acts)
  =+  kp=(partition-by-iota name kids)
  [match.ap match.kp rest.ap rest.kp]
::
++  partition-media-slots
  |=  kids=(list goad)
  ^-  [poster=(unit goad) tagline=(unit goad) summary=(unit goad) download=(unit goad) rest=(list goad)]
  =+  pst=(partition-poster kids)
  =+  dl=(partition-download rest.pst)
  =+  tag=(partition-tagline rest.dl)
  =+  sum=(partition-summary rest.tag)
  [poster.pst tagline.tag summary.sum download.dl rest.sum]
::
++  partition-drill-wrapper
  |=  kids=(list goad)
  ^-  [drill=(unit goad) rest=(list goad)]
  =|  acc=(list goad)
  =/  ks  kids
  |-  ^-  [(unit goad) (list goad)]
  ?~  ks  [~ (flop acc)]
  =/  child-kids=(list goad)  +>.i.ks
  ?:  ?&(!=(~ child-kids) (all-have-lede child-kids))
    [`i.ks (weld (flop acc) t.ks)]
  $(ks t.ks, acc [i.ks acc])
::
++  slot-value
  |=  g=goad
  ^-  @t
  (fall (attr-value +<.g) '')
::
++  slot-text
  |=  slot=(unit goad)
  ^-  tape
  ?~  slot  ""
  (trip (slot-value u.slot))
::
++  poster-url
  |=  g=goad
  ^-  @t
  (slot-value g)
::
++  poster-wide
  |=  g=goad
  ^-  ?
  =/  url=tape  (trip (poster-url g))
  ?&  !=(~ (find "w=320" url))
      !=(~ (find "h=180" url))
  ==
::
++  kids-have-wide-posters
  |=  kids=(list goad)
  ^-  ?
  ?~  kids  %.n
  =+  parts=(partition-poster +>.i.kids)
  ?:  ?=(^ poster.parts)
    ?:  (poster-wide u.poster.parts)  %.y
    $(kids t.kids)
  $(kids t.kids)
::
::  Layout classification helpers. These do not render.
::
++  all-have-lede
  |=  kids=(list goad)
  ^-  ?
  (levy kids |=(g=goad (attr-has-lede +<.g)))
::
++  all-leaves
  |=  kids=(list goad)
  ^-  ?
  %+  levy  kids
  |=  g=goad
  =+  parts=(partition-poster +>.g)
  ?=(~ rest.parts)
::
++  kids-palm-able
  |=  kids=(list goad)
  ^-  ?
  ?:  (lth (lent kids) 7)  %.n
  (all-have-lede kids)
::
++  view-mode
  |=  g=goad
  ^-  ?(%one-pager %palm %accordion %stack)
  =+  ^=  parts
      %.  +>.g
      partition-poster
  =/  kids=(list goad)  rest.parts
  ?~  kids  %one-pager
  ?:  ?&(!=(%about -.g) ?=([* ~] kids))  (view-mode i.kids)
  ?:  (kids-palm-able kids)  %palm
  ?:  ?&((all-have-lede kids) !(all-leaves kids))  %accordion
  %stack
::
::  Generic goon form affordances. Forms post to the current route so the
::  renderer does not need to know which vine is serving it.
::
++  render-edit-form
  |=  [p=^path cur=@t]
  ^-  manx
  =/  path-tape=tape  (trip (spat p))
  =/  cur-tape=tape  (trip cur)
  =/  form-id=tape  (weld "form-edit" (path-to-id p))
  %+  add-attribute  :-  'data-on:submit'
    "@post(location.pathname, \{contentType: 'form'})"
  ;form
    =id  form-id
    =data-goon  "form"
    =data-goon-children  "2"
    ;input(type "hidden", name "path", value path-tape);
    ;input(type "hidden", name "blade", value "edit");
    ;cluster
      ;span
        =data-goon  "edit-field"
        =data-goon-children  "0"
        =data-goon-interact  "edit"
        ;input(data-goon "field", class "p-2 br2 bd1 b0 f1 fs-1", type "text", name "value", value cur-tape);
      ==
      ;span
        =data-goon  "edit-save"
        =data-goon-children  "0"
        =data-goon-interact  "action"
        ;button(data-goon "action", class "p-2 br2 bd1 b2 f1 fs-2 bold", type "submit"): save
      ==
    ==
  ==
::
++  render-act-form
  |=  [p=^path a=act]
  ^-  manx
  =/  path-tape=tape  (trip (spat p))
  =/  term-tape=tape  (trip p.a)
  =/  lede-tape=tape  (trip lede.q.a)
  =/  destructive=?
    |(=(%cancel p.a) =(%deny p.a) =(%remove p.a) =(%revoke p.a))
  =/  async=?  =(%load p.a)
  =/  btn-kind=tape  ?:(destructive "action-destructive" "action")
  =/  btn-class=tape
    ?:  destructive  "p-2 br2 bd1 b-1 f-1 fs-2 bold"
    ?:  async  "goon-nav-async pulse p-2 br2 bd1 b2 f1 fs-2 bold"
    "p-2 br2 bd1 b2 f1 fs-2 bold"
  =/  form-id=tape  "form-act{(path-to-id p)}-{(trip p.a)}"
  %+  add-attribute  :-  'data-on:submit'
    "@post(location.pathname, \{contentType: 'form'})"
  ;form
    =id  form-id
    =data-goon  "form"
    =data-goon-children  "0"
    ;input(type "hidden", name "path", value path-tape);
    ;input(type "hidden", name "blade", value "act");
    ;input(type "hidden", name "value", value term-tape);
    ;cluster
      ;span
        =data-goon  "edit-save"
        =data-goon-children  "0"
        =data-goon-interact  "action"
        ;button(data-goon btn-kind, class btn-class, type "submit"): {lede-tape}
      ==
    ==
  ==
::
++  render-act-forms
  |=  [p=^path acts=(list act)]
  ^-  manx
  ?:  =(~ acts)  ;/("")
  ;cluster
    =style  "--space: var(--el-s-2);"
    ;*  (turn acts |=(a=act (render-act-form p a)))
  ==
::
++  render-add-form
  |=  p=^path
  ^-  manx
  =/  path-tape=tape  (trip (spat p))
  =/  form-id=tape  (weld "form-add" (path-to-id p))
  %+  add-attribute  :-  'data-on:submit'
    "@post(location.pathname, \{contentType: 'form'})"
  ;form
    =id  form-id
    =data-goon  "form"
    =data-goon-children  "2"
    ;input(type "hidden", name "path", value path-tape);
    ;input(type "hidden", name "blade", value "add");
    ;cluster
      ;span
        =data-goon  "edit-field"
        =data-goon-children  "0"
        =data-goon-interact  "edit"
        ;input(data-goon "field", class "p-2 br2 bd1 b0 f1 fs-1", type "text", name "value", value "");
      ==
      ;span
        =data-goon  "edit-save"
        =data-goon-children  "0"
        =data-goon-interact  "action"
        ;button(data-goon "action", class "p-2 br2 bd1 b2 f1 fs-2 bold", type "submit"): add
      ==
    ==
  ==
::
::  +goad-to-manx: public recursive renderer for goon $goad.
::
++  goad-to-manx
  |=  node=goad
  ^-  manx
  (render-node 0 ~ node)
::
++  render-accordion-shell
  |=  [kids=(list goad) parent=^path depth=@ud]
  ^-  manx
  =/  sections=marl
    =/  ks  kids
    |-  ^-  marl
    ?~  ks  ~
    ::  All sections render collapsed by default. nav.js's
    ::  restoreAccordionState applies localStorage state on init and
    ::  expands the first accordion-section in the page on first visit.
    ::  Server-side "first section expanded" caused every shell's first
    ::  kid (movies, subscribed-sources, hosting) to open simultaneously.
    =/  expanded=tape  "false"
    =/  sec-iota=iota  -.i.ks
    =/  sec-attrs=(list attr)  +<.i.ks
    =/  sec-label=tape  (attr-lede sec-attrs sec-iota)
    =/  sec-path=^path  (snoc parent (iota-to-knot sec-iota))
    =/  sec-path-tape=tape  (trip (spat sec-path))
    =/  sec-id=tape  (weld "acc" (path-to-id sec-path))
    ::  Use render-accordion-section-body (not goad-to-manx) so the
    ::  kid's own iota-label isn't re-emitted inside the section body —
    ::  the accordion-header already shows it. Mirrors render-palm-
    ::  detail-content's "skip own iota" pattern.
    =/  sec-content=manx
      (render-accordion-section-body +(depth) parent i.ks)
    :_  $(ks t.ks)
    ;box
      =id  sec-id
      =class  "bd1 br3 scroll-none"
      =style  "--padding: 0;"
      =data-goon  "accordion-section"
      =data-goon-accordion-expanded  expanded
      =data-goon-path  sec-path-tape
      ;button
        =class  "wf p4 b1 bdb1 f0 fs1 bold tl"
        =data-goon  "accordion-header"
        =data-goon-children  "1"
        =data-goon-accordion-expanded  expanded
        =type  "button"
        ;cluster
          =style  "--space: var(--el-s-2);"
          ;span
            =data-goon  "accordion-arrow"
            ; ;
          ==
          ;h3
            =class  "fs1 bold"
            =data-goon  "accordion-label"
            ; {sec-label}
          ==
        ==
      ==
      ;div
        =class  "p4"
        =data-goon  "accordion-content"
        =data-goon-accordion-expanded  expanded
        ;+  sec-content
      ==
    ==
  =/  shell-id=tape  (weld "acc-shell" (path-to-id parent))
  ;stack
    =id  shell-id
    =data-goon  "accordion-shell"
    ;*  sections
  ==
::
::  +render-accordion-section-body: render an accordion-section's kid as
::  its inner body — info, forms, kids — WITHOUT the kid's own iota-label
::  header bar. The accordion-header above already shows the kid's lede;
::  re-emitting it inside the section content produces visible duplication
::  (e.g. "hosting" header → "hosting" label inside; "allowed guests"
::  header → "allowed guests" label inside).
::
::  Mirrors +render-palm-detail-content's "strip own iota wrapper" pattern.
::  Pass-through (1-kid) and view-mode dispatch are preserved so kids that
::  are themselves palm-able or accordion-able render correctly inside the
::  section (e.g. settings/hosting holds a sub-accordion for allowed-guests).
::
::  TODO: factor the body emission shared with goad-to-manx's STACK
::  fallback into a single helper once the visual proves stable.
::
++  render-accordion-section-body
  |=  [depth=@ud parent=^path g=goad]
  ^-  manx
  =/  =iota  -.g
  =/  attrs=(list attr)  +<.g
  =/  all-kids=(list goad)  +>.g
  =/  act-list=(list act)  (attr-acts attrs)
  =+  parts=(partition-poster all-kids)
  =+  download-native=(partition-action-payload %download act-list rest.parts)
  =/  download-act=(unit act)  action.download-native
  =/  download-slot=(unit goad)  payload.download-native
  =/  kids=(list goad)  rest-kids.download-native
  =/  this-path=^path  (snoc parent (iota-to-knot iota))
  =/  path-tape=tape  (trip (spat this-path))
  ::  Pass-through inside a section: a 1-kid wrapper renders AS its kid.
  ::  Preserves URL semantics; kid's view-mode applies.
  ?:  ?=([* ~] kids)
    (render-node +(depth) this-path i.kids)
  ::  view-mode dispatch for the section's body. Palm/accordion sub-modes
  ::  emit their own root containers; STACK falls through to a plain wrapper.
  =/  mode  (view-mode g)
  ?:  ?=(%palm mode)
    (render-palm-layout kids this-path depth)
  ?:  ?=(%accordion mode)
    (render-accordion-shell kids this-path depth)
  ::  STACK / ONE_PAGER body: emit info, forms, kids — but NO own-iota
  ::  label-bar div. Re-uses the same arms as goad-to-manx's STACK fall-
  ::  through.
  =/  info=(unit @t)  (attr-info attrs)
  =/  edit-cur=(unit @t)  (attr-edit-cur attrs iota)
  =/  remaining-acts=(list act)  rest-acts.download-native
  =/  has-download=?  &(?=(^ download-act) ?=(^ download-slot))
  =/  has-add=?  (attr-has-add attrs)
  =/  info-manx=manx
    ?~  info  ;/("")
    ;span.o6: {(trip u.info)}
  =/  edit-form-manx=manx
    ?~  edit-cur  ;/("")
    (render-edit-form this-path u.edit-cur)
  =/  act-forms-manx=manx
    (render-act-forms this-path remaining-acts)
  =/  download-manx=manx
    ?.  has-download  ;/("")
    ?~  download-slot  ;/("")
    (render-download-anchor (slot-value u.download-slot))
  =/  add-form-manx=manx
    ?.  has-add  ;/("")
    (render-add-form this-path)
  =/  drillable-extras=@ud
    %+  add  ?:(has-download 1 0)
    (drillable-extra-count edit-cur remaining-acts has-add)
  =/  child-count=tape  (a-co:co (add (lent kids) drillable-extras))
  =/  kids-manx=manx
    ?:  =(~ kids)  ;/("")
    ;stack
      =style  "--space: var(--el-s-2);"
      ;*  (turn kids |=(k=goad (render-node +(depth) this-path k)))
    ==
  =/  node-id=tape  (weld "node" (path-to-id this-path))
  ;stack
    =id  node-id
    =style  "--space: var(--el-s-2);"
    =data-goon-path  path-tape
    ;+  info-manx
    ;+  edit-form-manx
    ;+  act-forms-manx
    ;+  download-manx
    ;+  add-form-manx
    ;+  kids-manx
  ==
::
::  ==================================================================
::  IDIOMORPH / DATASTAR DOM-KEYING RULES OF THUMB
::  ==================================================================
::  This app uses background Server-Sent Events (SSE) to aggressively
::  morph the DOM while the user is interacting with it. To prevent
::  Idiomorph from destroying elements (which loses cursor focus,
::  scroll position, and client-side state), follow these ID rules:
::
::  1. KEY THE CONTAINERS
::     Give unique, namespaced IDs to major structural wrappers
::     (e.g., palm-layout, palm-stage, accordion-shell).
::
::  2. KEY THE LOOPS
::     Any element generated in a list/`turn` (items, drill panes,
::     media cards) must have an ID so Idiomorph can track re-ordering.
::
::  3. KEY THE STATE
::     Forms and `<input>` elements MUST have IDs so the user's focus
::     and in-progress typing aren't wiped out by a background morph.
::
::  4. STATIC SIBLINGS ARE SAFE (NO IDs NEEDED)
::     Buttons, text spans, and links inside a keyed container do NOT
::     need IDs. Idiomorph uses "positional matching" to update them safely.
::
::  5. BEWARE THE SHIFT (DYNAMIC INSERTIONS)
::     Positional matching breaks if you dynamically insert new elements
::     (like an error message) between existing siblings, pushing them down.
::     Fix: Use a permanent, empty placeholder `<div id="error-slot"></div>`
::     and morph its text, OR use a modal.
::  ==================================================================
::
++  render-node
  |=  [depth=@ud path=^path node=goad]
  ^-  manx
  =/  =iota  -.node
  =/  attrs=(list attr)  +<.node
  =/  all-kids=(list goad)  +>.node
  =/  act-list=(list act)  (attr-acts attrs)
  ::  Extract poster-child slot (renders as cover-card visual in palm-list).
  ::  Downstream logic operates on rest — kids minus the poster.
  =+  parts=(partition-poster all-kids)
  =/  poster=(unit goad)  poster.parts
  =+  download-native=(partition-action-payload %download act-list rest.parts)
  =/  download-act=(unit act)  action.download-native
  =/  download-slot=(unit goad)  payload.download-native
  =/  kids=(list goad)  rest-kids.download-native
  ::  Root iota (depth 0) is the app scope name, not a path segment.
  ::  Event paths start at the first rendered child.
  =/  this-path=^path
    ?:  =(0 depth)  ~
    (snoc path (iota-to-knot iota))
  ::  Root: stable section labels (library / settings), NOT an accordion.
  ::  Each kid renders as a labeled section; content recurses to depth=1
  ::  where view-mode dispatches per kid. Labels are visual headers, not
  ::  navigable buttons — keyboard nav lands on the first interactive
  ::  node inside library.
  ::
  ::  %downloads kid is FILTERED OUT here: +render-frozen prepends the
  ::  #status-live strip to root-sections directly when a download is
  ::  active. The %downloads iota stays in the goad so +find-active-rid
  ::  + translate-stab-to-action ([%downloads @ ~]) still work.
  ?:  =(0 depth)
    =/  sections=marl
      %+  turn
        ::  iota for the %downloads kid is the @t atom %downloads (NOT a
        ::  cell — iota = $@(@t (pair aura @))). The atom literal pattern
        ::  is the correct match; cell patterns ?=([%downloads *] ...)
        ::  silently fail against atoms.
        (skip kids |=(k=goad ?=(%downloads -.k)))
      |=  k=goad
      ^-  manx
      =/  k-iota=^iota  -.k
      =/  k-attrs=(list attr)  +<.k
      =/  k-label=tape  (attr-lede k-attrs k-iota)
      =/  k-path=^path  (snoc this-path (iota-to-knot k-iota))
      =/  k-path-tape=tape  (trip (spat k-path))
      =/  k-id=tape  (weld "root" (path-to-id k-path))
      ::  data-goon-children + data-goon-path promote each root-section
      ::  to a navigable node. nav.js sibling traversal then walks between
      ::  library / settings via Up/Down. Always-visible — no collapse
      ::  semantics; Left from inside the section backs out to the
      ::  root-section itself (not above it).
      ;stack
        =id  k-id
        =data-goon  "root-section"
        =data-goon-children  "1"
        =data-goon-path  k-path-tape
        ;h2
          =class  "f0 fs4 bold lh2 bdb1 pb2"
          =data-goon  "label"
          =data-goon-depth  "1"
          ; {k-label}
        ==
        ;+  (render-node +(depth) this-path k)
      ==
    ;stack
      =data-goon  "root-sections"
      ;*  sections
    ==
  ::  Pass-through: a wrapper node with exactly one non-poster kid is
  ::  rendered AS its kid. The wrapper's iota stays in this-path so URLs
  ::  round-trip with the TUI, but no separate visual node is emitted
  ::  for the wrapper. Handles %library→%sections, %section-key→%items,
  ::  drill target→loaded list, etc.
  ?:  ?&(!=(%about iota) ?=([* ~] kids))
    (render-node depth this-path i.kids)
  ::  Mode dispatch. Palm and accordion short-circuit the standard
  ::  div(label, info, forms, kids) wrapper — their layouts already
  ::  carry their own root container with appropriate data-goon attrs.
  =/  mode  (view-mode node)
  ?:  ?=(%palm mode)
    (render-palm-layout kids this-path depth)
  ?:  ?=(%accordion mode)
    (render-accordion-shell kids this-path depth)
  =/  label=tape  (attr-lede attrs iota)
  =/  info=(unit @t)  (attr-info attrs)
  =/  edit-cur=(unit @t)  (attr-edit-cur attrs iota)
  =/  remaining-acts=(list act)  rest-acts.download-native
  =/  has-download=?  &(?=(^ download-act) ?=(^ download-slot))
  =/  has-add=?  (attr-has-add attrs)
  =/  pad=tape  ?:  =(0 depth)  ""  "pl{(a-co:co (mul depth 2))}"
  =/  info-manx=manx
    ?~  info  ;/("")
    ;span.o6: {(trip u.info)}
  =/  edit-form-manx=manx
    ?~  edit-cur  ;/("")
    (render-edit-form this-path u.edit-cur)
  =/  act-forms-manx=manx
    (render-act-forms this-path remaining-acts)
  =/  download-manx=manx
    ?.  has-download  ;/("")
    ?~  download-slot  ;/("")
    (render-download-anchor (slot-value u.download-slot))
  =/  add-form-manx=manx
    ?.  has-add  ;/("")
    (render-add-form this-path)
  ::  data-goon-children gates nav.js drillIn — must include EVERY
  ::  navigable child, not just goad kids. Without this, leaf nodes
  ::  with %edit/%act/%add forms are unreachable by keyboard
  ::  (drillIn returns early on count=0).
  =/  drillable-extras=@ud
    %+  add  ?:(has-download 1 0)
    (drillable-extra-count edit-cur remaining-acts has-add)
  =/  child-count=tape  (a-co:co (add (lent kids) drillable-extras))
  ::  STACK / ONE_PAGER fall-through. ONE_PAGER has kids=~, kids-manx is
  ::  empty. STACK emits each kid via goad-to-manx (which dispatches on
  ::  each kid's view-mode in turn). Accordion + palm are handled above
  ::  by the early-return dispatch.
  =/  kids-manx=manx
    ?:  =(~ kids)  ;/("")
    ;stack
      =style  "--space: var(--el-s-2);"
      ;*  (turn kids |=(g=goad (render-node +(depth) this-path g)))
    ==
  ::  data-goon-path lets goon-nav.js read/write ?focus= URLs that
  ::  match the TUI's encoding exactly — paste a URL minted by
  ::  the same encoded focus path and restore focus across renderers.
  =/  path-tape=tape
    ?:  =(~ this-path)  ""
    (trip (spat this-path))
  =/  node-id=tape  (weld "node" (path-to-id this-path))
  ;stack
    =id  node-id
    =class  pad
    =style  "--space: var(--el-s-2);"
    =data-goon-path  path-tape
    ;cluster
      =class  "fs-2 mono"
      =style  "--space: var(--el-s-2);"
      ;span.bold
        =data-goon  "label"
        ; {label}
      ==
      ;+  info-manx
    ==
    ;+  edit-form-manx
    ;+  act-forms-manx
    ;+  download-manx
    ;+  add-form-manx
    ;+  kids-manx
  ==
::
::  +render-palm-layout: emit the JRPG Hand+Palm sidebar layout for a
::  homogeneous list of leaf kids. Left pane = list of iota labels
::  (one ;li.palm-item per kid). Right pane = stacked detail panels
::  (one ;div.palm-detail per kid, only one visible at a time). nav.js
::  swaps which detail is data-goon-palm-active="true" as the cursor
::  walks the list. First kid is active by default.
::
::  palm-layout itself carries NO data-goon-children: that attribute
::  would mark it a NODE_SEL, which nav.js auto-pagination scans for
::  >8 traversable kids — the inner palm-detail contents would
::  leak into the scan and trigger pagination on palm-layout,
::  collapsing the detail pane. palm-list keeps its data-goon-
::  children (explicit pagination target, JRPG 7-8/page cap).
::
++  render-palm-layout
  |=  [kids=(list goad) parent=^path depth=@ud]
  ^-  manx
  =/  count-tape=tape  (a-co:co (lent kids))
  =/  path-prefix=tape  (path-to-id parent)
  =/  palm-list-items=marl
    =/  idx=@ud  0
    =/  ks  kids
    |-  ^-  marl
    ?~  ks  ~
    =/  =iota  -.i.ks
    =/  attrs=(list attr)  +<.i.ks
    =/  act-list=(list act)  (attr-acts attrs)
    =+  load-parts=(partition-act %load act-list)
    =/  pulse-class=tape  ?:(?=(^ match.load-parts) " pulse" "")
    =/  item-lab=tape  (attr-lede attrs iota)
    =/  idxt=tape  (a-co:co idx)
    =/  knot-str=tape  (trip (iota-to-knot iota))
    =/  item-id=tape    "palm-item-{path-prefix}-{knot-str}"
    =/  detail-id=tape  "palm-detail-{path-prefix}-{knot-str}"
    =+  kid-parts=(partition-poster +>.i.ks)
    =/  kid-poster=(unit goad)  poster.kid-parts
    :_  $(ks t.ks, idx +(idx))
    ?~  kid-poster
      ;li
        =id  item-id
        =class  "p-3 br2 f2 bold scroll-none{pulse-class}"
        =data-goon  "palm-item"
        =data-goon-children  "1"
        =data-goon-portal-in  detail-id
        =data-goon-palm-idx  idxt
        ;span: {item-lab}
      ==
    =/  thumb-url=tape  (trip (poster-url u.kid-poster))
    ;li
      =id  item-id
      =class  "goon-cover relative br3{pulse-class}"
      =data-goon  "palm-item"
      =data-goon-children  "1"
      =data-goon-portal-in  detail-id
      =data-goon-palm-idx  idxt
      ;shape
        =intrinsic  ""
        ;img(src thumb-url, alt item-lab, decoding "async");
        ;span
          =class  "goon-cover-label absolute bottom0 left0 right0 fs-2 bold lh2"
          ; {item-lab}
        ==
      ==
    ==
  =/  palm-detail-panels=marl
    =/  idx=@ud  0
    =/  ks  kids
    |-  ^-  marl
    ?~  ks  ~
    =/  =iota  -.i.ks
    =/  idxt=tape  (a-co:co idx)
    =/  knot-str=tape  (trip (iota-to-knot iota))
    =/  item-id=tape    "palm-item-{path-prefix}-{knot-str}"
    =/  detail-id=tape  "palm-detail-{path-prefix}-{knot-str}"
    =/  attrs=(list attr)  +<.i.ks
    =/  info=(unit @t)  (attr-info attrs)
    =/  value=(unit @t)  (attr-value attrs)
    =/  all-kids=(list goad)  +>.i.ks
    =/  act-list=(list act)  (attr-acts attrs)
    =+  slots=(partition-media-slots all-kids)
    =+  no-download=(partition-download rest.slots)
    =/  inner-kids=(list goad)  rest.no-download
    =/  item-path=^path  (snoc parent (iota-to-knot iota))
    =/  article-id=tape  (weld "article-full" (path-to-id item-path))
    =/  text-only=?  ?&  ?=(~ poster.slots)
                          ?=(~ tagline.slots)
                          ?=(~ summary.slots)
                          ?|(?=(^ info) ?=(^ value))
                          =(~ act-list)
                          =(~ inner-kids)
                      ==
    :_  $(ks t.ks, idx +(idx))
    ::  Palm-detail is a portal-in target with no useful DOM peers (other
    ::  detail panels are hidden swap-mates), so up/down on it is gated to
    ::  no-op via data-goon-no-siblings. Drill-in prefers the actions group
    ::  (buttons > text > image) — render-palm-detail-content emits a
    ::  data-goon="actions" stop that nav.js's prefer-child resolves to.
    ::  Children count is conceptual (image / text / actions); nav reads
    ::  DOM not the attr value, so the integer is a hint not a contract.
    ;div
      =id  detail-id
      =class  "scroll-y"
      =data-goon  "palm-detail"
      =data-goon-children  "3"
      =data-goon-portal-in  ?:(text-only article-id "")
      =data-goon-portal-out  item-id
      =data-goon-palm-idx  idxt
      =data-goon-no-siblings  ""
      =data-goon-prefer-child  ?:(text-only "article-full,text-block" "actions,form,link")
      ;*  (render-palm-detail-content parent depth i.ks)
    ==
  ::  sidebar[side="right"]: first-child = content (grows), last = side
  ::  (fixed flex-basis). Grid first / aside second gives wide screens a
  ::  growing cover grid with a fixed-width detail panel on the right;
  ::  on narrow viewports the sidebar's wrap puts palm-detail below the
  ::  grid (source order honored on wrap).
  =/  layout-id=tape  (weld "palm-layout" (path-to-id parent))
  =/  palm-min=tape  ?:  (kids-have-wide-posters kids)  "11rem"  "9rem"
  =/  base-layout=manx
    ;sidebar
      =id  layout-id
      =data-goon  "palm-layout"
      =side  "right"
      =style  "--side-width: 65ch; --content-min: 30%;"
      ;grid
        =data-goon  "palm-list"
        =style  "--min: {palm-min};"
        ;*  palm-list-items
      ==
      ;aside
        =data-goon  "palm"
        ;*  palm-detail-panels
      ==
    ==
  ::  nav.js injects cluster[data-goon=page-controls] after this sidebar via
  ::  sidebar.after() — placing it as a sibling inside accordion-content.
  ::  Datastar morphdom strips unmatched sibling nodes on each SSE fact;
  ::  data-ignore-morph on the injected node prevents attribute clobber but
  ::  cannot prevent removal when the node has no server-HTML counterpart.
  ::  The MO callback in goon-nav.js detects parentElement=null and re-runs
  ::  setupPagination to recover. Future JS-owned nodes inserted as siblings
  ::  of server-rendered content face the same vulnerability — prefer placing
  ::  them inside an existing data-ignore-morph container instead.
  ::  Palm-stage wrap: when any kid has a loaded drill-down list, the
  ::  renderer emits sibling palm-layouts for the drill swap.
  ::  data-active-palm is NOT emitted here — nav.js owns it exclusively.
  ::  Emitting it server-side caused SSE morphs to clobber client-set
  ::  state on every fact, producing visible flicker mid-drill. CSS uses
  ::  :not([data-active-palm]) fallback for first paint.
  =/  stage-id=tape  (weld "palm-stage" (path-to-id parent))
  =/  siblings=marl  (collect-drill-siblings kids parent depth)
  ?:  =(~ siblings)  base-layout
  ;div
    =id  stage-id
    =data-goon  "palm-stage"
    ;div
      =data-palm-id  "primary"
      ;+  base-layout
    ==
    ;*  siblings
  ==
::
::  +render-palm-detail-content: render a leaf kid's body (label, info,
::  download anchor, act forms) WITHOUT the data-goon-children wrapper
::  that goad-to-manx normally emits. Inside palm-detail we don't want
::  that wrapper — its data-goon-children would be picked up by nav.js
::  auto-pagination scanning four levels up, triggering pagination on
::  an outer container and hiding the active detail.
::
++  render-palm-detail-content
  |=  [parent=^path depth=@ud g=goad]
  ^-  marl
  =/  =iota  -.g
  =/  attrs=(list attr)  +<.g
  =/  all-kids=(list goad)  +>.g
  =/  act-list=(list act)  (attr-acts attrs)
  ::  Chain three name-keyed strips: poster → tagline → summary. The
  ::  remainder is inner-kids (including any drill-in wrappers).
  ::  Mirrors the Library Browser archetype slot contract — each slot
  ::  ships as a named child rather than an attr, keeping the goad
  ::  protocol canonical (no new attrs, no new hints).
  =+  slots=(partition-media-slots all-kids)
  =+  download-native=(partition-action-payload %download act-list all-kids)
  =/  kid-poster=(unit goad)  poster.slots
  =/  kid-tagline=(unit goad)  tagline.slots
  =/  kid-summary=(unit goad)  summary.slots
  =/  download-slot=(unit goad)  payload.download-native
  =+  no-download=(partition-download rest.slots)
  =/  inner-kids=(list goad)  rest.no-download
  =/  this-path=^path  (snoc parent (iota-to-knot iota))
  =/  label=tape  (attr-lede attrs iota)
  =/  info=(unit @t)  (attr-info attrs)
  =/  value=(unit @t)  (attr-value attrs)
  =/  meta-text=tape
    ?~  info  ""
    (trip u.info)
  =/  article-body=@t
    ?~  value
      ?~  info  ''
      u.info
    u.value
  =/  text-preview=tape
    ?:  ?=(^ info)  meta-text
    (trip article-body)
  =/  tagline-text=tape
    (slot-text kid-tagline)
  =/  summary-text=tape
    (slot-text kid-summary)
  =/  poster-thumb=tape
    ?~  kid-poster  ""
    (trip (poster-url u.kid-poster))
  ::  media-manx: nav stop only when a poster is present. data-goon-children
  ::  is "0" today (drilling lands here but doesn't descend); set to "1"
  ::  later when the enlarged-image view exists for it to drill into.
  =/  media-manx=manx
    ?~  kid-poster  ;span(data-slot "media");
    ;shape
      =data-slot  "media"
      =data-goon  "image-slot"
      =data-goon-children  "0"
      =intrinsic  ""
      ;img(src poster-thumb, alt label, decoding "async");
    ==
  =/  download-act=(unit act)  action.download-native
  =/  remaining-acts=(list act)  rest-acts.download-native
  ::  Drill branch: the first non-slot child whose children all carry
  ::  ledes is treated as a drill menu. Drill selectors live INSIDE the
  ::  actions slot so keyboard nav reaches them via the same sibling group
  ::  as the action verbs. Loaded drill panes live as palm-stage siblings.
  =+  drill-parts=(partition-drill-wrapper inner-kids)
  =/  drill-buttons-marl=marl
    ?~  drill.drill-parts  ~
    =/  wrapper-iota=^iota  -.u.drill.drill-parts
    =/  wrapper-kids=(list goad)  +>.u.drill.drill-parts
    =/  wrapper-path=^path  (snoc this-path (iota-to-knot wrapper-iota))
    %+  turn  wrapper-kids
    |=  s=goad
    (render-drill-button wrapper-path s)
  =/  has-drill=?  !=(~ drill-buttons-marl)
  ::  Download anchor: web presentation for the goon %download action.
  ::  Browser file-save semantics require an href; the goad still declares
  ::  the intent as a normal %act.
  =/  can-download=?  &(?=(^ download-act) ?=(^ download-slot) !has-drill)
  =/  download-manx=manx
    ?.  can-download  ;/("")
    ?~  download-slot  ;/("")
    (render-download-anchor (slot-value u.download-slot))
  =/  has-actions=?  ?|(can-download !=(~ remaining-acts) has-drill)
  ::  actions-manx: drill-in target for the palm-detail.
  ::    actions → reel nav stop (data-goon="actions", children=N); Right
  ::              descends into the first action. Singleton actions still use
  ::              the same wrapper so the card reserves identical chrome
  ::              (top border, padding, scrollbar gutter) across paginated
  ::              items.
  =/  action-marl=marl
    ;:  weld
      ?:(can-download ~[download-manx] ~)
      (turn remaining-acts |=(a=act (render-act-form this-path a)))
      drill-buttons-marl
    ==
  =/  action-count=@ud  (lent action-marl)
  =/  actions-manx=manx
    ?.  has-actions
      ;span(data-slot "actions");
    ;reel
      =data-slot  "actions"
      =data-goon  "actions"
      =data-goon-children  (a-co:co action-count)
      =data-goon-skip-single  ?:(=(action-count 1) "true" "false")
      =class  "bdt1 p3"
      =style  "max-inline-size: 100%;"
      ;*  action-marl
    ==
  =/  text-only=?  ?&  ?=(~ kid-poster)
                        ?=(~ kid-tagline)
                        ?=(~ kid-summary)
                        ?|(?=(^ info) ?=(^ value))
                        !has-actions
                        =(~ inner-kids)
                    ==
  =/  display-summary=tape  ?:(text-only text-preview summary-text)
  =/  card-class=tape  ?:(text-only "b1 bd1 br3 goon-text-card" "b1 bd1 br3")
  =/  text-id=tape  (weld "text-block" (path-to-id this-path))
  =/  article-id=tape  (weld "article-full" (path-to-id this-path))
  =/  detail-id=tape  (weld "palm-detail" (path-to-id this-path))
  ::  Slot grid card. CSS at style.css's palm-detail block applies
  ::  grid-template-areas: "media title" / "media tagline" / "media meta"
  ::  / "media summary" / "actions actions". Per-slot clamps enforce
  ::  vertical-static height (archetype L143-156): sibling navigation
  ::  never reflows because every slot reserves its space via fixed-
  ::  height clamps + [data-slot]:empty { visibility: hidden }.
  ::  text-block-manx: groups title/tagline/meta/summary as a single nav
  ::  stop ("all-of-the-text"). Real grid item (data-slot="text") so the
  ::  generic [data-goon-active] outline lights it up on focus. CSS at
  ::  style.css's palm-detail block places it via grid-area "text" and
  ::  stacks the inner spans as a flex column. data-goon-children="0"
  ::  today; set to "1" later when the text block can drill into a
  ::  one-pager view.
  =/  summary-manx=manx
    ?:  text-only
      ;div(data-slot "summary", class "f3 lh5")
        ;+  (render-udon article-body)
      ==
    ;span(data-slot "summary", class "f3 lh5"): {display-summary}
  =/  text-block-manx=manx
    ;stack
      =id  text-id
      =data-slot  "text"
      =data-goon  "text-block"
      =data-goon-children  ?:(text-only "1" "0")
      =data-goon-portal-in  ?:(text-only article-id "")
      ;span(data-slot "title", class "f0 fs5 bold lh1"): {label}
      ;*  ?:  text-only  ~
          :~  ;span(data-slot "tagline", class "f2 italic"): {tagline-text}
              ;span(data-slot "meta", class "f2"): {meta-text}
          ==
      ;+  summary-manx
    ==
  =/  article-manx=manx
    ?.  text-only  ;/("")
    ;box
      =id  article-id
      =class  "b1 bd1 br3 goon-article-full"
      =style  "--padding: var(--el-s-1);"
      =data-goon  "article-full"
      =data-goon-children  "0"
      =data-goon-portal-out  detail-id
      ;stack
        =style  "--space: var(--el-s-1);"
        ;h3(class "f0 fs5 bold lh1"): {label}
        ;+  (render-udon article-body)
      ==
    ==
  =/  card-manx=manx
    ;box
      =class  card-class
      =style  "--padding: var(--el-s-1);"
      =data-goon  "card"
      =data-goon-depth  "2"
      ;*  ?:(text-only ~ ~[media-manx])
      ;+  text-block-manx
      ;*  ?:(text-only ~ ~[actions-manx])
    ==
  ::  inner-kids (drill-down content, nested groups, etc.) live as
  ::  a SIBLING of the card, not inside it. Keeping them outside the
  ::  slot grid preserves the vertical-static contract for the card AND
  ::  lets the drill-in container be its own pagination root for nav.js.
  ::  Returns marl so the caller (;* in the palm-detail emit) splices
  ::  card + inner-kids as direct children of [data-goon="palm-detail"].
  ?:  text-only  ~[card-manx article-manx]
  ?:  =(~ inner-kids)  ~[card-manx]
  ::  When the drill wrapper was the inner child we've already emitted its
  ::  selectors inside the card's actions slot above. The loaded panes ride
  ::  along as palm-stage siblings via +collect-drill-siblings. Skip the
  ::  recursive inner-kids render to avoid duplicating the drill nav.
  ?:  has-drill  ~[card-manx]
  =/  inner-id=tape  (weld "goad-inner" (path-to-id this-path))
  =/  inner-kids-manx=manx
    ;stack
      =id  inner-id
      =style  "--space: var(--el-s-2);"
      ;*  (turn inner-kids |=(k=goad (render-node +(depth) this-path k)))
    ==
  ~[card-manx inner-kids-manx]
::
::  +render-drill-button: one ;form per drill-down choice. Mirrors render-act-form's
::  shape (hidden path/blade/value + button submit) so existing Datastar @post
::  pipeline carries the click through the serving vine's form handler. The button
::  is marked with a CSS class (NOT a data-* attr) so nav.js can find it
::  for the deferred-drill behavior — Datastar's plugin walker halts on
::  unknown data-* attrs anywhere in the form subtree, breaking the form's
::  data-on-submit binding and causing native GET fallback. Classes are
::  inert to the walker. nav.js derives the target palm-id by parsing the
::  form's hidden "path" input.
::
++  render-drill-button
  |=  [parent=^path item=goad]
  ^-  manx
  =/  =iota  -.item
  =/  attrs=(list attr)  +<.item
  =/  item-path=^path  (snoc parent (iota-to-knot iota))
  =/  path-tape=tape  (trip (spat item-path))
  =/  label-tape=tape  (attr-lede attrs iota)
  =/  act-list=(list act)  (attr-acts attrs)
  =+  load-parts=(partition-act %load act-list)
  =/  load-pending=?  ?=(^ match.load-parts)
  =/  load-term=tape
    ?~  match.load-parts  "load"
    (trip p.u.match.load-parts)
  =/  btn-class=tape
    "goon-nav-async inline-block p-2 br2 bd1 b2 f1 fs-1 bold nowrap shrink-none"
  =/  form-id=tape  (weld "form-drill" (path-to-id item-path))
  ::  swrap-id MUST match the id collect-drill-siblings emits on the
  ::  corresponding [data-palm-id] pane wrapper. Both arms derive it from
  ::  the same item-path so they line up automatically. nav.js reads
  ::  data-goon-pane on the form to know which palm-stage pane to
  ::  activate when this async leaf is triggered.
  =/  swrap-id=tape  (weld "palm-swrap" (path-to-id item-path))
  ::  data-on:submit (colon, NOT hyphen) is the Datastar plugin syntax:
  ::  the attribute-name parser splits on `:` to separate plugin name
  ::  from key. `data-on-submit` parses as plugin "on-submit" which is
  ::  unregistered → form goes native GET. Sail's @tas attribute names
  ::  can't contain `:`, so we apply the attribute post-build via
  ::  add-attribute (which accepts a literal cord name).
  %+  add-attribute  :-  'data-on:submit'
    "@post(location.pathname, \{contentType: 'form'})"
  ;form
    =id  form-id
    =data-goon  "form"
    =data-goon-children  "0"
    =data-goon-pane  swrap-id
    ;input(type "hidden", name "path", value path-tape);
    ;input(type "hidden", name "blade", value "act");
    ;input(type "hidden", name "value", value load-term);
    ;cluster
      ;span
        =data-goon  "edit-save"
        =data-goon-children  "0"
        =data-goon-interact  "action"
        ;button
          =data-goon  "drill-button"
          =class  btn-class
          =type  "submit"
          ; {label-tape}
        ==
      ==
    ==
  ==
::
::  +collect-drill-siblings: walk a list of media goads, return a marl of
::  palm-layout siblings for loaded drill targets. A drill target is any
::  non-slot wrapper with lede-bearing children; a loaded target carries
::  another wrapper of lede-bearing children.
::
::  Returns ~ when no items have loaded drill targets, letting the caller
::  fall back to a plain palm-layout.
::
++  collect-drill-siblings
  |=  [items=(list goad) parent=^path depth=@ud]
  ^-  marl
  %-  zing
  %+  turn  items
  |=  s=goad
  ^-  marl
  =/  s-iota  -.s
  =/  s-attrs=(list attr)  +<.s
  =/  parent-label=tape  (attr-lede s-attrs s-iota)
  =/  s-kids=(list goad)  +>.s
  =+  pst=(partition-poster s-kids)
  =/  after-poster=(list goad)  rest.pst
  =+  menu-parts=(partition-drill-wrapper after-poster)
  ?~  drill.menu-parts  ~
  =/  parent-path=^path  (snoc parent (iota-to-knot s-iota))
  =/  menu-iota=iota  -.u.drill.menu-parts
  =/  menu-path=^path  (snoc parent-path (iota-to-knot menu-iota))
  =/  target-list=(list goad)  +>.u.drill.menu-parts
  %+  turn  target-list
  |=  target=goad
  ^-  manx
  =/  target-iota  -.target
  =/  target-attrs=(list attr)  +<.target
  =/  target-label=tape  (attr-lede target-attrs target-iota)
  =/  target-kids=(list goad)  +>.target
  =+  target-slots=(partition-media-slots target-kids)
  =/  after-slots=(list goad)  rest.target-slots
  =+  loaded-parts=(partition-drill-wrapper after-slots)
  =/  target-path=^path  (snoc menu-path (iota-to-knot target-iota))
  =/  swrap-id=tape  (weld "palm-swrap" (path-to-id target-path))
  =/  palm-id-tape=tape  (weld "drill-" (trip (iota-to-knot target-iota)))
  ::  Inner content: real palm-layout if the child list is loaded; placeholder
  ::  hint otherwise. The placeholder MUST be emitted so palm-stage has
  ::  a swap target on first click; an SSE morph upgrades this div in place
  ::  once the child list arrives.
  =/  inner-content=manx
    ?~  drill.loaded-parts
      ;stack(class "o6", style "--space: var(--el-s-2);"): Loading...
    =/  loaded-iota=iota  -.u.drill.loaded-parts
    =/  loaded-list=(list goad)  +>.u.drill.loaded-parts
    ?:  =(~ loaded-list)
      ;stack(class "o6", style "--space: var(--el-s-2);"): No items.
    =/  loaded-path=^path  (snoc target-path (iota-to-knot loaded-iota))
    (render-palm-layout loaded-list loaded-path +(depth))
  ;stack
    =id  swrap-id
    =data-palm-id  palm-id-tape
    ;cluster
      ;button
        =data-slot  "back"
        =data-goon  "palm-back"
        =type  "button"
        ← back
      ==
      ;p(data-slot "parent", class "f2 fs-1"): {parent-label}
      ;p(data-slot "target", class "f0 fs1 bold"): {target-label}
    ==
    ;+  inner-content
  ==
::
::  +render-download-anchor: link for a URL supplied by the goad.
::  The server's Content-Disposition controls the file save after auth.
::
++  render-download-anchor
  |=  url=@t
  ^-  manx
  ;a
    =href  (trip url)
    =class  "winter inline-block p-2 br2 bd1 b4 f0 fs-2 bold"
    =data-goon-native  "download"
    =data-goon-interact  "link"
    =data-goon  "link"
    =data-goon-children  "0"
    ; download
  ==
::
++  drillable-extra-count
  |=  [edit-cur=(unit @t) acts=(list act) has-add=?]
  ^-  @ud
  %+  add  ?:(=(~ edit-cur) 0 1)
  %+  add  (lent acts)
  ?:(has-add 1 0)
--
