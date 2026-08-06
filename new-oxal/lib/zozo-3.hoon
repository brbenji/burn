::  three: common patterns (oxal-redux)
::
/+  *zozo-2
|%
++  zozo  %400
::
++  get-mesh
  ::
  ::  linear scan of meshes for a name match.
  ::
  |=  [acer want=term]
  ^-  (unit mesh)
  ?~  meshes  ~
  ?:  =(name.i.meshes want)  `mesh.i.meshes
  $(meshes t.meshes)
::
++  got-mesh
  ::
  |=  [=acer name=term]
  ~|  mesh-not-found/name
  (need (get-mesh acer name))
::
+$  staged
  ::
  ::  output of stage-load: a fully-validated mesh ready for commit.
  ::    forms   declared form-stems from ++forms
  ::    views   view layout from ++load, with system-controlled fields
  ::            (lyf/cas/err) defaulted from the user's view-specs
  ::    output  migration move returned by ++load
  ::
  $:  =mesh-core
      forms=(set stem)
      views=(map stem view)
      output=move
  ==
::
++  build-mesh-core
  ::
  ::  compile a %mono mesh source to a typed core.  errors land in
  ::  tang.
  ::
  |=  src=@t
  ^-  (each mesh-core tang)
  (mule |.(!<(mesh-core (slap !>(.) (ream src)))))
::
++  build-poly-views
  ::
  ::  compile a %poly mesh's per-stem sources.  each @t evaluates to
  ::  a view-spec.  on the first failure, prepend the offending stem
  ::  to the tang so the user can locate the broken view.
  ::
  |=  srcs=(map stem @t)
  ^-  (each (map stem view-spec) tang)
  =|  out=(map stem view-spec)
  =/  pairs=(list [stem @t])  ~(tap by srcs)
  |-
  ?~  pairs  [%& out]
  =/  res=(each view-spec tang)
    (mule |.(!<(view-spec (slap !>(.) (ream +.i.pairs)))))
  ?:  ?=(%| -.res)
    [%| leaf+"poly view at {(pate -.i.pairs)}" p.res]
  $(out (~(put by out) -.i.pairs p.res), pairs t.pairs)
::
++  call-forms
  ::
  ::  invoke ++forms against the door sample [our name].  pure;
  ::  prior-forms is not in scope for this arm.
  ::
  |=  [=mesh-core our=@p name=term]
  ^-  (each (set stem) tang)
  (mule |.(~(forms mesh-core [our name])))
::
++  call-load
  ::
  ::  invoke ++load with prior-forms.  the form-typed keys of the
  ::  returned view-specs must match ++forms exactly (caller validates).
  ::
  |=  [=mesh-core our=@p name=term =prior-forms]
  ^-  (each [views=(map stem view-spec) output=move] tang)
  (mule |.((~(load mesh-core [our name]) prior-forms)))
::
++  view-from-spec
  ::
  ::  expand a user-authored view-spec into a full view, defaulting
  ::  every system-controlled field.  lyf/cas start at 0 and err is
  ::  ~ — the user picks out+in+dep+sauc on a lens and out on a form;
  ::  everything else is engine bookkeeping.
  ::
  |=  =view-spec
  ^-  view
  ?-  -.view-spec
    %form  [%form out=out.view-spec]
    %lens
      :*  %lens
          out=out.view-spec
          in=in.view-spec
          sauc=sauc.view-spec
          dep=dep.view-spec
          lyf=0
          cas=0
          err=~
      ==
  ==
::
++  call-drop
  ::
  ::  same pattern for ++drop.
  ::
  |=  [=mesh-core our=@p name=term =prior-forms]
  ^-  (each output=move tang)
  (mule |.((~(drop mesh-core [our name]) prior-forms)))
::
++  ae
  :::
  ::    acer engine
  ::
  =|  cards=(list card:agent:gall)
  |_  [ax=acer our=ship now=@da verb=? effects=?]
  +*  fil  file.ax
      dat  data.fil
      cod  code.fil
  ::
  ++  cor   .
  ++  abet  [(flop cards) ax]
  ++  emit  |=  =card:agent:gall  cor(cards [card cards])
  ++  emil  |=  cs=(list card:agent:gall)  cor(cards (welp (flop cs) cards))
  ::
  ++  ingress-tick
    ::
    ::  advance the acer's hlc against now (local cause).  returns the
    ::  new hlc and an updated cor.
    ::
    ^-  [hlc _cor]
    =/  new=hlc  (hlc-tick now-hlc.ax now)
    =.  now-hlc.ax  new
    [new cor]
  ::
  ++  ingress-merge
    ::
    ::  merge a remote hlc into the acer's hlc against now.  returns
    ::  the merged hlc and an updated cor.
    ::
    |=  rem=hlc
    ^-  [hlc _cor]
    =/  new=hlc  (hlc-merge now-hlc.ax rem now)
    =.  now-hlc.ax  new
    [new cor]
  ::
  ++  vlog
    ::
    ::  verbose-only slog: emit msg as a leaf iff verb is %.y.
    ::
    |=  msg=tape
    ^+  cor
    ?.  verb  cor
    %-  (slog leaf+msg ~)
    cor
  ::
  ++  under-our
    ::
    ::  qualify a bare user-facing pith with /[our]
    ::
    |=  pax=pith
    ^-  pith
    [p+our pax]
  ::
  ++  min-meta-depth  2
  ++  meta-allowed
    ::
    ::  is full-pax deep enough to carry meta and participate in
    ::  propagation?  the root and /[ship] are pinned at life=0 case=0.
    ::
    |=  full-pax=pith
    ^-  ?
    (gte (lent full-pax) min-meta-depth)
  ::
  ++  ancestor-depths
    ::
    ::  valid ancestor depths for a pith of given length; empty if
    ::  shallower than min-meta-depth.
    ::
    |=  len=@ud
    ^-  (list @ud)
    ?:  (lth len min-meta-depth)  ~
    (gulf min-meta-depth len)
  ::
  ++  rebase-chng
    ::
    ::  replace the pith on a chng.  both arms have a pith field;
    ::  the case split is required by hoon's $% mutator rules.
    ::
    |=  [c=chng new=pith]
    ^-  chng
    ?-(-.c %ins c(pith new), %del c(pith new))
  ::
  ++  rebase-meta-chng
    ::
    ::  replace the pith on a meta-chng.
    ::
    |=  [c=meta-chng new=pith]
    ^-  meta-chng
    ?-(-.c %ins c(pith new), %del c(pith new))
  ::
  ++  step-chngs
    ::
    ::  apply each chng to data, returning the new data and the
    ::  subset of chngs that wasn't a no-op.
    ::
    |=  [d=data chs=(set chng)]
    ^-  [data (set chng)]
    =|  effective=(set chng)
    =/  changes=(list chng)  ~(tap in chs)
    |-
    ?~  changes  [d effective]
    ?-  -.i.changes
      %ins
        ?:  =(`node.i.changes (~(get do d) pith.i.changes))
          $(changes t.changes)
        %=  $
          changes    t.changes
          d          (~(put do d) pith.i.changes node.i.changes)
          effective  (~(put in effective) i.changes)
        ==
      ::
      %del
        ?.  (~(has do d) pith.i.changes)
          $(changes t.changes)
        %=  $
          changes    t.changes
          d          (~(del do d) pith.i.changes)
          effective  (~(put in effective) i.changes)
        ==
    ==
  ::
  ++  reject-shallow
    ::
    ::  slog a depth-rejection message and pass through cor
    ::
    |=  [op=tape full-pax=pith]
    ^+  cor
    %-  (slog leaf+"fe: rejected {op} at {(pate full-pax)}: depth < 2" ~)
    cor
  ::
  ++  gut-meta
    ::
    ::  get meta at pax, or default if missing
    ::
    |=  pax=pith
    ^-  meta
    (fall (~(get ox cod) pax) *meta)
  ::
  ++  merge-meta-on-place
    ::
    ::  build the meta to write when placing a mesh view at a stem.
    ::  if there's a prior meta, preserve subs/view-subs/grow/eyre/gall
    ::  and bump life iff grow was %.y; otherwise return a fresh meta
    ::  with life=0.  lord is set unconditionally.
    ::
    |=  [old=(unit meta) new-lord=[mesh=term =view]]
    ^-  meta
    ?~  old
      =/  m=meta  *meta
      m(lord `new-lord)
    %_  u.old
      lord  `new-lord
      life  ?:(grow.u.old +(life.u.old) life.u.old)
    ==
  ::
  ++  meta-significant-change
    ::
    ::  does the transition from old to new touch any structural field?
    ::  case/logs/life alone are engine bookkeeping and don't fire
    ::  code facts.
    ::
    |=  [old=(unit meta) new=(unit meta)]
    ^-  ?
    ?~  new  ?=(^ old)
    ?~  old  %.y
    ?|  !=(grow.u.old grow.u.new)
        !=(eyre.u.old eyre.u.new)
        !=(gall.u.old gall.u.new)
        !=(lord.u.old lord.u.new)
        !=(subs.u.old subs.u.new)
        !=(view-subs.u.old view-subs.u.new)
    ==
  ::
  ++  beneath-view
    ::
    ::  is pax beneath an existing view?
    ::
    |=  [pax=pith c=code]
    ^-  ?
    ?=(^ (~(abo ox c) pax |=(m=_c &(?=(^ leaf.m) ?=(^ lord.u.leaf.m)))))
  ::
  ++  beneath-lens
    ::
    ::  is pax beneath an existing %lens view?
    ::
    |=  [pax=pith c=code]
    ^-  ?
    ?=(^ (~(abo ox c) pax |=(m=_c ?&(?=(^ leaf.m) ?=(^ lord.u.leaf.m) ?=(%lens -.view.u.lord.u.leaf.m)))))
  ::
  ++  at-or-beneath-lens
    ::
    ::  does pax itself have a %lens view, or sit beneath one?
    ::  do-move rejects writes here: %lens output is derived, not
    ::  user-editable.  %form views (and unview'd paths) hold base
    ::  data and pass through.
    ::
    |=  [pax=pith c=code]
    ^-  ?
    =/  met=meta  (fall (~(get ox c) pax) *meta)
    ?:  ?&  ?=(^ lord.met)
            ?=(%lens -.view.u.lord.met)
        ==
      %.y
    (beneath-lens pax c)
  ::
  ++  suspend-view
    ::
    ::  unsub from faucet and store error on view
    ::
    |=  [pax=pith =view met=meta =tang]
    ^+  cor
    ?>  ?=(%lens -.view)
    ?>  ?=(^ lord.met)
    =.  cor  (vlog "ae: suspend view at {(pate pax)}")
    =.  cor  (faucet-unsub pax dep.view)
    =.  cod
      %+  ~(put ox cod)  pax
      met(lord `[mesh=mesh.u.lord.met view=view(err `tang)])
    cor
  ::
  ++  get-xfm
    ::
    ::  get transformer from cache, or compile and cache it.
    ::  returns [%| tang] on parse/type failure so callers can
    ::  suspend the view instead of crashing the whole op.
    ::  failed compiles are not cached: the same cord would fail
    ::  again, so there is nothing to memoize.
    ::
    |=  src=@t
    ^-  [(each transformer tang) _cor]
    =/  cached  (~(get by xfms.ax) src)
    ?^  cached  [[%& u.cached] cor]
    =/  result=(each transformer tang)
      (mule |.(!<(transformer (slap !>(.) (ream src)))))
    ?-  -.result
      %&  =.  xfms.ax  (~(put by xfms.ax) src p.result)
          [result cor]
      %|  [result cor]
    ==
  ::
  ++  resolve-code
    ::
    ::  resolve view.sauc to the @t cord to compile.
    ::    - atom: use as-is
    ::    - link: fetch leaf from local data; on miss or
    ::      wrong shape, fall back to a crashing-gate cord so the
    ::      view suspends via run-xfm's mule on first invocation.
    ::
    |=  =view
    ^-  @t
    ?>  ?=(%lens -.view)
    ?@  sauc.view  sauc.view
    =/  link-pax=pith  (ref-to-pith sauc.view)
    =/  fallback=@t
      %-  crip
      """
      |=  *
      ~|  no-code/(pate {<link-pax>})
      !!
      """
    =/  nod=(unit node)  (~(get do dat) link-pax)
    ?~  nod  fallback
    ?.  ?=([%t @] u.nod)  fallback
    t.u.nod
  ::
  ++  reset-submetas
    ::
    ::  increment life, reset case, and clear logs for all
    ::  submetas under pax.
    ::  skip-root: don't touch the root meta (for install).
    ::
    |=  [pax=pith skip-root=?]
    ^+  cor
    =/  subs=(list (pair pith meta))
      ~(tap ox (~(dip ox cod) pax))
    =/  sr=?  skip-root
    |-  ^+  cor
    ?~  subs  cor
    =?  cor  ?!(?&(sr =(/ p.i.subs)))
      =/  full  (weld pax p.i.subs)
      =/  new-met=meta
        %=  q.i.subs
          life  ?:(grow.q.i.subs +(life.q.i.subs) life.q.i.subs)
          case  0
          logs  ~
        ==
      =.  cod  (~(put ox cod) full new-met)
      =/  snap=data  (~(dip do dat) full)
      (emit-node-effects full new-met snap [*hlc ~])
    $(subs t.subs)
  ::
  ++  faucet-unsub
    ::
    ::  remove full-pax from a faucet's subscriber set.
    ::  the faucet may live on any ship's subtree.
    ::
    |=  [full-pax=pith dep=link]
    ^+  cor
    =/  faucet-pax       (ref-to-pith dep)
    =/  faucet-met=meta  (gut-meta faucet-pax)
    =.  cod
      %+  ~(put ox cod)  faucet-pax
      faucet-met(subs (~(del in subs.faucet-met) full-pax))
    cor
  ::
  ++  link-sub
    ::
    ::  register a view at full-pax as a link-subscriber on the
    ::  meta at link-pax (the pith pointed to by [%link pith]).
    ::
    |=  [full-pax=pith link-pax=pith]
    ^+  cor
    =/  met=meta  (gut-meta link-pax)
    =.  cod
      %+  ~(put ox cod)  link-pax
      met(view-subs (~(put in view-subs.met) full-pax))
    cor
  ::
  ++  link-unsub
    ::
    ::  remove a view at full-pax from the link-subscriber set
    ::  on the meta at link-pax.
    ::
    |=  [full-pax=pith link-pax=pith]
    ^+  cor
    =/  met=meta  (gut-meta link-pax)
    =.  cod
      %+  ~(put ox cod)  link-pax
      met(view-subs (~(del in view-subs.met) full-pax))
    cor
  ::
  ++  maybe-link-unsub
    ::
    ::  if view.sauc is a link, call link-unsub; else no-op.
    ::
    |=  [full-pax=pith =view]
    ^+  cor
    ?>  ?=(%lens -.view)
    ?@  sauc.view  cor
    (link-unsub full-pax (ref-to-pith sauc.view))
  ::
  ++  ingress-do-move
    ::
    ::  user-facing move: chng piths are bare, relative to /[our].
    ::  qualify them and dispatch to apply-move-qualified, rejecting
    ::  any writes at or beneath a %lens view (lens output is derived,
    ::  not user-editable).  ticks the agent-level hlc once and freezes
    ::  that time onto the move, so all log entries from this cause
    ::  share one timestamp.  wraps the dispatch to capture structural
    ::  code changes produced by transformer firings during propagate.
    ::
    |=  =move
    ^+  cor
    =^  time=hlc  cor  ingress-tick
    =.  move  move(time time)
    =.  cor  (vlog "ae: do-move ({(scow %ud ~(wyt in chng-set.move))} changes)")
    =/  cod-before  cod
    =.  cor  (apply-move-qualified [(prefix-move [p+our ~] move) %.n])
    (emit-code-at-ancestors cod-before)
  ::
  ++  apply-move-qualified
    ::
    ::  apply a move whose chng piths are already qualified
    ::  (start with a ship iota).  updates data, filters to
    ::  effective changes, walks up code tree.
    ::
    |=  [=move allow-view-write=?]
    ^+  cor
    =/  [d=data effective=(set chng)]
      (apply-changes move allow-view-write)
    ?:  =(~ effective)  cor
    (propagate d cod effective time.move)
  ::
  ++  rebuild-view
    ::
    ::  wipe a view's output and re-fire its transformer from the
    ::  current faucet snap.  used when the view's source code
    ::  changed (link target update) or its faucet's life bumped.
    ::  full-pax is fully qualified with [%p our].
    ::
    |=  full-pax=pith
    ^+  cor
    =/  met=meta  (gut-meta full-pax)
    ?~  lord.met  cor
    =*  vw  view.u.lord.met
    ?>  ?=(%lens -.vw)
    =.  cor  (vlog "ae: rebuild-view at {(pate full-pax)}")
    =.  dat  (~(lop do dat) full-pax)
    =/  faucet-met=meta  (gut-meta (ref-to-pith dep.vw))
    (initialize-from-snap full-pax vw faucet-met)
  ::
  ++  reinstall-links
    ::
    ::  for each effective change, rebuild every view-sub on the meta
    ::  at the change's pith from the current faucet snap.  re-resolves
    ::  link sources, so a code change at the link target propagates
    ::  into a fresh transformer.
    ::
    |=  effective=(set chng)
    ^+  cor
    =/  chs=(list chng)  ~(tap in effective)
    |-  ^+  cor
    ?~  chs  cor
    =/  m=meta  (gut-meta (pith-of-chng i.chs))
    =/  vs=(list pith)  ~(tap in view-subs.m)
    =.  cor
      |-  ^+  cor
      ?~  vs  cor
      =.  cor  (rebuild-view i.vs)
      $(vs t.vs)
    $(chs t.chs)
  ::
  ++  reinstall-subs
    ::
    ::  rebuild every view in pax's subs set from the current faucet
    ::  snap.  used on remote life-bump to force local subscribers
    ::  to rebuild from the fresh snap.
    ::
    |=  pax=pith
    ^+  cor
    =/  m=meta  (gut-meta pax)
    =/  subs-list=(list pith)  ~(tap in subs.m)
    |-  ^+  cor
    ?~  subs-list  cor
    =.  cor  (rebuild-view i.subs-list)
    $(subs-list t.subs-list)
  ::
  ++  apply-changes
    ::
    ::  user-facing change application.  reject writes at or beneath
    ::  any %lens view (lens output is derived, not user-editable),
    ::  unless allow-view-write -- transformer-produced output is
    ::  already prefixed with the view's own pith and gets through.
    ::
    |=  [=move allow-view-write=?]
    ^-  [data (set chng)]
    ?.  allow-view-write
      =/  cs=(list chng)  ~(tap in chng-set.move)
      |-
      ?~  cs  (step-chngs dat chng-set.move)
      =/  p=pith  (pith-of-chng i.cs)
      ?:  (at-or-beneath-lens p cod)
        ~|  "fe: rejected write at or beneath lens at {(pate p)}"
        !!
      $(cs t.cs)
    (step-chngs dat chng-set.move)
  ::
  ++  propagate
    ::
    ::  merge-walk.  process ancestor piths longest-first from a shared
    ::  queue; each pith bumps its case at most once.  firing a
    ::  subscriber's transformer produces a move whose ancestors and
    ::  relative chngs are merged back into the same queue/rels,
    ::  so downstream updates share the walk instead of triggering
    ::  nested propagates.  at the end, re-install %link-subscribed
    ::  views whose link target was in any effective change.
    ::
    ::  time is the cause's hlc, frozen at ingress.  every log entry
    ::  appended during this walk -- including transformer-produced
    ::  ones -- carries this same time.
    ::
    |=  [d=data c=code effective=(set chng) time=hlc]
    ^+  cor
    ::  commit data/code up front so transformer-produced changes
    ::  see the current state.
    ::
    =.  cor  cor(data.file.ax d, code.file.ax c)
    =/  rels=(map pith (set chng))  (build-rels effective)
    =/  queue=(list pith)  (sort-piths-desc ~(key by rels))
    =|  processed=(set pith)
    =/  combined=(set chng)  effective
    (propagate-loop queue rels processed combined time)
  ::
  ++  propagate-loop
    ::
    ::  one iteration of the merge-walk.
    ::
    |=  $:  queue=(list pith)
            rels=(map pith (set chng))
            processed=(set pith)
            combined=(set chng)
            time=hlc
        ==
    ^+  cor
    ?~  queue
      (reinstall-links combined)
    =/  anc=pith  i.queue
    =/  rest=(list pith)  t.queue
    ?:  (~(has in processed) anc)
      $(queue rest)
    =.  processed  (~(put in processed) anc)
    =/  rel=(set chng)  (fall (~(get by rels) anc) ~)
    ?~  rel
      $(queue rest)
    =/  met=meta  (gut-meta anc)
    =/  rel-move=move  [time rel]
    =/  new-met=meta
      %=  met
        case  +(case.met)
        logs  (snoc logs.met rel-move)
      ==
    ::  bump case and append this walk's [time rel] to logs
    ::
    =.  cor
      %-  vlog
      "ae: propagate at {(pate anc)} life={(scow %ud life.new-met)} case={(scow %ud case.new-met)}"
    =.  cod  (~(put ox cod) anc new-met)
    =/  snap=data  (~(dip do dat) anc)
    ::  fan this bump out to gall/grow/eyre channels
    ::
    =.  cor  (emit-node-effects anc new-met snap rel-move)
    ::  fire subscribers of this ancestor, collecting their outputs
    ::
    =^  xfm-chngs=(set chng)  cor
      (fire-subs-collect new-met snap rel life.new-met case.new-met time)
    ?:  =(~ xfm-chngs)
      $(queue rest)
    ::  apply transformer output to data; filter to effective chngs
    ::
    =^  xfm-effective=(set chng)  cor  (apply-extra-changes xfm-chngs)
    ?:  =(~ xfm-effective)
      $(queue rest)
    =.  combined  (~(uni in combined) xfm-effective)
    =/  added-rels=(map pith (set chng))  (build-rels xfm-effective)
    =.  rels   (merge-rels rels added-rels)
    =/  new-queue=(list pith)
      (merge-queue rest ~(key by added-rels) processed)
    $(queue new-queue)
  ::
  ++  run-xfm
    ::
    ::  fire a transformer and apply its output if any.  used by
    ::  initialize-from-snap; propagation invokes run-xfm-collect
    ::  directly so it can merge outputs into the merge-walk.
    ::
    |=  [sub=pith =view met=meta snap=data mov=(set chng) lyf=@ud cas=@ud]
    ^+  cor
    =/  time=hlc  now-hlc.ax
    =^  out=(unit (set chng))  cor
      (run-xfm-collect sub view met snap mov lyf cas time)
    ?~  out  cor
    (apply-move-qualified [[time u.out] %.y])
  ::
  ++  validate-mesh-views
    ::
    ::  pre-flight check on a mesh's view layout.  returns the first
    ::  rejection message, or ~ if every view is placeable.  rules:
    ::    - stem must be deep enough to carry meta (>= min-meta-depth)
    ::    - stem must lie under the mesh's territory /[our]/[name]
    ::    - stem must not sit at or beneath an existing view
    ::    - %lens stem must not be at or above its own faucet
    ::
    |=  [name=term vws=(map stem view)]
    ^-  (unit @t)
    =/  pairs=(list [stem view])  ~(tap by vws)
    |-  ^-  (unit @t)
    ?~  pairs  ~
    =/  full-pax  (under-our -.i.pairs)
    =/  vw=view   +.i.pairs
    ?.  (meta-allowed full-pax)
      `(crip "ae: load-mesh rejected: stem too shallow at {(pate full-pax)}")
    ?.  (under-mesh name -.i.pairs)
      `(crip "ae: load-mesh rejected: stem at {(pate full-pax)} must lie under /{(trip (scot %p our))}/{(trip name)}")
    ?:  (beneath-view full-pax cod)
      `(crip "ae: load-mesh rejected: stem at or beneath existing view at {(pate full-pax)}")
    ?:  ?&  ?=(%lens -.vw)
            (~(is-ancestor-or-same th full-pax) (ref-to-pith dep.vw))
        ==
      `(crip "ae: load-mesh rejected: lens at {(pate full-pax)} has self or ancestor as faucet at {(pate (ref-to-pith dep.vw))}")
    $(pairs t.pairs)
  ::
  ++  under-mesh
    ::
    ::  is `stem` placed under the mesh `name`'s territory?  the first
    ::  iota of stem must be the mesh name (a bare term).
    ::
    |=  [name=term stem=pith]
    ^-  ?
    ?~  stem  %.n
    =(name i.stem)
  ::
  ++  place-mesh-view
    ::
    ::  install one view from mesh `name` at stem.  for %lens, wires
    ::  faucet subs, optional link subs, lops the prior data subtree
    ::  (lens output is derived, never user-data), and runs
    ::  initialize-from-snap.  for %form, writes the meta and leaves
    ::  data in place — data is sovereign; a mesh declaring a form at
    ::  a stem with pre-existing data is just structuring it.  pre-
    ::  validated by stage-load, so the meta-allowed and beneath-view
    ::  checks here are defensive.
    ::
    |=  [name=term stem=pith =view]
    ^+  cor
    =/  full-pax  (under-our stem)
    =/  old=(unit meta)  (~(get ox cod) full-pax)
    =/  met=meta  (merge-meta-on-place old [mesh=name view=view])
    =.  cod  (~(put ox cod) full-pax met)
    ?:  ?=(%form -.view)  cor
    =.  dat  (~(lop do dat) full-pax)
    =/  full-dep=pith    (ref-to-pith dep.view)
    =/  faucet-met=meta  (gut-meta full-dep)
    =.  cod
      %+  ~(put ox cod)  full-dep
      faucet-met(subs (~(put in subs.faucet-met) full-pax))
    =?  cor  ?=(^ sauc.view)
      (link-sub full-pax (ref-to-pith sauc.view))
    (initialize-from-snap full-pax view faucet-met)
  ::
  ++  uninstall-mesh-view
    ::
    ::  graceful tear-down: faucet/link unsub for %lens, then clear
    ::  lord on meta.  preserves data and the rest of the meta record
    ::  (grow, eyre, gall, subs, view-subs).  stem is bare; qualified
    ::  with /[our] before lookup.
    ::
    |=  [stem=pith =view]
    ^+  cor
    =/  full-pax  (under-our stem)
    =/  met=meta  (gut-meta full-pax)
    =?  cor  ?=(%lens -.view)
      =.  cor  (faucet-unsub full-pax dep.view)
      (maybe-link-unsub full-pax view)
    =.  cod  (~(put ox cod) full-pax met(lord ~))
    cor
  ::
  ++  wipe-mesh-view
    ::
    ::  failure-path tear-down: lop the data and delete the meta
    ::  record entirely (not just clear lord).  for both form and
    ::  lens views.  any grow/eyre/gall/subs state on the meta is
    ::  gone.  used when ++drop fails — the mesh's territory burns.
    ::
    |=  [stem=pith =view]
    ^+  cor
    =/  full-pax  (under-our stem)
    =?  cor  ?=(%lens -.view)
      =.  cor  (faucet-unsub full-pax dep.view)
      (maybe-link-unsub full-pax view)
    =.  cod  (~(del ox cod) full-pax)
    =.  dat  (~(lop do dat) full-pax)
    cor
  ::
  ++  outgoing-form-stems
    ::
    ::  the form-typed stems of an outgoing mesh's stored views.
    ::
    |=  vs=(map stem view)
    ^-  (set stem)
    %-  silt
    %+  murn  ~(tap by vs)
    |=  [s=stem v=view]
    ?.(?=(%form -.v) ~ `s)
  ::
  ++  capture-priors
    ::
    ::  build prior-forms keyed by `stems`.  each entry's data is the
    ::  data subtree at the stem (qualified with /[our]); shape is
    ::  recovered from the matching outgoing form view if present, ~
    ::  otherwise.
    ::
    |=  [stems=(set stem) outgoing=(map stem view)]
    ^-  prior-forms
    %-  malt
    %+  turn  ~(tap in stems)
    |=  s=stem
    :-  s
    ^-  prior-form
    =/  ovw=(unit view)  (~(get by outgoing) s)
    =/  shp=(unit shape)
      ?~  ovw  ~
      ?.(?=(%form -.u.ovw) ~ `out.u.ovw)
    [shp (~(dip do dat) (under-our s))]
  ::
  ++  stage-load
    ::
    ::  plan-phase of a load.  no tree mutation.  dispatches on the
    ::  mesh-source kind:
    ::
    ::    %mono  builds the user-authored door, calls ++forms +
    ::           ++load, captures prior-forms over (declared ∪
    ::           outgoing-form-stems).
    ::    %poly  compiles each per-stem @t to a view-spec.  no door
    ::           — declared form-stems are derived from the spec map,
    ::           there's no migration move, and the staged mesh-core
    ::           is the bunt (a no-op for ++drop later).
    ::
    ::  returns a staged bundle ready for commit, or a tang on any
    ::  error.
    ::
    |=  [name=term =mesh-source outgoing-views=(map stem view)]
    ^-  (each staged tang)
    ?-  -.mesh-source
      %mono  (stage-load-mono name src.mesh-source outgoing-views)
      %poly  (stage-load-poly name srcs.mesh-source)
    ==
  ::
  ++  stage-load-mono
    ::
    ::  %mono path of stage-load.  see +stage-load for shape.
    ::
    |=  [name=term src=@t outgoing-views=(map stem view)]
    ^-  (each staged tang)
    =/  comp  (build-mesh-core src)
    ?:  ?=(%| -.comp)  [%| p.comp]
    =/  =mesh-core  p.comp
    =/  fout  (call-forms mesh-core our name)
    ?:  ?=(%| -.fout)  [%| p.fout]
    =/  declared=(set stem)  p.fout
    ::
    ::  pre-validate declared form-stems
    ::
    =/  pre-validation=(unit @t)
      =/  pairs=(list stem)  ~(tap in declared)
      |-  ^-  (unit @t)
      ?~  pairs  ~
      =/  full-pax  (under-our i.pairs)
      ?.  (meta-allowed full-pax)
        `(crip "ae: load-mesh rejected: ++forms stem too shallow at {(pate full-pax)}")
      ?.  (under-mesh name i.pairs)
        `(crip "ae: load-mesh rejected: ++forms stem at {(pate full-pax)} must lie under /{(trip (scot %p our))}/{(trip name)}")
      ?:  (beneath-view full-pax cod)
        `(crip "ae: load-mesh rejected: ++forms stem at or beneath existing view at {(pate full-pax)}")
      $(pairs t.pairs)
    ?^  pre-validation  [%| ~[leaf+(trip u.pre-validation)]]
    ::
    ::  capture prior-forms over (declared ∪ outgoing form-stems)
    ::
    =/  outgoing-fs=(set stem)  (outgoing-form-stems outgoing-views)
    =/  all-stems=(set stem)  (~(uni in declared) outgoing-fs)
    =/  =prior-forms  (capture-priors all-stems outgoing-views)
    ::
    ::  call ++load
    ::
    =/  lout  (call-load mesh-core our name prior-forms)
    ?:  ?=(%| -.lout)  [%| p.lout]
    ::
    ::  expand user-authored view-specs into full views, defaulting
    ::  every system-controlled field
    ::
    =/  views=(map stem view)
      (~(run by views.p.lout) view-from-spec)
    ::
    ::  validate form-keys ↔ ++forms strictness
    ::
    =/  returned-forms=(set stem)
      %-  silt
      %+  murn  ~(tap by views)
      |=  [s=stem v=view]
      ?.(?=(%form -.v) ~ `s)
    ?.  =(returned-forms declared)
      :-  %|
      :_  ~
      leaf+"ae: load-mesh rejected: returned form-view keys must equal ++forms exactly"
    ::
    ::  per-view validation (depth, beneath-view, lens self-faucet)
    ::
    =/  view-validation=(unit @t)  (validate-mesh-views name views)
    ?^  view-validation  [%| ~[leaf+(trip u.view-validation)]]
    =/  st=staged  [mesh-core declared views output.p.lout]
    [%& st]
  ::
  ++  stage-load-poly
    ::
    ::  %poly path of stage-load.  see +stage-load for shape.
    ::
    |=  [name=term srcs=(map stem @t)]
    ^-  (each staged tang)
    =/  comp  (build-poly-views srcs)
    ?:  ?=(%| -.comp)  [%| p.comp]
    =/  specs=(map stem view-spec)  p.comp
    ::
    ::  declared form-stems are the spec keys whose value is %form.
    ::
    =/  declared=(set stem)
      %-  silt
      %+  murn  ~(tap by specs)
      |=  [s=stem v=view-spec]
      ?.(?=(%form -.v) ~ `s)
    ::
    ::  expand specs into views and run per-view validation.  no
    ::  pre-validate step: validate-mesh-views covers depth +
    ::  beneath-view + self-faucet uniformly across forms and lenses.
    ::
    =/  views=(map stem view)  (~(run by specs) view-from-spec)
    =/  view-validation=(unit @t)  (validate-mesh-views name views)
    ?^  view-validation  [%| ~[leaf+(trip u.view-validation)]]
    =/  st=staged  [*mesh-core declared views *move]
    [%& st]
  ::
  ++  commit-load
    ::
    ::  apply a staged load.  tear down outgoing views (no ++drop —
    ::  this is mid-life, not terminal), place new views, apply the
    ::  move, store the new entry replacing any prior of the same
    ::  name.
    ::
    |=  [name=term =mesh-source st=staged outgoing-views=(map stem view)]
    ^+  cor
    =/  cod-before  cod
    ::
    ::  tear down outgoing
    ::
    =.  cor
      =/  pairs=(list [stem view])  ~(tap by outgoing-views)
      |-  ^+  cor
      ?~  pairs  cor
      =.  cor  (uninstall-mesh-view -.i.pairs +.i.pairs)
      $(pairs t.pairs)
    ::
    ::  place new views
    ::
    =.  cor
      =/  pairs=(list [stem view])  ~(tap by views.st)
      |-  ^+  cor
      ?~  pairs  cor
      =.  cor  (place-mesh-view name -.i.pairs +.i.pairs)
      $(pairs t.pairs)
    ::
    ::  apply move (allow-view-write=%.n)
    ::
    =?  cor  ?=(^ chng-set.output.st)
      (apply-move-qualified [(prefix-move [p+our ~] output.st) %.n])
    ::
    ::  store entry, replacing any prior of the same name
    ::
    =/  =mesh  *mesh
    =.  mesh-source.mesh  mesh-source
    =.  mesh-core.mesh    mesh-core.st
    =.  forms.mesh        forms.st
    =.  views.mesh        views.st
    =.  meshes.ax
      %+  snoc
        %+  skip  meshes.ax
        |=  [n=term *]
        =(n name)
      [name mesh]
    (emit-code-at-ancestors cod-before)
  ::
  ++  store-fresh-failure
    ::
    ::  fresh-load failure: store an entry with views=~ and the tang.
    ::  no tree changes.  partial mesh-core (may be *mesh-core if
    ::  compile failed before we had one).
    ::
    |=  [name=term =mesh-source =mesh-core =tang]
    ^+  cor
    =/  =mesh  *mesh
    =.  mesh-source.mesh  mesh-source
    =.  mesh-core.mesh    mesh-core
    =.  error.mesh        `tang
    =.  meshes.ax  (snoc meshes.ax [name mesh])
    cor
  ::
  ++  mark-mid-life-failure
    ::
    ::  mid-life load failure: keep old views in place, mark the
    ::  existing entry's error field with the new tang.  source/views/
    ::  forms unchanged.
    ::
    |=  [name=term =tang]
    ^+  cor
    =.  meshes.ax
      %+  turn  meshes.ax
      |=  [n=term m=mesh]
      ?.  =(n name)  [n m]
      [n m(error `tang)]
    cor
  ::
  ++  ingress-load-mesh
    ::
    ::  fresh install, same-source reinstall, and new-source update in
    ::  one entry.  detects fresh vs mid-life by name lookup.  on
    ::  fresh failure: store error entry, no tree change.  on mid-
    ::  life failure: keep old running, mark error.
    ::
    |=  [name=term =mesh-source]
    ^+  cor
    =.  cor  (vlog "ae: load-mesh {<name>}")
    =/  found=(unit mesh)  (get-mesh ax name)
    =/  outgoing-views=(map stem view)
      ?~  found  ~
      views.u.found
    =/  out  (stage-load name mesh-source outgoing-views)
    ?:  ?=(%| -.out)
      ?~  found  (store-fresh-failure name mesh-source *mesh-core p.out)
      (mark-mid-life-failure name p.out)
    (commit-load name mesh-source p.out outgoing-views)
  ::
  ++  ingress-set-poly-view
    ::
    ::  upsert one (stem, src) entry in a poly mesh's srcs map and
    ::  re-run +ingress-load-mesh.  if the mesh doesn't exist, creates
    ::  a fresh poly mesh holding just this entry.  rejects mono
    ::  meshes — convert via %load-mesh first.
    ::
    |=  [name=term stem=pith src=@t]
    ^+  cor
    =/  found=(unit mesh)  (get-mesh ax name)
    =/  current-srcs=(map ^stem @t)
      ?~  found  ~
      ?-  -.mesh-source.u.found
        %mono  ~|("ae: set-poly-view rejected: mesh {<name>} is mono" !!)
        %poly  srcs.mesh-source.u.found
      ==
    =/  new-srcs=(map ^stem @t)  (~(put by current-srcs) stem src)
    (ingress-load-mesh name [%poly new-srcs])
  ::
  ++  ingress-del-poly-view
    ::
    ::  remove one stem from a poly mesh's srcs map and re-run
    ::  +ingress-load-mesh.  no-op if the mesh is missing.  rejects
    ::  mono meshes.
    ::
    |=  [name=term stem=pith]
    ^+  cor
    =/  found=(unit mesh)  (get-mesh ax name)
    ?~  found  cor
    =/  current-srcs=(map ^stem @t)
      ?-  -.mesh-source.u.found
        %mono  ~|("ae: del-poly-view rejected: mesh {<name>} is mono" !!)
        %poly  srcs.mesh-source.u.found
      ==
    =/  new-srcs=(map ^stem @t)  (~(del by current-srcs) stem)
    (ingress-load-mesh name [%poly new-srcs])
  ::
  ++  ingress-drop-mesh
    ::
    ::  terminal removal.  capture prior-forms over outgoing form-view
    ::  stems, run ++drop, apply move, tear down views, drop entry.
    ::  on ++drop failure (raise or move-apply error): skip the move,
    ::  wipe data and meta at every view stem (form + lens), drop
    ::  entry.
    ::
    |=  name=term
    ^+  cor
    =.  cor  (vlog "ae: drop-mesh {<name>}")
    =/  found=(unit mesh)  (get-mesh ax name)
    ?~  found
      %-  (slog leaf+"ae: rejected drop-mesh: {<name>} not found" ~)
      cor
    =/  cod-before  cod
    =/  =prior-forms
      %+  capture-priors
        (outgoing-form-stems views.u.found)
      views.u.found
    =/  drop-out  (call-drop mesh-core.u.found our name prior-forms)
    =.  cor
      ?:  ?=(%| -.drop-out)
        ::
        ::  ++drop raised: wipe data + meta at every view stem
        ::
        =/  pairs=(list [stem view])  ~(tap by views.u.found)
        |-  ^+  cor
        ?~  pairs  cor
        =.  cor  (wipe-mesh-view -.i.pairs +.i.pairs)
        $(pairs t.pairs)
      ::
      ::  ++drop succeeded: apply move, then graceful tear-down
      ::
      =/  out=move  output.p.drop-out
      =?  cor  ?=(^ chng-set.out)
        (apply-move-qualified [(prefix-move [p+our ~] out) %.n])
      =/  pairs=(list [stem view])  ~(tap by views.u.found)
      |-  ^+  cor
      ?~  pairs  cor
      =.  cor  (uninstall-mesh-view -.i.pairs +.i.pairs)
      $(pairs t.pairs)
    =.  meshes.ax
      %+  skip  meshes.ax
      |=  [n=term *]
      =(n name)
    (emit-code-at-ancestors cod-before)
  ::
  ++  ingress-set-grow
    ::
    ::  set grow flag on meta at pax, creating meta if missing.
    ::  pax is user-facing (qualified with /[our]).
    ::
    |=  [pax=pith val=?]
    ^+  cor
    ?>  effects
    =/  full-pax  (under-our pax)
    =.  cor  (vlog "ae: set-grow at {(pate full-pax)} = {?:(val "y" "n")}")
    ?.  (meta-allowed full-pax)  (reject-shallow "set-grow" full-pax)
    =/  cod-before  cod
    =/  met=meta  (gut-meta full-pax)
    =.  cod  (~(put ox cod) full-pax met(grow val))
    (emit-code-at-ancestors cod-before)
  ::
  ++  ingress-set-eyre
    ::
    ::  set eyre auth on meta at pax, creating meta if missing.
    ::  pax is user-facing (qualified with /[our]).
    ::  if the new state is cache-safe, push current node to the
    ::  eyre cache; if we left a cache-safe state, evict.
    ::
    |=  [pax=pith val=(unit auth)]
    ^+  cor
    ?>  effects
    =/  full-pax  (under-our pax)
    =.  cor  (vlog "ae: set-eyre at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "set-eyre" full-pax)
    =/  cod-before  cod
    =/  met=meta  (gut-meta full-pax)
    =/  new-met=meta  met(eyre val)
    =.  cod  (~(put ox cod) full-pax new-met)
    =.  cor
      ?:  (eyre-cached new-met)
        (eyre-push full-pax new-met (~(get do dat) full-pax))
      ?:  (eyre-cached met)
        (eyre-evict full-pax)
      cor
    (emit-code-at-ancestors cod-before)
  ::
  ++  ingress-set-gall
    ::
    ::  set gall auth on meta at pax, creating meta if missing.
    ::  pax is user-facing (qualified with /[our]).
    ::  on flip-off, kick existing /sub/, /code/, and /both/ subscribers
    ::  (their subscription is no longer valid).  on flip-on, nothing
    ::  to push: subscribers will arrive via on-watch and get initial
    ::  state there.
    ::
    |=  [pax=pith val=(unit auth)]
    ^+  cor
    ?>  effects
    =/  full-pax  (under-our pax)
    =.  cor  (vlog "ae: set-gall at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "set-gall" full-pax)
    =/  cod-before  cod
    =/  met=meta  (gut-meta full-pax)
    =.  cod  (~(put ox cod) full-pax met(gall val))
    =.  cor  (emit-code-at-ancestors cod-before)
    ?.  &(?=(^ gall.met) ?=(~ val))  cor
    =/  bp=path  (bare-path full-pax)
    %-  emit
    [%give %kick ~[[%sub bp] [%code bp] [%both bp]] ~]
  ::
  ++  initialize-from-snap
    ::
    ::  run the transformer once with the faucet's current snap and
    ::  an empty move, signaling "reconstruct state from snap".
    ::  full-pax is qualified.
    ::
    |=  [full-pax=pith =view faucet-met=meta]
    ^+  cor
    ?>  ?=(%lens -.view)
    =/  met=meta  (gut-meta full-pax)
    ?.  ?=(^ lord.met)  cor
    =*  vw  view.u.lord.met
    ?>  ?=(%lens -.vw)
    ?:  ?=(^ err.vw)  cor
    =/  snap=data  (~(dip do dat) (ref-to-pith dep.view))
    %:  run-xfm
      full-pax  view  met  snap  ~
      life.faucet-met  case.faucet-met
    ==
  ::
  ++  ingress-hear-remote
    ::
    ::  apply an incoming fact about ship's faucet at pax.
    ::  life bump => replace subtree with snap and reset submetas;
    ::  otherwise apply the incremental move.  subscriber views
    ::  living under /[our]/... are fired via the normal propagate
    ::  path inside apply-move-qualified.
    ::
    |=  [=ship pax=pith snap=data =move =life =case]
    ^+  cor
    =/  full-pax  `pith`[p+ship pax]
    =.  cor  (vlog "ae: hear-remote from {<ship>} at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "hear-remote" full-pax)
    ::  merge the originator's hlc into our agent clock and re-stamp
    ::  the move with the merged hlc.  any local downstream fan-out
    ::  uses this merged time, so the receiver's logs record "when i
    ::  learned this", not the originator's clock alone.
    ::
    =^  time=hlc  cor  (ingress-merge time.move)
    =.  move  move(time time)
    =/  cod-before  cod
    =/  met=meta  (gut-meta full-pax)
    =?  cor  |((gth life life.met) =(~ chng-set.move))
      =.  dat  (~(rep do dat) full-pax snap)
      =.  cod
        %+  ~(put ox cod)  full-pax
        met(life life, case case, logs ~)
      =.  cor  (reset-submetas full-pax %.y)
      =/  new-met=meta  (gut-meta full-pax)
      =/  snp=data  (~(dip do dat) full-pax)
      =.  cor  (emit-node-effects full-pax new-met snp [*hlc ~])
      (reinstall-subs full-pax)
    =.  cor  (apply-move-qualified (prefix-move [p+ship ~] move) %.y)
    (emit-code-at-ancestors cod-before)
  ::
  ++  ingress-hear-remote-code
    ::
    ::  apply an incoming %oxal-code fact about ship's faucet at pax.
    ::  life bump or empty meta-move => overwrite our mirrored code
    ::  subtree at full-pax with snap; otherwise apply the incremental
    ::  meta-move by welding full-pax onto each relative pith.  local
    ::  /code/ and /both/ subscribers are notified by the trailing
    ::  emit-code-at-ancestors call.
    ::
    |=  [=ship pax=pith snap=code =meta-move =life =case]
    ^+  cor
    =/  full-pax  `pith`[p+ship pax]
    =.  cor  (vlog "ae: hear-remote-code from {<ship>} at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "hear-remote-code" full-pax)
    =/  cod-before  cod
    =/  met=meta  (gut-meta full-pax)
    ?:  |((gth life life.met) =(~ meta-move))
      =.  cod  (~(rep ox cod) full-pax snap)
      (emit-code-at-ancestors cod-before)
    =.  cod
      =/  chs=(list meta-chng)  ~(tap in meta-move)
      |-  ^+  cod
      ?~  chs  cod
      =.  cod
        ?-  -.i.chs
          %ins  (~(put ox cod) (weld full-pax pith.i.chs) meta.i.chs)
          %del  (~(del ox cod) (weld full-pax pith.i.chs))
        ==
      $(chs t.chs)
    (emit-code-at-ancestors cod-before)
  ::
  ++  ingress-bump
    ::
    ::  wipe data subtree, increment lifes, reset cases and logs.
    ::  only valid within a %form view; rejected otherwise.
    ::  pax is user-facing (qualified with /[our]).
    ::
    |=  pax=pith
    ^+  cor
    =/  full-pax  (under-our pax)
    =.  cor  (vlog "ae: bump at {(pate full-pax)}")
    ?.  (meta-allowed full-pax)  (reject-shallow "bump" full-pax)
    ::  the closest enclosing view (including self) must be a %form
    ::
    ~|  %bump-must-be-within-form-view
    =/  ancs=(list (pair pith _cod))
      %+  ~(anc ox cod)  full-pax
      |=(m=_cod ?&(?=(^ leaf.m) ?=(^ lord.u.leaf.m)))
    ?<  ?=(~ ancs)
    ?>  ?=(^ leaf.q.i.ancs)
    ?>  ?=(^ lord.u.leaf.q.i.ancs)
    ?>  ?=(%form -.view.u.lord.u.leaf.q.i.ancs)
    ::
    =/  cod-before  cod
    =.  dat  (~(lop do dat) full-pax)
    =.  cor  (reset-submetas full-pax %.n)
    (emit-code-at-ancestors cod-before)
  ::
  ++  build-rels
    ::
    ::  map each ancestor pith of each chng (every prefix of length
    ::  >= min-meta-depth) to the set of chngs relativized to that
    ::  ancestor.
    ::
    |=  chs=(set chng)
    ^-  (map pith (set chng))
    =/  cl=(list chng)  ~(tap in chs)
    =|  out=(map pith (set chng))
    |-  ^+  out
    ?~  cl  out
    =/  ch=chng  i.cl
    =/  p=pith  (pith-of-chng ch)
    =/  depths=(list @ud)  (ancestor-depths (lent p))
    =.  out
      |-  ^+  out
      ?~  depths  out
      =/  d=@ud  i.depths
      =/  anc=pith  (scag d p)
      =/  rel-chng=chng  (rebase-chng ch (slag d p))
      =/  have=(set chng)  (fall (~(get by out) anc) ~)
      =.  out  (~(put by out) anc (~(put in have) rel-chng))
      $(depths t.depths)
    $(cl t.cl)
  ::
  ++  sort-piths-desc
    ::
    ::  list of piths from a set, sorted by length descending.
    ::
    |=  ps=(set pith)
    ^-  (list pith)
    %+  sort  ~(tap in ps)
    |=  [a=pith b=pith]
    (gth (lent a) (lent b))
  ::
  ++  merge-rels
    ::
    ::  merge b into a, unioning chng sets at shared piths.
    ::
    |=  [a=(map pith (set chng)) b=(map pith (set chng))]
    ^-  (map pith (set chng))
    =/  kvs=(list (pair pith (set chng)))  ~(tap by b)
    |-  ^+  a
    ?~  kvs  a
    =/  have  (fall (~(get by a) p.i.kvs) ~)
    =.  a  (~(put by a) p.i.kvs (~(uni in have) q.i.kvs))
    $(kvs t.kvs)
  ::
  ++  merge-queue
    ::
    ::  add new piths to queue, skipping any that are already
    ::  processed or already in the queue; re-sort longest-first.
    ::
    |=  [q=(list pith) adds=(set pith) processed=(set pith)]
    ^-  (list pith)
    =/  have=(set pith)  (~(gas in *(set pith)) q)
    =/  new=(list pith)
      %+  skim  ~(tap in adds)
      |=  p=pith
      ?&  !(~(has in processed) p)
          !(~(has in have) p)
      ==
    %+  sort  (weld q new)
    |=  [a=pith b=pith]
    (gth (lent a) (lent b))
  ::
  ++  fire-subs-collect
    ::
    ::  fire every subscriber of met's subs, collecting their
    ::  transformer outputs into one unioned chng-set.  suspended
    ::  and absent views are skipped.  time is the cause's hlc and
    ::  is passed through to each transformer's input move; it does
    ::  not appear in the output -- the engine attaches it at the
    ::  boundary.
    ::
    |=  [met=meta snap=data mov=(set chng) lyf=@ud cas=@ud time=hlc]
    ^-  [(set chng) _cor]
    =/  sub-list=(list pith)  ~(tap in subs.met)
    =|  out=(set chng)
    |-  ^+  [out cor]
    ?~  sub-list  [out cor]
    =/  sub=pith  i.sub-list
    =/  sub-met=meta  (gut-meta sub)
    ?~  lord.sub-met  $(sub-list t.sub-list)
    =*  vw  view.u.lord.sub-met
    ?>  ?=(%lens -.vw)
    ?:  ?=(^ err.vw)  $(sub-list t.sub-list)
    =^  maybe-out=(unit (set chng))  cor
      (run-xfm-collect sub vw sub-met snap mov lyf cas time)
    =?  out  ?=(^ maybe-out)
      (~(uni in out) u.maybe-out)
    $(sub-list t.sub-list)
  ::
  ++  run-xfm-collect
    ::
    ::  run a subscriber's transformer.  on success, update the view
    ::  meta and return the prefixed output chngs.  on crash, suspend
    ::  the view and return ~.  the input move carries the cause's
    ::  time so transformers can read it; the output is just a set
    ::  of changes -- transformers don't get to invent timestamps
    ::  (otherwise replay diverges), so the engine attaches the
    ::  cause's time at the boundary.
    ::
    |=  [sub=pith =view met=meta snap=data mov=(set chng) lyf=@ud cas=@ud time=hlc]
    ^-  [(unit (set chng)) _cor]
    ?>  ?=(%lens -.view)
    ?>  ?=(^ lord.met)
    =.  cor  (vlog "ae: fire xfm at {(pate sub)}")
    =^  xfm-res=(each transformer tang)  cor  (get-xfm (resolve-code view))
    ?:  ?=(%| -.xfm-res)
      [~ (suspend-view sub view met p.xfm-res)]
    =/  xfm=transformer  p.xfm-res
    =/  mine=data  (~(dip do dat) sub)
    =/  in-move=move  [time mov]
    =/  result=(each (set chng) tang)
      (mule |.((xfm [mine snap in-move lyf cas])))
    ?-  -.result
      %&
        =.  cod
          %+  ~(put ox cod)  sub
          met(lord `[mesh=mesh.u.lord.met view=view(lyf lyf, cas cas)])
        [`(prefix-chngs sub p.result) cor]
      ::
      %|
        [~ (suspend-view sub view met p.result)]
    ==
  ::
  ++  apply-extra-changes
    ::
    ::  apply a transformer's output chngs; already prefixed with
    ::  the view's own pith, so no lens-write filtering.  commits
    ::  the new data to cor and returns the effective set.
    ::
    |=  chngs=(set chng)
    ^-  [(set chng) _cor]
    =/  [d=data effective=(set chng)]  (step-chngs dat chngs)
    =.  cor  cor(data.file.ax d)
    [effective cor]
  ::
  ++  initial-watch-response
    ::
    ::  current [snap life case] at a fully-qualified pax, for on-watch.
    ::
    |=  full-pax=pith
    ^-  [snap=data life=@ud case=@ud]
    =/  met=meta  (gut-meta full-pax)
    =/  snap=data  (~(dip do dat) full-pax)
    [snap life.met case.met]
  ::
  ::
  ::  effect emission
  ::
  ::  three independent channels, each gated on one meta property:
  ::    gall.met ≠ ~            => /sub/<pax> facts
  ::    grow.met                => /logs/ history facts
  ::    eyre.met ∈ {^%white ^%black}, no exceptions
  ::                            => %set-response (node-summary node)
  ::
  ::  all emission paths strip the leading ship iota of full-pax,
  ::  so subscribers and urls are ship-less.
  ::
  ++  bare-path
    ::
    ::  path rendering of full-pax minus its leading ship iota.
    ::
    |=  full-pax=pith
    ^-  path
    ?>  ?=(^ full-pax)
    (pout t.full-pax)
  ::
  ++  eyre-cached
    ::
    ::  cache-safe auth? only [%white ~] and [%black ~] (no exceptions).
    ::
    |=  met=meta
    ^-  ?
    ?~  eyre.met  %.n
    ?.  ?=(~ exceptions.u.eyre.met)  %.n
    ?=(?(%white %black) kind.u.eyre.met)
  ::
  ++  eyre-url
    ::
    ::  cache url, e.g. /-/foo/22/pith.
    ::
    |=  full-pax=pith
    ^-  @t
    (rap 3 ~['/-' (spat (bare-path full-pax))])
  ::
  ++  eyre-set
    ::
    ::  low-level: send %set-response to eyre.
    ::
    |=  [url=@t entry=(unit cache-entry:eyre)]
    ^+  cor
    %-  emit
    [%pass /set-response %arvo %e %set-response url entry]
  ::
  ++  gall-channel
    ::
    ::  /sub/ and /both/ subscription effects.  always emits %oxal-snap.
    ::  an empty move signals a full-replace; otherwise incremental.
    ::  no-op if gall.met is ~.
    ::
    |=  [full-pax=pith met=meta snap=data =move]
    ^+  cor
    ?~  gall.met  cor
    =/  bp=path  (bare-path full-pax)
    =/  paths=(list path)  ~[[%sub bp] [%both bp]]
    %-  emit
    [%give %fact paths %oxal-snap !>([snap move life.met case.met])]
  ::
  ++  code-channel
    ::
    ::  /code/ and /both/ subscription effects.  emits %oxal-code.
    ::  an empty meta-move signals a full-replace; otherwise incremental.
    ::  no-op if gall.met is ~.
    ::
    |=  [full-pax=pith met=meta snap=code =meta-move]
    ^+  cor
    ?~  gall.met  cor
    =/  bp=path  (bare-path full-pax)
    =/  paths=(list path)  ~[[%code bp] [%both bp]]
    %-  emit
    [%give %fact paths %oxal-code !>([snap meta-move life.met case.met])]
  ::
  ++  grow-channel
    ::
    ::  /logs/ history effects.  no-op if grow.met is false.
    ::
    |=  [full-pax=pith met=meta snap=data =move]
    ^+  cor
    ?.  grow.met  cor
    =/  bp=path  (bare-path full-pax)
    =/  logs-path=path  [(scot %ud nuke.ax) %logs (scot %ud life.met) (scot %ud case.met) bp]
    %-  emit
    [%give %fact ~[logs-path] %oxal-snap !>([snap move life.met case.met])]
  ::
  ++  eyre-push
    ::
    ::  cache (node-summary node) as plain-text response at full-pax's url.
    ::  no-op if eyre.met is not cache-safe; evict if no leaf at full-pax.
    ::  auth in the entry is true iff %white (only self); %black is public.
    ::
    |=  [full-pax=pith met=meta nod=(unit node)]
    ^+  cor
    ?~  eyre.met  cor
    ?.  ?=(~ exceptions.u.eyre.met)  cor
    ?.  ?=(?(%white %black) kind.u.eyre.met)  cor
    =/  url=@t  (eyre-url full-pax)
    ?~  nod  (eyre-set url ~)
    =/  body=@t  (crip (node-summary u.nod))
    =/  entry=cache-entry:eyre
      :*  auth=?=(%white kind.u.eyre.met)
          :-  %payload
          (node-to-simple-payload u.nod)
      ==
    (eyre-set url `entry)
  ::
  ++  eyre-evict
    ::
    ::  unconditionally evict full-pax's cached response.
    ::
    |=  full-pax=pith
    ^+  cor
    (eyre-set (eyre-url full-pax) ~)
  ::
  ++  emit-node-effects
    ::
    ::  fan a bump out to the three channels.
    ::  an empty move signals a full-replace on the gall channel.
    ::
    |=  [full-pax=pith met=meta snap=data =move]
    ^+  cor
    ?.  effects  cor
    =.  cor  (gall-channel full-pax met snap move)
    =.  cor  (grow-channel full-pax met snap move)
    (eyre-push full-pax met (~(get do dat) full-pax))
  ::
  ++  initial-watch-response-code
    ::
    ::  current [snap life case] of code subtree at full-pax, for
    ::  on-watch of /code/ and /both/.
    ::
    |=  full-pax=pith
    ^-  [snap=code life=@ud case=@ud]
    =/  met=meta  (gut-meta full-pax)
    =/  snap=code  (~(dip ox cod) full-pax)
    [snap life.met case.met]
  ::
  ++  emit-code-at-ancestors
    ::
    ::  diff cod-before against current cod, filter by
    ::  meta-significant-change, and fan each surviving change out to
    ::  every gall-authorized ancestor (of length >= min-meta-depth),
    ::  relativizing the change pith to each ancestor.
    ::
    |=  cod-before=code
    ^+  cor
    ?.  effects  cor
    =/  before-list=(list [pith meta])  ~(tap ox cod-before)
    =/  after-list=(list [pith meta])   ~(tap ox cod)
    =/  before-map=(map pith meta)  (malt before-list)
    =/  after-map=(map pith meta)   (malt after-list)
    =/  all-piths=(set pith)
      %-  ~(uni in (silt (turn before-list head)))
      (silt (turn after-list head))
    =/  chngs=(list [pith meta-chng])
      %+  murn  ~(tap in all-piths)
      |=  p=pith
      ^-  (unit [pith meta-chng])
      =/  old=(unit meta)  (~(get by before-map) p)
      =/  new=(unit meta)  (~(get by after-map) p)
      ?.  (meta-significant-change old new)  ~
      ?~  new  `[p [%del p]]
      `[p [%ins p u.new]]
    ?~  chngs  cor
    =|  rels=(map pith meta-move)
    =.  rels
      =/  cs=(list [pith meta-chng])  chngs
      |-  ^+  rels
      ?~  cs  rels
      =/  pax=pith       -.i.cs
      =/  mc=meta-chng   +.i.cs
      =/  depths=(list @ud)  (ancestor-depths (lent pax))
      =.  rels
        |-  ^+  rels
        ?~  depths  rels
        =/  d=@ud       i.depths
        =/  anc=pith    (scag d pax)
        =/  anc-met=meta  (gut-meta anc)
        ?~  gall.anc-met
          $(depths t.depths)
        =/  rel=meta-chng  (rebase-meta-chng mc (slag d pax))
        =/  have=meta-move  (fall (~(get by rels) anc) ~)
        =.  rels  (~(put by rels) anc (~(put in have) rel))
        $(depths t.depths)
      $(cs t.cs)
    =/  rel-list=(list [pith meta-move])  ~(tap by rels)
    |-  ^+  cor
    ?~  rel-list  cor
    =/  anc=pith       -.i.rel-list
    =/  mm=meta-move   +.i.rel-list
    =/  anc-met=meta   (gut-meta anc)
    =/  anc-snap=code  (~(dip ox cod) anc)
    =.  cor  (code-channel anc anc-met anc-snap mm)
    $(rel-list t.rel-list)
  --
--
