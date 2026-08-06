::  /ted/fetch-plex-items.hoon — fetch library items from plex-hawk
::
::  Pokes local plex-hawk with %fetch-items, subscribes to
::  /library/items/[key] for the response. Returns item list as noun.
::
::  Usage from raw view:
::  [%pass /wire %arvo %k %fard %plex-hawk %fetch-plex-items %noun !>(key)]
::
/-  spider
/+  strandio
=,  strand=strand:spider
=,  strandio
|=  args=vase
=/  m  (strand ,vase)
^-  form:m
=/  section-key=@t  !<(@t args)
~&  >  "fetch-plex-items: starting for section {<section-key>}"
::  poke local plex-hawk with fetch-items action
;<  our=@p  bind:m  get-our
;<  ~  bind:m
  (poke [our %plex-hawk] %noun !>([%fetch-items section-key]))
~&  >  "fetch-plex-items: poked, subscribing for response"
::  subscribe and wait for one fact
;<  =cage  bind:m
  %:  watch-one
    /items/[section-key]
    [our %plex-hawk]
    /library/items/[section-key]
  ==
~&  >  "fetch-plex-items: received items fact"
(pure:m q.cage)
