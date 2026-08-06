::  /lib/doctests/serial: round-trip tests for node and pith serializers
::
::    exercises the round-tripable printers +nate/+pate (url-safe) and
::    +nare/+pare (hoon source, via +ream) against their parser inverses
::    +sily / +stib / +ream, plus the lossy +node-summary.
::
/-  *doctest
^-  script
::
=/  intro=section
  :-  %prose
  ;p: round-trip tests for node and pith serializers — +nate/+sily, +pate/+stib (url-safe); +nare/+pare via +ream; +node-summary (lossy).
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  node round trips (url-safe)
::  ::  ::  ::  ::  ::  ::  ::  ::
::
=/  hdr-node-tape=section
  :-  %prose
  ;p: node round trips via +nate then +sily.
::
=/  s-node-tas=section
  :-  %unit
  :-  ;p: %tas node
  '''
  ^-  tang
  =/  n=node  %foo
  ?:  =(n (sily (nate n)))  ~
  ['nate/sily failed: %tas' ~]
  '''
::
=/  s-node-empty-tas=section
  :-  %unit
  :-  ;p: empty %tas node
  '''
  ^-  tang
  =/  n=node  %$
  ?:  =(n (sily (nate n)))  ~
  ['nate/sily failed: %$' ~]
  '''
::
=/  s-node-ud=section
  :-  %unit
  :-  ;p: %ud node
  '''
  ^-  tang
  =/  n=node  ud+42
  ?:  =(n (sily (nate n)))  ~
  ['nate/sily failed: ud+42' ~]
  '''
::
=/  s-node-ud-zero=section
  :-  %unit
  :-  ;p: %ud zero node
  '''
  ^-  tang
  =/  n=node  ud+0
  ?:  =(n (sily (nate n)))  ~
  ['nate/sily failed: ud+0' ~]
  '''
::
=/  s-node-ux=section
  :-  %unit
  :-  ;p: %ux node
  '''
  ^-  tang
  =/  n=node  ux+0xdead.beef
  ?:  =(n (sily (nate n)))  ~
  ['nate/sily failed: ux+0xdead.beef' ~]
  '''
::
=/  s-node-p=section
  :-  %unit
  :-  ;p: %p node (galaxy)
  '''
  ^-  tang
  =/  n=node  p+~zod
  ?:  =(n (sily (nate n)))  ~
  ['nate/sily failed: p+~zod' ~]
  '''
::
=/  s-node-p-comet=section
  :-  %unit
  :-  ;p: %p node (star)
  '''
  ^-  tang
  =/  n=node  p+~nec
  ?:  =(n (sily (nate n)))  ~
  ['nate/sily failed: p+~nec' ~]
  '''
::
=/  s-node-da=section
  :-  %unit
  :-  ;p: %da node
  '''
  ^-  tang
  =/  n=node  da+~2026.4.30
  ?:  =(n (sily (nate n)))  ~
  ['nate/sily failed: da+~2026.4.30' ~]
  '''
::
=/  s-node-f-yes=section
  :-  %unit
  :-  ;p: %f yes node
  '''
  ^-  tang
  =/  n=node  [%f &]
  ?:  =(n (sily (nate n)))  ~
  ['nate/sily failed: [%f &]' ~]
  '''
::
=/  s-node-f-no=section
  :-  %unit
  :-  ;p: %f no node
  '''
  ^-  tang
  =/  n=node  [%f |]
  ?:  =(n (sily (nate n)))  ~
  ['nate/sily failed: [%f |]' ~]
  '''
::
=/  s-node-n=section
  :-  %unit
  :-  ;p: %n node
  '''
  ^-  tang
  =/  n=node  [%n ~]
  ?:  =(n (sily (nate n)))  ~
  ['nate/sily failed: [%n ~]' ~]
  '''
::
=/  s-node-ta=section
  :-  %unit
  :-  ;p: %ta node
  '''
  ^-  tang
  =/  n=node  ta+~.hello
  ?:  =(n (sily (nate n)))  ~
  ['nate/sily failed: ta+~.hello' ~]
  '''
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  pith round trips (url-safe)
::  ::  ::  ::  ::  ::  ::  ::  ::
::
=/  hdr-pith-tape=section
  :-  %prose
  ;p: pith round trips via +pate then +stib.
::
=/  s-pith-empty=section
  :-  %unit
  :-  ;p: empty pith
  '''
  ^-  tang
  =/  p=pith  ~
  ?:  =(p (stib (pate p)))  ~
  ['pate/stib failed: ~' ~]
  '''
::
=/  s-pith-single-tas=section
  :-  %unit
  :-  ;p: single-segment pith
  '''
  ^-  tang
  =/  p=pith  /foo
  ?:  =(p (stib (pate p)))  ~
  ['pate/stib failed: /foo' ~]
  '''
