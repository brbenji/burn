::  /lib/doctest: pure runner and oxal-data conversion for doctests
::
::    +run-script           : evaluate one $script, return a $report
::    +parse-stem-name      : decode a filename like a-b---c to a pith
::    +report-to-changes    : project a $report under a base pith into
::                            a (set chng) ready for %do-move
::    +report-to-data       : project a $report into a single $data
::                            tree (layout matches +report-to-changes)
::    +reports-to-tang      : format a list of named reports as a tang
::                            for printing in the dojo
::    +data-to-doctest-chngs : convert a doctest-mesh data subtree
::                            into a (set chng) with /doctest prefix
::    +doctest-mesh-source  : fixed %mono mesh-core text for the
::                            %doctest mesh.  declares one form at
::                            /doctest; ++drop wipes its data subtree
::                            so dropping the mesh leaves no orphans
::
::    the runner has no dependence on the oxal agent or its data
::    tree.  the agent's %doctest-build poke chains drop-mesh,
::    load-mesh (with +doctest-mesh-source), and do-move (with
::    +data-to-doctest-chngs of the supplied data).
::
/-  *doctest
/+  *zozo
|%
::
++  parse-stem-name
  ::
  ::  decode a script filename to a pith.  triple-hyphens separate
  ::  path segments: a-b---c-d  ->  /a-b/c-d.  each segment becomes a
  ::  single @tas, so single hyphens stay inside one segment.
  ::
  |=  txt=@ta
  ^-  pith
  %+  rash  txt
  %+  more  (jest '---')
  %+  cook
    |=  =tape
    ^-  iota
    =/  c=@tas  (crip tape)
    ?>  ((sane %tas) c)
    c
  (star ;~(less (jest '---') next))
::
++  run-script
  ::
  ::  run every section in input order, threading an isolated +ae
  ::  acer through %full sections.  the aggregate pass flag is && of
  ::  every section's pass.
  ::
  |=  [=script our=@p now=@da]
  ^-  report
  =|  acc=(list section-result)
  =/  pass=?  &
  =|  ax=acer
  =/  steps=(list section)  steps.script
  |-
  ?~  steps
    [title.script pass (flop acc)]
  =^  out=section-result  ax  (run-section i.steps ax our now)
  =/  sect-pass=?
    ?-  -.out
      %prose  &
      %unit   pass.unit-result.out
      %full   pass.full-result.out
    ==
  $(steps t.steps, pass &(pass sect-pass), acc [out acc])
::
++  run-section
  ::
  |=  [=section ax=acer our=@p now=@da]
  ^-  [section-result _ax]
  ?-  -.section
    %prose  [section ax]
    %unit   [unit+(run-unit unit-test.section) ax]
    %full   (run-full full-test.section ax our now)
  ==
::
++  run-unit
  ::
  ::  compile and evaluate a unit-test's code.  result tang is
  ::  always present (possibly empty); pass = empty tang.
  ::
  |=  ut=unit-test
  ^-  unit-result
  =/  res=(each vase tang)
    %-  mule  |.
    (slap !>(.) (ream code.ut))
  =/  =tang
    ?:  ?=(%.n -.res)  p.res
    =/  rus=(each tang tang)
      %-  mule  |.
      !<  tang  p.res
    ?:  ?=(%.n -.rus)  p.rus
    p.rus
  =/  pass=?  =(~ tang)
  [description.ut code.ut pass tang]
