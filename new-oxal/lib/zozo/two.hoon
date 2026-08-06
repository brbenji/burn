::  two: file engine and event loop
::
::    the core runtime for hawk views. provides:
::      ++fe          file engine door (data+code tree operations)
::      ++build-raw   compile view source into a raw-core
::      ++event-loop  process events, apply changes, propagate reactions
::
::    view type conversion chain (in ++build-raw):
::      %raw        used directly
::      %mantis     -> one-mantis -> raw-core
::      %feather-1  -> one-feather-1 -> one-mantis -> raw-core
::      %pure       -> one-pure -> one-feather-1 -> one-mantis -> raw-core
::      %profile    -> one-profile -> raw-core
::
::    the event loop (++event-loop) takes incoming events (HTTP,
::    arvo signs), routes them to the appropriate view's raw-core,
::    applies resulting changes to the data tree, and propagates
::    changes to ancestor/descendant views for reaction.
::
/+  *zozo-one
/+  unpack-pure-view=zozo-one-pure
/+  unpack-feather-1=zozo-one-feather-1
/+  unpack-profile=zozo-one-profile
/+  unpack-mantis=zozo-one-mantis
::
::  xx remove quest from on-change pams
::
|%
++  zozo  %499
::
::::  conversions
::
++  bowl-to-quest
  |=  [here=pith gowl=bowl:gall]
  ^-  quest
  %*  .  *quest
    our  our.gowl
    src  src.gowl
    now  now.gowl
    eny  eny.gowl
    ::
    here  here
  ==
