::  /lib/burn-to-goad.hoon — produce a goad tree from burn state
::
::  Pure derivation: walks state and emits a canonical Hoon Native UI
::  goad. NEVER mutates state. Called from app/burn.hoon's
::  ++on-peek /x/goon. The vine (M6 — lib/vines/oxal--plex.hoon)
::  consumes the same goad over Eyre's %channel.
::
::  Goad shape (the "paper map"):
::    %plex
::      /library/sections/<key>/items/<rkey>/{seasons/<srkey>/episodes/<erkey>}
::      /downloads/<rid>
::      /settings/hosting/{url,token}
::      /settings/{allowed,invitations,sources}/<ship>
::      /about/<section>/<paragraph>
::
::  Hoon UI declares structure only — no expand/collapse semantics.
::  Children are present (loaded) or absent (unloaded). The renderer
::  decides accordion / inline / etc.
::::
/-  goon, burn
=,  goon
|%
::  +to-goad: top-level entry point. `host-ship` selects which ship's
::  library appears under /library:
::    - Self-host mode: caller passes our.bowl → sources[our.bowl]
::    - Subscriber mode: caller passes a remote host @p → sources[that ship]
::  Caller (app/burn.hoon) decides via +pick-host-ship. Multi-source
::  surfaces (e.g. /library/<ship>/...) are a next-run scry redesign.
::
++  to-goad
  |=  [s=state:burn host-ship=ship]
  ^-  goad
  =/  self-src=source-state:burn  (resolve s host-ship)
  :+  %plex
    ~[lede+'plex' info+'burn Hoon Native UI']
  ^-  (list goad)
  :~  (library self-src)
      (downloads s)
      (about ~)
      (settings s)
  ==
::
::  +resolve: get source-state for a ship; bunt entry if absent.
::
++  resolve
  |=  [s=state:burn =ship]
  ^-  source-state:burn
  =/  existing=(unit source-state:burn)  (~(get by sources.s) ship)
  ?^  existing  u.existing
  [ship %ok ~ ~ ~ ~]
::
::  +library: /library — wrapper containing /library/sections.
::
++  library
  |=  src=source-state:burn
  ^-  goad
  :+  %library  ~[lede+'library']
  ^-  (list goad)
  ~[(sections src)]
::
::  +sections: /library/sections — one child per library-section.
::
++  sections
  |=  src=source-state:burn
  ^-  goad
  :+  %sections  ~[lede+'sections']
  ^-  (list goad)
  %+  murn  sections.src
  |=  ls=library-section:burn
  ^-  (unit goad)
  =/  cached  (~(get by items.src) key.ls)
  ::  Hide sections that have been fetched and returned zero items.
  ::  Sections not yet in the cache (loading) still emit so the UI shows
  ::  them populating progressively.
  ?:  ?&(?=(^ cached) =(~ u.cached))  ~
  :-  ~
  :+  key.ls
    :~  lede+title.ls
        info+(rap 3 'section type: ' type.ls ~)
    ==
  ~[(items src ls)]
::
::  +items: /library/sections/<key>/items — one child per item.
::
++  items
  |=  [src=source-state:burn ls=library-section:burn]
  ^-  goad
  =/  cached  (~(get by items.src) key.ls)
  :+  %items
    ?:  ?=(~ cached)
      :~  lede+'items'
          (load-attr 'load items for this section' 'load items')
      ==
    ~[lede+'items']
  ^-  (list goad)
  ?~  cached  ~
  %+  turn  u.cached
  |=  it=library-item:burn
  (item src it)
::
::  +poster-child: emit a %poster child node carrying the thumbnail URL.
::  Convention: iota=%poster, value+url attr. The URL includes ?w=&h=
::  dimension hints so Plex transcodes/cache-keys the right variant while
::  renderers can let intrinsic media dimensions determine display shape.
::
++  poster-child
  |=  [thumb=@t kind=@tas]
  ^-  goad
  :+  %poster  ~[value+(poster-url thumb kind)]
  ~
