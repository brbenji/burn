/+  *zozo-one
::
|=  =pure-core
^-  feather-1-core
|%
++  title
  |=  [here=pith =data]
  ?~(here "pure" (print-node (rear here)))
++  get
  |=  [our=@p src=@p =data =stem =query]
  ^-  node
  ?.  |(public.pure-core =(our src))
    tang+~['permission denied']
  =/  res=(each node tang)
    (mule |.((gate.pure-core (~(lop do data) #/~))))
  ?-  -.res
    %.y  p.res
    %.n  tang+p.res
  ==
++  post
  |=  [our=@p src=@p =data =stem =query =body]
  ^-  [(unit [^stem ^query]) (list move)]
  [~ ~]
++  on
  |=  [=prov =move =file]
  ^-  (list _move)
  =/  res=(each node tang)
    (mule |.((gate.pure-core (~(lop do data.file) #/~))))
  ?:  ?=(%.n -.res)  ~
  ~[[/ / %ins p.res]]
--
