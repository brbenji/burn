::  oxal : the backbone of a programmable interface
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
++  comp-nodes  ::: xx i think this is broken for pith comparisons
  ::
  ::  canonical node ordering
  ::
  |=  [a=* b=*]
  ^-  ?
  =>  .(a ?@(a [%tas a] a), b ?@(b [%tas b] b))
  ?>  ?=([@ *] a)
  ?>  ?=([@ *] b)
  ?:  ?=([%n ~] a)  %.y  :: n/~ is always first
  ?:  ?=([%n ~] b)  %.n  ::
  ?.  =(-.a -.b)
    (aor -.a -.b)
  ?:  ?=(^ +.a)  %.y  :: xx maybe broken here
  ?:  ?=(^ +.b)  %.y
  ?:  ?=(?(%t %ta %tas %f) -.a)
    (aor +.a (@ +.b))
  (lte +.a (@ +.b))
  ::
::
::
+$  iota  $+  iota  node
+$  pith  $+  pith  (list iota)
+$  line  pith
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
  $:  =meta
      leaf=(unit item)
      kids=((mop iota $) comp-nodes)
  ==
::
::  +$  xap
::
::     xap is not a real type.
::     it's a way to use oxal as a map
::     
::     (~(nep ox data) %some-iota)
::
+$  meta
  ::
  ::  location metadata
  ::
  $:  dirs=@ud
      leafs=[y=@ud z=@ud]
      hash=[x=@uw z=@uw]   :: xx y=@uw
      ::
      ::  xx  level hashes
      ::
      ::      (map iota @uw) where @uw is the hash of the (unit leaf)
      ::      at the dir corresponding to .iota
      ::
  ==
::
::
+$  care   ?(%leaf %kids %cone)
+$  mask   (list [=stem =care])
+$  shot   (list [loc=pith =care hash=@uw])
+$  look   [line=pith =mask]
::
::  pith aliases
::
::  base   pith    :: ??
+$  here   pith    :: a view's self location
+$  root   pith    :: location of a %view
+$  stem   pith    :: location of data below a %view
+$  stim   pith    :: ??
::
+$  prov  (each root root)  :: & relative, | absolute
::
::   xx rectify other usages of `twig`
::
+$  twig   pith           :: a virual within a view (sans ~)
::
+$  cache  (map look [=shot =data])
::
+$  view-core
  ::
  ::  raw is the most general.
  ::
  ::  users should not need to ever write a %raw,
  ::  but all the other kinds can be converted to %raw.
  ::
  $%  [%raw raw-core]
      [%pure pure-core]
      [%feather-1 feather-1-core]
      [%profile profile-core]
      [%mantis mantis-core]
  ==
::
++  mantis-core
  $-  [prov move file]
  (list move)
::
++  profile-core
  $+  profile-core
  who=@p
::
++  pure-core
  $+  pure-core
  [public=_| gate=$-(data node)]
::
+$  query  (list [@t tape])
+$  body   data
++  feather-1-core
  $+  feather-core
  ::
  ::  the one with batteries included
  ::
  $_  ^&
  |%
  ++  title  ^*  $-  [pith data]  tape
  ++  get
    ^*
    $-  [our=@p src=@p data stem query]
    ::
    :: node is sent to the browser after a "best effort" rendering.
    ::    %json is simple.
    ::    %mime is simple.
    ::    %tang displays an error page
    ::    %manx gets wrapped in a standard html/head wrapper.
    ::    everything else just gets printed to a manx then treated as manx
    ::
    node
  ++  post
    ^*
    $-  [our=@p src=@p data stem query body]
    :: if the unit is empty, stay on the same url.
    :: if full, simulate a redirect with SSE events
    ::
    :: user does not have to specify the moves to respond to an http request.
    :: the unpacker does that automatically. so these moves here are
    :: just user-level IO like timers and outgoing http requests.
    ::
    [(unit [stem query]) (list move)]
  ::
  ::
  ++  on
    ::
    ::  if not http related, the apps is like mantis (but returns move)
    ::
    ^*
    $-  [prov move file]
    (list move)
  ::
  --
::
+$  raw-core
  $+  raw-core
  $_  ^& 
  |%
  ++  on-crash
    ^*
    $-  [tang change quest file]
    (list change)
  ++  on-arvo
    ^*
    $-  [wire sign-arvo quest file]
    (list change)
  ::
  ++  on-http
    ^*
    $-  [http-req quest file]
    (list change)
  ::
  ++  cancel-http
    ^*
    $-  [rid=@ta stem quest file]
    (list change)
  ::
  ++  on-change
    ^*
    $-  [prov move quest file]
    (list card)
  ::
  ::
  ::  ++  locked-data
  ::    (list [pith care])     :: areas only this code can write
  ::
  ::  ++  locked-bindings
  ::    (list [pith care])     :: areas only this code can bind
  ::
  --
