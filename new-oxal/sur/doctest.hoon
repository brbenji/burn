::  /sur/doctest: types for the doctest runner
::
::    a doctest is a hoon source file in /lib/doctests that produces
::    a $script.  the runner walks each section and returns a $report
::    — a plain hoon value, no oxal data tree involved.  callers that
::    want to put results into oxal use +report-to-changes (in lib).
::
/+  *zozo
|%
::
::::  inputs
::
::  $script: a doctest source file produces a script.
::
+$  script
  $:  title=cord
      steps=(list section)
  ==
::
::  $section: one entry in a script's step list.
::
+$  section
  $%  [%prose =manx]
      [%unit =unit-test]
      [%full =full-test]
  ==
::
::  $unit-test: code slaps to a vase; result is cast to tang.
::    empty tang = pass.
::
+$  unit-test
  $:  description=manx
      code=@t
  ==
::
::  $full-test: drive the agent through ingress-ops on a fresh acer,
::    then run an acer-test gate against the resulting state.
::
+$  full-test
  $:  description=manx
      show-file=?
      ops=(list ingress-op)
      code=@t
  ==
::
::  $ingress-op: one of the oxal agent's existing pokes.  the runner
::    dispatches each op into the matching +ingress-* arm of +ae.
::    effects are discarded; tests inspect the resulting acer only.
::
+$  ingress-op
  $%  [%do-move changes=(set chng)]
      [%load-mesh name=term source=@t]
      [%drop-mesh name=term]
      [%bump pax=pith]
      [%set-grow pax=pith val=?]
      [%set-eyre pax=pith val=(unit auth)]
      [%set-gall pax=pith val=(unit auth)]
      [%hear-remote =ship pax=pith snap=data =move =life =case]
      [%hear-remote-code =ship pax=pith snap=code =meta-move =life =case]
  ==
::
::  $acer-test: a check gate over the acer that results from running
::    a full-test's ops.  empty tang = pass; non-empty tang is the
::    failure trace.
::
+$  acer-test  $-(acer tang)
::
::::  outputs
::
::  $report: result of running one $script.
::
::    a plain hoon value: title, aggregate pass flag, and one
::    $section-result per step in input order.
::
+$  report
  $:  title=cord
      pass=?
      sections=(list section-result)
  ==
::
::  $section-result: outcome of one section run.
::
::    %prose mirrors the input.  %unit and %full add a pass flag and
::    the resulting tang (empty = success, non-empty = failure trace).
::
+$  section-result
  $%  [%prose =manx]
      [%unit =unit-result]
      [%full =full-result]
  ==
::
+$  unit-result
  $:  description=manx
      code=@t
      pass=?
      =tang
  ==
::
+$  full-result
  $:  description=manx
      show-file=?
      ops=(list ingress-op)
      code=@t
      pass=?
      =tang
      file-snapshot=(unit data)
  ==
--