::
++  run-full
  ::
  ::  thread ops through a fresh +ae engine, then evaluate the
  ::  acer-test gate against the resulting acer.  any crash inside
  ::  ops or the gate becomes a fail with the crash trace as tang.
  ::  on crash, the outer acer is preserved (ops were aborted).
  ::
  |=  [ft=full-test ax=acer our=@p now=@da]
  ^-  [section-result _ax]
  =/  result=(each [acer tang] tang)
    %-  mule  |.
    =/  ax-after  (run-ops ops.ft ax our now)
    =/  vas=vase  (slap !>(.) (ream code.ft))
    =/  gut=(each acer-test tang)
      %-  mule  |.
      !<  acer-test  vas
    ?:  ?=(%.n -.gut)  [ax-after p.gut]
    [ax-after (p.gut ax-after)]
  ?:  ?=(%.n -.result)
    :_  ax
    :-  %full
    :*  description.ft  show-file.ft  ops.ft  code.ft  |
        p.result  ~
    ==
  =/  [ax-after=acer =tang]  p.result
  =/  pass=?  =(~ tang)
  =/  snap=(unit data)  ?:(show-file.ft `data.file.ax-after ~)
  :_  ax-after
  :-  %full
  :*  description.ft  show-file.ft  ops.ft  code.ft  pass
      tang  snap
  ==
::
++  run-ops
  ::
  ::  thread a sequence of ingress ops through a fresh +ae engine.
  ::  effects are discarded — tests inspect acer only.  any crash
  ::  inside an op propagates up to the +mule wrapper in run-full,
  ::  where it is captured as the section's tang.
  ::
  |=  [ops=(list ingress-op) ax=acer our=@p now=@da]
  ^-  acer
  ?~  ops  ax
  =/  engine  ~(. ae ax our now | |)
  =/  new-ax=acer
    ?-  -.i.ops
      %do-move
        +:abet:(ingress-do-move:engine `move`[*hlc changes.i.ops])
      ::
      %load-mesh
        +:abet:(ingress-load-mesh:engine name.i.ops [%mono source.i.ops])
      ::
      %drop-mesh
        +:abet:(ingress-drop-mesh:engine name.i.ops)
      ::
      %bump
        +:abet:(ingress-bump:engine pax.i.ops)
      ::
      %set-grow
        +:abet:(ingress-set-grow:engine pax.i.ops val.i.ops)
      ::
      %set-eyre
        +:abet:(ingress-set-eyre:engine pax.i.ops val.i.ops)
      ::
      %set-gall
        +:abet:(ingress-set-gall:engine pax.i.ops val.i.ops)
      ::
      %hear-remote
        =/  args=[ship=ship pax=pith snap=data move=move life=life case=case]
          [ship.i.ops pax.i.ops snap.i.ops move.i.ops life.i.ops case.i.ops]
        +:abet:(ingress-hear-remote:engine args)
      ::
      %hear-remote-code
        =/  args=[ship=ship pax=pith snap=code move=meta-move life=life case=case]
          [ship.i.ops pax.i.ops snap.i.ops meta-move.i.ops life.i.ops case.i.ops]
        +:abet:(ingress-hear-remote-code:engine args)
    ==
  $(ops t.ops, ax new-ax)
::
++  report-to-changes
  ::
  ::  project a report into a (set chng), with all piths under base.
  ::
  ::    base/title              [%t cord]
  ::    base/pass               [%f ?]
  ::    base/sections/[ud+i]/<fields>...
  ::
  ::  callers prefix to taste; the doctest vine uses base=/docs/<stem>.
  ::
  |=  [base=pith =report]
  ^-  (set chng)
  =|  acc=(set chng)
  =.  acc  (~(put in acc) [%ins (welp base /title) [%t title.report]])
  =.  acc  (~(put in acc) [%ins (welp base /pass) [%f pass.report]])
  =|  i=@ud
  =/  sects=(list section-result)  sections.report
  |-
  ?~  sects  acc
  =/  section-base=pith  (welp base ~[%sections [%ud i]])
  =.  acc  (~(uni in acc) (section-result-to-changes section-base i.sects))
  $(sects t.sects, i +(i), acc acc)
::
++  section-result-to-changes
  ::
  |=  [base=pith =section-result]
  ^-  (set chng)
  ?-  -.section-result
    %prose
      %-  silt
      ^-  (list chng)
      :~  [%ins (welp base /kind) %prose]
          [%ins (welp base /manx) [%manx +.section-result]]
      ==
    ::
    %unit
      =*  ur  unit-result.section-result
      %-  silt
      ^-  (list chng)
      :~  [%ins (welp base /kind) %unit]
          [%ins (welp base /description) [%manx description.ur]]
          [%ins (welp base /code) [%t code.ur]]
          [%ins (welp base /result) ?:(pass.ur %pass %fail)]
          [%ins (welp base /tang) [%tang tang.ur]]
      ==
    ::
    %full
      =*  fr  full-result.section-result
      =/  base-changes=(list chng)
        :~  [%ins (welp base /kind) %full]
            [%ins (welp base /description) [%manx description.fr]]
            [%ins (welp base /show-file) [%f show-file.fr]]
            [%ins (welp base /code) [%t code.fr]]
            [%ins (welp base /ops) [%noun ops.fr]]
            [%ins (welp base /result) ?:(pass.fr %pass %fail)]
            [%ins (welp base /tang) [%tang tang.fr]]
        ==
      =?  base-changes  ?=(^ file-snapshot.fr)
        %+  weld  base-changes
        ^-  (list chng)
        :~  [%ins (welp base /file-snapshot) [%data u.file-snapshot.fr]]
        ==
      (silt base-changes)
  ==
::
++  report-to-data
  ::
  ::  project a report into a single $data tree, sharing layout with
  ::  +report-to-changes.  the output is a value (not a chng set);
  ::  callers +rep this into a larger tree (e.g. the doctest mesh's
  ::  form) and poke %do-move or %load-mesh.
  ::
  |=  =report
  ^-  data
  =|  d=data
  =/  cl=(list chng)  ~(tap in (report-to-changes ~ report))
  |-
  ?~  cl  d
  ?>  ?=(%ins -.i.cl)
  $(cl t.cl, d (~(put do d) pith.i.cl node.i.cl))
::
++  data-to-doctest-chngs
  ::
  ::  convert a doctest-mesh data subtree (relative to /doctest/results)
  ::  into a (set chng) with the /doctest/results prefix welded on.
  ::  used by the agent's %doctest-build poke to populate the mesh's
  ::  form via ingress-do-move.
  ::
  |=  d=data
  ^-  (set chng)
  %-  silt
  %+  turn  ~(tap do d)
  |=  [p=pith n=node]
  ^-  chng
  [%ins (welp /doctest/results p) n]
::
++  doctest-mesh-source
  ::
  ::  fixed %mono mesh-core text for the %doctest mesh.  declares
  ::  one form-stem at /doctest/results; ++load is a no-op on data
  ::  (the agent's %doctest-build sequence drops the mesh first to
  ::  wipe prior data, then loads, then pokes do-move).  ++drop walks
  ::  the prior data subtree at /doctest/results and emits %del for
  ::  every leaf, so dropping the mesh leaves no orphans behind.
  ::
  ^-  @t
  '''
  |_  [our=@p name=@tas]
  ::
  ++  forms  (silt ~[/doctest/results])
  ::
  ++  load
    |=  =prior-forms
    =/  vs=(map stem view-spec)  (malt ~[[/doctest/results [%form ~]]])
    [vs *move]
  ::
  ++  drop
    |=  =prior-forms
    =/  prior=data  data:(~(got by prior-forms) /doctest/results)
    =/  del-chngs=(set chng)
      %-  silt
      %+  turn  ~(tap do prior)
      |=  [p=pith *]
      ^-  chng
      [%del (welp /doctest/results p)]
    ^-  move
    [*hlc del-chngs]
  --
  '''
::
++  reports-to-tang
  ::
  ::  format a list of [name report] pairs as a tang.  one header
  ::  line summarises pass count; each script gets a status line, and
  ::  failed scripts list each failing section's index, kind, and
  ::  trace.
  ::
  ::  the dojo prints tangs in reverse list order (last element on
  ::  top), so the list is built in the natural top-down display
  ::  order and flopped at the end.  scripts are sorted by name for
  ::  stable output.
  ::
  |=  reports=(list [name=@ta =report])
  ^-  tang
  =/  sorted=(list [name=@ta =report])
    %+  sort  reports
    |=  [a=[name=@ta *] b=[name=@ta *]]
    (aor name.a name.b)
  =/  total=@ud  (lent sorted)
  =/  passed=@ud
    %-  lent
    %+  skim  sorted
    |=  [@ta r=report]
    pass.r
  =/  header=tank
    leaf+"doctest: {(scow %ud passed)}/{(scow %ud total)} scripts pass"
  =|  body=tang
  =.  body
    |-  ^-  tang
    ?~  sorted  body
    =/  out=tang  (script-result-to-tang i.sorted)
    $(sorted t.sorted, body (weld body out))
  (flop [header body])
::
++  script-result-to-tang
  ::
  ::  one script's status line plus, on failure, the failing-section
  ::  trace from each unit/full section.
  ::
  |=  [name=@ta =report]
  ^-  tang
  =/  status=tape  ?:(pass.report "PASS" "FAIL")
  =/  hdr=tank
    leaf+"  {status}  {(trip name)} - {(trip title.report)}"
  ?:  pass.report  ~[hdr]
  =|  body=tang
  =|  i=@ud
  =/  sects=(list section-result)  sections.report
  |-
  ?~  sects  [hdr body]
  =/  out=tang  (failed-section-to-tang i i.sects)
  $(sects t.sects, i +(i), body (weld body out))
::
++  failed-section-to-tang
  ::
  ::  index/kind header plus the section's trace, only for failing
  ::  unit and full sections; everything else returns ~.
  ::
  |=  [i=@ud =section-result]
  ^-  tang
  ?-  -.section-result
    %prose  ~
    ::
    %unit
      =*  ur  unit-result.section-result
      ?:  pass.ur  ~
      :-  leaf+"    section {(scow %ud i)} [unit]"
      tang.ur
    ::
    %full
      =*  fr  full-result.section-result
      ?:  pass.fr  ~
      :-  leaf+"    section {(scow %ud i)} [full]"
      tang.fr
  ==
--