::
=/  s-pith-multi-tas=section
  :-  %unit
  :-  ;p: multi-segment pith
  '''
  ^-  tang
  =/  p=pith  /foo/bar/baz
  ?:  =(p (stib (pate p)))  ~
  ['pate/stib failed: /foo/bar/baz' ~]
  '''
::
=/  s-pith-mixed=section
  :-  %unit
  :-  ;p: mixed-aura pith
  '''
  ^-  tang
  =/  p=pith  ~[%foo ud+1 %bar p+~zod]
  ?:  =(p (stib (pate p)))  ~
  ['pate/stib failed: ~[%foo ud+1 %bar p+~zod]' ~]
  '''
::
=/  s-pith-nested=section
  :-  %unit
  :-  ;p: nested pith
  '''
  ^-  tang
  =/  p=pith  ~[%meshes [%pith /foo/users] %view]
  ?:  =(p (stib (pate p)))  ~
  ['pate/stib failed: nested pith' ~]
  '''
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  fixed-string deserialization
::  ::  ::  ::  ::  ::  ::  ::  ::
::
=/  hdr-deser=section
  :-  %prose
  ;p: +sily and +stib decode known literals.
::
=/  s-sily-tas=section
  :-  %unit
  :-  ;p: +sily decodes "%foo"
  '''
  ^-  tang
  ?:  =(`node`%foo (sily "%foo"))  ~
  ['sily "%foo" mismatch' ~]
  '''
::
=/  s-sily-ud=section
  :-  %unit
  :-  ;p: +sily decodes "42"
  '''
  ^-  tang
  ?:  =(`node`ud+42 (sily "42"))  ~
  ['sily "42" mismatch' ~]
  '''
::
=/  s-sily-p=section
  :-  %unit
  :-  ;p: +sily decodes "~zod"
  '''
  ^-  tang
  ?:  =(`node`p+~zod (sily "~zod"))  ~
  ['sily "~zod" mismatch' ~]
  '''
::
=/  s-stib-empty=section
  :-  %unit
  :-  ;p: +stib decodes "/"
  '''
  ^-  tang
  ?:  =(`pith`~ (stib "/"))  ~
  ['stib "/" mismatch' ~]
  '''
::
=/  s-stib-simple=section
  :-  %unit
  :-  ;p: +stib decodes "/foo/bar"
  '''
  ^-  tang
  ?:  =(`pith`/foo/bar (stib "/foo/bar"))  ~
  ['stib "/foo/bar" mismatch' ~]
  '''
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  fixed-string serialization
::  ::  ::  ::  ::  ::  ::  ::  ::
::
=/  hdr-ser=section
  :-  %prose
  ;p: +nate and +pate emit known literals.
::
=/  s-nate-tas=section
  :-  %unit
  :-  ;p: +nate emits "%foo"
  '''
  ^-  tang
  ?:  =("%foo" (nate %foo))  ~
  ['nate %foo mismatch' ~]
  '''
::
=/  s-nate-ud=section
  :-  %unit
  :-  ;p: +nate emits "42"
  '''
  ^-  tang
  ?:  =("42" (nate ud+42))  ~
  ['nate ud+42 mismatch' ~]
  '''
::
=/  s-pate-empty=section
  :-  %unit
  :-  ;p: +pate emits "/"
  '''
  ^-  tang
  ?:  =("/" (pate ~))  ~
  ['pate ~ mismatch' ~]
  '''
::
=/  s-pate-simple=section
  :-  %unit
  :-  ;p: +pate emits "/foo/bar"
  '''
  ^-  tang
  ?:  =("/foo/bar" (pate /foo/bar))  ~
  ['pate /foo/bar mismatch' ~]
  '''
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  nare round trips (via ream)
::  ::  ::  ::  ::  ::  ::  ::  ::
::
=/  hdr-nare-round=section
  :-  %prose
  ;p: node round trips via +nare then +ream — produces hoon source.
::
=/  s-nare-tas=section
  :-  %unit
  :-  ;p: %tas node
  '''
  ^-  tang
  =/  n=node  %foo
  =/  back=node  !<(node (slap !>(.) (ream (crip (nare n)))))
  ?:  =(n back)  ~
  ['nare/ream failed: %foo' ~]
  '''
::
=/  s-nare-empty-tas=section
  :-  %unit
  :-  ;p: empty %tas node
  '''
  ^-  tang
  =/  n=node  %$
  =/  back=node  !<(node (slap !>(.) (ream (crip (nare n)))))
  ?:  =(n back)  ~
  ['nare/ream failed: %$' ~]
  '''
::
=/  s-nare-ud=section
  :-  %unit
  :-  ;p: %ud node
  '''
  ^-  tang
  =/  n=node  ud+42
  =/  back=node  !<(node (slap !>(.) (ream (crip (nare n)))))
  ?:  =(n back)  ~
  ['nare/ream failed: ud+42' ~]
  '''