::
++  default-view
  '''
  :+  %pure  %.n
  |=  =data
  :-  %ud
  :: number of leafs below
  z.leafs.meta.data
  '''
::
::  pith-ified gall types
::
+$  wire  pith
::
+$  card
  $+  card
  $%  card-outer
      change
  ==
+$  card-outer
  $+  card-outer
  $%  [%pass =wire =note:agent:gall]
      [%give =gift:agent:gall]
      [%grow =here =care =claf]
  ==
+$  lope  [=root =card-outer]
+$  move  [=wire =stem =action]
+$  change
  $+  change
  $%  [%hawk move]
  ==
+$  coop  coop:gall
+$  action
  $+  action
  $%  [%ins =node]
      [%bind bound]
      [%del ~]
      [%lop ~]
      [%nic ~]
    ::
      [%install source=@t]
      [%uninstall ~]
  ==
++  envelope
  |=  [root=pith =(list card-outer)]
  %+  turn  list
  |=  =card-outer
  ^-  lope
  [root card-outer]
::
::
+$  data  $+  data  (oxal node)
+$  code  $+  code  (oxal view)
::
++  fams  ((mop @ud fam) lte)
+$  fam   (trel @da (each page @uvI) (unit coop))
++  fomo  ((on @ud fam) lte)
::
+$  view
  $:  source=(unit @t)
      built=(unit view-core)
      inner=data  :: local non-bindable state for source (working state)
      =bound      :: which aspects are put in which static namespaces
      final=data  :: /leaf/24 -> response
  ==
::
+$  claf   [auth=(unit term) past=?]
+$  clef   (unit claf)  
+$  bound  [leaf=clef kids=clef cone=clef http=(unit private=?)]
::
++  fans  ((mop @ud fan) lte)
+$  fan   (pair @da (each page @uvI))
++  fono  ((on @ud fan) lte)
::
+$  file  [=data =code]
::
+$  bond  (pair pith node)
+$  bonds  (list bond)
::
++  modi  ((on iota data) comp-nodes)
++  moci  ((on iota code) comp-nodes)
::
::  everything a program needs
::
+$  quest
  $:
      our=@p
      src=@p
      now=@da
      eny=@uv
      here=pith            :: view location
  ==
::
+$  http-req
  $:  
      seed=path            :: eyre url binding
      stem=pith            :: rest
      pams=(map @t @t)
      ::
      rid=@ta
      =method:http
      =header-list:http
      body=(unit octs)
  ==
::
++  sse-keep-alive-interval  ~s30
++  sse-timeout  ~m4
++  sse-open
  |=  [rid=@ta]
  ^-  card
  =/  header-list
    :~  ['content-type' 'text/event-stream']
        ['cache-control' 'no-cache']
        ['Connection' 'keep-alive']
    ==
  [%give %fact ~[/http-response/[rid]] [%http-response-header !>([200 header-list])]]
