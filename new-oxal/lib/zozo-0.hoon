::  oxal : the backbone of a programmable interface
::
::  $hlc: hybrid logical clock
::
::    every move committed to the tree carries an hlc stamp.  an hlc is
::    a pair [phys=@da logi=@ud]:
::
::      .phys   wall-clock time, taken from the bowl's `now` at the
::              moment the move entered the system.
::      .logi   logical counter that breaks ties when two events share
::              the same physical time, and that keeps the clock moving
::              forward when the wall clock stalls or runs backwards.
::
::    why both halves?  a bare wall-clock stamp is broken under clock
::    skew between ships: two writes that happen "at the same time" by
::    one ship's clock can interleave incorrectly with a peer's writes.
::    a bare logical counter (lamport-style) is causally correct but
::    meaningless to humans -- it can't express "the last hour" or
::    "wednesday afternoon".  the hybrid clock gives both: physical
::    ordering when the wall clocks agree, lamport-style fallback when
::    they don't.
::
::    rules:
::
::      on a local cause (a poke, a self-arvo): tick once.
::        new.phys = max(old.phys, now)
::        new.logi = (now > old.phys) ? 0 : old.logi + 1
::
::      on receiving a remote move with hlc r: merge.
::        m = max(old.phys, r.phys, now)
::        if m == old.phys && m == r.phys: new.logi = max(old.logi, r.logi) + 1
::        elif m == old.phys:              new.logi = old.logi + 1
::        elif m == r.phys:                new.logi = r.logi + 1
::        else:                            new.logi = 0
::        new.phys = m
::
::    invariants:
::
::      - hlcs are monotonic per-ship.  the agent-level clock
::        (now-hlc.acer) only goes forward.
::      - an hlc stamped onto a move is frozen.  it travels with the
::        move through fan-out (transformer outputs all carry the
::        cause's hlc, not their own newly-computed one) and through
::        replication.
::      - transformers may *read* time.move but must never read `now`
::        themselves; otherwise view replay diverges.
::
::    reference: kulkarni et al., "logical physical clocks", opodis 2014.
::
::
/+  multipart
|%
::
::  $node: sane coin
::
+$  node
  ::
  $+  node
  $@  term
  $%
    :::
    ::  known %blobs
    ::
    [%tang =tang]
    [%manx =manx]
    [%json =json]
    [%mime =mime]
    [%data =data]
    ::
    ::  escape hatch
    ::
    [%noun =noun]
    ::
    ::  %many
    ::
    [%pith =pith]
    ::
    ::  known %dimes
    ::
    [%n ~]      [%f f=?]
    [%ub =@ub]  [%uc =@uc]  [%ud =@ud]  [%ui =@ui]
    [%ux =@ux]  [%uv =@uv]  [%uw =@uw]
    [%sb =@sb]  [%sc =@sc]  [%sd =@sd]  [%si =@si]
    [%sx =@sx]  [%sv =@sv]  [%sw =@sw]
    [%da =@da]  [%dr =@dr]
    [%if =@if]  [%is =@is]
    [%t =@t]    [%ta =@ta]  ::  tas
    [%p =@p]    [%q =@q]
    [%rs =@rs]  [%rd =@rd]  [%rh =@rh]  [%rq =@rq]
    ::
  ==
::
++  comp-nodes
  ::
  ::  canonical node ordering
  ::
  |=  [a=node b=node]
  ^-  ?
  =>  .(a ?@(a [%tas a] a), b ?@(b [%tas b] b))
  ?:  ?=([%n ~] a)  %.y  :: n/~ is always first
  ?:  ?=([%n ~] b)  %.n
  ?.  =(-.a -.b)
    (aor -.a -.b)
  ::  heads equal — order by tail, dispatched by tag
  ::
  ?:  ?=(%pith -.a)
    ?>  ?=([%pith *] b)
    (por +.a +.b)
  ?:  ?=(?(%t %ta %tas %f) -.a)
    ?>  ?=(?(%t %ta %tas %f) -.b)
    (aor +.a +.b)
  ?:  ?=(@ +.a)
    ?>  ?=(@ +.b)
    (lte +.a +.b)
  ::  cell-tailed blobs (manx, tang, mime, data, json, noun) —
  ::  no semantic order, fall back to noun order
  ::
  (aor +.a +.b)
  ::
::
::
+$  iota  $+  iota  node
+$  pith  $+  pith  (list iota)
++  por
  ::
  ::  canonical pith order
  ::
  |=  [a=pith b=pith]
  ^-  ?
  ?~  a  %.y
  ?~  b  %.n
  ?.  =(i.a i.b)  (comp-nodes i.a i.b)
  $(a t.a, b t.b)
::
::
+$  aota
  ::
  $%
    [%ub =@ub]  [%uc =@uc]  [%ud =@ud]  [%ui =@ui]
    [%ux =@ux]  [%uv =@uv]  [%uw =@uw]
    [%sb =@sb]  [%sc =@sc]  [%sd =@sd]  [%si =@si]
    [%sx =@sx]  [%sv =@sv]  [%sw =@sw]
    [%da =@da]  [%dr =@dr]
    [%f f=?]    [%n ~]
    [%if =@if]  [%is =@is]
    [%t =@t]    [%ta =@ta]  [%tas =@tas]
    [%p =@p]    [%q =@q]
    [%rs =@rs]  [%rd =@rd]  [%rh =@rh]  [%rq =@rq]
  ==
::
++  oxal
  ::
  ::  $oxal: ordered, pith-based tree
  ::
  |$  [item]
  $:  leaf=(unit item)
      kids=((mop iota $) comp-nodes)
  ==
::
+$  case  @ud
+$  life  @ud
+$  hlc   $+(hlc [phys=@da logi=@ud])
::
++  hlc-tick
  ::
  ::  advance an hlc against wall-clock now (local cause).
  ::
  |=  [old=hlc now=@da]
  ^-  hlc
  ?:  (gth now phys.old)  [now 0]
  [phys.old +(logi.old)]
::
++  hlc-merge
  ::
  ::  merge a remote hlc into the local one against wall-clock now.
  ::
  |=  [old=hlc rem=hlc now=@da]
  ^-  hlc
  =/  m=@da  (max phys.old (max phys.rem now))
  ?:  &(=(m phys.old) =(m phys.rem))
    [m +((max logi.old logi.rem))]
  ?:  =(m phys.old)  [m +(logi.old)]
  ?:  =(m phys.rem)  [m +(logi.rem)]
  [m 0]
::
++  comp-hlcs
  ::
  ::  total order on hlcs: physical, then logical.
  ::
  |=  [a=hlc b=hlc]
  ^-  ?
  ?:  =(phys.a phys.b)  (lte logi.a logi.b)
  (lte phys.a phys.b)
::
::  pith aliases
::
::  base   pith    :: ??
+$  here   pith    :: a view's self location
+$  root   pith    :: location of a %view
+$  stem   pith    :: location of data below a %view
+$  line   pith    :: url sub-path
+$  stim   pith    :: ??
::
::
+$  twig   pith           :: a virual within a view (sans ~)
::
::
+$  data  $+  data  (oxal node)
+$  code  $+  code  (oxal meta)
::
::
+$  shape  (list %not-implemented)
+$  view
  $%  [%form form]  :: base data
      [%lens lens]  :: derived data
  ==
::
+$  form
  $:
    out=shape
  ==
+$  lens
  $:
    out=shape
    in=shape
    =sauc
    dep=link
    lyf=@ud
    cas=@ud
    err=(unit tang)
  ==
::
::  view-spec is the user-authored projection of a view — only the
::  fields a mesh-core may legitimately set.  the system fills in the
::  rest (lyf, cas, err) with defaults before placement.
::
+$  view-spec
  $%  [%form form-spec]
      [%lens lens-spec]
  ==
+$  form-spec
  $:
    out=shape
  ==
+$  lens-spec
  $:
    dep=link
    out=shape
    in=shape
    =sauc
  ==
::
+$  prior-form   $+  prior-form  [shape=(unit shape) =data]
+$  prior-forms  $+  prior-forms  (map stem prior-form)
::
+$  mesh-core
  ::
  ::  pure lifecycle declarer.  authored as a door over [our name].
  ::
  ::    +forms  declares the mesh's form-view stem locations — its
  ::            data-bearing footprint.  lens stems are not declared
  ::            here; they're discovered from the views ++load returns.
  ::            must be data-independent (the system invokes ++forms
  ::            without binding any prior data).
  ::
  ::    +load   produces the view layout and a migration move.  the
  ::            sample is keyed by (++forms ∪ outgoing form-view stems);
  ::            each entry carries the shape the outgoing version had
  ::            at that stem (~ on a stem with no prior form) and the
  ::            data at the stem.  views are returned as view-specs
  ::            (only the user-settable fields); the system supplies
  ::            defaults for lyf, cas, err, and the lens in/out shapes.
  ::            the form-typed keys of the returned specs must equal
  ::            ++forms exactly.  views are placed first, then output
  ::            is applied with allow-view-write=%.n.
  ::
  ::    +drop   terminal cleanup move.  required, but the body may
  ::            return *move to no-op.  views are torn down by the
  ::            system after.
  ::
  $_  ^|
  |_  [our=@p name=term]
  ++  forms  *(set stem)
  ++  load
    |~  =prior-forms
    *[views=(map stem view-spec) output=move]
  ++  drop
    |~  =prior-forms
    *move
  --
::
+$  mesh-source
  ::
  ::  source for a mesh.
  ::    %mono   single hoon door @t (the user authors a mesh-core).
  ::    %poly   per-view @t keyed by stem, each compiling to a
  ::            view-spec.  meant for ui-driven, per-view editing —
  ::            spreadsheet-style.
  ::
  $%  [%mono src=@t]
      [%poly srcs=(map stem @t)]
  ==
::
+$  mesh
  $:  =mesh-source
      =mesh-core
      forms=(set stem)
      views=(map stem view)
      error=(unit tang)
  ==
+$  meshes  (list [name=term =mesh])  ::  all named meshes
+$  link  [=ship =root]            ::  location
+$  sauc  $@(@t link)              ::  lambda code or [@t *] leaf location
::
+$  meta
  ::
  $+  meta
  $:  life=@ud
      =case
      logs=(list move)
      ::
      grow=_|              :: is this life static?, if no, lifes can be re-used.
      ::                   :: after yet, can't go back til next life
      ::
      eyre=(unit auth)     :: ~ not served over http, ^ who can request
      ::                   ::  (massive speedup with `[%white ~] or `[%black ~]
      ::                   ::   because those can make use of the eyre cache)
      ::
      ::                   ::  served under <domain>/-
      ::
      gall=(unit auth)     :: ~ no subcription facts, ^ who can subscribe
      ::
      lord=(unit [mesh=term =view])
      ::
      subs=(set pith)        :: views subscribed to my log
      view-subs=(set pith)   :: views using my node as code
  ==
::
+$  auth-kind
  $?  %white         :: only self
      %black         :: any ship
      %black-moon    :: any non-comet ship
      %black-planet  :: any planet or higher
      %black-star    :: any star or higher
      %black-galaxy  :: any galaxy
  ==
+$  auth       [kind=auth-kind exceptions=(set ship)]
++  check-auth
  ::
  |=  [=auth our=ship who=ship]
  ^-  ?
  ?:  =(our who)  &
  =/  allowed=?
    ?-  kind.auth
      %white         |
      %black         &
      %black-moon    !=(%pawn (clan:title who))
      %black-planet  ?=(?(%czar %king %duke) (clan:title who))
      %black-star    ?=(?(%czar %king) (clan:title who))
      %black-galaxy  =(%czar (clan:title who))
    ==
  ?:  (~(has in exceptions.auth) who)
    !allowed
  allowed
::
+$  file  [=data =code]
+$  acer
  ::
  $:  =file
      nuke=@ud
      xfms=(map @t transformer) :: xx (map @t [transformer (set pith)]) :: (set pith) is refcount
      ::
      ::  agent-level hybrid logical clock.  advanced on every local
      ::  cause and on every remote-receive.  the source of truth for
      ::  "the next timestamp this ship will emit".
      ::
      now-hlc=hlc
      ::
      ::  future field: an index of local subscribers keyed by remote
      ::  faucet [ship pith].  when the gall-networking layer lands,
      ::  it will read this to decide which remote ships to open
      ::  watches on without walking the code tree.  maintained by
      ::  +install / +uninstall.
      ::
      ::  remote-subs=(jar link pith)
      ::
      ::  future field
      =meshes
  ==
::
+$  chng
  $+  chng
  $%  [%ins =pith =node]
      [%del =pith]
  ==
+$  move  $+(move [time=hlc chng-set=(set chng)])
+$  meta-chng
  $+  meta-chng
  $%  [%ins =pith =meta]
      [%del =pith]
  ==
+$  meta-move  $+(meta-move (set meta-chng))
+$  transformer  $-([mine=data snap=data =move life=@ case=@] (set chng))
::
++  ref-to-pith
  ::
  ::  link to a tree pith: [ship root] -> /[ship]/root
  ::
  |=  r=link
  ^-  pith
  [p+ship.r root.r]
::
++  pith-of-chng
  ::
  ::  extract the pith from a chng
  ::
  |=  =chng
  ^-  pith
  ?-(-.chng %ins pith.chng, %del pith.chng)
::
++  prefix-chngs
  ::
  ::  weld a prefix pith onto every chng in a set.
  ::
  |=  [pre=pith chngs=(set chng)]
  ^-  (set chng)
  %-  silt
  %+  turn  ~(tap in chngs)
  |=  =chng
  ?-  -.chng
    %ins  chng(pith (weld pre pith.chng))
    %del  chng(pith (weld pre pith.chng))
  ==
::
++  prefix-move
  ::
  ::  weld a prefix pith onto every chng in a move; preserve time.
  ::
  |=  [pre=pith =move]
  ^-  ^move
  move(chng-set (prefix-chngs pre chng-set.move))
::
+$  bond  (pair pith node)
+$  bonds  (list bond)
::
++  modi  ((on iota data) comp-nodes)
++  moci  ((on iota code) comp-nodes)
::
:: :: :: :: :: :: :: :: :: :: :: :: :: :: :: :: :: :: 
::
::  oxal engine
::
++  ox
  =|  fat=(oxal)
  |@
  ++  cor  .
  +$  item  _?>(?=(^ leaf.fat) u.leaf.fat)
  +$  xal  (oxal item)
  ++  ion  ((on iota (oxal item)) comp-nodes)
  ::
  ++  kid-list
    ::
    ^-  (list (pair iota xal))
    (tap:ion kids.fat)
  ::
  ++  check-sizes  !!
  ++  recompute-sizes  !!
  ::
  ++  wyt  (lent tap)
  ::
  ++  dip
    ::
    |=  pax=pith
    ^+  fat
    ?~  pax  fat
    =/  kid  (get:ion kids.fat i.pax)
    ?~  kid  [~ ~]
    $(fat u.kid, pax t.pax)
  ::
  ++  dit
    ::
    |=  pax=pith
    ^+  cor
    ~(. cor (dip pax))
  ::
  ++  din  :: dip and remove kids
    ::
    |=  pax=pith
    ^+  fat
    (~(pet ox *(oxal item)) / (get pax))
  ::
  ++  dik  :: dip and remove node
    ::
    |=  pax=pith
    ^+  fat
    =.  fat  (dip pax)
    =.  fat  (del /)
    fat
  ::
  ++  get
    ::
    |=  pax=pith
    ^-  (unit item)
    leaf:(dip pax)
  ::
  ++  got
    ::
    |=  pax=pith
    ~|  not-got/pax
    (need (get pax))
  ::
  ++  nep
    ::
    |=  toy=iota
    ^-  (unit item)
    ?~  kid=(get:ion kids.fat toy)  ~
    leaf.u.kid
  ::
  ++  nop
    ::
    |=  toy=iota
    ^-  item
    (need (nep toy))
  ::
  ++  ram
    ::
    ::  rightmost or null
    ::
    ^-  (unit [iota xal])
    (ram:ion kids.fat)
  ::
  ++  rom
    ::
    ::  rightmost
    ::
    ^-  [iota xal]
    (need ram)
  ::
  ++  dys  :: y leaf
    ::
    ^-  (list (pair iota item))
    %+  murn  (tap:ion kids.fat)
    |=  [=iota f=_fat]
    ?~  leaf.f  ~
    `[iota u.leaf.f]
  ::
  ++  only-y
    ::
    ^+  fat
    fat
  ::
  ++  fit
    ::
    ::  longest root with a leaf
    ::
    |=  pax=pith
    ^+  [root=pax stem=pax leaf=leaf.fat]
    =;  [stem=pith leaf=(unit item)]
      :+  (scag (sub (lent pax) (lent stem)) pax)
        stem
      leaf
    |-
    ^+  [pax leaf.fat]
    ?~  pax  [~ leaf.fat]
    =/  kid  (get:ion kids.fat i.pax)
    ?~  kid  [pax leaf.fat]
    =/  low  $(fat u.kid, pax t.pax)
    ?~  +.low
      [pax leaf.fat]
    low
  ::
  ++  anc
    ::
    ::  ancestors (including self) matching some condition
    ::
    ::  the longest match is at the head of the returned list
    ::
    |=  [self=pith con=$-(_fat ?)]
    ^-  (list (pair pith _fat))
    =|  loc=pith
    =|  out=(list (pair pith _fat))
    |-
    =?  out  (con fat)  [[loc fat] out]
    ?:  =(self loc)  out
    =/  seg  (snag (lent loc) self)
    =.  loc  (snoc loc seg)
    $(fat (dip #/[seg]))
    ::
  ++  abo
    ::
    ::  +anc without self
    ::
    |=  [self=pith con=$-(_fat ?)]
    ^-  (list (pair pith _fat))
    =/  ancs  (anc self con)
    ?~  ancs  ~
    ?:  =(p.i.ancs self)  t.ancs
    ancs
  ::
  ++  kiz
    ::
    ::  descendants matchings some condition
    ::    (not including self)
    ::
    |=  [self=pith con=$-(_fat ?)]
    ^-  (list (pair pith _fat))
    !!  :: xx
  ::
  ++  has
    ::
    |=  pax=pith
    ^-  ?
    !=(~ (get pax))
  ::
  ++  hos
    ::
    |=  pax=pith
    ^-  ?
    =/  d  (dip pax)
    ?|
      !=(~ kids:d)
      !=(~ leaf:d)
    ==
  ::
  ++  has-kids
    ::
    |=  pax=pith
    ^-  ?
    !=(~ kids:(dip pax))
  ::
  ++  tap
    ::
    ::  listify
    ::
    =|  pax=pith
    =|  out=(list (pair pith _?>(?=(^ leaf.fat) u.leaf.fat)))
    |-  ^+   out
    =?  out  ?=(^ leaf.fat)  :_(out [pax u.leaf.fat])
    =/  kids=(list (pair iota _fat))  (tap:ion kids.fat)
    |-  ^+   out
    ?~  kids  out
    %=  $
      kids  t.kids
      out  ^$(pax (weld pax /[p.i.kids]), fat q.i.kids)
    ==
  ::
  ++  tap-gens
    ::
    ::  listify within .gen generations
    ::
    |=  gens=@
    =|  lvl=@ud
    =|  pax=pith
    =|  out=(list (pair pith _?>(?=(^ leaf.fat) u.leaf.fat)))
    |-  ^+   out
    ?:  (gte lvl gens)  out
    =.  lvl  +(lvl)
    =?  out  ?=(^ leaf.fat)  :_(out [pax u.leaf.fat])
    =/  kids=(list (pair iota _fat))  (tap:ion kids.fat)
    |-  ^+   out
    ?~  kids  out
    %=  $
      kids  t.kids
      out  ^$(pax (weld pax /[p.i.kids]), fat q.i.kids)
    ==
  ::
  ++  tah  (turn tap head)
  ::
  ++  tah-inner
    ::
    ::  list of paths with population below a n/~
    ::
    =|  pax=pith
    =|  out=(list pith)
    |-  ^+   out
    =/  kids=(list (pair iota _fat))  (tap:ion kids.fat)
    |-  ^+   out
    ?~  kids  out
    ?:  ?=([%n ~] p.i.kids)
      %=  $
        kids  t.kids
        out   [pax out]
      ==
    %=  $
      kids  t.kids
      out  ^$(pax (weld pax /[`iota`p.i.kids]), fat q.i.kids)
    ==
  ::
  ++  tap-inner
    ::
    ::  list of [pith data] with population below a n/~
    ::
    =|  pax=pith
    =|  out=(list [pith _fat])
    |-  ^+   out
    =/  kids=(list (pair iota _fat))  (tap:ion kids.fat)
    |-  ^+   out
    ?~  kids  out
    ?:  ?=([%n ~] p.i.kids)
      %=  $
        kids  t.kids
        out   [[pax q.i.kids] out]
      ==
    %=  $
      kids  t.kids
      out  ^$(pax (weld pax /[`iota`p.i.kids]), fat q.i.kids)
    ==
  ::
  ++  yap
    ::
    :: tap y-s only
    ::
    %+  murn  kid-list
    |=  [=iota o=_fat]
    ?~  leaf.o  ~
    `[iota u.leaf.o]
  ::
  ++  nic
    ::
    ::  delete kids but not leaf
    ::
    |=  pax=pith
    =/  e  (get pax)
    =.  fat  (lop pax)
    =.  fat  (pet pax e)
    fat
  ::
  ++  lop
    ::
    ::  delete subtree
    ::
    |=  pax=pith
    ?:  =(~ pax)  [~ ~]
    |-
    ^+  fat
    ?~  pax
      fat(leaf ~, kids ~)
    =/  kid  (get:ion kids.fat i.pax)
    ?~  kid  fat
    =/  f=_fat  $(fat u.kid, pax t.pax)
    =;  ore=_fat
      =/  kod  (got:ion kids.ore i.pax)
      ?.  &(?=(~ leaf.kod) ?=(~ kids.kod))
        ore
      ore(kids +:(del:ion kids.ore i.pax))
    fat(kids (put:ion kids.fat i.pax f))
  ::
  ++  del
    ::
    ::  delete leaf
    ::
    |=  pax=pith
    ^-  (oxal item)
    |-
    ^-  (oxal item)
    ?~  pax
      fat(leaf ~)
    =/  kid  (get:ion kids.fat i.pax)
    ?~  kid  fat
    =/  f=(oxal item)  $(fat u.kid, pax t.pax)
    =;  ore=(oxal item)
      ^-  (oxal item)
      =/  kod  (got:ion kids.ore i.pax)
      ?.  &(=(~ leaf.kod) =(~ kids.kod))
        ore
      ore(kids +:(del:ion kids.ore i.pax))
    fat(kids (put:ion kids.fat i.pax f))
  ::
  ++  pet
    ::
    ::  maybe insert leaf
    ::
    |*  [pax=pith dat=(unit *)]
    =>  .(dat `(unit item)`dat, pax `pith`pax)
    ?~  dat  fat
    (put pax u.dat)
  ::
  ++  ins
    ::
    ::  insert leaf or delete
    ::
    |*  [pax=pith dat=(unit *)]
    =>  .(dat `(unit item)`dat, pax `pith`pax)
    ?~  dat  (del pax)
    (put pax u.dat)
  ::
  ++  put
    ::
    ::  insert leaf
    ::
    |*  [pax=pith dat=*]
    =>  .(dat `_?>(?=(^ leaf.fat) u.leaf.fat)`dat, pax `pith`pax)
    |-
    ^+  fat
    ?~  pax  fat(leaf `dat)
    =/  kid=_fat
      (fall (get:ion kids.fat i.pax) ^+(fat [~ ~]))
    =/  f=_fat  $(fat kid, pax t.pax)
    fat(kids (put:ion kids.fat i.pax f))
  ::
  ++  mol
    ::
    ::  morph leaf
    ::
    |*  [pax=pith morph=$-((unit item) (unit item))]
    ^+  fat
    (ins pax (morph leaf:(dip pax)))
    ::
  ::
  ++  mox
    ::
    ::  morph subtree
    ::
    |*  [pax=pith morph=$-(xal xal)]
    ^+  fat
    %+  rep  pax
    (morph (dip pax))
  ::
  ++  rep
    ::
    ::  replace subtree
    ::
    |*  [pax=pith new=_fat]
    |-
    ^+  fat
    ?~  pax  new
    =/  kid=_fat
      (fall (get:ion kids.fat i.pax) ^+(fat [~ ~]))
    =/  f=_fat  $(fat kid, pax `pith`t.pax)
    fat(kids (put:ion kids.fat i.pax f))
  ::
  +$  band  (pair pith item)
  ::
  ++  gas
    ::
    ::  insert many from list
    ::
    |=  lit=(list band)
    ^+  fat
    (gis / lit)
    :: (cury gis /)
  ::
  ++  gis
    ::
    ::  gas at subpath
    ::
    |=  [pax=pith lit=(list band)]
    ^+  fat
    ?~  lit  fat
    $(fat (put (welp pax p.i.lit) q.i.lit), lit t.lit)
  ::
  ++  ges
    ::
    ::  gas units at subpath
    ::
    |=  [pax=pith lit=(list (pair pith (unit item)))]
    ^+  fat
    ?~  lit  fat
    ?~  q.i.lit  $(lit t.lit)
    $(fat (put (welp pax p.i.lit) u.q.i.lit), lit t.lit)
  ::
  ++  gep
    ::
    ::  gas oxals at subpaths
    ::
    |=  lit=(list (pair pith xal))
    ^+  fat
    ?~  lit  fat
    %=  $
      lit  t.lit
      fat  (rep p.i.lit q.i.lit)
    ==
  ::
  ++  mer
    ::
    ::  merge in file (slow!)
    ::
    |=  [=pith new=_fat]
    ^+  fat
    =/  bonds  ~(tap ox new)
    |-
    ?~  bonds  fat
    =.  fat  (put (welp pith p.i.bonds) q.i.bonds)
    $(bonds t.bonds)
  ::
  ++  ran
    ::
    ::  transform kids, in place
    ::
    |=  g=$-(xal xal)
    ^+  fat
    %=  fat
      kids  (run:ion kids.fat g)
    ==
  ::
  ++  run
    ::
    ::  transform & filter kids, in place
    ::
    |=  g=$-([iota xal] (unit xal))
    ^+  fat
    %=  fat
      kids
        ^+  kids.fat
        =<  +
        %^  (dip:ion ,~)  kids.fat  ~
        |=  [@ k=iota v=xal]
        :-  (g k v)
        [.n ~]
    ==
  ::
  ++  ren
    ::
    ::  render kids
    ::
    |=  g=$-([iota xal] (unit manx))
    ^-  marl
    %-  flop
    =<  -
    %^  (dip:ion marl)  kids.fat  ~
    |=  [=marl k=iota v=xal]
    :-  ~
    :-  %.n
    =/  try=(unit manx)  (g k v)
    ?~  try  marl
    [u.try marl]
  ::
  ++  tur
    ::
    |*  g=gate
    ::
    =/  a  tap
    |-
    ?~  a  ~
    [i=(g -.a) t=$(a +.a)]
    ::
  ::
  ++  mur
    ::
    |*  g=gate
    ::
    =/  a  tap
    |-
    ?~  a  ~
    =/  x  (g -.a)
    ?~  x  $(a +.a)
    [i=+.x t=$(a +.a)]
    ::
  --
::
::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::
::
::  +th: pith engine
::
++  th
  ::
  |_  a=pith
  ++  ends-in
    ::
    ::  does a end in b
    ::
    |=  b=pith
    ^-  ?
    ?:  =((lent b) 0)  %.n
    ?.  (gte (lent a) (lent b))  %.n
    .=  b
    (slag (sub (lent a) (lent b)) a)
    ::
  ++  prefix-ends-in
    ::
    ::  the longest prefix of a which ends in b
    ::
    |=  b=pith
    ^-  (unit pith)
    ?:  =((lent b) 0)  ~
    ?~  a  ~
    ?:  (~(ends-in th a) b)  `a
    $(a t.a)
    ::
  ++  split-end
    ::
    |=  stem=pith
    ^-  pith
    (scag (sub (lent a) (lent stem)) a)
    ::
  ++  ancestors
    ::
    ^-  (list pith)
    %-  snip
    %+  turn  (gulf 0 (lent a))
    |=  n=@
    (scag n a)
    ::
  ++  is-ancestor
    ::
    ::  is b the ancestor of a
    ::
    |=  b=pith
    ^-  ?
    .=  b
    (scag (lent b) a)
    ::
  ++  is-ancestor-or-same
    ::
    ::  is b the ancestor of a
    ::
    |=  b=pith
    ^-  ?
    ?|  =(a b)
        (is-ancestor b)
    ==
  --
::
::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::
::  node <-> coin bridge
::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::
::
++  coin-to-node
  ::
  |=  =coin
  ^-  node
  ?-  -.coin
    %$
      ^-  node
      ?:  ?=(%tas -.p.coin)
        +.p.coin
      ~|  %failed-dime-to-coin
      (node p.coin)
    %blob   [%noun +.coin]
    %many
      :-  %pith
      ^-  pith
      %+  turn  p.coin
      |=  c=^coin
      ^$(coin c)
  ==
::
++  node-to-coin
  ::
  |=  nod=node
  ^-  coin
  ?+  nod  [%blob nod]
    @  [%$ %tas nod]
    aota   [%$ nod]
    [%pith *]
      :-  %many
      %+  turn  pith.nod
      |=  nod=node
      ^$(nod nod)
  ==
::
::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::
::  pith <-> path bridge
::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::
::
::    +pave  path -> pith (slay-decode each segment)
::    +pout  pith -> path (rend each segment via coin)
::
++  pave
  ::
  |=  pit=pith
  ^-  pith
  %+  turn  pit
  |=  i=iota
  ?@  i
    ^-  iota
    =;  =coin  (coin-to-node coin)
    %+  fall
      (rush i nuck:so)
    ?:  =('.__' i)  [%many ~]
    ?:  =('' i)     [%$ %tas %$]
    [%$ %t (@t i)]
  i
::
++  pout
  ::
  |=  =pith
  ^-  path
  %+  turn  pith
  |=  =node
  %-  crip
  ~(rend co (node-to-coin node))
::
::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::
::  url-safe round-trip serializers
::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::
::
::    +nate  node -> tape   (terms render as %foo)
::    +sily  tape -> node   (inverse of +nate)
::    +pate  pith -> tape   (path-segment form, no % on terms)
::    +stib  tape -> pith   (inverse of +pate; +stip on the inside)
::
++  nate
  ::
  ::  hoon-literal form: terms render as %foo so the output is
  ::  unambiguously parseable by +sily.
  ::
  |=  =node
  ^-  tape
  ?@  node  ['%' (trip node)]
  ~(rend co (node-to-coin node))
::
++  sily
  ::
  ::  url-safe tape -> node.
  ::
  |=  tap=tape
  ^-  iota
  =/  =wall
    %-  turn  :_  trip
    %-  to-wain:format
    (crip tap)
  ?:  (lte (lent wall) 1)
    %-  fall  :_  t+(crip tap)
    %-  mole  |.
    ?:  =('/' (snag 0 tap))
      pith+(stib tap)
    ?:  =('%' (snag 0 tap))
      ::
      ::  hoon-literal term: %foo, %$
      ::
      =/  rest=tape  (slag 1 tap)
      ?~  rest  ^-  iota  %$
      ^-  iota
      `@tas`(scan rest sym:so)
    %-  iota
    %+  snag  0
    (scan (welp "/" tap) stip)
  !!
::
++  pate
  ::
  ::  pith renders as a path; each segment is the path-style form of
  ::  its node (terms bare, with no %), matching what +stip parses.
  ::
  |=  =pith
  ^-  tape
  %-  zing
    =;  =wall
      ?^  wall  wall
      ~["/"]
  %+  turn  pith
  |=  =node
  :-  '/'
  ?@  node  (trip node)
  ~(rend co (node-to-coin node))
::
++  stib
  ::
  ::  url-safe tape -> pith.
  ::
  |=  =tape
  ^-  pith
  ~|  invalid-pith-tape+(crip tape)
  (scan tape stip)
::
++  stip
  ::
  ::  parser combinator (rule) consumed by +stib and +sily.  parses
  ::  /-prefixed paths whose segments are slay-decodable coins.
  ::
  =<  swot
  |%
  ++  swot  |=(n=nail (;~(pfix fas (more fas spot)) n))
  ::
  ++  spot
    %+  sear
      |=  txt=tape
      ^-  (unit iota)
      ?~  cn=(slay (crip txt))  ~
      `(coin-to-node u.cn)
    (plus ;~(less fas next))
  --
::
::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::
::  hoon-source round-trip serializers (via +ream)
::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::
::
::    +nare  node -> tape (human-readable hoon source)
::    +pare  pith -> tape (human-readable hoon source)
::
::  unlike +nate / +pate (terse, url-safe), these emit the form
::  a programmer would write in source, e.g. for [%t cord]:
::
::      :-  %t
::      '''
::      <text>
::      '''
::
::  inverse: +ream + +slap (no built-in helper).
::
++  nare
  ::
  |=  =node
  ^-  tape
  ?@  node
    ?:  =(%$ node)  "%$"
    ['%' (trip node)]
  ?+    node  <node>
    [%t *]
        %-  trip
        %^  cat  3  ':-  %t\0a'
        %^  cat  3  '\'\'\'\0a'
        %^  cat  3  t.node
        '\0a\'\'\''
    [%mime *]
        ?.  ?=([%text * ~] p.mime.node)  <node>
        %-  of-wall:format
        :~  ":+  %mime  {(spud p.mime.node)}"
            "%-  as-octs:mimes:html"
            "'''"
            (trip q.q.mime.node)
            "'''"
        ==
    [%pith *]
        (welp "[%pith " (welp (pare pith.node) "]"))
    aota
        ::  wide-form coin literal: ud+42, p+~zod, da+~2026.4.30 — fits
        ::  inside ~[...] list literals so +pare stays roundtripable.
        ::
        %+  welp  (trip -.node)
        ['+' (scow node)]
  ==
::
++  pare
  ::
  ::  emits a pith as the bracketed `#/` path-literal hoon syntax,
  ::  which (unlike `/foo/bar`) parses without a trailing `%$`.
  ::  segments use the path parser's coin auto-decoding for atoms
  ::  (foo, 22, ~zod, ...).  nested pith nodes are emitted as
  ::  `[pith+<pare>]`, which the path parser reads as a wide-form
  ::  cell `[%pith inner]`.
  ::
  ::      ~              ->  "~"
  ::      /foo/bar       ->  "[#/foo/bar]"
  ::      /foo/22        ->  "[#/foo/22]"
  ::      /a/[%pith /b]  ->  "[#/a/[pith+[#/b]]]"
  ::
  |=  pat=pith
  ^-  tape
  ?~  pat  "~"
  =/  full=pith  pat
  =/  inner=tape
    %-  zing
    %+  turn  full
    |=  =node
    ^-  tape
    :-  '/'
    ?@  node  (trip node)
    ?:  ?=([%pith *] node)
      ;:  weld
        "[pith+"
        (pare pith.node)
        "]"
      ==
    ~(rend co (node-to-coin node))
  (welp "#" inner)
::
::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::
::  human-readable summaries (lossy, not round-trippable)
::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::  ::
::
::    +node-summary  one-line, max-80-char, no-newlines tape summary
::                   of a node.  delegates per-type to +raw-summary.
::    +print-aura    aura name as a tape ("ud", "tas", ...)
::    +print-aota    +scow with safe fallback for any aota
::
++  node-summary
  ::
  ::  one-line, human-readable summary of a node.  no newlines, max
  ::  80 characters with trailing "..." if truncated.  not round-
  ::  trippable; use +nate / +nare for that.
  ::
  ::  some node types have richer summaries:
  ::    %mime  shows the mime type and byte count
  ::    %manx  shows the tag with id, classes, and trailing attr count
  ::    %data  shows the leaf count
  ::    %t     shows the cord truncated to first newline
  ::    %tang  flattens to a single line
  ::    aota   uses +scow on the dime
  ::
  |=  nod=node
  ^-  tape
  =/  raw=tape
    =;  x=(unit tape)
      ?^  x  u.x
      "render-failed"
    %-  mole  |.
    (raw-summary nod)
  =/  flat=tape  (flatten-tape raw)
  ?:  (lte (lent flat) 80)  flat
  (welp (scag 77 flat) "...")
::
++  raw-summary
  ::
  |=  nod=node
  ^-  tape
  ?@  nod  (trip nod)
  ?-    -.nod
      ?(%n %f %ub %uc %ud %ui %ux %uv %uw %sb %sc %sd %si %sx %sv %sw)
        (print-aota nod)
      ?(%da %dr %if %is %ta %p %q %rs %rd %rh %rq)
        (print-aota nod)
      %t
        ::  cord up to first newline
        ::
        %-  trip
        ^-  @t
        =/  long  t.nod
        =|  out=@t
        |-
        ?~  long  out
        =/  firt  (cut 3 [0 1] long)
        ?:  =(firt 10)  out
        =.  out  (cat 3 out firt)
        $(long (rsh 3 long))
      %pith  (pate pith.nod)
      %data  "<data {(a-co:co (lent ~(tap ox data.nod)))} leaves>"
      %manx  (manx-summary manx.nod)
      %mime  "{(spud p.mime.nod)} ({(a-co:co p.q.mime.nod)} bytes)"
      %tang
        %-  zing
        %+  turn  tang.nod
        |=  =tank
        %-  of-wall:format
        (~(win re tank) 0 80)
      %json  "<json>"
      %noun  "<noun>"
  ==
::
++  flatten-tape
  ::
  ::  replace newlines with spaces.
  ::
  |=  tap=tape
  ^-  tape
  %+  turn  tap
  |=  c=@tD
  ?:(=(10 c) ' ' c)
::
++  manx-summary
  ::
  ::  ";tag#id.class +N attrs" — only id and class are shown by
  ::  value; remaining attribute count is appended if non-zero.
  ::
  |=  =manx
  ^-  tape
  =/  =marx  g.manx
  =/  tag=tape
    ?@  n.marx  (trip n.marx)
    "{(trip -.n.marx)}:{(trip +.n.marx)}"
  =/  attrs=mart  a.marx
  =/  id=(unit tape)  (lookup-attr 'id' attrs)
  =/  cls=(unit tape)  (lookup-attr 'class' attrs)
  =/  other=@ud
    %-  lent
    %+  skip  attrs
    |=  [n=mane v=tape]
    ?&  ?=(@ n)
        |(=('id' n) =('class' n))
    ==
  =/  out=tape  (welp ";" tag)
  =?  out  ?=(^ id)   (welp out (welp "#" u.id))
  =?  out  ?=(^ cls)
    %-  zing
    :~  out
        "."
        (turn u.cls |=(c=@tD ?:(=(' ' c) '.' c)))
    ==
  =?  out  (gth other 0)
    "{out} +{(a-co:co other)} attr{?:(=(other 1) "" "s")}"
  out
::
++  lookup-attr
  ::
  |=  [name=@tas attrs=mart]
  ^-  (unit tape)
  ?~  attrs  ~
  =/  n  n.i.attrs
  ?:  &(?=(@ n) =(name n))
    `v.i.attrs
  $(attrs t.attrs)
::
++  print-aota
  ::
  |=  =aota
  ^-  tape
  ?+  -.aota
    %-  fall  :_  "print-error {<aota>}"
    %-  mole  |.
    (scow aota)
    %p    (scow %p +.aota)
    %da   (scow %da +.aota)
    %ud   (scow %ud +.aota)
    %t    (trip +.aota)
    %ta   (trip +.aota)
  ==
::
++  print-aura
  ::
  |=  nod=node
  ^-  tape
  ?@  nod
    "tas"
  (trip -.nod)
::
++  node-as
  ::
  |*  [aura=term =node]
  ?-  aura
    %tas   ?>  ?=(@ node)          node
    %n     ?>  ?=([%n *] node)     +.node
    %f     ?>  ?=([%f *] node)     +.node
    %ta    ?>  ?=([%ta *] node)    +.node
    %t     ?>  ?=([%t *] node)     +.node
    %p     ?>  ?=([%p *] node)     +.node
    %q     ?>  ?=([%q *] node)     +.node
    %da    ?>  ?=([%da *] node)    +.node
    %dr    ?>  ?=([%dr *] node)    +.node
    %if    ?>  ?=([%if *] node)    +.node
    %is    ?>  ?=([%is *] node)    +.node
    %ub    ?>  ?=([%ub *] node)    +.node
    %uc    ?>  ?=([%uc *] node)    +.node
    %ud    ?>  ?=([%ud *] node)    +.node
    %ui    ?>  ?=([%ui *] node)    +.node
    %ux    ?>  ?=([%ux *] node)    +.node
    %uv    ?>  ?=([%uv *] node)    +.node
    %uw    ?>  ?=([%uw *] node)    +.node
    %sb    ?>  ?=([%sb *] node)    +.node
    %sc    ?>  ?=([%sc *] node)    +.node
    %sd    ?>  ?=([%sd *] node)    +.node
    %si    ?>  ?=([%si *] node)    +.node
    %sx    ?>  ?=([%sx *] node)    +.node
    %sv    ?>  ?=([%sv *] node)    +.node
    %sw    ?>  ?=([%sw *] node)    +.node
    %rs    ?>  ?=([%rs *] node)    +.node
    %rd    ?>  ?=([%rd *] node)    +.node
    %rh    ?>  ?=([%rh *] node)    +.node
    %rq    ?>  ?=([%rq *] node)    +.node
    %tang  ?>  ?=([%tang *] node)  +.node
    %manx  ?>  ?=([%manx *] node)  +.node
    %json  ?>  ?=([%json *] node)  +.node
    %mime  ?>  ?=([%mime *] node)  +.node
    %noun  ?>  ?=([%noun *] node)  +.node
    %pith  ?>  ?=([%pith *] node)  +.node
    %data  ?>  ?=([%data *] node)  +.node
  ==
::
++  make-gut
  ::
  |*  [nude=(unit node) aura=term default=node]
  =/  back  (node-as aura default)
  ?~  nude  back
  %-  fall  :_  back
  %-  mole  |.
  (node-as aura u.nude)
::
++  bunt-node
  ::
  ::  bunt-node: construct the bunt node for an aura
  ::
  ::    dual of node-as. used by tit (polymorphic git).
  ::
  |*  aura=term
  ^-  node
  ?-  aura
    %tas   %$
    %n     n+~         %f     f+*@f
    %t     t+*@t       %ta    ta+*@ta
    %p     p+*@p       %q     q+*@q
    %da    da+*@da     %dr    dr+*@dr
    %if    if+*@if     %is    is+*@is
    %ub    ub+*@ub     %uc    uc+*@uc
    %ud    ud+*@ud     %ui    ui+*@ui
    %ux    ux+*@ux     %uv    uv+*@uv     %uw    uw+*@uw
    %sb    sb+*@sb     %sc    sc+*@sc
    %sd    sd+*@sd     %si    si+*@si
    %sx    sx+*@sx     %sv    sv+*@sv     %sw    sw+*@sw
    %rs    rs+*@rs     %rd    rd+*@rd
    %rh    rh+*@rh     %rq    rq+*@rq
    %tang  tang+*tang   %manx  manx+*manx
    %json  json+*json   %mime  mime+*mime
    %noun  noun+*noun   %pith  pith+*pith   %data  data+*data
  ==
::
++  mono
  ::
  |=  =node
  ^-  data
  %*  .  *data
    leaf  `node
  ==
::
::  data engine
::
::    this exists mostly because raw +ox
::    in userspace has very slow compile times.
::    and faster compile times is better bc our
::    users are developers. they will be compiling.
::
++  do
  |_  dat=data
  ++  ion  ((on iota data) comp-nodes)
  ++  ox  ~(. ^ox dat)
  ::
  ::
  ++  kid-list     kid-list:ox
  ++  wyt  wyt:ox
  ++  dip  dip:ox
  ++  anc  anc:ox
  ++  din  din:ox
  ++  dik  dik:ox
  ++  dit  |=  =pith  ~(. do (dip pith))
  ++  get  get:ox
  ++  got  got:ox
  ++  gut
    ::
    |=  [=pith back=node]
    (fall (get pith) back)
  ++  nep  nep:ox
  ++  nop  nop:ox
  ++  fit  fit:ox
  ++  has  has:ox
  ++  hos  hos:ox
  ++  has-kids  has-kids:ox
  ++  tap  tap:ox
  ++  tap-gens  tap-gens:ox
  ++  tah  tah:ox
  ++  tah-inner  tah-inner:ox
  ++  tap-inner  tap-inner:ox
  ++  yap  yap:ox
  ++  lop  lop:ox
  ++  nic  nic:ox
  ++  del  del:ox
  ++  pet  pet:ox
  ++  put  put:ox
  ++  rep  rep:ox
  ++  gep  gep:ox
  ++  gas  gas:ox
  ++  gis  gis:ox
  ++  ges  ges:ox
  ++  mer  mer:ox
  ++  ran  ran:ox
  ++  run  run:ox
  ++  ren  ren:ox
  ++  ram  ram:ox
  ++  rom  rom:ox
  ++  mol  mol:ox
  ++  mox  mox:ox
  ++  tur  tur:ox
  ++  mur  mur:ox
  ::
  ++  peb
    ::
    |=  pax=pith
    ^-  (unit tape)
    ?~  x=(get pax)  ~
    `(node-summary u.x)
    ::
  ++  pib
    ::
    |=  pax=pith
    ^-  tape
    %+  fall  (peb pax)  ""
    ::
  ++  pob
    ::
    |=  pax=pith
    ^-  tape
    (node-summary (got pax))
    ::
  ++  pub
    ::
    |=  [pax=pith back=tape]
    ^-  tape
    ?~  x=(get pax)  back
    (node-summary u.x)
    ::
  ::
  ::  polymorphic getters: aura-parameterized node accessors
  ::
  ::    (tot:d %ud /x)          assert + extract
  ::    (tet:d %ud /x)          optional extract
  ::    (tit:d %ud /x)          bunt default
  ::    (tut:d ud+0 /x)         user default
  ::
  ++  tot
    ::
    |*  [aura=term pax=pith]
    (node-as aura (got:ox pax))
  ::
  ++  tet
    ::
    |*  [aura=term pax=pith]
    =/  nod  (get:ox pax)
    ?~  nod  ~
    %-  mole  |.
    (node-as aura u.nod)
  ::
  ++  tit
    ::
    |*  [aura=term pax=pith]
    (make-gut (get:ox pax) aura (bunt-node aura))
  ::
  ++  tut
    ::
    |*  [sam=node pax=pith]
    (make-gut (get:ox pax) ?@(sam %tas -.sam) sam)
    ::
  --
  ::
::
::  code helpers
::
++  handler
  ::
  ::  nearest non-suspended view
  ::
  |=  [co=code =stem]
  ^-  (list (pair pith code))
  %+  ~(anc ox co)  stem
  |=  code
  ?&  ?=(^ leaf)
      ?=(^ lord.u.leaf)
      ?=(%lens -.view.u.lord.u.leaf)
      ?=(~ err.view.u.lord.u.leaf)
  ==
  ::
::
+$  easy-core  $+  easy-core
  $_  ^&
  |%
  ++  ins
    ::
    ^*
    $-  [pith node]
    (unit chng)
    ::
  ++  del
    ::
    ^*
    $-  pith
    (unit chng)
    ::
  --
::
++  easy-transform
  ::
  |=  ec=easy-core
  ^-  transformer
  |=  [mine=data snap=data =move *]
  ^-  (set chng)
  %-  silt
  ^-  (list chng)
  ?:  =(~ chng-set.move)  (~(mur do snap) ins:ec)
  %+  murn  ~(tap in chng-set.move)
  |=  =chng
  ^-  (unit _chng)
  ?-  -.chng
    %del  (del:ec pith.chng)
    %ins  (ins:ec pith.chng node.chng)
  ==
::
++  easy-mirror
  %-  easy-transform
  |%
  ++  ins
    |=  [=pith =node]
    `[%ins pith node]
  ++  del
    |=  =pith
    `[%del pith]
  --
--