::
=/  s-nare-p=section
  :-  %unit
  :-  ;p: %p node
  '''
  ^-  tang
  =/  n=node  p+~zod
  =/  back=node  !<(node (slap !>(.) (ream (crip (nare n)))))
  ?:  =(n back)  ~
  ['nare/ream failed: p+~zod' ~]
  '''
::
=/  s-nare-da=section
  :-  %unit
  :-  ;p: %da node
  '''
  ^-  tang
  =/  n=node  da+~2026.4.30
  =/  back=node  !<(node (slap !>(.) (ream (crip (nare n)))))
  ?:  =(n back)  ~
  ['nare/ream failed: da+~2026.4.30' ~]
  '''
::
=/  s-nare-t=section
  :-  %unit
  :-  ;p: %t node
  '''
  ^-  tang
  =/  n=node  [%t 'hello world']
  =/  back=node  !<(node (slap !>(.) (ream (crip (nare n)))))
  ?:  =(n back)  ~
  ['nare/ream failed: [%t hello world]' ~]
  '''
::
=/  s-nare-t-multiline=section
  :-  %unit
  :-  ;p: %t multi-line node
  '''
  ^-  tang
  =/  n=node  [%t 'line one\0aline two\0aline three']
  =/  back=node  !<(node (slap !>(.) (ream (crip (nare n)))))
  ?:  =(n back)  ~
  ['nare/ream failed: multi-line %t' ~]
  '''
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  nare literal output
::  ::  ::  ::  ::  ::  ::  ::  ::
::
=/  s-nare-t-format=section
  :-  %unit
  :-  ;p: +nare emits canonical multi-line %t cord form
  '''
  ^-  tang
  ?:  =(":-  %t\0a'''\0ahello\0a'''" (nare [%t 'hello']))  ~
  ['nare canonical %t form mismatch' ~]
  '''
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  pare round trips (via ream)
::  ::  ::  ::  ::  ::  ::  ::  ::
::
=/  hdr-pare-round=section
  :-  %prose
  ;p: pith round trips via +pare then +ream — produces hoon source.
::
=/  s-pare-empty=section
  :-  %unit
  :-  ;p: empty pith
  '''
  ^-  tang
  =/  p=pith  ~
  =/  back=pith  !<(pith (slap !>(.) (ream (crip (pare p)))))
  ?:  =(p back)  ~
  ['pare/ream failed: ~' ~]
  '''
::
=/  s-pare-simple=section
  :-  %unit
  :-  ;p: simple pith
  '''
  ^-  tang
  =/  p=pith  /foo/bar
  =/  back=pith  !<(pith (slap !>(.) (ream (crip (pare p)))))
  ?:  =(p back)  ~
  ['pare/ream failed: /foo/bar' ~]
  '''
::
=/  s-pare-mixed=section
  :-  %unit
  :-  ;p: mixed-aura pith
  '''
  ^-  tang
  =/  p=pith  ~[%foo ud+1 %bar p+~zod]
  =/  back=pith  !<(pith (slap !>(.) (ream (crip (pare p)))))
  ?:  =(p back)  ~
  ['pare/ream failed: ~[%foo ud+1 %bar p+~zod]' ~]
  '''
::
=/  s-pare-nested=section
  :-  %unit
  :-  ;p: nested pith
  '''
  ^-  tang
  =/  p=pith  ~[%blog [%pith ~[da+~2021.1.1]]]
  =/  back=pith  !<(pith (slap !>(.) (ream (crip (pare p)))))
  ?:  =(p back)  ~
  ['pare/ream failed: nested pith' ~]
  '''
::
=/  s-pare-nested-empty=section
  :-  %unit
  :-  ;p: nested-empty pith
  '''
  ^-  tang
  =/  p=pith  ~[[%pith ~]]
  =/  back=pith  !<(pith (slap !>(.) (ream (crip (pare p)))))
  ?:  =(p back)  ~
  ['pare/ream failed: ~[[%pith ~]]' ~]
  '''
::
=/  s-pare-nested-deep=section
  :-  %unit
  :-  ;p: deeply-nested pith
  '''
  ^-  tang
  =/  p=pith  ~[%a [%pith ~[%b [%pith ~[%c]]]]]
  =/  back=pith  !<(pith (slap !>(.) (ream (crip (pare p)))))
  ?:  =(p back)  ~
  ['pare/ream failed: deep nesting' ~]
  '''
::
::  ::  ::  ::  ::  ::  ::  ::  ::
::  node-summary (lossy)
::  ::  ::  ::  ::  ::  ::  ::  ::
::
=/  hdr-summary=section
  :-  %prose
  ;p: +node-summary produces a human-readable, max-80-char tape — not round-trippable.
