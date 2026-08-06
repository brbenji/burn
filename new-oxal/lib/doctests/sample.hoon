::  /lib/doctests/sample: smoke test for the doctest runner
::
::  exercises the runner with a prose section, a unit test, and a
::  full test that asserts a fresh acer is empty.
::
/-  *doctest
^-  script
=/  prose-section=section
  :-  %prose
  ;p: this is the sample doctest suite.
::
=/  passing-unit=section
  :-  %unit
  :-  ;p: addition is commutative
  '''
  ^-  tang
  =/  a=@ud  2
  =/  b=@ud  3
  ?:  =((add a b) (add b a))  ~
  ['expected commutativity' ~]
  '''
::
=/  passing-full=section
  :-  %full
  :*  ;p: a fresh acer has an empty data tree
      |       :: don't store file snapshot
      ~       :: no ingress ops
      '''
      |=  =acer
      ^-  tang
      ?:  =(*data data.file.acer)  ~
      ['expected empty data' ~]
      '''
  ==
::
:-  'sample doctest'
:~  prose-section
    passing-unit
    passing-full
==
