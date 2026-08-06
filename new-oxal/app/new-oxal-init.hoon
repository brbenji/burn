::  new-oxal-init: static assets (post-rebrand of %hawk-init) :: xx remove this file
::
/+  *zozo-1, dbug
::
/*  feather-1-style                %css   /lib/web/feather-1/style/css
/*  feather-1-lit                  %js    /lib/web/feather-1/lit/js
/*  feather-1-layout-basic         %js    /lib/web/feather-1/layout-basic/js
/*  feather-1-text-editor          %js    /lib/web/feather-1/text-editor/js
/*  feather-1-layout-triptych      %js    /lib/web/feather-1/layout-triptych/js
/*  feather-1-iframe               %js    /lib/web/feather-1/iframe/js
/*  feather-1-da-ta                %js    /lib/web/feather-1/da-ta/js
/*  feather-1-textarea             %js    /lib/web/feather-1/textarea/js
/*  feather-1-slide-panels         %js    /lib/web/feather-1/slide-panels/js
/*  feather-1-datastar             %js    /lib/web/feather-1/datastar/js
/*  feather-1-datastar-inspector   %js    /lib/web/feather-1/datastar-inspector/js
::
/*  every-layout-1-style           %css   /lib/web/every-layout-1/style/css
/*  goon-oxal-1-style              %css   /lib/web/goon-oxal-1/style/css
/*  goon-oxal-1-nav                %js    /lib/web/goon-oxal-1/nav/js
::
/*  xterm-6-style                  %css   /lib/web/xterm-6/xterm/css
/*  xterm-6-lib                    %js    /lib/web/xterm-6/xterm/js
::
/*  favicon-egg  %png  /lib/web/assets/egg/png
/*  hawk-svg     %svg  /lib/web/assets/hawk/svg
::
::
|%
++  content-type
  |=  name=@tas
  ?+  name  !!
    %datastar            ['text/javascript' feather-1-datastar]
    %datastar            ['text/javascript' feather-1-datastar]
    %datastar-inspector  ['text/javascript' feather-1-datastar-inspector]
    %lit                 ['text/javascript' feather-1-lit]
    %da-ta               ['text/javascript' feather-1-da-ta]
    %iframe              ['text/javascript' feather-1-iframe]
    %textarea            ['text/javascript' feather-1-textarea]
    %text-editor         ['text/javascript' feather-1-text-editor]
    %layout-triptych     ['text/javascript' feather-1-layout-triptych]
    %layout-basic        ['text/javascript' feather-1-layout-basic]
    %slide-panels        ['text/javascript' feather-1-slide-panels]
  ==
+$  card  card:agent:gall
+$  state-0  [%0 ~]
+$  state-n  $%(state-0)
::
--
::
=|  state-0
=*  state  -
%-  agent:dbug
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    cor  ~(. +> [bowl ~])
++  on-init
  ::
  [~[bind-url-card] this]
  ::
++  on-load
  ::
  |=  ole=vase
  =/  try  (mole |.(!<(state-0 ole)))
  =?  state  ?=(^ try)  (need try)
  [~[bind-url-card] this]
  ::
++  on-poke
  ::
  |=  [=mark =vase]
  ^-  (quip card _this)
  =^  cards  state  abet:(poke:cor mark vase)
  :-  cards  this
  ::
++  on-fail
  ::
  |=  [=term =tang]
  ^-  (quip card _this)
  %-  (slog term tang)
  `this
  ::
++  on-watch
  ::
  |=  =path
  ^-  (quip card _this)
  =^  cards  state  abet:(watch:cor path)
  :-  cards  this
  ::
++  on-agent
  ::
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  =^  cards  state  abet:(agent:cor wire sign)
  :-  cards  this
  ::
++  on-save  !>  state
++  on-leave  |=(path ^*((quip card _this)))
++  on-peek   |=(path ~)
++  on-arvo
  ::
  |=  [=wire sign-arvo]
  *(quip card _this)
  ::
--
::
|_  [=bowl:gall cards=(list card)]
++  cor   .
++  abet  :-  (flop cards)  state
++  emit  |=  =card  cor(cards [card cards])
++  emil  |=  caz=(list card)  cor(cards (welp (flop caz) cards))
++  bind-url-card  [%pass /bind %arvo %e %connect [~ /new-oxal-init] %new-oxal-init]
::
++  watch
  ::
  |=  pax=path
  ^+  cor
  cor
  ::
++  agent
  ::
  |=  [=wire =sign:agent:gall]
  ^+  cor
  cor
  ::
++  poke
  ::
  |=  [=mark =vase]
  ^+  cor
  ?+  mark  ~|(bad-poke/mark !!)
    %handle-http-request  (handle-http-request !<([@ta inbound-request:eyre] vase))
  ==
  ::
++  lit-feather
  ::
  ^-  cord
  %^  cat  3
    %^  cat  3
      '''
      import { css } from '/new-oxal-init/feather/1/lit';
      export const feather = css`

      '''
    feather-1-style
  '''

  `;
  '''
++  handle-http-request
  |=  [rid=@ta req=inbound-request:eyre]
  ^+  cor
  =/  method=@tas   (crip (cass (trip method.request.req)))
  =/  [url-raw=path pams=(map @t @t)]        (parse-url url.request.req)
  =/  url=pith  (tail (pave url-raw))
  =/  action=@tas   (~(gut by pams) %action %$)
  =/  admin=@tas    ?:  =(our.bowl src.bowl)  %y  %n
  =/  route  [method admin action url]
  ::
  |^
    =/  =(each _cor tang)  (mule |.(static-routes))
    ?:  ?=([%.y *] each)  p.each
    %-  emil
    %+  payload-cards  rid
    :-  [500 ~[['Content-Type' 'text/plain']]]
    `(as-octt:mimes:html (print-tang p.each))
    ::
  ++  static-routes
    ^+  cor
    ?+  route=((pole) route)  ~|(unknown-static-route/route !!)
      [%get * %$ %assets rest=*]
        ::
        %-  emil
        =+  ?+  rest.route  !!
              [%favicon %egg ~]   ['image/png' favicon-egg]
              [%icons %hawk ~]    ['image/svg+xml' hawk-svg]
            ==
        (resource-payload-cards rid `~d100 -)
      [%get * %$ %feather [%ud %1] %style ~]
        ::
        %-  emil
        =+  ?:  (~(has by pams) 'lit')
              ['text/javascript' lit-feather]
            ['text/css' feather-1-style]
        (resource-payload-cards rid `~d2 -)
      [%get * %$ %feather [%ud %1] seg=@tas ~]
        ::
        %-  emil
        =+  (content-type seg.route)
        (resource-payload-cards rid `~d2 -)
      [%get * %$ %every-layout [%ud %1] %style ~]
        ::
        %-  emil
        (resource-payload-cards rid `~d2 ['text/css' every-layout-1-style])
      [%get * %$ %goon-oxal [%ud %1] %style ~]
        ::
        %-  emil
        (resource-payload-cards rid `~d2 ['text/css' goon-oxal-1-style])
      [%get * %$ %goon-oxal [%ud %1] %nav ~]
        ::
        %-  emil
        (resource-payload-cards rid `~d2 ['text/javascript' goon-oxal-1-nav])
      [%get * %$ %xterm [%ud %6] %style ~]
        ::
        %-  emil
        (resource-payload-cards rid `~d2 ['text/css' xterm-6-style])
      [%get * %$ %xterm [%ud %6] %lib ~]
        ::
        %-  emil
        (resource-payload-cards rid `~d2 ['text/javascript' xterm-6-lib])
    ==
  --
--
