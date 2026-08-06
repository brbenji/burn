::  /lib/vines/oxal--rss-palm: accordion + palm layout reference
::
::    GET  /new-oxal/rss-palm   feeds as accordion sections; episodes as
::                          palm list + detail panels (≥3 eps) or
::                          stack of cards (<3 eps).
::
::  Render-only port of fogduc poots-rss-palm. Iris/behn/post stripped —
::  this is a layout reference. Seed /feeds via dojo for content.
::
/+  *vineio, *zozo
::
=<
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
;<  =data  bind:m
  (scry ,data /gx/new-oxal/data/(scot %p our.bowl)/feeds/noun)
;<  ~  bind:m  (send-html-payload:vio (render-page bowl data))
(pure:m !>(~))
::
|%
::  ::  ::  ::  helpers
::
++  gut-t
  |=  [=data =pith back=@t]
  ^-  @t
  =/  d  ~(. do data)
  =/  res  (get:d pith)
  ?~  res  back
  ?.  ?=([%t *] u.res)  back
  t.u.res
::
++  gut-da
  |=  [=data =pith back=@da]
  ^-  @da
  =/  d  ~(. do data)
  =/  res  (get:d pith)
  ?~  res  back
  ?.  ?=([%da *] u.res)  back
  da.u.res
::
++  nodet
  |=  nod=node
  ^-  tape
  ?@  nod  (trip nod)
  ?+  -.nod  ""
    %t   (trip t.nod)
    %ta  (trip ta.nod)
  ==
::
++  format-date
  |=  d=@da
  ^-  tape
  ?:  =(d *@da)  ""
  =/  =date  (yore d)
  =/  mon=@ud  m.date
  =/  month-name=tape
    ?+  mon  "???"
      %1   "Jan"   %2   "Feb"   %3   "Mar"   %4   "Apr"
      %5   "May"   %6   "Jun"   %7   "Jul"   %8   "Aug"
      %9   "Sep"   %10  "Oct"   %11  "Nov"   %12  "Dec"
    ==
  =/  yr=tape  (a-co:co y.date)
  =/  dy=tape  (a-co:co d.t.date)
  "{month-name} {dy}, {yr}"
::
++  truncate-at-word
  |=  [txt=tape max=@ud]
  ^-  tape
  ?:  (lte (lent txt) max)  txt
  =/  chunk=tape  (scag max txt)
  =/  rev=tape  (flop chunk)
  =/  space-pos  (find " " rev)
  ?~  space-pos  (welp chunk "...")
  =/  cut-at=@ud  (sub max +(u.space-pos))
  (welp (scag cut-at txt) "...")
::
++  strip-html
  |=  raw=@t
  ^-  tape
  =/  input=tape  (trip raw)
  =|  out=tape
  =|  in-tag=?
  |-
  ?~  input  (flop out)
  =/  c=@tD  i.input
  ?:  =(c '<')  $(input t.input, in-tag %.y)
  ?:  =(c '>')  $(input t.input, in-tag %.n)
  ?:  in-tag    $(input t.input)
  $(input t.input, out [c out])
::
::  ::  ::  ::  rendering
::
++  render-episode-card
  |=  ep-data=data
  ^-  manx
  =/  ep-title=tape
    ?~  leaf.ep-data  "Untitled"
    (nodet u.leaf.ep-data)
  =/  ep-date=@da  (gut-da ep-data /date *@da)
  =/  raw-summary=@t  (gut-t ep-data /summary '')
  =/  trunc-raw=tape  (scag 400 (trip raw-summary))
  =/  stripped=tape  (strip-html (crip trunc-raw))
  =/  ep-summary=tape  (truncate-at-word stripped 200)
  =/  ep-link=tape  (trip (gut-t ep-data /link ''))
  ;box(data-goon "card", data-goon-depth "2", data-goon-children "3")
    ;stack
      ;h3(data-goon "label", data-goon-depth "2"): {ep-title}
      ;p(data-goon-children "0")
        ;strong(data-goon "label"): date:
        ;span(data-goon "value"): {" "}{(format-date ep-date)}
      ==
    ==
  ==
::
++  render-palm-list-item
  |=  [idx=@ud ep-data=data]
  ^-  manx
  =/  ep-title=tape
    ?~  leaf.ep-data  "Untitled"
    (truncate-at-word (nodet u.leaf.ep-data) 70)
  =/  idxt=tape  (scow %ud idx)
  =/  active=tape  ?:(=(idx 0) "true" "false")
  ;li(data-goon "palm-item", data-goon-children "1", data-goon-palm-idx idxt, data-goon-palm-active active): {ep-title}