::
::  +poster-url: build the canonical /apps/burn URL the renderer emits
::  on <img> tags AND the cache key the prefetch arms in burn.hoon
::  must populate. Same URL string both sides → Eyre cache hit on first
::  browser request. Kinds: %tall (movies/shows/seasons, 2:3), %wide
::  (episodes, 16:9), %square (albums/artists, 1:1).
::
++  poster-url
  |=  [thumb=@t kind=@tas]
  ^-  @t
  =/  dims=tape
    ?+  kind  "w=200&h=300"
      %wide    "w=320&h=180"
      %square  "w=300&h=300"
    ==
  (rap 3 '/apps/burn' thumb '?' (crip dims) ~)
::
::  +library-item-kind: aspect-kind dispatch on item.type. Mirrors the
::  inline logic in +item (around line 230) so prefetch + cache-key
::  derivation share the same mapping.
::
++  library-item-kind
  |=  type=@t
  ^-  @tas
  ?:  =('album' type)   %square
  ?:  =('artist' type)  %square
  ?:  =('track' type)   %square
  %tall
::
::  +prepend-poster: if thumb is non-empty, prepend a poster-child to the
::  existing kid list; otherwise return kids unchanged. Single source of
::  truth for the convention used by +item, +season, and the per-episode
::  block of +episodes. Kind controls aspect ratio (%tall=2:3 movie/show
::  poster, %wide=16:9 episode still, %square=1:1 album art).
::
++  prepend-poster
  |=  [thumb=@t kind=@tas base=(list goad)]
  ^-  (list goad)
  ?:  =('' thumb)  base
  [(poster-child thumb kind) base]
::
::  +summary-child / +prepend-summary: a %summary iota child carries the
::  long-form description in its value attr. Mirrors %poster convention —
::  iota name, single value+text attr, no own kids. Renderer extracts via
::  +partition-summary into the summary slot of palm-detail. Empty cord
::  emits NOTHING so the renderer's :empty slot rule reserves space.
::
++  summary-child
  |=  text=@t
  ^-  goad
  :+  %summary  ~[value+text]
  ~
::
++  prepend-summary
  |=  [text=@t base=(list goad)]
  ^-  (list goad)
  ?:  =('' text)  base
  [(summary-child text) base]
::
::  +tagline-child / +prepend-tagline: a %tagline iota child carries the
::  short marketing tagline. Same shape as summary-child.
::
++  tagline-child
  |=  text=@t
  ^-  goad
  :+  %tagline  ~[value+text]
  ~
::
++  download-child
  |=  rkey=@t
  ^-  goad
  :+  %download  ~[value+(rap 3 '/apps/burn/download/' rkey ~)]
  ~
::
++  load-attr
  |=  [info=@t lede=@t]
  ^-  attr
  [%act `(list act)`~[[%load info lede]]]
::
++  prepend-tagline
  |=  [text=@t base=(list goad)]
  ^-  (list goad)
  ?:  =('' text)  base
  [(tagline-child text) base]
::
::  +fmt-duration: cord milliseconds → "Nm" or "NhMm". Empty cord → ''.
::  Crash-safe parse via +rush+dem; malformed input degrades to '' rather
::  than blowing up render.
::
++  fmt-duration
  |=  ms=@t
  ^-  @t
  ?:  =('' ms)  ''
  =/  parsed=(unit @ud)  (rush ms dem)
  ?~  parsed  ''
  =/  total-min=@ud  (div u.parsed 60.000)
  ?:  (lth total-min 60)
    (rap 3 (scot %ud total-min) 'm' ~)
  =/  hrs=@ud   (div total-min 60)
  =/  mins=@ud  (mod total-min 60)
  (rap 3 (scot %ud hrs) 'h ' (scot %ud mins) 'm' ~)
