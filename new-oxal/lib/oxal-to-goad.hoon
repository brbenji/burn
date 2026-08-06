::  /lib/oxal-to-goad.hoon — convert oxal data tree to goad
::
::  One of three valid sources of goad (per design_renderer_agnostic_goad.md):
::    1. Source 1 (this lib): oxal data tree → goad
::    2. Source 2: lens emits goad as boilerplate
::    3. Source 3: agent /x/goon scry emits goad directly (e.g. burn)
::
::  Type policy: goad/iota/attr types are INLINED in this lib's core
::  rather than imported from a sur/. Each goad producer owns its own
::  type copy in its own desk (burn will have its own sur/goon.hoon
::  when Run 3 ships /x/goon). Lenses inline as boilerplate. The type
::  shape is canonical from /Users/benjaminbrown/dev/urbit/goon repo.
::
::  Recognizes reserved children:
::    /edit              presence-only → [%edit ~]
::    /act/<verb>        each verb → (act = [term info=lede=verb-name])
::    /info              leaf cord → [%info <cord>]
::  All other children become recursive child goads. Branch leaf cords
::  become %lede on the parent.
::
::  Run 1a scope: minimal recognition. No %hint, %add, %click, %key
::  emission yet. %value not emitted on bare leaves — Run 1b's
::  goad-to-manx will recompute display from the source data when needed.
::
/+  *zozo
::
=>
|%
::  goad protocol type definitions (canonical from upstream goon).
::  Inlined here per "type-with-producer" policy. Identical shape to
::  what burn's sur/goon.hoon will declare in Run 3.
::
+$  info  @t
+$  lede  @t
+$  interact  [info=info lede=lede]
+$  act       (pair term interact)
+$  goon-iota
  $@(@t (pair aura @))
+$  goad
  $~  [*goon-iota ~ ~]
  (trel goon-iota (list attr) (list goad))
::
+$  blade
  $%  [%act =term]
      [%edit =goon-iota]
      [%add =goon-iota]
  ==
::
+$  stab  (pair path blade)
::
+$  attr
  $%  [%key p=term]
      [%lede p=lede]
      [%info p=info]
      [%value p=goon-iota]
      [%edit ~]
      [%add ~]
      [%act p=(list act)]
      [%click p=? q=wire]
  ==
--
::
|%
++  oxal-to-goad
  |=  [i=goon-iota dat=data]
  ^-  goad
  =/  d  ~(. do dat)
  =/  all-kids  kid-list:d
  ::
  =|  attrs=(list attr)
  ::
  ::  /edit presence: [%edit ~]
  =?  attrs  (has-reserved all-kids "edit")
    [[%edit ~] attrs]
  ::
  ::  /act/<verb> children: [%act ~[acts]]
  =/  acts=(list act)  (collect-acts all-kids)
  =?  attrs  ?=(^ acts)
    [[%act acts] attrs]
  ::
  ::  /info leaf: [%info <cord>]
  =/  info-text=(unit @t)  (read-info all-kids)
  =?  attrs  ?=(^ info-text)
    [[%info u.info-text] attrs]
  ::
  ::  branch leaf cord becomes %lede
  =/  lede-cord=(unit @t)  (read-text-leaf leaf.dat)
  =?  attrs  ?=(^ lede-cord)
    [[%lede u.lede-cord] attrs]
  ::
  =/  child-goads=(list goad)
    %+  turn  (filter-non-reserved all-kids)
    |=  [ki=iota kd=data]
    (oxal-to-goad (cast-iota ki) kd)
  ::
  [i (flop attrs) child-goads]
::
::  cast-iota: zozo iota (= node) → scalar goon-iota
::
::  Bare term passes through (term IS @t at noun level). Scalar typed
::  iotas pass through structurally. Blob-typed iotas crash — they
::  aren't valid goad iotas.
::
++  cast-iota
  |=  =iota
  ^-  goon-iota
  ?@  iota  iota
  ?+  -.iota  ~|([%blob-iota-unsupported -.iota] !!)
    %t   iota
    %ta  iota
    %p   iota
    %q   iota
    %ud  iota
    %ui  iota
    %ux  iota
    %uv  iota
    %uw  iota
    %ub  iota
    %uc  iota
    %sd  iota
    %si  iota
    %sx  iota
    %sb  iota
    %sc  iota
    %sv  iota
    %sw  iota
    %da  iota
    %dr  iota
    %if  iota
    %is  iota
    %f   iota
    %n   iota
    %rs  iota
    %rd  iota
    %rh  iota
    %rq  iota
  ==
::
++  has-reserved
  |=  [kids=(list [iota data]) name=tape]
  ^-  ?
  ?~  kids  %.n
  =/  ki  -.i.kids
  ?:  ?=(%$ ki)  $(kids t.kids)
  ?:  =((node-summary ki) name)  %.y
  $(kids t.kids)
::
++  collect-acts
  |=  kids=(list [iota data])
  ^-  (list act)
  ?~  kids  ~
  =/  ki  -.i.kids
  ?:  ?=(%$ ki)  $(kids t.kids)
  ?.  =((node-summary ki) "act")
    $(kids t.kids)
  =/  act-d  ~(. do +.i.kids)
  =/  verb-kids  kid-list:act-d
  %+  weld
    (verbs-to-acts verb-kids)
  $(kids t.kids)
::
++  verbs-to-acts
  |=  vk=(list [iota data])
  ^-  (list act)
  ?~  vk  ~
  =/  vi  -.i.vk
  ?:  ?=(%$ vi)  $(vk t.vk)
  =/  verb=tape  (node-summary vi)
  =/  vc=@t  (crip verb)
  :_  $(vk t.vk)
  [vc info=vc lede=vc]
::
++  read-info
  |=  kids=(list [iota data])
  ^-  (unit @t)
  ?~  kids  ~
  =/  ki  -.i.kids
  ?:  ?=(%$ ki)  $(kids t.kids)
  ?.  =((node-summary ki) "info")
    $(kids t.kids)
  =/  info-data  +.i.kids
  (read-text-leaf leaf.info-data)
::
++  read-text-leaf
  |=  l=(unit node)
  ^-  (unit @t)
  ?~  l  ~
  =/  ln  u.l
  ?@  ln  `ln                          ::  bare term passes as @t
  ?+  -.ln  ~                          ::  non-text leaf: no lede
    %t   `t.ln
    %ta  `(crip (trip ta.ln))
  ==
::
++  filter-non-reserved
  |=  kids=(list [iota data])
  ^-  (list [iota data])
  ?~  kids  ~
  =/  ki  -.i.kids
  ?:  ?=(%$ ki)  $(kids t.kids)
  =/  kn=tape  (node-summary ki)
  ?:  ?|  =(kn "edit")
          =(kn "act")
          =(kn "info")
          =(kn "hint")
          =(kn "~")
      ==
    $(kids t.kids)
  [i.kids $(kids t.kids)]
--
