!:
:-  %mantis
|=  [=prov move =file]
^-  (list move)
%.  ~
|_  out=(list move)
+*  cor   .
    d     ~(. do data.file)
++  abet  (flop out)
++  emit  |=  =move  cor(out [move out])
++  emil  |=  moves=(list move)  cor(out (welp (flop moves) out))
++  $
  =<  abet
  ?:  ?=(%.n -.prov)  cor
  ::
  ?+  wire=((pole iota) wire)
      ~|  unhandled-wire/wire  !!
    [%in %eyre rid=[%ta @] ~]
      =/  req=data  (got-data:d stem)
      =/  r  ~(. do req)
      =/  method  (got-tas:r /method)
      ?:  =(%'POST' method)
        handle-post
      render
  ==
++  handle-post
  ^+  cor
  =/  count=@ud  (gut-ud:d /count 0)
  =/  new-count=@ud  +(count)
  %-  emil
  :~  [~ /count %ins ud+new-count]
      [[%out +.wire] stem %ins t+'/oxal/mantis']
  ==
++  render
  ^+  cor
  =/  count=@ud  (gut-ud:d /count 0)
  %-  emit
  =-  [[%out +.wire] stem %ins manx+page]
  =/  page=manx
  ;div
    ;h1: Count: {<count>}
    ;form(method "POST")
      ;button(type "submit"): Increment
    ==
  ==
--