::
::  +fmt-bytes: byte count cord -> "1.2 GB", "526.0 MB", etc.
::  Empty/malformed size degrades to ''.
::
++  fmt-bytes
  |=  raw=@t
  ^-  @t
  ?:  =('' raw)  ''
  =/  parsed=(unit @ud)  (rush raw dem)
  ?~  parsed  ''
  =/  n=@ud  u.parsed
  =/  kb=@ud  1.024
  =/  mb=@ud  (mul kb kb)
  =/  gb=@ud  (mul mb kb)
  ?:  (gte n gb)
    =/  whole=@ud  (div n gb)
    =/  frac=@ud  (div (mul (mod n gb) 10) gb)
    (crip "{(a-co:co whole)}.{(a-co:co frac)} GB")
  ?:  (gte n mb)
    =/  whole=@ud  (div n mb)
    =/  frac=@ud  (div (mul (mod n mb) 10) mb)
    (crip "{(a-co:co whole)}.{(a-co:co frac)} MB")
  ?:  (gte n kb)
    =/  whole=@ud  (div n kb)
    =/  frac=@ud  (div (mul (mod n kb) 10) kb)
    (crip "{(a-co:co whole)}.{(a-co:co frac)} KB")
  (crip "{(a-co:co n)} B")
::
::  +join-info: " · "-join a list of cord segments, skipping empties.
::
++  join-info
  |=  parts=(list @t)
  ^-  @t
  =/  filtered=(list @t)  (skim parts |=(p=@t !=('' p)))
  ?~  filtered  ''
  =/  out=@t  i.filtered
  =/  rest=(list @t)  t.filtered
  |-  ^-  @t
  ?~  rest  out
  $(out (rap 3 out ' · ' i.rest ~), rest t.rest)
::
::  +rating-segment: '★ N' if rating non-empty, else ''.
::
++  rating-segment
  |=  rating=@t
  ^-  @t
  ?:  =('' rating)  ''
  (rap 3 '★ ' rating ~)
::
::  +item: /library/sections/<key>/items/<rkey> — one library item.
::
::  Show items get /seasons child only if seasons map is populated
::  for this rkey. Movies and other types never carry /seasons.
::  Non-empty thumb produces a leading %poster child consumed by the
::  web renderer as a cover-card visual.
::
++  item
  |=  [src=source-state:burn it=library-item:burn]
  ^-  goad
  =/  info-text=@t
    ?:  =('movie' type.it)
      %-  join-info
      :~  year.it
          (fmt-duration duration.it)
          (fmt-bytes size.it)
          (rating-segment rating.it)
          genre.it
      ==
    %-  join-info
    :~  year.it
        (rating-segment rating.it)
        genre.it
    ==
  =/  base-attrs=(list attr)
    :~  lede+title.it
        info+info-text
        value+title.it
    ==
  =/  season-cache=(unit (list season-item:burn))
    ?.  =('show' type.it)  ~
    (~(get by seasons.src) rating-key.it)
  =/  album-cache=(unit (list season-item:burn))
    ?.  =('artist' type.it)  ~
    (~(get by seasons.src) rating-key.it)
  =/  track-cache=(unit (list episode-item:burn))
    ?.  =('album' type.it)  ~
    (~(get by episodes.src) rating-key.it)
  =/  download-attr=attr
    [%act `(list act)`~[[%download 'download this item' 'download']]]
  =/  load-seasons-attr=attr
    (load-attr 'load seasons for this show' 'load seasons')
  =/  load-albums-attr=attr
    (load-attr 'load albums for this artist' 'load albums')
  =/  load-tracks-attr=attr
    (load-attr 'load tracks for this album' 'load tracks')
  =/  attrs=(list attr)
    ?:  =('show' type.it)
      ?~  season-cache
        (snoc base-attrs load-seasons-attr)
      base-attrs
    ?:  =('artist' type.it)
      ?~  album-cache
        (snoc base-attrs load-albums-attr)
      base-attrs
    ?:  =('album' type.it)
      ?~  track-cache
        (snoc base-attrs load-tracks-attr)
      base-attrs
    (snoc base-attrs download-attr)
  =/  season-kids=(list goad)
    ?~  season-cache  ~
    ~[(seasons src rating-key.it u.season-cache)]
  =/  album-kids=(list goad)
    ?~  album-cache  ~
    ~[(albums src rating-key.it u.album-cache)]
  =/  track-kids=(list goad)
    ?~  track-cache  ~
    ~[(tracks u.track-cache)]
  ::  %act declares the intent; %download child carries the href required
  ::  by web renderers that need native browser file-save behavior.
  =/  download-kids=(list goad)
    ?:  =('show' type.it)    season-kids
    ?:  =('artist' type.it)  album-kids
    ?:  =('album' type.it)   track-kids
    [(download-child rating-key.it) ~]
  =/  with-summary=(list goad)  (prepend-summary summary.it download-kids)
  =/  with-tagline=(list goad)  (prepend-tagline tagline.it with-summary)
  [rating-key.it attrs (prepend-poster thumb.it (library-item-kind type.it) with-tagline)]

