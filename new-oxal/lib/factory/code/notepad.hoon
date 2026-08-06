::  notepad: simple plaintext notes
::
!:
:-  %feather-1
|%
++  title
  |=  [here=pith =data]
  ?~(here "notepad" (print-node (rear here)))
::
++  get
  |=  [our=@p src=@p =data =stem =query]
  =/  d  ~(. do data)
  =/  auth  ?:  =(our src)  %admin  %other
  ^-  node
  :-  %manx
  ?+  route=((pole iota) [auth stem])  ~|  page-not-found/route  !!
    [%admin ~]
      ;div.fc.g4.p4.mono.winter.hf.scroll-y.b1
        ;form.bd1.fr.bbh
          =method  "post"
          =action  "?action=create"
          ;input.p2.w1.grow.focus
            =placeholder  "name"
            =required  ""
            =name  "name"
            =spellcheck  "false"
            =autocomplete  "off"
            ;*  ~
          ==
          ;button.p2.b1.hover.focus
            ; create
          ==
        ==
        ;div.fc
          ;*
          =;  =marl  ?^  marl  marl
            ;=
              ;div: none
            ==
          %-  ren:d
          |=  [=iota =_data]
          ?~  leaf.data  ~
          :-  ~
          ;a.underline.b1.hover.p2.br2.pulser
            =href  (dane iota)
            ;-  (print-node iota)
          ==
        ==
      ==
    ::
    [%admin name=* ~]
      =/  name=iota  name.route
      ;div.fc.bbv.wf.hf.scroll-none.mono.shrink-none.winter.b1
        ;div.fr.bbh.fs1.af
          ;a.p-3.b1.hover.f5.pulser.focus
            =href  ".."
            ; ⇐
          ==
          ;form.grow.fr(method "post", action "?action=rename")
            =data-on_post-complete  "$_namemod = false;"
            ;input.p-3.b1.pulser.w1.grow.focus
              =data-class_bold  "$_namemod"
              =required  ""
              =autocomplete  "off"
              =spellcheck  "false"
              =name  "new-name"
              =data-on_input  "$_namemod = true;"
              =data-on_keydown  "if (evt.key == 's' && evt.metaKey) \{   ".
                                "  evt.preventDefault();                 ".
                                "  if (!!$_namemod) \{                     ".
                                "    el.closest('form').requestSubmit(); ".
                                "  }                                     ".
                                "}"
              =value  (print-node name)
              ;*  ~
            ==
          ==
          ;form.fc(method "post", action "?action=delete")
            =onsubmit  "return confirm('{(print-node name)} : delete?')"
            ;button.p-3.b1.hover.f7.pulser.fs-1.grow.focus
              ; delete
            ==
          ==
        ==
        ;form#submit.grow.fc.bbv.shrink-1
          =method  "post"
          =action  "?action=update"
          =data-on_post-complete  "$_modified = false;"
          ;+
          =/  =node  (fall (get:d #/[name]) t+'')
          ?+    node
              ;div.grow.fc.ac.jc: no renderer {(print-aura node)}
            ::
            [%t *]
              ;textarea#txt.grow.p3.shrink-1.pre.lh2.focus
                =name  "txt"
                =rows  "1"
                =spellcheck  "false"
                =placeholder  "txt"
                =autocomplete  "off"
                =data-on_input  "$_modified = true;"
                =data-on_keydown  "if (evt.key == 's' && evt.metaKey) \{  ".
                                  "  evt.preventDefault();                ".
                                  "  el.closest('form').requestSubmit();  ".
                                  "}"
                ;-  (trip t.node)
              ==
            ::
          ==
          ;button.p4.b1.hover.shrink-none.pulser.fs1.focus
            =data-attr_disabled  "!$_modified"
            =data-class_bold  "!!$_modified"
            ; save
          ==
        ==
      ==
  ==
::
++  post
  |=  [our=@p src=@p =data =stem =query =body]
  =/  d  ~(. do data)
  =/  b  ~(. do body)
  =/  auth  ?:  =(our src)  %admin  %other
  =/  action=@tas  (crip (~(gut by (malt query)) 'action' ""))
  ?+  route=((pole iota) [auth action stem])  ~|  no-route/route  !!
    ::
    [%admin %create ~]
      =/  name=node  t+(got-t:b #/[t/'name'])
      :-  `[#/[name] ~]
      ^-  (list move)
      :~
        :+  /  #/[name]  [%ins t+'']
      ==
    ::
    [%admin %delete name=* ~]
      =/  name=node  name.route
      :-  `[/ ~]
      ^-  (list move)
      :~
        :+  /  #/[name]  [%del ~]
      ==
    ::
    [%admin %update name=* ~]
      =/  name=node  name.route
      =/  txt        (git-t:b #/[t/'txt'])
      :-  ~
      ^-  (list move)
      :~
        :+  /  #/[name]  [%ins t+txt]
      ==
    ::
    [%admin %rename name=* ~]
      =/  name=node      name.route
      =/  contents=node  (got:d #/[name])
      =/  new-name=node  t+(got-t:b #/[t/'new-name'])
      :-  `[#/[new-name] ~]
      ^-  (list move)
      :~
        :+  /  #/[name]      [%del ~]
        :+  /  #/[new-name]  [%ins contents]
      ==
    ::
  ==
::
++  on
  |=  [=prov =move =file]
  ~
--