::
=/  s-summary-tas=section
  :-  %unit
  :-  ;p: %tas summary
  '''
  ^-  tang
  ?:  =("foo" (node-summary %foo))  ~
  ['node-summary %foo mismatch' ~]
  '''
::
=/  s-summary-ud=section
  :-  %unit
  :-  ;p: %ud summary
  '''
  ^-  tang
  ?:  =("42" (node-summary ud+42))  ~
  ['node-summary ud+42 mismatch' ~]
  '''
::
=/  s-summary-p=section
  :-  %unit
  :-  ;p: %p summary
  '''
  ^-  tang
  ?:  =("~zod" (node-summary p+~zod))  ~
  ['node-summary p+~zod mismatch' ~]
  '''
::
=/  s-summary-pith=section
  :-  %unit
  :-  ;p: %pith summary
  '''
  ^-  tang
  ?:  =("/foo/bar" (node-summary [%pith /foo/bar]))  ~
  ['node-summary %pith mismatch' ~]
  '''
::
=/  s-summary-mime=section
  :-  %unit
  :-  ;p: %mime summary shows type and byte count
  '''
  ^-  tang
  =/  =mime  [/text/plain (as-octs:mimes:html 'hello world')]
  ?:  =("/text/plain (11 bytes)" (node-summary [%mime mime]))  ~
  ['node-summary %mime mismatch' ~]
  '''
::
=/  s-summary-truncates=section
  :-  %unit
  :-  ;p: long %t summaries are truncated to 80 chars
  '''
  ^-  tang
  =/  long=@t  (rap 3 (reap 100 'x'))
  =/  out=tape  (node-summary [%t long])
  ?:  =(80 (lent out))  ~
  ['node-summary did not truncate to 80' ~]
  '''
::
=/  s-summary-no-newlines=section
  :-  %unit
  :-  ;p: %t summary strips embedded newlines
  '''
  ^-  tang
  =/  =node  [%t 'hello\0aworld']
  =/  out=tape  (node-summary node)
  ?:  =(~ (find "\0a" out))  ~
  ['node-summary leaked newline' ~]
  '''
::
=/  s-summary-manx-tag=section
  :-  %unit
  :-  ;p: %manx summary shows tag
  '''
  ^-  tang
  =/  =manx  ;div;
  ?:  =(";div" (node-summary [%manx manx]))  ~
  ['node-summary %manx tag mismatch' ~]
  '''
::
=/  s-summary-manx-id=section
  :-  %unit
  :-  ;p: %manx summary shows id
  '''
  ^-  tang
  =/  =manx  ;div(id "foo");
  ?:  =(";div#foo" (node-summary [%manx manx]))  ~
  ['node-summary %manx id mismatch' ~]
  '''
::
=/  s-summary-manx-class=section
  :-  %unit
  :-  ;p: %manx summary shows class list
  '''
  ^-  tang
  =/  =manx  ;div(class "alpha beta");
  ?:  =(";div.alpha.beta" (node-summary [%manx manx]))  ~
  ['node-summary %manx class mismatch' ~]
  '''
::
=/  s-summary-manx-other-attrs=section
  :-  %unit
  :-  ;p: %manx summary counts other attrs
  '''
  ^-  tang
  =/  =manx  ;div(id "x", data-foo "y", role "main");
  ?:  =(";div#x +2 attrs" (node-summary [%manx manx]))  ~
  ['node-summary %manx other-attrs mismatch' ~]
  '''
::
:-  'serialization round trips'
:~  intro
    hdr-node-tape
    s-node-tas
    s-node-empty-tas
    s-node-ud
    s-node-ud-zero
    s-node-ux
    s-node-p
    s-node-p-comet
    s-node-da
    s-node-f-yes
    s-node-f-no
    s-node-n
    s-node-ta
    hdr-pith-tape
    s-pith-empty
    s-pith-single-tas
    s-pith-multi-tas
    s-pith-mixed
    s-pith-nested
    hdr-deser
    s-sily-tas
    s-sily-ud
    s-sily-p
    s-stib-empty
    s-stib-simple
    hdr-ser
    s-nate-tas
    s-nate-ud
    s-pate-empty
    s-pate-simple
    hdr-nare-round
    s-nare-tas
    s-nare-empty-tas
    s-nare-ud
    s-nare-p
    s-nare-da
    s-nare-t
    s-nare-t-multiline
    s-nare-t-format
    hdr-pare-round
    s-pare-empty
    s-pare-simple
    s-pare-mixed
    s-pare-nested
    s-pare-nested-empty
    s-pare-nested-deep
    hdr-summary
    s-summary-tas
    s-summary-ud
    s-summary-p
    s-summary-pith
    s-summary-mime
    s-summary-truncates
    s-summary-no-newlines
    s-summary-manx-tag
    s-summary-manx-id
    s-summary-manx-class
    s-summary-manx-other-attrs
==