::
::  +albums: /library/sections/<key>/items/<artist-rkey>/albums — one child per album.
::
++  albums
  |=  [src=source-state:burn artist-rkey=@t as=(list season-item:burn)]
  ^-  goad
  :+  %albums  ~[lede+'albums']
  ^-  (list goad)
  %+  turn  as
  |=  al=season-item:burn
  (album src al)
::
::  +album: /library/.../albums/<album-rkey>.
::
++  album
  |=  [src=source-state:burn al=season-item:burn]
  ^-  goad
  =/  base-attrs=(list attr)
    :~  lede+title.al
        info+'album'
    ==
  =/  track-kids=(list goad)
    =/  cached  (~(get by episodes.src) rating-key.al)
    ?~  cached  ~
    ~[(tracks u.cached)]
  =/  load-tracks-attr=attr
    (load-attr 'load tracks for this album' 'load tracks')
  =/  attrs=(list attr)
    ?:  =(~ track-kids)
      (snoc base-attrs load-tracks-attr)
    base-attrs
  =/  with-summary=(list goad)  (prepend-summary summary.al track-kids)
  [rating-key.al attrs (prepend-poster thumb.al %square with-summary)]
::
::  +seasons: /library/sections/<key>/items/<rkey>/seasons — one child per season.
::
++  seasons
  |=  [src=source-state:burn show-rkey=@t ss=(list season-item:burn)]
  ^-  goad
  :+  %seasons  ~[lede+'seasons']
  ^-  (list goad)
  %+  turn  ss
  |=  se=season-item:burn
  (season src se)
::
::  +season: /library/sections/<key>/items/<rkey>/seasons/<srkey>.
::
::  /episodes child only if episodes map is populated for this srkey.
::
++  season
  |=  [src=source-state:burn se=season-item:burn]
  ^-  goad
  =/  base-attrs=(list attr)
    :~  lede+title.se
        info+(rap 3 'Season ' index.se ~)
    ==
  =/  episode-kids=(list goad)
    =/  cached  (~(get by episodes.src) rating-key.se)
    ?~  cached  ~
    ~[(episodes u.cached)]
  =/  load-episodes-attr=attr
    (load-attr 'load episodes for this season' 'load episodes')
  =/  attrs=(list attr)
    ?:  =(~ episode-kids)
      (snoc base-attrs load-episodes-attr)
    base-attrs
  =/  with-summary=(list goad)  (prepend-summary summary.se episode-kids)
  [rating-key.se attrs (prepend-poster thumb.se %tall with-summary)]
::
::  +episodes: /library/.../seasons/<srkey>/episodes — one child per episode.
::
++  episodes
  |=  es=(list episode-item:burn)
  ^-  goad
  :+  %episodes  ~[lede+'episodes']
  ^-  (list goad)
  %+  turn  es
  |=  ep=episode-item:burn
  ^-  goad
  =/  info-text=@t
    %-  join-info
    :~  (rap 3 'Ep ' index.ep ~)
        (fmt-duration duration.ep)
        (fmt-bytes size.ep)
    ==
  =/  download-attr=attr
    [%act `(list act)`~[[%download 'download this episode' 'download']]]
  =/  attrs=(list attr)
    :~  lede+title.ep
        info+info-text
        download-attr
    ==
  ::  Pair the semantic %download action with the URL slot the web renderer
  ::  needs for a native <a download>.
  =/  with-download=(list goad)  ~[(download-child rating-key.ep)]
  =/  with-summary=(list goad)  (prepend-summary summary.ep with-download)
  [rating-key.ep attrs (prepend-poster thumb.ep %wide with-summary)]