::
++  sse-data
  |=  [rid=@ta =octs]
  ^-  card
  [%give %fact ~[/http-response/[rid]] [%http-response-data !>(`octs)]]
::
++  sse-keep-alive
  |=  rid=@ta
  ^-  card
  (sse-data rid (as-octs:mimes:html ': keep-alive\0a\0a'))
::
++  sse-close
  |=  [rid=@ta]
  ^-  card
  [%give %kick ~[/http-response/[rid]] ~]
::
:: :: :: :: :: :: :: :: :: :: :: :: :: :: :: :: :: :: 
::
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
    ^-  (list (pair iota xal))
    (tap:ion kids.fat)
  ::
  ++  check-sizes  !!
  ++  recompute-sizes  !!
  ::
  ++  dip
    |=  pax=pith
    ^+  fat
    ?~  pax  fat
    =/  kid  (get:ion kids.fat i.pax)
    ?~  kid  [*meta ~ ~]
    $(fat u.kid, pax t.pax)
  ::
  ++  dit
    |=  pax=pith
    ^+  cor
    ~(. cor (dip pax))
  ::
  ++  din  :: dip and remove kids
    |=  pax=pith
    ^+  fat
    (~(pet ox *(oxal item)) / (get pax))
  ::
  ++  dik  :: dip and remove node
    |=  pax=pith
    ^+  fat
    =.  fat  (dip pax)
    =.  fat  (del /)
    fat
  ::
  ++  get
    |=  pax=pith
    ^-  (unit item)
    leaf:(dip pax)
  ::
  ++  got
    |=  pax=pith
    ~|  not-got/pax
    (need (get pax))
  ::
  ++  nep
    |=  toy=iota
    ^-  (unit item)
    ?~  kid=(get:ion kids.fat toy)  ~
    leaf.u.kid
  ::
  ++  nop
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
  ++  met
    |=  pax=pith
    ^-  meta
    meta:(dip pax)
  ::
  ++  dys  :: y leaf
    ^-  (list (pair iota item))
    %+  murn  (tap:ion kids.fat)
    |=  [=iota f=_fat]
    ?~  leaf.f  ~
    `[iota u.leaf.f]
  ::
  ++  only-y
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
    ::  ancestors matching some condition
    ::    (not including self)
    ::
    ::  the longest match is at the head of the returned list
    ::
    |=  [self=pith con=$-(_fat ?)]
    ^-  (list (pair pith _fat))
    =|  loc=pith
    =|  out=(list (pair pith _fat))
    |-
    ?:  =(self loc)  out
    =?  out  (con fat)
      [[loc fat] out]
    =/  seg  (snag (lent loc) self)
    =.  loc  (snoc loc seg)
    %=  $
      fat  (dip #/[seg])
    ==
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
    |=  pax=pith
    ^-  ?
    !=(~ (get pax))
  ::
  ++  hos
    |=  pax=pith
    ^-  ?
    =/  d  (dip pax)
    ?|
      !=(~ kids:d)
      !=(~ leaf:d)
    ==
  ::
  ++  has-kids
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
    ?:  =(~ pax)  [*meta ~ ~]
    =;  x  res.x
    |-
    ^-  [[y=@ud z=@ud] res=_fat]
    ?~  pax
      :_  fat(leaf ~, kids ~)
      ?^  leaf.fat  [1 +(z.leafs.meta.fat)]
      [0 z.leafs.meta.fat]
    =/  kid  (get:ion kids.fat i.pax)
    ?~  kid  [[0 0] fat]
    =/  [had=[y=@ud z=@ud] f=_fat]  $(fat u.kid, pax t.pax)
    :-  had
    =;  ore
      =/  kod  (got:ion kids.ore i.pax)
      ?.  &(?=(~ leaf.kod) ?=(~ kids.kod))
        ore
      %=  ore
        dirs.meta  (dec dirs.meta.ore)
        kids  +:(del:ion kids.ore i.pax)
      ==
    =/  nkids  (put:ion kids.fat i.pax f)
    %=  fat
      :: z.leafs.meta  (sub z.leafs.meta.fat z.had)
      :: y.leafs.meta  ?^(t.pax y.leafs.meta.fat (sub y.leafs.meta.fat y.had))
      z.hash.meta  (mug nkids)
      kids  nkids
    ==
  ::
  ++  del
    ::
    ::  delete leaf
    ::
    |=  pax=pith
    ^-  (oxal item)
    =;  [* f=(oxal item)]  f
    |-
    ^-  [had=? res=(oxal item)]
    ?~  pax
      ?~  leaf.fat  [%.n fat]
      [%.y fat(leaf ~)]
    =/  kid  (get:ion kids.fat i.pax)
    ?~  kid  [%.n fat]
    =/  [had=? f=(oxal item)]  $(fat u.kid, pax t.pax)
    :-  had
    =;  ore=(oxal item)
      ^-  (oxal item)
      =/  kod  (got:ion kids.ore i.pax)
      ?.  &(=(~ leaf.kod) =(~ kids.kod))
        ore
      %=  ore
        dirs.meta  (dec dirs.meta.ore)
        kids  +:(del:ion kids.ore i.pax)
      ==
    =/  nkids  (put:ion kids.fat i.pax f)
    %=  fat
      :: z.leafs.meta  ?:(had (dec z.leafs.meta.fat) z.leafs.meta.fat)
      :: y.leafs.meta  ?:(&(had ?=(~ t.pax)) (dec y.leafs.meta.fat) y.leafs.meta.fat)
      z.hash.meta  (mug nkids)
      kids  nkids
    ==
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
    =;  [* f=_fat]  f
    |-
    ^-  [? _fat]
    ?~  pax  [?=(~ leaf.fat) fat(leaf `dat, x.hash.meta (mug dat))]
    =/  [new-kids=? kid=_fat]
      ?~  x=(get:ion kids.fat i.pax)
        [%.y ^+(fat [*meta ~ ~])]
      [%.n u.x]
    =/  [new=flag f=_fat]  $(fat kid, pax t.pax)
    :-  new
    =/  nkids  (put:ion kids.fat i.pax f)
    %=  fat
      dirs.meta  ?:(new-kids +(dirs.meta.fat) dirs.meta.fat)
      :: y.leafs.meta  ?:(&(new ?=(~ t.pax)) +(y.leafs.meta.fat) y.leafs.meta.fat)
      :: z.leafs.meta  ?:(new +(z.leafs.meta.fat) z.leafs.meta.fat)
      z.hash.meta  (mug nkids)
      kids     nkids
    ==
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
  ++  rep  ::  xx this messes up sizes and probably hashes too
    ::
    ::  replace subtree
    ::
    |*  [pax=pith new=_fat]
    =;  [* f=_fat]  f
    |-
    ^-  [? _fat]
    ?~  pax
      :-  ?=(~ leaf.fat)
      new
    =/  [new-kids=? kid=_fat]
      ?~  x=(get:ion kids.fat i.pax)
        [%.y ^+(fat [*meta ~ ~])]
      [%.n u.x]
    =/  [new=flag f=_fat]  $(fat kid, pax `pith`t.pax)
    :-  new
    =/  nkids  (put:ion kids.fat i.pax f)
    %=  fat
      dirs.meta  ?:(new-kids +(dirs.meta.fat) dirs.meta.fat)
      :: y.leafs.meta  ?:(&(new ?=(~ t.pax)) +(y.leafs.meta.fat) y.leafs.meta.fat)
      :: z.leafs.meta  ?:(new +(z.leafs.meta.fat) z.leafs.meta.fat)
      z.hash.meta  (mug nkids)
      kids     nkids
    ==
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
    ::xx bookkeep cases
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
  ++  dif
    ::
    ::  compute diff
    ::
    ::  xx updated to use new definition of $change
    ::
    |=  new=xal
    ^-  (list [pith ?(%del %ins %mod)])
    =/  old  (malt tap)
    =/  new-bands  ~(tap ox new)
    =|  out=(list [pith ?(%del %ins %mod)])
    |-
    ?~  new-bands
      %+  welp  out
      %+  turn  ~(tap by old)
      |=  [=pith =node]
      [pith %del]
    =/  [=pith =node]  i.new-bands
    =/  pur
      =/  o  (~(get by old) pith)
      :-  (~(del by old) pith)
      ?~  o
        [[pith %ins] out]
      ?:  =(u.o node)
        out
      [[pith %mod] out]
    ::
    =.  old  -.pur
    =.  out  +.pur
    $(new-bands t.new-bands)
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
::  pith helpers
::
++  stip
  ::
  =<  swot
  |%
  ++  swot  |=(n=nail (;~(pfix fas (more fas spot)) n))
  ::
  ++  spot
    %+  sear  (soft iota)
    %-  stew
    ^.  stet  ^.  limo
    :~  :-  'a'^'z'  sym                    :: PATCHED here!
        :-  '$'      (cold [%tas %$] buc)
        :-  '0'^'9'  bisk:so
        :-  '-'      tash:so
        :-  '.'      ;~(pfix dot zust:so)   :: PATCHED here!
        :-  '~'      ;~(pfix sig ;~(pose crub:so (easy [%n ~])))
        :-  '\''     (stag %t qut)
    ==
  --
::
++  pave
  |=  pit=pith
  ^-  pith
  %+  turn  pit
  |=  i=iota
  ?@  i
    ^-  iota
    =;  =coin  (coin-to-node coin)
    %+  fall
      (rush i nuck:so)
    ?:  =('.__' i)  [%many ~]  :: XX upstream
    ?:  =('' i)     [%$ %tas %$]
    [%$ %t (@t i)]
  i
::
++  coin-to-node
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
++  pout
  |=  =pith
  ^-  path
  %+  turn  pith
  |=  =node
  %-  crip
  ~(rend co (node-to-coin node))
  ::
::
::  parsers
::
++  tape-to-iota
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
      pith+(tape-to-pith tap)
    %-  iota
    %+  snag  0
    (scan (welp "/" tap) stip)
  !!
::
++  cord-to-iota
  ::
  |=  =cord
  ^-  iota
  (tape-to-iota (trip cord))
::
++  cord-to-node  cord-to-iota
::
++  tape-to-pith
  ::
  |=  =tape
  ^-  pith
  ~|  invalid-pith-tape+(crip tape)
  (scan tape stip)
::
++  cord-to-pith
  ::
  |=  =cord
  ^-  pith
  ~|  invalid-pith-cord+cord
  (rash cord stip)
::
++  print-node-strict
  |=  =node
  ^-  tape
  ~(rend co (node-to-coin node))
::
++  dane  print-node-strict
::
++  pate
  |=  =pith
  ^-  tape
  %-  zing
    =;  =wall
      ?^  wall  wall
      ~["/"]
  %+  turn  pith
  |=  =node
  ['/' (print-node-strict node)]
::
++  print-aota
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
++  print-node
  |=  nod=node
  ^-  tape
  =;  x=(unit tape)
    ?^  x  u.x
    "render-failed"
  %-  mole  |.
  ?+    nod  "lost: {<-.nod>}"
      @  (trip nod)
      [%t *]
          %-  trip
          ^-  @t
          =/  long  t.nod
          =|  out=@t
          =|  i=@
          |-
          ?~  long  out
          ?:  (gte i 50)  out
          =/  firt  (cut 3 [0 1] long)
          ?:  =(firt 10)  out
          =.  out  (cat 3 out firt)
          $(long (rsh 3 long), i +(i))
      aota  (print-aota nod)
    [%pith *]  (pate pith.nod)
    [%data *]  "{(scow %uw z.hash.meta.data.nod)} : {(scow %ud z.leafs.meta.data.nod)}"
    [%mime *]
      ?+    p.mime.nod
          "non-printable mite: {<`(list cord)`p.mime.nod>}"
        [%text * ~]
          %+  welp  "mime: {(spud p.mime.nod)}\0a"
          (trip q.q.mime.nod)
      ==
    [%tang *]
      %-  zing
      %+  turn  tang.nod
      |=  =tank
      %-  of-wall:format
      (~(win re tank) 0 55)
  ==
::
::  prints in a machine-readable way
::
++  print-strict
  |=  =node
  ^-  (unit tape)
  ?+    node  ~
    @  `<node>
    [%t *]
      :-  ~
      =/  ticl  (crip "'''\0a")
      %-  trip
      %^  cat  3  ':-  %t\0a'
      %^  cat  3  ticl
      %^  cat  3  t.node
      %^  cat  3  '\0a'
      ticl
    [%mime *]
      ?:  ?=([%text *] p.mime.node)
        :-  ~
        %-  of-wall:format
        :~  ":+  %mime  {(spud p.mime.node)}"
            "%-  as-octs:mimes:html"
            "'''"
            (trip q.q.mime.node)
            "'''"
        ==
      ~
    aota
      `(welp ":-  {<-.node>}\0a" (scow node))
  ==
::
++  print-aura
  |=  nod=node
  ^-  tape
  ?@  nod
    "tas"
  (trip -.nod)
::
::
++  node-as
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
::  data makers
::
++  mono
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
  ++  kid-list     kid-list:ox
  ++  dip  dip:ox
  ++  anc  anc:ox
  ++  din  din:ox
  ++  dik  dik:ox
  ++  dit  |=  =pith  ~(. do (dip pith))
  ++  get  get:ox
  ++  got  got:ox
  ++  gut
    |=  [=pith back=node]
    (fall (get pith) back)
  ++  nep  nep:ox
  ++  nop  nop:ox
  ++  met  met:ox
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
  ++  dif  dif:ox
  ++  ram  ram:ox
  ++  rom  rom:ox
  ++  mol  mol:ox
  ++  mox  mox:ox
  ::
  ++  peb
    ::
    |=  pax=pith
    ^-  (unit tape)
    ?~  x=(get pax)  ~
    `(print-node u.x)
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
    (print-node (got pax))
    ::
  ++  pub
    ::
    |=  [pax=pith back=tape]
    ^-  tape
    ?~  x=(get pax)  back
    (print-node u.x)
    ::
  ::
  ++  got-n     |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%n ~] -)     ~
  ++  got-f     |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%f *] -)     +:-
  ++  got-tas   |=  pax=pith  =+  (got:ox pax)  ?>  ?=(@ -)          -
  ++  got-ta    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%ta *] -)    +:-
  ++  got-t     |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%t *] -)     +:-
  ++  got-p     |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%p *] -)     +:-
  ++  got-q     |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%q *] -)     +:-
  ++  got-da    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%da *] -)    +:-
  ++  got-dr    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%dr *] -)    +:-
  ++  got-if    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%if *] -)    +:-
  ++  got-is    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%is *] -)    +:-
  ++  got-ub    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%ub *] -)    +:-
  ++  got-uc    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%uc *] -)    +:-
  ++  got-ud    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%ud *] -)    +:-
  ++  got-ui    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%ui *] -)    +:-
  ++  got-ux    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%ux *] -)    +:-
  ++  got-uv    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%uv *] -)    +:-
  ++  got-uw    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%uw *] -)    +:-
  ++  got-sb    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%sb *] -)    +:-
  ++  got-sc    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%sc *] -)    +:-
  ++  got-sd    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%sd *] -)    +:-
  ++  got-si    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%si *] -)    +:-
  ++  got-sx    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%sx *] -)    +:-
  ++  got-sv    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%sv *] -)    +:-
  ++  got-sw    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%sw *] -)    +:-
  ++  got-rs    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%rs *] -)    +:-
  ++  got-rd    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%rd *] -)    +:-
  ++  got-rh    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%rh *] -)    +:-
  ++  got-rq    |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%rq *] -)    +:-
  ++  got-tang  |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%tang *] -)  +:-
  ++  got-manx  |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%manx *] -)  +:-
  ++  got-json  |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%json *] -)  +:-
  ++  got-mime  |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%mime *] -)  +:-
  ++  got-noun  |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%noun *] -)  +:-
  ++  got-pith  |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%pith *] -)  +:-
  ++  got-data  |=  pax=pith  =+  (got:ox pax)  ?>  ?=([%data *] -)  +:-
  ::
  ++  get-n     |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%n ~] u.-)  ~     `u=~
  ++  get-f     |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%f *] u.-)  ~     `u=+.u.-
  ++  get-tas   |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=(@ u.-)  ~          `u=u.-
  ++  get-ta    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%ta *] u.-)  ~    `u=+.u.-
  ++  get-t     |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%t *] u.-)  ~     `u=+.u.-
  ++  get-p     |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%p *] u.-)  ~     `u=+.u.-
  ++  get-q     |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%q *] u.-)  ~     `u=+.u.-
  ++  get-da    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%da *] u.-)  ~    `u=+.u.-
  ++  get-dr    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%dr *] u.-)  ~    `u=+.u.-
  ++  get-if    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%if *] u.-)  ~    `u=+.u.-
  ++  get-is    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%is *] u.-)  ~    `u=+.u.-
  ++  get-ub    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%ub *] u.-)  ~    `u=+.u.-
  ++  get-uc    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%uc *] u.-)  ~    `u=+.u.-
  ++  get-ud    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%ud *] u.-)  ~    `u=+.u.-
  ++  get-ui    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%ui *] u.-)  ~    `u=+.u.-
  ++  get-ux    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%ux *] u.-)  ~    `u=+.u.-
  ++  get-uv    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%uv *] u.-)  ~    `u=+.u.-
  ++  get-uw    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%uw *] u.-)  ~    `u=+.u.-
  ++  get-sb    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%sb *] u.-)  ~    `u=+.u.-
  ++  get-sc    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%sc *] u.-)  ~    `u=+.u.-
  ++  get-sd    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%sd *] u.-)  ~    `u=+.u.-
  ++  get-si    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%si *] u.-)  ~    `u=+.u.-
  ++  get-sx    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%sx *] u.-)  ~    `u=+.u.-
  ++  get-sv    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%sv *] u.-)  ~    `u=+.u.-
  ++  get-sw    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%sw *] u.-)  ~    `u=+.u.-
  ++  get-rs    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%rs *] u.-)  ~    `u=+.u.-
  ++  get-rd    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%rd *] u.-)  ~    `u=+.u.-
  ++  get-rh    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%rh *] u.-)  ~    `u=+.u.-
  ++  get-rq    |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%rq *] u.-)  ~    `u=+.u.-
  ++  get-tang  |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%tang *] u.-)  ~  `u=+.u.-
  ++  get-manx  |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%manx *] u.-)  ~  `u=+.u.-
  ++  get-json  |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%json *] u.-)  ~  `u=+.u.-
  ++  get-mime  |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%mime *] u.-)  ~  `u=+.u.-
  ++  get-noun  |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%noun *] u.-)  ~  `u=+.u.-
  ++  get-pith  |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%pith *] u.-)  ~  `u=+.u.-
  ++  get-data  |=  pax=pith  =+  (get:ox pax)  ?~  -  ~  ?.  ?=([%data *] u.-)  ~  `u=+.u.-
  ::
  ++  git-n     |=  pax=pith  ^-  ~     %^  make-gut  (get:ox pax)  %n     n+~
  ++  git-f     |=  pax=pith  ^-  @f    %^  make-gut  (get:ox pax)  %f     f+*@f
  ++  git-tas   |=  pax=pith  ^-  @tas  %^  make-gut  (get:ox pax)  %tas   %$
  ++  git-ta    |=  pax=pith  ^-  @ta   %^  make-gut  (get:ox pax)  %ta    ta+*@ta
  ++  git-t     |=  pax=pith  ^-  @t    %^  make-gut  (get:ox pax)  %t     t+*@t
  ++  git-p     |=  pax=pith  ^-  @p    %^  make-gut  (get:ox pax)  %p     p+*@p
  ++  git-q     |=  pax=pith  ^-  @q    %^  make-gut  (get:ox pax)  %q     q+*@q
  ++  git-da    |=  pax=pith  ^-  @da   %^  make-gut  (get:ox pax)  %da    da+*@da
  ++  git-dr    |=  pax=pith  ^-  @dr   %^  make-gut  (get:ox pax)  %dr    dr+*@dr
  ++  git-if    |=  pax=pith  ^-  @if   %^  make-gut  (get:ox pax)  %if    if+*@if
  ++  git-is    |=  pax=pith  ^-  @is   %^  make-gut  (get:ox pax)  %is    is+*@is
  ++  git-ub    |=  pax=pith  ^-  @ub   %^  make-gut  (get:ox pax)  %ub    ub+*@ub
  ++  git-uc    |=  pax=pith  ^-  @uc   %^  make-gut  (get:ox pax)  %uc    uc+*@uc
  ++  git-ud    |=  pax=pith  ^-  @ud   %^  make-gut  (get:ox pax)  %ud    ud+*@ud
  ++  git-ui    |=  pax=pith  ^-  @ui   %^  make-gut  (get:ox pax)  %ui    ui+*@ui
  ++  git-ux    |=  pax=pith  ^-  @ux   %^  make-gut  (get:ox pax)  %ux    ux+*@ux
  ++  git-uv    |=  pax=pith  ^-  @uv   %^  make-gut  (get:ox pax)  %uv    uv+*@uv
  ++  git-uw    |=  pax=pith  ^-  @uw   %^  make-gut  (get:ox pax)  %uw    uw+*@uw
  ++  git-sb    |=  pax=pith  ^-  @sb   %^  make-gut  (get:ox pax)  %sb    sb+*@sb
  ++  git-sc    |=  pax=pith  ^-  @sc   %^  make-gut  (get:ox pax)  %sc    sc+*@sc
  ++  git-sd    |=  pax=pith  ^-  @sd   %^  make-gut  (get:ox pax)  %sd    sd+*@sd
  ++  git-si    |=  pax=pith  ^-  @si   %^  make-gut  (get:ox pax)  %si    si+*@si
  ++  git-sx    |=  pax=pith  ^-  @sx   %^  make-gut  (get:ox pax)  %sx    sx+*@sx
  ++  git-sv    |=  pax=pith  ^-  @sv   %^  make-gut  (get:ox pax)  %sv    sv+*@sv
  ++  git-sw    |=  pax=pith  ^-  @sw   %^  make-gut  (get:ox pax)  %sw    sw+*@sw
  ++  git-rs    |=  pax=pith  ^-  @rs   %^  make-gut  (get:ox pax)  %rs    rs+*@rs
  ++  git-rd    |=  pax=pith  ^-  @rd   %^  make-gut  (get:ox pax)  %rd    rd+*@rd
  ++  git-rh    |=  pax=pith  ^-  @rh   %^  make-gut  (get:ox pax)  %rh    rh+*@rh
  ++  git-rq    |=  pax=pith  ^-  @rq   %^  make-gut  (get:ox pax)  %rq    rq+*@rq
  ++  git-tang  |=  pax=pith  ^-  tang  %^  make-gut  (get:ox pax)  %tang  tang+*tang
  ++  git-manx  |=  pax=pith  ^-  manx  %^  make-gut  (get:ox pax)  %manx  manx+*manx
  ++  git-json  |=  pax=pith  ^-  json  %^  make-gut  (get:ox pax)  %json  json+*json
  ++  git-mime  |=  pax=pith  ^-  mime  %^  make-gut  (get:ox pax)  %mime  mime+*mime
  ++  git-noun  |=  pax=pith  ^-  noun  %^  make-gut  (get:ox pax)  %noun  noun+*noun
  ++  git-pith  |=  pax=pith  ^-  pith  %^  make-gut  (get:ox pax)  %pith  pith+*pith
  ::
  ++  gut-f     |=  [pax=pith back=?]     ^-  @f    %^  make-gut  (get:ox pax)  %f     f+back
  ++  gut-tas   |=  [pax=pith back=@tas]  ^-  @tas  %^  make-gut  (get:ox pax)  %tas   back
  ++  gut-ta    |=  [pax=pith back=@ta]   ^-  @ta   %^  make-gut  (get:ox pax)  %ta    ta+back
  ++  gut-t     |=  [pax=pith back=@t]    ^-  @t    %^  make-gut  (get:ox pax)  %t     t+back
  ++  gut-p     |=  [pax=pith back=@p]    ^-  @p    %^  make-gut  (get:ox pax)  %p     p+back
  ++  gut-q     |=  [pax=pith back=@q]    ^-  @q    %^  make-gut  (get:ox pax)  %q     q+back
  ++  gut-da    |=  [pax=pith back=@da]   ^-  @da   %^  make-gut  (get:ox pax)  %da    da+back
  ++  gut-dr    |=  [pax=pith back=@dr]   ^-  @dr   %^  make-gut  (get:ox pax)  %dr    dr+back
  ++  gut-if    |=  [pax=pith back=@if]   ^-  @if   %^  make-gut  (get:ox pax)  %if    if+back
  ++  gut-is    |=  [pax=pith back=@is]   ^-  @is   %^  make-gut  (get:ox pax)  %is    is+back
  ++  gut-ub    |=  [pax=pith back=@ub]   ^-  @ub   %^  make-gut  (get:ox pax)  %ub    ub+back
  ++  gut-uc    |=  [pax=pith back=@uc]   ^-  @uc   %^  make-gut  (get:ox pax)  %uc    uc+back
  ++  gut-ud    |=  [pax=pith back=@ud]   ^-  @ud   %^  make-gut  (get:ox pax)  %ud    ud+back
  ++  gut-ui    |=  [pax=pith back=@ui]   ^-  @ui   %^  make-gut  (get:ox pax)  %ui    ui+back
  ++  gut-ux    |=  [pax=pith back=@ux]   ^-  @ux   %^  make-gut  (get:ox pax)  %ux    ux+back
  ++  gut-uv    |=  [pax=pith back=@uv]   ^-  @uv   %^  make-gut  (get:ox pax)  %uv    uv+back
  ++  gut-uw    |=  [pax=pith back=@uw]   ^-  @uw   %^  make-gut  (get:ox pax)  %uw    uw+back
  ++  gut-sb    |=  [pax=pith back=@sb]   ^-  @sb   %^  make-gut  (get:ox pax)  %sb    sb+back
  ++  gut-sc    |=  [pax=pith back=@sc]   ^-  @sc   %^  make-gut  (get:ox pax)  %sc    sc+back
  ++  gut-sd    |=  [pax=pith back=@sd]   ^-  @sd   %^  make-gut  (get:ox pax)  %sd    sd+back
  ++  gut-si    |=  [pax=pith back=@si]   ^-  @si   %^  make-gut  (get:ox pax)  %si    si+back
  ++  gut-sx    |=  [pax=pith back=@sx]   ^-  @sx   %^  make-gut  (get:ox pax)  %sx    sx+back
  ++  gut-sv    |=  [pax=pith back=@sv]   ^-  @sv   %^  make-gut  (get:ox pax)  %sv    sv+back
  ++  gut-sw    |=  [pax=pith back=@sw]   ^-  @sw   %^  make-gut  (get:ox pax)  %sw    sw+back
  ++  gut-rs    |=  [pax=pith back=@rs]   ^-  @rs   %^  make-gut  (get:ox pax)  %rs    rs+back
  ++  gut-rd    |=  [pax=pith back=@rd]   ^-  @rd   %^  make-gut  (get:ox pax)  %rd    rd+back
  ++  gut-rh    |=  [pax=pith back=@rh]   ^-  @rh   %^  make-gut  (get:ox pax)  %rh    rh+back
  ++  gut-rq    |=  [pax=pith back=@rq]   ^-  @rq   %^  make-gut  (get:ox pax)  %rq    rq+back
  ++  gut-tang  |=  [pax=pith back=tang]  ^-  tang  %^  make-gut  (get:ox pax)  %tang  tang+back
  ++  gut-manx  |=  [pax=pith back=manx]  ^-  manx  %^  make-gut  (get:ox pax)  %manx  manx+back
  ++  gut-json  |=  [pax=pith back=json]  ^-  json  %^  make-gut  (get:ox pax)  %json  json+back
  ++  gut-mime  |=  [pax=pith back=mime]  ^-  mime  %^  make-gut  (get:ox pax)  %mime  mime+back
  ++  gut-noun  |=  [pax=pith back=noun]  ^-  noun  %^  make-gut  (get:ox pax)  %noun  noun+back
  ++  gut-pith  |=  [pax=pith back=pith]  ^-  pith  %^  make-gut  (get:ox pax)  %pith  pith+back
  --
--
