::  blog: simple blog with source text and rendered HTML
::
::  feather-1 view. posts stored under /posts/slug with
::  title, source, rendered manx, and date.
::
!:
:-  %feather-1
=>
|%
::
::  render source text to manx — split on blank lines into <p> tags
::
++  render-tang
  |=  =tang
  ^-  manx
  ;pre.pre.mono.scroll-x.p2.f-1
    ;*
    %+  turn  (scag 50 tang)
    |=  =tank
    ;/  %-  of-wall:format
    (~(win re tank) 0 80)
  ==
++  render-source
  |=  src=@t
  ^-  manx
  ?:  =('' src)  ;div: nothing yet
  =/  src  (cat 3 src '\0a')
  =/  res  (mule |.(!<(manx (slap !>(..zuse) (ream src)))))
  ?-  -.res
    %&  p.res
    %|  (render-tang p.res)
  ==
--
|%
++  title
  |=  [here=pith =data]
  "blog"
::
::  GET — render page
::
++  get
  |=  [our=@p src=@p =data =stem =query]
  =/  d  ~(. do data)
  =/  auth  ?:(=(our src) %admin %other)
  ^-  node
  :-  %manx
  ?+  route=((pole iota) [auth stem])  ~|  page-not-found/route  !!
    ::
    ::  admin index — create form + post list with delete buttons
    ::
    [%admin ~]
      =/  posts  kid-list:(~(dit do data) /posts)
      ;div.fc.g4.p4.mono.hf.scroll-y
        ;h2: blog of {<our>}
        ;div.p3.br2.bd1.b2.fs-1.lh2
          ;span.bold: warning:
          ; every change you make in this tree is published to the
          ; public namespace. anyone who knows your ship name can
          ; read your posts.
        ==
        ::  create form
        ;form.fr.g2(method "post", action "?action=create")
          ;input.p2.grow.b2.br2.bd1.focus
            =type  "text"
            =name  "title"
            =placeholder  "post title"
            =required  ""
            ;*  ~
          ==
          ;button.p2.b2.br2.bd1.hover.focus: create
        ==
        ::  post list
        ;div.fc.g2
          ;*
          ?~  posts
            :~  ;div.p4.o5.tc: no posts yet.
            ==
          %+  turn  posts
          |=  [=node post-data=^data]
          =/  pd  ~(. do post-data)
          =/  post-title=@t  (gut-t:pd /title '')
          =/  post-date=@da  (gut-da:pd /date *@da)
          ;div.fr.g3.jb.as
            ;a.fc.g1.grow.hover.p-2.b2.br2.bd1(href (dane node))
              ;span.bold: {(trip post-title)}
              ;span.o5.fs-1: {?:(=(post-date *@da) "" (scow %da post-date))}
            ==
            ;form(method "post", action "{(dane node)}?action=delete")
              ;button.p-2.b2.br2.bd1.hover.focus.fs-1: delete
            ==
          ==
        ==
      ==
    ::
    ::  public index — post list only
    ::
    [%other ~]
      =/  posts  kid-list:(~(dit do data) /posts)
      ;div.fc.g4.p4.mono.hf.scroll-y
        ;h2: blog
        ;div.fc.g2
          ;*
          ?~  posts
            :~  ;div.p4.o5.tc: No posts yet.
            ==
          %+  turn  posts
          |=  [=node post-data=^data]
          =/  pd  ~(. do post-data)
          =/  post-title=@t  (gut-t:pd /title '')
          =/  post-date=@da  (gut-da:pd /date *@da)
          ;div.fr.g2.p3.b2.br2.bd1.ac
            ;a.fc.g1.grow.hover(href (dane node))
              ;span.bold: {(trip post-title)}
              ;span.o5.fs-1: {?:(=(post-date *@da) "" (scow %da post-date))}
            ==
          ==
        ==
      ==
    ::
    ::  admin post — rendered content + edit form
    ::
    [%admin name=* ~]
      =/  name=iota  name.route
      =/  pd  ~(. do (~(dip do data) (welp /posts #/[name])))
      =/  post-title=@t  (gut-t:pd /title '')
      =/  source=@t  (gut-t:pd /source '')
      ;div.fc.g4.p4.grow.scroll-none
        =data-signals  "\{'_tab': 'view'}"
        ;div.fr.g2.as
          ;a.hover.fs-1.b2.wfc.p-2.br2.bd1(href ".."): back
          ;div.grow;
          ;button.p-2.b2.br2.bd1.hover.focus
            =data-on_click  "$_tab = 'view'"
            =data-class_toggled  "$_tab == 'view'"
            ; view
          ==
          ;button.p-2.b2.br2.bd1.hover.focus
            =data-on_click  "$_tab = 'edit'"
            =data-class_toggled  "$_tab == 'edit'"
            ; edit
          ==
          ;button.p-2.b2.br2.bd1.hover.focus
            =data-on_click  "$_tab = 'help'"
            =data-class_toggled  "$_tab == 'help'"
            ; help
          ==
        ==
        ::  view tab
        ;div.p3.lh2.prose(data-show "$_tab == 'view'")
          ;h1.bold: {(trip post-title)}
          ;hr;
          ;+
          ?~  x=(get-manx:pd /rendered)  ;div: none yet
          u.x
        ==
        ::  edit tab
        ;form.fc.g3.grow.scroll-none
          =method  "post"
          =action  "?action=update"
          =data-show  "$_tab == 'edit'"
          =data-on_post-complete  "$_tab = 'view'"
          =style  hid
          ;input.p2.b2.br2.bd1.focus
            =type  "text"
            =name  "title"
            =value  (trip post-title)
            =required  ""
            ;*  ~
          ==
          ;feather-text-editor.p2.b2.br2.bd1.lh2.focus
            =name  "source"
            =rows  "10"
            =placeholder  "hoon that results in manx"
            ;-  (trip source)
          ==
          ;button.p3.b2.br2.bd1.hover.focus: save
        ==
        ::  help tab
        ;div.fc.g3.p3.grow.scroll-y(data-show "$_tab == 'help'")
          ;h3.bold: sail example
          ;pre.b2.br2.bd1.mono.fs-1.scroll-x.p3
            ;-  %-  trip
            '''
            ;>

            # hello world

            - ok
            - fine

            ---

            this is a paragraph
            with two sentences. ain't it cool?

            ;div
              ;h2: a smaller heading
              ;p: a paragraph of text.
              ;ul
                ;li: first item
                ;li: second item
              ==
              ;ol
                ;li: step one
                ;li: step two
              ==
              ;a(href "https://willhanlen.com"): a link
            ==
            '''
          ==
        ==
      ==
    ::
    ::  public post — rendered content only
    ::
    [%other name=* ~]
      =/  name=iota  name.route
      =/  pd  ~(. do (~(dip do data) (welp /posts #/[name])))
      =/  post-title=@t  (gut-t:pd /title '')
      ;div.fc.g4.p4.mono.hf.scroll-y
        ;a.hover.fs-1(href ".."): back
        ;h2: {(trip post-title)}
        ;div.p3.br2.bd1.lh2
          ;+
          ?~  x=(get-manx:pd /rendered)  ;div: no post
          u.x
        ==
      ==
  ==
::
::  POST — handle create/update/delete
::
++  post
  |=  [our=@p src=@p =data =stem =query =body]
  ^-  [(unit [^stem ^query]) (list move)]
  =/  d  ~(. do data)
  =/  b  ~(. do body)
  =/  now=@da  (gut-da:d #/~/meta/now *@da)
  =/  auth  ?:(=(our src) %admin %other)
  =/  action=@tas  (crip (~(gut by (malt query)) 'action' ""))
  ?+  route=((pole iota) [auth action stem])  [~ ~]
    ::
    [%admin %create ~]
      =/  title=@t  (gut-t:b #/[t+'title'] '')
      ?:  =('' title)  [`[/ ~] ~]
      =/  rendered=manx  (render-source '')
      :-  `[#/[t+title] ~]
      ^-  (list move)
      :~  [/ (welp /posts #/[t+title]/title) %ins t+title]
          [/ (welp /posts #/[t+title]/source) %ins t+'']
          [/ (welp /posts #/[t+title]/rendered) %ins manx+rendered]
          [/ (welp /posts #/[t+title]/date) %ins da+now]
      ==
    ::
    [%admin %update name=* ~]
      =/  name=iota  name.route
      =/  raw-title=@t  (gut-t:b #/[t+'title'] '')
      =/  source=@t  (gut-t:b #/[t+'source'] '')
      =/  rendered=manx  (render-source source)
      ?:  =('' raw-title)  [~ ~]
      :-  ~
      ^-  (list move)
      :~  [/ (welp /posts #/[name]/title) %ins t+raw-title]
          [/ (welp /posts #/[name]/source) %ins t+source]
          [/ (welp /posts #/[name]/rendered) %ins manx+rendered]
      ==
    ::
    [%admin %delete name=* ~]
      =/  name=iota  name.route
      :-  `[/ ~]
      ^-  (list move)
      :~  [/ (welp /posts #/[name]) %lop ~]
      ==
  ==
::
::  ON — bind publicly on install
::
++  on
  |=  [=prov =move =file]
  ^-  (list ^move)
  ?:  ?=(%install -.action.move)
    :~  [/ / %bind ~ ~ `[~ %.n] ~]
    ==
  ~
--