::
::  +tracks: /library/.../albums/<album-rkey>/tracks — one child per track.
::
++  tracks
  |=  ts=(list episode-item:burn)
  ^-  goad
  :+  %tracks  ~[lede+'tracks']
  ^-  (list goad)
  %+  turn  ts
  |=  tr=episode-item:burn
  ^-  goad
  =/  info-text=@t
    %-  join-info
    :~  ?:  =('' index.tr)  ''  (rap 3 'Track ' index.tr ~)
        (fmt-duration duration.tr)
        (fmt-bytes size.tr)
    ==
  =/  download-attr=attr
    [%act `(list act)`~[[%download 'download this track' 'download']]]
  =/  attrs=(list attr)
    :~  lede+title.tr
        info+info-text
        download-attr
    ==
  =/  with-download=(list goad)  ~[(download-child rating-key.tr)]
  =/  with-summary=(list goad)  (prepend-summary summary.tr with-download)
  [rating-key.tr attrs (prepend-poster thumb.tr %square with-summary)]
::
::  +downloads: /downloads — one child per pending-streams entry.
::
::  Anti-criteria: byte/cursor ticks do NOT show here as fact emissions.
::  This branch shows the snapshot at goad-construction time only;
::  M5 ships /goon/progress/<rid> for live byte ticks.
::
++  downloads
  |=  s=state:burn
  ^-  goad
  :+  %downloads  ~[lede+'downloading']
  ^-  (list goad)
  %+  turn  ~(tap by pending-streams.s)
  |=  [rid=@uv ss=stream-state:burn]
  ^-  goad
  =/  node-id=@ta  (scot %uv rid)
  =/  bytes=@t
    %-  crip
    "{((d-co:co 1) emitted.ss)}/{((d-co:co 1) total-size.ss)}"
  =/  attrs=(list attr)
    :~  lede+display-name.ss
        info+(rap 3 bytes ' bytes' ~)
        value+bytes
        :-  %act
        :~  [%cancel 'cancel' 'cancel this download']
        ==
    ==
  [node-id attrs ~]
::
::  +about: /about — static explanatory copy for the web renderer.
::
++  about-section
  |=  [id=@tas title=@t article-body=@t]
  ^-  goad
  :+  id
    :~  lede+title
        [%value `@t`article-body]
    ==
  ~
::
++  about
  |=  ~
  ^-  goad
  :+  %about  ~[lede+'about']
  (about-articles ~)
::
++  about-articles
  |=  ~
  ^-  (list goad)
  =/  navigation-body=@t
'''
Use arrow keys to move around. WASD and vim `jkhl` also work.

Think of the interface as a tree:

- up/down moves between siblings
- right drills into a branch for more detail
- left drills out toward larger sections
- enter interacts with action buttons and text fields
- esc exits text fields and drills out like left

For vim folks, `i` jumps into a text field to start inserting text.
'''
  =/  plex-share-body=@t
'''
Hello, I'm nord bird. At my house I run a Plex server that plays local movie and TV files like a standard streaming service.

That is a good way to actually own your entertainment.

The hard part is sharing it. My home Internet is slow and out of my control. I cannot make my Plex server public to the Internet at large, and it would not do a good job streaming anyway.

So plex-share does three things:

- talks to my Plex server at home
- displays what is available on this webpage
- lets people with access download the files

The pieces that make this possible are `hawk`, `goon`, directed messaging, and Urbit.
'''
  =/  download-body=@t
'''
First of all, get comfy. These downloads can take awhile.

Kiki's Delivery Service was my first 2.3GB movie to download. It took 17hrs.

The slowness has nothing to do with directed messaging. That works great. My residential Internet upload speed is just abysmal, which is a fact of peer-to-peer networking.

So settle in and let it download overnight.

If the download pauses, use your browser's download manager to resume it.

## access

- Urbit users can login at the top right using eauth.
- People without an Urbit can use the passcode I gave them.
- The passcode is prompted after every click of the download button.
- Your download and Urbit ID will be publicly displayed as a fun gag for the demo.

## limits

- Only one download at a time.
- There is no queue for the next download, so be ready when one completes.
- Regular maintenance will be required.

Every movie passing through the two urbits involved increases the size of both until storage fills up. I will regularly have to shut both down and reduce their size, so this demo may be short lived or more restrictive.
'''
  =/  hawk-body=@t
