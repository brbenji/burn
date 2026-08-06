::  /gen/doctest-run: run all doctests and print a summary to the dojo
::
::    `+oxal!doctest-run` builds every script in /lib/doctests, runs each
::    through the pure runner, and returns a $tang summarising
::    pass/fail counts plus the failing-section traces.  unlike
::    +doctest-build-manual, this generator does not poke oxal — it is
::    a read-only check meant for the dev loop.
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
=/  reports=(list [name=@ta =report])
  %+  turn  entries
  |=  [name=@ta =script]
  [name (run-script:dt script our now)]
:-  %tang
^-  tang
(reports-to-tang:dt reports)
