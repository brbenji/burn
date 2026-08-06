::  /lib/goad-to-homunculus-sail.hoon — goad → tui-frame walker
::
::  Walks a burn goad into the list of tui-row records that ship
::  over Eyre SSE as a %tui-frame fact. The browser owns ALL focus and
::  editing-draft state, so rows are emitted with neutral styling — the
::  JS-side `focusedFila` and edit-mode override apply highlight per
::  repaint.
::
::  Path convention matches lib/vines/oxal--plex.hoon's goad-to-manx:
::  the root iota is the SCOPE NAME (e.g. %plex) and is NOT a path
::  segment. burn's /settings/hosting/url is path
::  [%settings %hosting %url ~], not [%plex %settings %hosting %url ~].
::
::  Focusable nodes: any leaf or branch heading carrying %click | %act
::  | %edit | %add. Classifier priority sits in +focusable-kind below.
::
/-  goon, *tui-engine
/+  *goon
=,  goon
|%
::
++  walk-frame
  |=  [g=goad here=path parent=path depth=@ud]
  ^-  (list tui-row)
  =*  attrs           q.g
  =*  kids            r.g
  =/  bag             ~(. has attrs)
  =/  marker=tape     ?:((interactable attrs) "> " "  ")
  =/  lede-text=tape  (lede-or-iota p.g attrs)
  =/  pad-left=@ud    (mul depth 2)
  =/  fkind=(unit interact-kind)  (focusable-kind attrs)
  ?~  kids
    ::  leaf
    =/  value-text=tape
      =/  u  value:bag  ?~(u "" (iota-text u.u))
    =/  body=tape  ?:(=("" value-text) lede-text value-text)
    =/  text=tape  (weld marker body)
    :~  :*  path=here  parent=parent  depth=depth  kind=%leaf
            pad-left=pad-left
            cells=~[[text=text fila=[~ %~ %~]]]
            focusable=fkind
        ==
    ==
  ::  branch
  =/  info-text=tape
    =/  u  info:bag  ?~(u "" (trip u.u))
  =/  head=(list tui-row)
    ?:  =("" lede-text)  ~
    =/  text=tape  (weld marker lede-text)
    :~  :*  path=here  parent=parent  depth=depth  kind=%head
            pad-left=pad-left
            cells=~[[text=text fila=[(silt ~[%br]) %~ %~]]]
            focusable=fkind
        ==
    ==
  =/  info=(list tui-row)
    ?:  =("" info-text)  ~
    :~  :*  path=here  parent=parent  depth=depth  kind=%info
            pad-left=pad-left
            cells=~[[text=info-text fila=[~ %~ %~]]]
            focusable=~
        ==
    ==
  =/  body=(list tui-row)
    %-  zing
    %+  turn  kids
    |=  k=goad
    =/  child-here=path  (snoc here (iota-to-knot p.k))
    (walk-frame k child-here here +(depth))
  ;:  weld  head  info  body  ==
::
::  +interactable: does this attr-list carry an interaction attr?
::  Per goon spec: %click | %act intent, %edit | %add data input.
::
++  interactable
  |=  attrs=(list attr)
  ^-  ?
  ?~  attrs  %.n
  ?:  ?=(?(%click %act %edit %add) -.i.attrs)  %.y
  $(attrs t.attrs)
::
++  acts-of
  |=  attrs=(list attr)
  ^-  (list act)
  ?~  attrs  ~
  ?:  ?=(%act -.i.attrs)  p.i.attrs
  $(attrs t.attrs)
::
++  has-click
  |=  attrs=(list attr)
  ^-  ?
  ?~  attrs  %.n
  ?:  ?=(%click -.i.attrs)  %.y
  $(attrs t.attrs)
::
++  lede-or-iota
  |=  [i=iota attrs=(list attr)]
  ^-  tape
  =/  u  ~(lede has attrs)
  ?~  u  (iota-text i)
  (trip u.u)
::
++  iota-text
  |=  i=iota
  ^-  tape
  ?@  i  (trip i)
  (trip (scot p.i q.i))
::
++  iota-to-knot
  |=  i=iota
  ^-  @ta
  ?@  i  i
  (scot p.i q.i)
::
::  +focusable-kind: priority-ordered focusable classifier.
::    %click first (library-item / download — JS short-circuits these
::      to window.open via isLibraryDownload),
::    then %act for generic intents — carries the act list so JS can
::      dispatch the picked term back without the agent needing
::      per-path translation,
::    then %edit for inline-edit fields,
::    then %add for inline-add fields,
::    else ~ (non-focusable).
::
++  focusable-kind
  |=  attrs=(list attr)
  ^-  (unit interact-kind)
  =/  bag  ~(. has attrs)
  ?:  (has-click attrs)  `[%click ~]
  =/  acts=(list act)  (acts-of attrs)
  ?^  acts             `[%act acts]
  ?:  edit:bag         `[%edit ~]
  ?:  add:bag          `[%add ~]
  ~
--