'''
Go to hawk.computer.

Hawk is an elegant personal website builder built on Urbit. It is elegant because the tool and location in which the website is built is one and the same.

You can build and serve anything you want. No need for WordPress, Squarespace, or anything like that. It is totally yours.

plex-share is another Urbit app which Hawk communicates with to create and serve this webpage here at this URL.

Note on oxal: truth be told this particular project was built on an offshoot of Hawk called oxal. Oxal is a clever way to structure data in the Urbit world so that all parts of that data are maximally useful and comprehensible, in a computer science sense, across the network.

It is very promising and includes an overlap of functionality with Hawk in serving websites. But in reality plex-share could, and will, be ported over to Hawk in an upcoming update.
'''
  =/  goon-body=@t
'''
Goon is a specification for Urbit user interfaces developed by Liam Fitzgerald.

See the GitHub repo: https://github.com/liam-fitzgerald/goon

The genius with goon is that it specifies a way in which app developers can describe exactly what matters about a UI for their app without actually designing the look.

Developers put into their app all the relevant info about actions a user can take and the text which should be displayed. After this it is up to a second bit of software, called a renderer, to receive the goon-shaped UI info from an app, any app, and display it with its chosen aesthetic.

plex-share outputs goon and Hawk holds several libraries that make up a goon renderer. It is a prototype of my creation to stretch the possibilities of a goon renderer and see what all it would need.

One key factor in this Hawk goon renderer is Every Layout. If you have ever fought CSS to center a div, check out https://every-layout.dev/

Heydon Pickering and Andy Bell created a complete set of CSS layouts which actually flows like water with browsers. Before Every Layout I would not have thought a renderer would be feasible.
'''
  =/  directed-body=@t
'''
The Urbit network is peer to peer. This means when your Urbit wishes to communicate with another, it asks its sponsor for a direct line. Once received, only those two urbits are involved in the communication.

The Urbit network is called Ames.

Ames has undergone major improvements called directed messaging, or mesa. Historically Ames has been very slow, but with directed messaging it has gained a 100x boost.

This essentially allows for the potential of maxing out upload and download speeds between any two urbits.

With this speed up it became plausible that large files, like 2GB movies, could be sent over Ames. This is big because by default my Plex server is inaccessible to the public Internet. However, urbits have means to navigate around the thing that blocks my computer.

Therefore, by putting an Urbit on the same computer as my Plex server I can grant access to it from anywhere via the Urbit network. If someone else had the plex-share app they could potentially make requests to my Plex server.

This website is served from a second Urbit in the cloud which is subscribed to my local Urbit and which has permission to make download requests. I am making that second Urbit publicly visible.
'''
  =/  urbit-body=@t
'''
Urbit is a reinvention of computers from the ground up. But this time it was created with the foresight that all computers should be networked over an internet.

Back when computers filled entire rooms it was hard to envision people using the computer without being in that room, or that the computer would wish to connect to millions of others, or that the computer would ever change addresses and still wish to have the same identity.

Urbit holistically solves our modern issues by making the computer a simple folder you can transfer to and run from any physical computer.

Giving that computer a permanent identity means you can always know you are talking to the same computer. No two factor verification needed.

Along with this comes the ability to change a computer's address without changing its identity. This is critical for mobile devices like laptops.

Put simply, without Urbit you, an average person, have not been able to send a file directly from one computer to another. But now you can.

When a movie is downloaded from this site, an Urbit from my computer at home is sending that movie directly, peer-to-peer style, to another Urbit which is serving this website and which will deliver the movie via the browser download.
'''
  :~  (about-section %navigation 'navigation' navigation-body)
      (about-section %plex-share 'what is plex-share?' plex-share-body)
      (about-section %hawk '1. hawk' hawk-body)
      (about-section %goon '2. goon' goon-body)
      (about-section %directed-messaging '3. directed messaging' directed-body)
      (about-section %how-to-download 'how to download' download-body)
      (about-section %urbit '4. urbit' urbit-body)
  ==