::
++  render-palm-detail-panel
  |=  [idx=@ud ep-data=data]
  ^-  manx
  =/  idxt=tape  (scow %ud idx)
  =/  active=tape  ?:(=(idx 0) "true" "false")
  ;div(data-goon "palm-detail", data-goon-palm-idx idxt, data-goon-palm-active active)
    ;+  (render-episode-card ep-data)
  ==
::
++  render-feed-content
  |=  feed-data=data
  ^-  manx
  =/  fd  ~(. do feed-data)
  ?.  (hos:fd /items)
    ;p(data-goon "description"): no episodes
  =/  id  (~(dit do feed-data) /items)
  =/  items-kids  (flop kid-list:id)
  =/  ep-count=@ud  (lent items-kids)
  =/  palm-list-items=marl
    =/  idx=@ud  0
    =/  rem  items-kids
    |-  ^-  marl
    ?~  rem  ~
    =/  ep-data=^data  +.i.rem
    :_  $(rem t.rem, idx +(idx))
    (render-palm-list-item idx ep-data)
  =/  palm-detail-panels=marl
    =/  idx=@ud  0
    =/  rem  items-kids
    |-  ^-  marl
    ?~  rem  ~
    =/  ep-data=^data  +.i.rem
    :_  $(rem t.rem, idx +(idx))
    (render-palm-detail-panel idx ep-data)
  ?:  (gte ep-count 3)
    ;sidebar(data-goon "palm-layout")
      ;stack(data-goon "palm-list")
        ;*  palm-list-items
      ==
      ;aside(data-goon "palm")
        ;*  palm-detail-panels
      ==
    ==
  ;stack(data-goon "collection")
    ;*  palm-detail-panels
  ==
::
++  render-accordion-section
  |=  [idx=@ud feed-title=tape feed-content=manx]
  ^-  manx
  =/  expanded=tape  ?:(=(idx 0) "true" "false")
  ;div(data-goon "accordion-section", data-goon-accordion-expanded expanded)
    ;button(data-goon "accordion-header", data-goon-children "1", data-goon-accordion-expanded expanded)
      ;span(data-goon "accordion-arrow"): ;
      ;span: {feed-title}
    ==
    ;div(data-goon "accordion-content", data-goon-accordion-expanded expanded)
      ;+  feed-content
    ==
  ==
::
++  feed-title-of
  |=  [=node feed-data=data]
  ^-  tape
  ?~  leaf.feed-data  (node-summary node)
  (nodet u.leaf.feed-data)
::
++  render-page
  |=  [bowl=http-bowl =data]
  ^-  manx
  =/  d  ~(. do data)
  =/  feeds  kid-list:d
  =/  feed-count=@ud  (lent feeds)
  =/  rendered-sections=marl
    =/  idx=@ud  0
    =/  rem  feeds
    |-  ^-  marl
    ?~  rem  ~
    =/  =iota  -.i.rem
    =/  feed-data=^data  +.i.rem
    =/  ft  (feed-title-of iota feed-data)
    =/  fc  (render-feed-content feed-data)
    :_  $(rem t.rem, idx +(idx))
    (render-accordion-section idx ft fc)
  ;html
    ;head
      ;meta(charset "UTF-8");
      ;meta
        =name  "viewport"
        =content  "width=device-width, initial-scale=1"
        ;*  ~
      ==
      ;title: /feeds — RSS palm
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
      ;link(rel "stylesheet", href "/hawk-init/every-layout/1/style");
      ;link(rel "stylesheet", href "/hawk-init/goon-oxal/1/style");
      ;script(src "/hawk-init/goon-oxal/1/nav", defer "");
    ==
    ;body.p5
      ;box
        ;stack
          ;lane
            ;stack
              ;h1: RSS palm
              ;p(data-goon "description"): Feeds as accordion sections, episodes as palm lists. Static reference port.
            ==
          ==
          ;hr;
          ;+
          ?:  =(feed-count 0)
            ;p(data-goon "description"): no feeds yet — seed /feeds via dojo
          ;stack(data-goon "root", data-goon-depth "0", data-goon-nav "dormant", data-goon-children (scow %ud feed-count))
            ;*  rendered-sections
          ==
        ==
      ==
    ==
  ==
--
