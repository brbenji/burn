::  rss: basic RSS/Atom feed aggregator
::
::  feather-1 view. timer fetches stalest feed every 15 mins.
::
!:
:-  %feather-1
=>
|%
::
::  render feed list
::
++  render-feed-list
  |=  [=data now=@da]
  ^-  manx
  =/  d  ~(. do data)
  =/  feeds  kid-list:(~(dit do data) /feeds)
  =/  next-tick=@da  (gut-da:d /next-tick *@da)
  =/  refresh-in=tape
    ?:  =(next-tick *@da)  "no timer set"
    ?:  (gth now next-tick)  "any moment"
    =/  remaining=@dr  (sub next-tick now)
    (scow %dr remaining)
  ;div.fc.g5.p6.hf.scroll-y.mw-page.ma.wf
    ;div.fc.g6
      ;div.fr.jb.ae
        ;span.fs2.bold: feeds
        ;div.fr.g3.ac
          ;form(method "post", action "?action=refresh")
            ;button.py2.px3.br3.hover.focus.fs-1.o5.b2: refresh
          ==
          ;span.o4.fs-2.mono: {refresh-in}
        ==
      ==
      ;form.fr.g2(method "post", action "?action=add")
        ;input.py2.px3.grow.bdb1.focus(type "url", name "url", placeholder "add a feed url...", required "");
        ;button.py2.px3.br3.hover.focus.b2: add
      ==
    ==
    ;div.fc.bbv
      ;*
      ?~  feeds
        :~  ;div.py6.o4.tc: no feeds yet
        ==
      %+  turn  feeds
      |=  [=node feed-data=^data]
      =/  fd  ~(. do feed-data)
      =/  fid=@t
        ?+  node  ''
          [%ta @]  ta.node
        ==
      =/  title=@t  (gut-t:fd /title '')
      =/  fetched=@da  (gut-da:fd /fetched *@da)
      =/  item-count=@ud
        (lent kid-list:(~(dit do data) (welp /feeds #/[ta/(crip (trip fid))]/items)))
      ;div.fr.jb.as.py4
        ;a.fc.g1.grow.hover(href "{(trip fid)}")
          ;span: {(trip title)}
          ;span.o4.fs-2.mono: {<item-count>} items
        ==
        ;form(method "post", action "?action=remove&feed={(trip fid)}")
          ;button.p3.br3.hover.focus.fs-2.o4.b2: remove
        ==
      ==
    ==
  ==
::
::  render items for one feed
::
++  render-feed-items
  |=  [=data fid=iota]
  ^-  manx
  =/  d  ~(. do data)
  =/  fid-ta=@ta
    ?+  fid  ''
      [%ta @]  ta.fid
      [%uv @]  (scot %uv uv.fid)
    ==
  ?:  =('' fid-ta)
    (render-feed-list data *@da)
  =/  feed-path  (welp /feeds #/[ta/fid-ta])
  ?.  (hos:d feed-path)
    (render-feed-list data *@da)
  =/  fd  ~(. do (dip:d feed-path))
  =/  title=@t  (gut-t:fd /title '')
  =/  items  kid-list:(~(dit do (dip:d feed-path)) /items)
  ;div.fc.g5.p6.hf.scroll-y.mw-page.ma.wf.pb20
    ;div.fc.g3
      ;a.hover.fs-2.o4.py3(href ".."): back
      ;span.fs2.bold: {(trip title)}
    ==
    ;div.fc.bbv
      ;*
      ?~  items
        :~  ;div.py6.o4.tc: no items yet
        ==
      %+  turn  items
      |=  [=node item-data=^data]
      =/  id  ~(. do item-data)
      =/  item-title=@t  (gut-t:id /title '')
      =/  item-link=@t   (gut-t:id /link '')
      =/  item-date=@t   (gut-t:id /date '')
      =/  summary=@t     (gut-t:id /summary '')
      =/  snippet=tape
        =/  full  (trip summary)
        ?:  (lte (lent full) 200)  full
        (welp (scag 200 full) "...")
      ;div.fc.g3.py4
        ;a.hover(href (trip item-link), target "_blank")
          ;-  (trip item-title)
        ==
        ;+
        ?.  =('' item-date)
          ;span.o4.fs-2.mono: {(trip item-date)}
        ;span;
        ;+
        ?.  =('' summary)
          ;div.fs-1.o5.lh4: {snippet}
        ;span;
      ==
    ==
  ==
::
::  emit an iris fetch request for a feed
::
++  iris-fetch
  |=  [=wire url=@t]
  ^-  move
  :*
    #/o/iris/[pith/wire]
    #/~/iris/[pith/wire]
    %ins
    %data
    %-  ~(gas do *data)
    :~  :-  /url  t+url
        :-  /method  t+'GET'
    ==
  ==
::
::  schedule next tick timer
::
++  schedule-tick
  |=  now=@da
  ^-  (list move)
  =/  next=@da  (add now ~m15)
  :~  :-  [%o %behn %tick ~]
      :-  #/~/behn/tick
      [%ins da+next]
    ::
      [/ /next-tick %ins da+next]
  ==
::
::  find stalest feed — returns [fid url] or ~
::
++  find-stalest
  |=  [=data feeds=(list (pair iota data))]
  ^-  (unit [fid=@ta url=@t])
  =/  d  ~(. do data)
  =|  stalest-fid=@ta
  =|  stalest-da=@da
  =/  first=?  %.y
  |-
  ?~  feeds
    ?:  =('' stalest-fid)  ~
    =/  url=@t  (gut-t:d (welp /feeds #/[ta/stalest-fid]/url) '')
    ?:  =('' url)  ~
    `[stalest-fid url]
  =/  [=node feed-data=^data]  i.feeds
  ?.  ?=([%ta @] node)
    $(feeds t.feeds)
  =/  fid=@ta  ta.node
  =/  fd  ~(. do feed-data)
  =/  fetched=@da  (gut-da:fd /fetched *@da)
  ?:  first
    $(feeds t.feeds, stalest-fid fid, stalest-da fetched, first %.n)
  ?.  (lth fetched stalest-da)
    $(feeds t.feeds)
  $(feeds t.feeds, stalest-fid fid, stalest-da fetched)
::
::  find and fetch the stalest feed
::
++  do-fetch-stalest
  |=  [=data now=@da]
  ^-  (list move)
  =/  feeds  kid-list:(~(dit do data) /feeds)
  =/  res  (find-stalest data feeds)
  ?~  res  ~
  =/  [fid=@ta url=@t]  u.res
  =/  =wire  #/[ta/fid]/[da/now]
  ~&  %rss-fetch
  %+  welp
    :~  [/ (welp /feeds #/[ta/fid]/fetched) %ins da+now]
        (iris-fetch wire url)
    ==
  (schedule-tick now)
::
::  iris response — parse feed XML and store items
::
++  handle-fetch-response
  |=  [=data fid=@ta =stem]
  ^-  (list move)
  =/  iris-data  (~(got-data do data) stem)
  =/  id  ~(. do iris-data)
  =/  status=@ud  (gut-ud:id /status 0)
  =/  body=@t  (gut-t:id /body '')
  ::  bad response — just bail
  ?.  =(200 status)  ~
  ?:  =('' body)  ~
  ::  parse XML
  =/  xml=(unit manx)  (de-xml:html body)
  ?~  xml  ~
  ::  extract items from RSS or Atom
  =/  items=(list [id=@ta title=@t link=@t date=@t summary=@t])
    (extract-items u.xml)
  ::  extract feed title
  =/  feed-title=@t  (extract-feed-title u.xml)
  ::  store title, clear old items, add new items
  =/  moves=(list move)
    :~  [/ #/feeds/[ta/fid]/title %ins t+feed-title]
        [/ #/feeds/[ta/fid]/items %lop ~]
    ==
  |-
  ?~  items
    moves
  =/  item  i.items
  =/  item-id=@ta  id.item
  =.  moves
    %+  welp  moves
    :~  [/ #/feeds/[ta/fid]/items/[ta/item-id]/title %ins t+title.item]
        [/ #/feeds/[ta/fid]/items/[ta/item-id]/link %ins t+link.item]
        [/ #/feeds/[ta/fid]/items/[ta/item-id]/date %ins t+date.item]
        [/ #/feeds/[ta/fid]/items/[ta/item-id]/summary %ins t+summary.item]
    ==
  $(items t.items)
::
::  XML parsing — extract feed title
::
++  extract-feed-title
  |=  =manx
  ^-  @t
  ::  RSS 2.0: <rss><channel><title>
  =/  rss-title  (find-child-text %title (find-element %channel (find-element %rss manx)))
  ?^  rss-title  u.rss-title
  ::  Atom: <feed><title>
  =/  atom-title  (find-child-text %title (find-element %feed manx))
  ?^  atom-title  u.atom-title
  'Untitled Feed'
::
::  XML parsing — extract items from RSS or Atom
::
++  extract-items
  |=  =manx
  ^-  (list [id=@ta title=@t link=@t date=@t summary=@t])
  ::  try RSS 2.0 first
  =/  channel  (find-element %channel (find-element %rss manx))
  =/  rss-items  (find-elements %item channel)
  ?.  =(~ rss-items)
    (turn rss-items parse-rss-item)
  ::  try Atom
  =/  feed  (find-element %feed manx)
  =/  entries  (find-elements %entry feed)
  (turn entries parse-atom-entry)
::
::  parse a single RSS <item>
::
++  parse-rss-item
  |=  =manx
  ^-  [id=@ta title=@t link=@t date=@t summary=@t]
  =/  title=@t    (fall (find-child-text %title manx) '')
  =/  link=@t     (fall (find-child-text %link manx) '')
  =/  date=@t     (fall (find-child-text %'pubDate' manx) '')
  =/  summary=@t  (fall (find-child-text %description manx) '')
  =/  id=@ta      (scot %uv (sham [link title date]))
  [id title link date summary]
::
::  parse a single Atom <entry>
::
++  parse-atom-entry
  |=  =manx
  ^-  [id=@ta title=@t link=@t date=@t summary=@t]
  =/  title=@t    (fall (find-child-text %title manx) '')
  =/  link=@t     (find-atom-link manx)
  =/  date=@t     (fall (find-child-text %updated manx) '')
  =/  summary=@t  (fall (find-child-text %summary manx) '')
  ?:  =('' summary)
    =.  summary  (fall (find-child-text %content manx) '')
    =/  id=@ta  (scot %uv (sham [link title date]))
    [id title link date summary]
  =/  id=@ta  (scot %uv (sham [link title date]))
  [id title link date summary]
::
::  find Atom <link href="..."> attribute
::
++  find-atom-link
  |=  =manx
  ^-  @t
  =/  kids  c.manx
  |-
  ?~  kids  ''
  =/  kid  i.kids
  ?.  ?=(%link n.g.kid)
    $(kids t.kids)
  ::  check for rel="alternate" or no rel
  =/  rel  (get-attribute %rel kid)
  =/  href  (get-attribute %href kid)
  ?~  href  $(kids t.kids)
  ?:  |(?=(~ rel) =('alternate' u.rel))
    (crip u.href)
  $(kids t.kids)
--
|%
++  title
  |=  [here=pith =data]
  ?~(here "rss" "{(print-node (rear here))} - rss")
::
::  GET — render page (body content only)
::
++  get
  |=  [our=@p src=@p =data =stem =query]
  ^-  node
  =/  d  ~(. do data)
  =/  now=@da  (gut-da:d #/~/meta/now *@da)
  :-  %manx
  ?+  route=((pole iota) stem)  ~|  page-not-found/route  !!
    ::
    ::  feed list
    ::
    [~]
      (render-feed-list data now)
    ::
    ::  feed items
    ::
    [fid=* ~]
      (render-feed-items data fid.route)
  ==
::
::  POST — handle add/remove/refresh
::
++  post
  |=  [our=@p src=@p =data =stem =query =body]
  ^-  [(unit [^stem ^query]) (list move)]
  =/  d  ~(. do data)
  =/  b  ~(. do body)
  =/  now=@da  (gut-da:d #/~/meta/now *@da)
  =/  action=@tas  (crip (~(gut by (malt query)) 'action' ""))
  ?+  action  [~ ~]
    ::
    %add
      =/  url=@t  (gut-t:b #/[t+'url'] '')
      ?:  =('' url)  [`[/ ~] ~]
      =/  fid=@ta  (scot %uv (sham url))
      =/  =wire  #/[ta/fid]/[da/now]
      :-  `[/ ~]
      ^-  (list move)
      %+  welp
        :~  [/ #/feeds/[ta/fid]/url %ins t+url]
            [/ #/feeds/[ta/fid]/title %ins t+url]
            [/ #/feeds/[ta/fid]/fetched %ins da+now]
            (iris-fetch wire url)
        ==
      (schedule-tick now)
    ::
    %remove
      =/  fid=@t  (crip (~(gut by (malt query)) 'feed' ""))
      ?:  =('' fid)  [`[/ ~] ~]
      :-  `[/ ~]
      ^-  (list move)
      :~  [/ (welp /feeds #/[ta/(crip (trip fid))]) %lop ~]
      ==
    ::
    %refresh
      =/  feeds  kid-list:(~(dit do data) /feeds)
      =/  res  (find-stalest data feeds)
      :-  `[/ ~]
      ?~  res  ~
      =+  [fid url]=u.res
      =/  =wire  #/[ta/fid]/[da/now]
      ^-  (list move)
      %+  welp
        :~  [/ (welp /feeds #/[ta/fid]/fetched) %ins da+now]
            (iris-fetch wire url)
        ==
      (schedule-tick now)
  ==
::
::  ON — handle behn ticks and iris responses
::
++  on
  |=  [=prov =move =file]
  ^-  (list ^move)
  ?+  wir=((pole iota) wire.move)  ~
    ::
    [%i %behn %tick ~]
      =/  now=@da  (~(git-da do data.file) #/~/meta/now)
      (do-fetch-stalest data.file now)
    ::
    [%i %iris wire=[%pith *] ~]
      =/  war  ((pole iota) pith.wire.wir)
      ?.  ?=(fid=[[%ta @] [%da @] ~] war)
        ~|  invailid-wire/war
        !!
      (handle-fetch-response data.file ta.fid.war stem.move)
  ==
--