::
++  settings
  |=  s=state:burn
  ^-  goad
  :+  %settings  ~[lede+'settings']
  ^-  (list goad)
  :~  (settings-hosting s)
      (settings-allowed s)
      (settings-invitations s)
      (settings-sources s)
  ==
::
::  +settings-hosting: /settings/hosting — url + token, both editable.
::
++  settings-hosting
  |=  s=state:burn
  ^-  goad
  =/  url-val=@t   ?~(hosting.s default-plex-url:burn url.u.hosting.s)
  =/  token-val=@t  ?~(hosting.s '' token.u.hosting.s)
  :+  %hosting  ~[lede+'hosting']
  ^-  (list goad)
  :~  ^-  goad
      :+  %url
        :~  lede+'plex server url'
            value+url-val
            [%edit ~]
        ==
      ~
      ^-  goad
      :+  %token
        :~  lede+'plex server token'
            value+token-val
            [%edit ~]
        ==
      ~
  ==
::
::  +settings-allowed: /settings/allowed — one child per guest ship.
::
++  settings-allowed
  |=  s=state:burn
  ^-  goad
  =/  guest-children=(list goad)
    %+  turn  ~(tap by allowed.s)
    |=  [=ship gc=guest-config:burn]
    ^-  goad
    :+  (scot %p ship)
      :~  lede+(scot %p ship)
          info+(rap 3 'label: ' label.gc ~)
          value+(scot %p ship)
          :-  %act
          :~  [%deny 'deny' 'remove this guest']
          ==
      ==
    ~
  ::  %add affordance: invite a new guest by typing their @p. Wired in
  ::  ++translate-stab-to-action under [%settings %allowed ~] %add → %allow.
  =/  invite-node=goad
    :+  %new
      :~  lede+'invite ship (e.g. ~sampel-palnet)'
          [%add ~]
      ==
    ~
  :+  %allowed  ~[lede+'allowed guests']
  (snoc guest-children invite-node)
::
::  +settings-invitations: /settings/invitations — one child per invitation.
::
++  settings-invitations
  |=  s=state:burn
  ^-  goad
  :+  %invitations  ~[lede+'invitations']
  ^-  (list goad)
  %+  turn  ~(tap by invitations.s)
  |=  [=ship inv=invitation:burn]
  ^-  goad
  =/  status-cord=@t
    ?-  status.inv
      %pending   'pending'
      %accepted  'accepted'
      %declined  'declined'
    ==
  ::  Pending invitations get an accept button. Accepted/declined are
  ::  display-only — the agent's %accept-invitation auto-subscribes,
  ::  so once accepted it appears under /settings/sources too.
  =/  attrs=(list attr)
    ?:  =(%pending status.inv)
      :~  lede+(scot %p ship)
          info+(rap 3 'status: ' status-cord ~)
          value+(scot %p ship)
          :-  %act
          :~  [%accept 'accept' 'accept this invitation and subscribe']
          ==
      ==
    :~  lede+(scot %p ship)
        info+(rap 3 'status: ' status-cord ~)
        value+(scot %p ship)
    ==
  [(scot %p ship) attrs ~]
::
::  +settings-sources: /settings/sources — one child per subscribed source.
::
++  settings-sources
  |=  s=state:burn
  ^-  goad
  :+  %sources  ~[lede+'subscribed sources']
  ^-  (list goad)
  %+  turn  ~(tap by sources.s)
  |=  [=ship src=source-state:burn]
  ^-  goad
  =/  saga-cord=@t
    ?-  saga.src
      %ok        'ok'
      %mismatch  'mismatch'
      %pending   'pending'
    ==
  :+  (scot %p ship)
    :~  lede+(scot %p ship)
        info+(rap 3 'saga: ' saga-cord ~)
        value+(scot %p ship)
    ==
  ~
--
