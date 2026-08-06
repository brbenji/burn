:-  %feather-1
|%
++  title
  |=  [here=pith =data]
  ?~(here "docs" "{(print-node (rear here))} - docs")
++  get
  |=  [our=@p src=@p =data =stem =query]
  =/  d  ~(. do data)
  ^-  node 
  :-  %manx
  ?+  stem=((pole iota) stem)  ~|  page-not-found/stem  !!
      ~
    ;div.page.fc.g8
      ;h1: hawk docs
      ;p: hawk is a reactive web framework for urbit. write views that render a data tree as HTML, with automatic live updates across all connected browsers.
      ;div.fc
        ;*
        %-  ren:d
        |=  [=iota =_data]
        ?~  leaf.data  ~
        ?.  ?=([%manx *] u.leaf.data)  ~
        :-  ~
        ;a.underline.b1.hover.p2.br2.pulser
          =href  (dane iota)
          ;-  (print-node iota)
        ==
      ==
    ==
  ::
      [name=* ~]
    =/  name=iota  name.stem
    ;div.page.fc.g8
      ;div
        ;a.underline.b1.hover.p2.br2.pulser(href "..")
          ; ⇐ back
        ==
      ==
      ;+
      =/  leaf  (get:d #/[name])
      ?~  leaf  ;div: not found
      ?.  ?=([%manx *] u.leaf)  ;div: not a document
      %+  add-class  "prose pb10 bdb1"
      manx.u.leaf
    ==
  ==
++  post
  |=  [our=@p src=@p =data =stem =query =body]
  :-  ~
  ~
++  on
  |=  [=prov =move =file]
  ~
--
