::  mirror-test: test self-keen mirroring
::
!:
:-  %feather-1
|%
++  title
  |=  [here=pith =data]
  "mirror test"
::
++  get
  |=  [our=@p src=@p =data =stem =query]
  =/  d  ~(. do data)
  =/  mp  #/~/mirror/[ta/'test']
  ^-  node
  :-  %manx
  ;div.fc.g4.p4.mono.winter.hf.scroll-y.b1
    ;div.bold.f3: mirror test
    ;form.fc.g2.p3.bbh
      =method  "post"
      =action  "?action=start"
      ;input.p2.b1.focus
        =name  "target"
        =placeholder  "/path/to/mirror"
        =required  ""
        =autocomplete  "off"
        ;*  ~
      ==
      ;button.p2.b1.hover.focus: mirror self
    ==
    ;div.fc.g2.p3
      ;div: state:   {(pib:d (welp mp /state))}
      ;div: case:    {(pib:d (welp mp /case))}
      ;div: attempt: {(pib:d (welp mp /attempt))}
      ;div: ship:    {(pib:d (welp mp /ship))}
      ;div: path:    {(pib:d (welp mp /path))}
      ;div: care:    {(trip (gut-tas:d (welp mp /care) %none))}
    ==
    ;div.fc.g2.p3.bbh
      ;div.bold: data
      ;*
      =/  md  ~(. do (fall (get-data:d (welp mp /data)) (dip:d (welp mp /data))))
      %-  ren:md
      |=  [=iota =_data]
      ^-  (unit manx)
      :-  ~
      ;div: {(print-node iota)}: {(print-node (fall leaf.data t+'~'))}
    ==
  ==
::
++  post 
  |=  [our=@p src=@p =data =stem =query =body]
  =/  b  ~(. do body)
  =/  action=@tas  (crip (~(gut by (malt query)) 'action' ""))
  ?+  route=((pole iota) [action stem])  ~|  no-route/route  !!
    [%start ~]
      =/  target=@t  (got-t:b #/[t/'target'])
      =/  target-pith=pith  (pave (stab target))
      :-  ~
      ^-  (list move)
      :~  :+  [%out %mirror ta/'test' ~]
              #/mirror-cfg
          :-  %ins
          :-  %data
          %-  ~(gas do *^data)
          :~  [#/ship p+our]
              [#/path pith+target-pith]
          ==
      ==
  ==
::
++  on  |=  [=prov =move =file] 
  ~
--
