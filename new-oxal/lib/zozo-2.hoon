::  two: file engine
::
/+  *zozo-1
|%
++  fe
  |_  fil=file
  +*  dat  data.fil
      cod  code.fil
      de   ~(. do data.fil)
      ce   ~(. ox code.fil)
  ++  out  fil
  ++  cor  .
  ::
  ++  kid-list
    ::
    ::  the first layer of children across both data and code trees,
    ::  merged by iota. produces a list of [iota file] pairs.
    ::
    =|  out=(list [iota file])
    =/  dk  kids.dat
    =/  ck  kids.cod
    |-
    ^+  out
    ?:  =(~ dk)
      %+  welp  out
      %+  turn  (tap:moci ck)
      |=  [=iota *]
      [iota (dip #/[iota])]
    ?:  =(~ ck)
      %+  welp  out
      %+  turn  (tap:modi dk)
      |=  [=iota *]
      [iota (dip #/[iota])]
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
  ++  dip
    ::
    ::  descend both data and code trees to a path
    ::
    |=  pax=pith
    ^-  file
    [(~(dip do dat) pax) (~(dip ox cod) pax)]
  ::
  ++  dit
    ::
    ::  descend and return a new +fe at that path
    ::
    |=  pax=pith
    ~(. fe (dip pax))
  ::
  ++  views-below
    ::
    ::  set of installed views below
    ::
    |=  pax=pith
    ^-  (set pith)
    =.  fil  (dip pax)
    %-  silt
    ^-  (list pith)
    %-  ~(mur ox cod)
    |=  [=pith =meta]
    ?~  lord.meta  ~
    `(welp pax pith)
    ::
  ::
  ++  partial
    ::
    ::  (set pith) stitched back together
    ::
    |=  parts=(set pith)
    ^-  file
    =|  fax=file
    =/  todo=(list pith)  ~(tap in parts)
    |-
    ?~  todo  fax
    =.  code.fax  (~(rep ox code.fax) i.todo (~(dip ox code.fil) i.todo))
    =.  data.fax  (~(rep ox data.fax) i.todo (~(dip ox data.fil) i.todo))
    $(todo t.todo)
  --
--
