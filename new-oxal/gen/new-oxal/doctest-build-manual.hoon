::  /gen/doctest-build-manual: run all doctests and install the
::                              %doctest mesh holding their results
::
::    `:oxal!doctest-build-manual` builds every script in
::    /lib/doctests, runs each through the pure runner, converts the
::    resulting $report to a $data via +report-to-data, and +rep's
::    each script's data into a single mesh-data tree at the script's
::    stem (so /sample/title, /sample/pass, etc.).  it then pokes
::    oxal with %doctest-build, which (in one cause) drops the prior
::    %doctest mesh, loads a fresh one declaring a form at
::    /doctest/results, and do-moves the mesh-data into the form.
::
::    dropping the %doctest mesh wipes all data so a re-run with
::    renamed scripts leaves no orphan leaves behind.
::
::    for a quick pass/fail summary in the dojo without touching the
::    oxal tree, use +doctest-run instead.
::
/-  *doctest
/+  *zozo, dt=doctest
/~  scripts  script  /lib/doctests
::
:-  %say
|=  $:  [now=@da eny=@uvJ bec=beak]
        ~
        ~
    ==
=*  our  p.bec
=/  entries=(list [@ta script])  ~(tap by scripts)
=/  mesh-data=data
  =|  d=data
  |-
  ?~  entries  d
  =/  [name=@ta =script]  i.entries
  =/  =stem    (parse-stem-name:dt name)
  =/  =report  (run-script:dt script our now)
  =/  rd=data  (report-to-data:dt report)
  $(entries t.entries, d (~(rep do d) stem rd))
:-  %doctest-build
mesh-data