::
::
::  fe: file engine door
::
::    operates on a file (data tree + code tree pair).
::    ++d  data tree operations (get, put, rep, del, lop, etc.)
::    ++s  data tree read-only queries (has, got, tap, etc.)
::    ++c  code tree operations (get, put, source, build)
::
++  fe
  =|  our=@p
  =|  now=@da
  |_  fil=file
  +*  dat  data.fil
      cod  code.fil
      de   ~(. do data.fil)                                ::  data engine
      ce   ~(. ox code.fil)                                ::  code engine
      se   ~(. ox data.fil)                                ::  data engine (alt)
  ++  out  fil                                             ::  produce the file
  ++  cor  .                                               ::  self reference
  ::
  ++  d                                                    ::  data tree operations
    |%
    ++  anc  anc:de
    ++  get  |=  [=pith]         (get:de pith)
    ++  din  |=  [=pith]         (din:de pith)
    ++  dik  |=  [=pith]         (dik:de pith)
    ++  gis  |=  [=pith =bonds]  fil(data (gis:de pith bonds))
    ++  gas  |=  [=bonds]        fil(data (gas:de bonds))
    ++  put  |=  [=pith =node]   fil(data (put:de pith node))
    ++  rep  |=  [=pith =data]   fil(data (rep:de pith data))
    ++  mer  |=  [=pith =data]   fil(data (mer:de pith data))
    ++  del  |=  [=pith]         fil(data (del:de pith))
    ++  lop  |=  [=pith]         fil(data (lop:de pith))
    ++  tah  tah:de
    ++  tap  tap:de
    ++  ren  ren:de
    ++  met  met:de
    ++  tah-inner  tah-inner:de
    ++  tap-inner  tap-inner:de
    ++  tap-gens  tap-gens:de
    ++  dip  dip:de
    ++  dit  dit:de
    ++  kid-list  kid-list:de
    --
  ::
  ::
  ++  s                                                    ::  data tree queries
    |%
    ++  anc  anc:se
    ++  got  got:se
    ++  has  has:se
    ++  tah  tah:se
    ++  met  met:se
    ++  tap  tap:se
    ++  tap-gens  tap-gens:se
    ++  tah-inner  tah-inner:se
    ++  tap-inner  tap-inner:se
    ++  kid-list  kid-list:se
    ++  dip  dip:se
    ++  dit  dit:se
    ++  fit  fit:se
    --
  ::
  ++  c                                                    ::  code tree operations
    |%
    ++  anc  anc:ce
    ++  got  got:ce
    ++  has  has:ce
    ++  tah  tah:ce
    ++  met  met:ce
    ++  tap  tap:ce
    ++  tap-gens  tap-gens:ce
    ++  tah-inner  tah-inner:ce
    ++  tap-inner  tap-inner:ce
    ++  kid-list  kid-list:ce
    ++  dip  dip:ce
    ++  dit  dit:ce
    ++  fit  fit:ce
    ++  put  |=  [=pith =view]  fil(code (put:ce pith view))
    ++  rep  |=  [=pith =code]  fil(code (rep:ce pith code))
    ++  mer  |=  [=pith =code]  fil(code (mer:ce pith code))
    ++  get  |=  [=pith]        (get:ce pith)
    ++  del  |=  [=pith]        fil(code (del:ce pith))
    ++  lop  |=  [=pith]        fil(code (lop:ce pith))
    ++  source
      |=  =pith
      ^-  (unit @t)
      ?~  x=(get pith)  ~
      source.u.x
    --
  ::
  ::  the first layer of children across both data and code trees,
  ::  merged by iota. produces a list of [iota file] pairs.
  ::
  ++  kid-list
    =|  out=(list [iota file])
    =/  dk  kids.dat
    =/  ck  kids.cod
    |-
    ^+  out
    ?:  =(~ dk)
      %+  welp  out
      %+  turn  (tap:moci ck)
      |=  [=iota *]
      [iota (dips #/[iota])]
    ?:  =(~ ck)
      %+  welp  out
      %+  turn  (tap:modi dk)
      |=  [=iota *]
      [iota (dips #/[iota])]
    =/  [[fd=iota fdata=data] restd=_dk]  (pop:modi dk)
    =/  [[fc=iota fcode=code] restc=_ck]  (pop:moci ck)
    ?:  =(fd fc)
      %=  $
        out  (snoc out [fd [fdata fcode]])
        dk   restd
        ck   restc
      ==
    ?:  (comp-nodes fd fc)
      %=  $
        out  (snoc out [fd [fdata *code]])
        dk   restd
      ==
    %=  $
      out  (snoc out [fc [*data fcode]])
      ck   restc
    ==
  ::
  ++  dips                                                ::  dive into both trees
    |=  =pith
    ^+  fil
    [(dip:d pith) (dip:c pith)]
  ::
  ++  dit                                                  ::  dive + rewrap door
    |=  =pith
    ^+  cor
    ~(. cor (dips pith))
  ::
  ++  reps                                                ::  replace both trees
    |=  [=pith =file]
    =.  fil  (rep:d pith data.file)
    =.  fil  (rep:c pith code.file)
    fil
  ::
  ::  install a view: store its source and build it
  ++  install
    |=  [=root source=@t]
    ^+  fil
    =/  vew=view
      %*  .  (fall (get:c root) *view)
        source  `source
        built  ~
        inner  *data
        bound  *bound
      ==
    ~&  installed/[root ?=(^ source.vew)]
    =.  fil  (put:c root vew)
    =^  fnn  fil  (build-raw root vew)
    fil
  ::
  ++  uninstall                                           ::  remove a view's code
    |=  =pith
    ^+  fil
    (del:c pith)
  ::
  ++  make  put:d                                          ::  insert data node
  ++  tomb  del:d                                          ::  delete data node
  ++  cull                                                 ::  delete data subtree
    |=  =pith
    ^+  fil
    ?:  (~(hos ox code.fil) pith)
      ~|  %cull-blocked-by-code  :: idk if i really need this crash
      !!
    (lop:d pith)
  ::
  ::  fill in mask values from the data tree into a new file
  ++  peel
    |=  =mask
    ^+  fil
    =|  new=file
    =*  dd  ~(. do data.new)
    |-
    ?~  mask  new(code code.fil)
    =/  [=pith =care]  i.mask
    =.  data.new
      ?-  care
        %leaf  (mer:dd pith (din:d pith))
        %kids  (mer:dd pith (dik:d pith))
        %cone
          =.  data.new  (mer:dd pith (din:d pith))
          =.  data.new  (mer:dd pith (dik:d pith))
          data.new
      ==
    $(mask t.mask)
  ::
  ::  compute content hashes for each mask entry
  ++  draw
    |=  =mask
    %+  turn  mask
    |=  [=pith =care]
    :+  pith  care
    ^-  @uw
    ?-  care
      %leaf  x.hash.meta:(dip:d pith)
      %kids  z.hash.meta:(dip:d pith)
      %cone  (add [x z]:hash.meta:(dip:d pith))
    ==
  ::
  ::  compile view source code into a built view-core
  ++  build
    |=  [=view root=pith]
    ^+  view
    %=  view
      built
        %-  (slog >hawk/building/(pout root)< ~)
        ~|  failed-to-build-view/(pout root)
        :-  ~
        !<  view-core
        %+  slap
          !>(..zozo)
        (ream (need source.view)) 
    ==
  ::
  ::  build a view and convert it to raw-core via the type-specific
  ::  adapter. caches the built view in the code tree.
  ++  build-raw
    |=  [=root =view]
    ^-  [raw-core file]
    =?  view  ?=(~ built.view)
      (build view root)
    =.  fil  (put:c root view)
    =/  cor  (need built.view)
    :_  fil
    ?-  -.cor
      %raw        +.cor
      %pure       (unpack-mantis (unpack-feather-1 (unpack-pure-view +.cor)))
      %feather-1  (unpack-mantis (unpack-feather-1 +.cor))
      %profile    (unpack-mantis (unpack-feather-1 (unpack-profile +.cor)))
      %mantis     (unpack-mantis +.cor)
    ==
  ::
  ::  event-loop: the core change propagation engine.
  ::
  ::    takes initial changes, applies them to the data tree,
  ::    then propagates to affected views (ancestors and descendants).
  ::    each affected view's on-change arm may produce more changes,
  ::    which are spread again. continues until no more changes
  ::    remain (max 20 iterations to prevent infinite loops).
  ::
  ::    on crash from the originating view: revert to pre-event state.
  ::    on crash from a foreign view: continue processing.
  ::
  ++  event-loop
    ::
    =|  has-failed=_|                                      ::  crash recovery flag
    =|  total=@                                            ::  iteration count
    =|  plan=(map here (list [prov change]))               ::  pending reactions by view
    =|  done=(map here (list [prov change]))               ::  completed reactions
    =|  lopes=(list lope)                                  ::  accumulated gall effects
    |_  [=quest gowl=bowl:gall changes=(list change)]
    +*  this  .
    ::
    ::  main loop: spread initial changes, then process plan
    ::  until empty or max iterations reached.
    ::
    ++  $
      ^+  [lopes fil]
      =.  this  (spread here.quest changes)
      ::
      =/  og-fil  fil
      |-
      ::
      ::  prevent infinite loops
      ::
      ?:  (gth total 20)  ~|  %probably-looping  !!
      ::
      ::  if done, finalize
      ::
      ?:  =(~ plan)
        =.  lopes  (welp (envelope here.quest (static-cards here.quest)) lopes)
        [(flop lopes) (close-sig here.quest)]
      ::
      ::  pop the longest .plan and evaluate it
      ::
      =.  total  +(total)
      =/  longest=(pair here (list [prov change]))
        =<  -
        %+  sort  ~(tap by plan)
        |=  [[a=here *] [b=here *]]
        (gth (lent a) (lent b))
      ::
      =.  plan  (~(del by plan) p.longest)
      =/  todo  (flop q.longest)
      ::
      ::  run each change in .longest, then spread the result back into .plan
      |-
      ?~  todo
        ::
        =.  lopes  (welp (envelope p.longest (static-cards p.longest)) lopes)
        ::
        ^$  ::  done with this entry of the plan
        ::
      =/  cup=(each [(list card) file] tang)  (run-on-change p.longest i.todo)
      ::
      ?:  ?=(%.y -.cup)
        ::
        =^  caz  fil  p.cup
        ::  cross-view: load inner before spread so writes merge
        =?  fil  !=(p.longest here.quest)
          (open-sig p.longest)
        =.  this  (spread p.longest caz)
        ::  cross-view: if spread wrote to #/~, persist to inner
        =?  fil  ?&  !=(p.longest here.quest)
                     (~(hos do data.fil) (welp p.longest #/~))
                 ==
          (close-sig p.longest)
        =.  done  (~(add ja done) p.longest i.todo)
        $(todo t.todo)
        ::
      ::
      ::  applying failed, run on-crash instead
      ::
      ~&  has-failed/p.longest
      ?:  has-failed
        ~&  %double-fail
        ~|  double-failure/[p.longest -.i.todo]
        ~_  (collapse-tang p.cup)
        !!
      =.  has-failed  %.y
      ::
      =/  =prov  -.i.todo
      =/  ch=change  +.i.todo
      ::
      ?:  ?=(%.y -.prov)
        ::
        ::  revert the event
        ::
        =.  done   ~
        =.  lopes  ~
        =.  fil  og-fil
        ::
        =/  rat  p.longest
        ~&  reverting-event/rat
        ::
        =.  plan
          %+  ~(put by *_plan)  rat
          %+  turn  (do-crash rat p.cup ch)
          |=  =change
          :-  [%.y /]  change
        ^$
      ::
      ::  continue
      ::
      =/  rat=root  p.longest
      ::
      ~&  continuting-after-crash/rat
      ::
      =.  plan
        %+  ~(put by plan)  rat
        %+  turn  (do-crash rat p.cup ch)
        |=  =change
        :-  [%.y /]  change
      ^$
    ::
::  produce grow cards for any bound namespace at this view location
    ++  static-cards
      |=  =here
      ^-  (list card-outer)
      =/  dipped  (dips here)
      ?~  leaf.code.dipped  ~
      =/  =view  u.leaf.code.dipped
      =|  out=(list card-outer)
      ::
      =?  out  ?=(^ leaf.bound.view)  [[%grow here %leaf u.leaf.bound.view] out]
      =?  out  ?=(^ kids.bound.view)  [[%grow here %kids u.kids.bound.view] out]
      =?  out  ?=(^ cone.bound.view)  [[%grow here %cone u.cone.bound.view] out]
      ::
      out
    ::
    ++  spread
      ::
      ::  take a [=root caz=(list card)]
      ::  (which is the output of an ingress arm or
      ::    the output of a reaction elsewhere in the tree),
      ::  and
      ::    - accumulate non-%hawk cards into .lopes
      ::    - apply the %hawk cards, changing the main tree
      ::    - spread %hawk cards to the .plan, so that ancestors
      ::        of changed locations have an opportunity to react
      ::
      =|  already-crashed=_|
      |=  [=root caz=(list card)]
      ^+  this
      ::
      =/  vab=(list stem)  (views-affected-below root caz)
      =/  vaa=(list (pair pith code))
        %+  anc:c  root
        |=  code
        ?&
          ?=  ^  leaf
        ==
      ::
      =/  og-fil  fil
      |-
      ^+  this
      ?~  caz  this
      =/  =card  i.caz
      ::
      ?.  ?=(%hawk -.card)
        ::
        ::  add card-outer to .lopes
        ::
        =.  lopes  [[root card] lopes]
        $(caz t.caz)
      ::
      ::  apply the %hawk card
      ::
      =/  action  action.card
      =/  is-inner=?
        ?|  ?=(^ (find #/~ stem.card))
            ?&(?=(^ wire.card) =(i.wire.card %out))
        ==
      =/  loc  (welp root stem.card)
      =/  dipped  (~(dip do data.fil) loc)
      ::
      =/  =(each [(list card-outer) _fil] tang)
        %-  mule  |.
        ?-  -.action
          %ins
            ::
            ::  XX do sanity checking on the inserted node
            ::
            =.  data.fil  (~(put do data.fil) loc node.action)
            [~ fil]
          ::
          %bind
            ::
            =.  code.fil
              %+  ~(mol ox code.fil)  loc
              |=  =(unit view)
              ^+  unit
              =/  =view  (fall unit *view)
              :-  ~
              %=  view
                bound  +.action
              ==
            ::
            [~ fil]
          ::
          ::
          %del
            =.  data.fil  (~(del do data.fil) loc)
            [~ fil]
          ::
          %lop
            =.  data.fil  (~(lop do data.fil) loc)
            [~ fil]
          ::
          %nic
            =.  data.fil  (~(nic do data.fil) loc)
            [~ fil]
          ::
          %install
            :-  ~
            (install loc source.action)
          ::
          %uninstall
            :-  ~
            (uninstall loc)
        ==
      ?:  ?=(%.n -.each)
        ~&  not-good-not-good/root
        =.  done  ~
        =.  fil  og-fil
        =/  crash-changes  (do-crash root p.each card)
        ^$(caz crash-changes, already-crashed &)
      ::
      =^  cops  fil  p.each
      =.  lopes  (welp (envelope root cops) lopes)
      ::
      ::  install: also notify the installed view
      ::
      =?  plan  ?=(%install -.action)
        %+  ~(add ja plan)  loc
        [[%.n root] card(stem ~)]
      ::
      ::  install/uninstall: also notify the originating view
      ::  so it can close the HTTP connection
      ::
      =?  plan  ?=(?(%install %uninstall) -.action)
        %+  ~(add ja plan)  root
        [[%.y /] card]
      ::
      =.  plan
        ::
        ::  add for views below
        ::  skip for %install/%uninstall: already handled above
        ::
        ?:  ?=(?(%install %uninstall) -.action)  plan
        =/  below=(list stem)  vab
        |-
        ?~  below  plan
        =/  subroot=pith  i.below
        =/  absroot=pith  (welp root subroot)
        =/  relstem=pith  (slag (lent subroot) stem.card)
        ::
        =/  =prov
          ?~  subroot  [%.y /]
          [%.n root]
        ::
        =?  plan  ?|
                    =(stem.card i.below)
                    (~(is-ancestor th stem.card) i.below)
                  ==
          %+  ~(add ja plan)  absroot  [prov card(stem relstem)]
        ::
        $(below t.below)
      ::
      =?  plan  !is-inner
        ::
        ::  add for views above
        ::
        =/  above=(list (pair pith code))  vaa
        |-
        ?~  above  plan
        =/  absroot=pith  p.i.above
        =/  difroot=pith  (slag (lent absroot) root)
        =/  relstem=pith  (welp difroot stem.card)
        ::
        =/  =prov  [%.y difroot]
        ::
        =.  plan  %+  ~(add ja plan)  absroot  [prov card(stem relstem)]
        ::
        $(above t.above)
      $(caz t.caz)
    ::
    ::  find child views below .root whose subtree overlaps
    ::  with any of the changed stems in .caz
    ++  views-affected-below
      |=  [=root caz=(list card)]
      ^-  (list stem)
      =/  changed-stems=(set stem)
        %-  silt
        %+  murn  caz
        |=  =card
        ?.  ?=(%hawk -.card)  ~
        `stem.card
      %+  murn  tap:(dit:c root)
      |=  [view-loc=pith *]
      =/  is-affected=?
        %-  ~(any in changed-stems)
        |=  =stem
        (~(is-ancestor th stem) view-loc)  :: is view-loc ancestor of stem
      ?.  is-affected  ~
      `view-loc
    ::
::  handle a crash: build the view and call its ++on-crash arm
    ++  do-crash
      |=  [=here =tang =change]
      ^-  (list _change)
      =/  vew
        ~|  not-view/here
        (need (get:c here))
      =^  cor  fil  (build-raw here vew)
      ~&  running-crash/here
      =;  =(unit (list _change))
        ?^  unit  u.unit
        %-  (slog 'on-crash-fail' leaf+(pate here) tang)
        ~
      %-  mole  |.
      =.  fil  (open-sig here)
      (on-crash:cor tang change quest(here here) (dips here))
    ::
::  build a view and run its ++on-change arm, returning cards+file or tang
    ++  run-on-change
      |=  [=here =prov =change]
      ^-  (each [(list card) file] tang)
      %-  mule  |.
      ^-  [(list card) file]
      =/  vuw  (get:c here)
      ?.  ?&  ?=  ^  vuw
              ?=  ^  source.u.vuw
          ==
        [~ fil]
      ::
      =^  cor  fil  (build-raw here (need vuw))
      ~|  on-change-fail/here
      =?  fil  !=(here here.quest)  (open-sig here)
      =?  fil  !=(here here.quest)  (close-sig here.quest)
      =/  effects=(list card)  (on-change:cor prov +.change quest(here here) (dips here))
      =?  fil  !=(here here.quest)  (close-sig here)
      =?  fil  !=(here here.quest)  (open-sig here.quest)
      :: =?  fil  ?=(%uninstall -.action.change)
      ::   (uninstall (welp here stem.change))
      [effects fil]
    --
  ::
::::  top-level entry points (called by the gall agent)
  ::
  ++  cancel-http
    |=  [gowl=bowl:gall rid=@ta =root =stem =view]
    ^-  [(list lope) file]
    =/  =quest
      %*  .  *quest
        our  our.gowl
        src  src.gowl
        now  now.gowl
        eny  eny.gowl
        here  root
      ==
    =^  cor  fil  (build-raw root view)
    =.  fil  (open-sig root)
    (event-loop quest gowl (cancel-http:cor rid stem quest (dips root)))
  ::
  ++  on-http
    |=  [gowl=bowl:gall rid=@ta req=request:http pams=(map @t @t) =root =stem =view]
    ^-  [(list lope) file]
    =/  =quest
      %*  .  *quest
        our  our.gowl
        src  src.gowl
        now  now.gowl
        eny  eny.gowl
        here  root
      ==
    =/  http-req
      %*  .  *http-req
        seed  /oxal
        stem  stem
        pams  pams
        ::
        rid  rid
        method  method.req
        header-list  header-list.req
        body  body.req
      ==
    =;  =(each [lopes=(list lope) file] tang)
      ?:  ?=  %.y  -.each  p.each
      %-  (slog >on-http-crashed/[root stem]< p.each)
      :_  fil
      %+  envelope  root
      %+  payload-cards  rid
      =-  -(status-code.response-header 500)
      %^    feather-1-payload
          "crash!"
        ~
      ;div.p5.pb15.fc.g5.mono
        ;div: crash
        ;button.underline
          =onclick  "window.location.reload()"
          ; refresh
        ==
        ;+  (render-tang p.each)
      ==
    %-  mule  |.
    =^  cor  fil  (build-raw root view)
    =.  fil  (open-sig root)
    (event-loop quest gowl (on-http:cor http-req quest (dips root)))
  ::
  ++  on-reinstall
    |=  [gowl=bowl:gall =root]
    ^-  [(list lope) file]
    =/  =view  (fall (get:c root) *view)
    ?~  source.view  [~ fil]
    =/  =quest  (bowl-to-quest root gowl)
    =^  cor  fil  (build-raw root view)
    =.  fil  (open-sig root)
    (event-loop quest gowl ~[[%hawk [/no-op/reinstall / [%install (need source.view)]]]])
  ::
  ++  on-arvo
    |=  [gowl=bowl:gall =root =wire =sign-arvo]
    ^-  [(list lope) file]
    ::
    :: xx catch fails
    ::
    =/  =view  (got:c root)
    =/  =quest  (bowl-to-quest root gowl)
    =^  cor  fil  (build-raw root view)
    =.  fil  (open-sig root)
    (event-loop quest gowl (on-arvo:cor wire sign-arvo quest (dips root)))
  ::
::  open-sig: expose the view's inner (framework-private) data
  ::  by copying it from the code tree into the data tree at #/~.
  ::  this lets the view's arms read their own internal state.
  ++  open-sig
    |=  =root
    ^+  fil
    =/  sig=pith  (welp root #/~)
    =.  data.fil
      %+  ~(rep do data.fil)  sig
      %.  #/sig
      %~  dip  do
      =<  inner
      (fall (~(get ox code.fil) root) *view)
    fil
  ::
::  close-sig: save the view's inner data back from the data tree
  ::  into the code tree, then remove it from #/~ in the data tree.
  ::  inverse of ++open-sig.
  ++  close-sig
    |=  =root
    ^+  fil
    =/  sig=pith  (welp root #/~)
    =.  code.fil
      %+  ~(put ox code.fil)  root
      =/  before=view  (fall (~(get ox code.fil) root) *view)
      %*  .  before
        inner
          ^-  data
          %+  ~(rep do `data`inner.before)  `pith`/sig
          (~(dip do data.fil) sig)
      ==
    =.  data.fil  (~(lop do data.fil) sig)
    fil
  --
--