::  sur/burn.hoon — types for %burn agent
::
::  Ames protocol for host/subscriber media sharing via Urbit identity.
::
|%
::  Protocol version for epic negotiation. Reset to 0 — burn starts
::  fresh; no migration history to preserve.
::
++  okay  `@ud`0
::
++  default-plex-url  `@t`'http://localhost:32400'
::
::  Buffered chunk for trickle-pace download delivery. The %proxy-chunk
::  subsequent-branch stores the full chunk here; the /dl-trickle behn
::  arm peels off slices and emits %http-response-data cards on a steady
::  cadence so the Vere HTTP-response idle timer doesn't fire between
::  chunks (which arrive over Mesa more slowly than Vere's ~46s ceiling
::  on slow upstream pipes). See trickle-pace PRD 20260427-200000.
::
+$  buffered-chunk
  $:  bytes=octs                               ::  full chunk bytes
      cursor=@ud                               ::  next byte offset to emit
      final=?                                  ::  was this the last chunk?
  ==
::
::  Library section metadata (parsed from Plex /library/sections)
::
+$  library-section
  $:  key=@t                                   ::  Plex section key (e.g. '1', '2')
      title=@t                                 ::  Section title (e.g. 'movies')
      type=@t                                  ::  Section type (e.g. 'movie', 'show')
  ==
::
::  Library item metadata (parsed from Plex /library/sections/[key]/all)
::
+$  library-item
  $:  rating-key=@t                            ::  Plex ratingKey (unique ID)
      title=@t                                 ::  item title
      year=@t                                  ::  release year
      type=@t                                  ::  'movie' or 'show'
      rating=@t                                ::  critic rating ('' if absent)
      thumb=@t                                 ::  Eyre-relative thumb URL or ''
      watched=?                                ::  has viewCount > 0
      duration=@t                              ::  duration in ms ('' for shows)
      summary=@t                               ::  long-form description ('' if absent; scag-1000 capped at parse)
      genre=@t                                 ::  ' · '-joined top genres ('' if absent)
      tagline=@t                               ::  short tagline ('' if absent)
      size=@t                                  ::  media file size in bytes as text ('' if unknown/non-downloadable)
  ==
::
::  Season metadata (parsed from Plex /library/metadata/<show-rkey>/children
::  Directory entries — one per season). Lazy-fetched on UI expansion.
::
+$  season-item
  $:  rating-key=@t                            ::  Plex ratingKey for the season
      title=@t                                 ::  e.g. 'Season 1'
      index=@t                                 ::  season number as cord
      thumb=@t                                 ::  Eyre-relative thumb URL or ''
      summary=@t                               ::  season-level summary ('' if absent; scag-1000 capped at parse)
  ==
::
::  Episode metadata (parsed from Plex /library/metadata/<season-rkey>/children
::  Video entries — one per episode). Lazy-fetched on UI expansion.
::
+$  episode-item
  $:  rating-key=@t                            ::  Plex ratingKey for the episode
      title=@t                                 ::  episode title
      index=@t                                 ::  episode number as cord
      thumb=@t                                 ::  Eyre-relative thumb URL or ''
      duration=@t                              ::  duration in ms
      watched=?                                ::  has viewCount > 0
      summary=@t                               ::  per-episode summary ('' if absent; scag-1000 capped at parse)
      size=@t                                  ::  media file size in bytes as text ('' if unknown)
  ==
::
::  Tracking for internal fetches
::
+$  internal-fetch
  $:  tag=@tas                                 ::  e.g. %library-sections, %library-items
      key=@t                                   ::  section key for item fetches
      requested=@da                            ::  when the fetch was initiated
  ==
::
::  Plex server configuration (local server the host proxies)
::
+$  plex-config
  $:  url=@t                                   ::  e.g. 'http://localhost:32400'
      token=@t                                 ::  X-Plex-Token
  ==
::
::  State of a remote source we're subscribed to
::
+$  source-state
  $:  =ship                                    ::  host ship @p (our.bowl for self-host entry)
      saga=?(%ok %mismatch %pending)           ::  epic sync status
      sections=(list library-section)          ::  cached library metadata
      items=(map @t (list library-item))       ::  section key → items
      seasons=(map @t (list season-item))      ::  show rkey → seasons
      episodes=(map @t (list episode-item))    ::  season rkey → episodes
  ==
::
::  Per-subscriber guest identity
::
+$  guest-config
  $:  token=@t                                 ::  Plex managed user token ('' = use host token)
      label=@t                                 ::  display name for this guest
  ==
::
::  Invitation from host to subscriber
::
+$  invitation
  $:  from=ship                                ::  host ship who sent the invite
      sent=@da                                 ::  when invitation was sent
      status=?(%pending %accepted %declined)   ::  invitation state
  ==
::
::  Pending proxy entry with timestamp for timeout sweep
::
+$  proxy-entry
  $:  eyre-id=@ta                              ::  Eyre request id
      sent=@da                                 ::  when proxy was initiated
  ==
::
::  L3 parallel-chunks: per-flow assignment record. Each burn download
::  runs up to ++max-flows concurrent fetches; this struct tracks one
::  flow's status and the chunk-seq it's currently fetching (only
::  meaningful when %in-flight). Original "warm-bones" theory rejected
::  2026-05-01; speedup mechanism unverified but code is load-bearing
::  for out-of-order chunk handling under concurrent dispatch.
::
+$  flow-state
  $:  status=?(%idle %in-flight)
      seq=@ud                                  ::  chunk-seq this flow is fetching when %in-flight
  ==
::
::  Generic media path for an active download. The library cache still
::  stores Plex's concrete hierarchy, but live download metadata should
::  carry a path of typed nodes instead of TV-specific fields. Art URLs
::  are canonical /apps/burn thumbnail variants; width/height describe
::  the chosen variant so renderers can use ;shape[intrinsic] without
::  inferring shape from media kind, container, or query strings.
::
+$  media-art
  $:  url=@t
      width=@ud
      height=@ud
  ==
::
+$  media-node-ref
  $:  kind=@tas                                ::  %movie %show %season %episode %artist %album %track %unknown
      label=@t
      art=(unit media-art)
      index=@t                                 ::  episode/track/season index, '' when not meaningful
  ==
::
+$  media-path
  $:  ancestors=(list media-node-ref)          ::  root→parent path, e.g. show/season or artist/album
      item=media-node-ref                      ::  downloadable item node
  ==
::
::  Per-stream state — tracks one in-flight chunked transfer end-to-end.
::  Active-or-gone model: membership in pending-streams IS the lifecycle
::  signal for a single Eyre stream. Browser resumes create a fresh stream
::  with start-byte set from Range; earlier bytes stay browser-owned.
::
+$  stream-state
  $:  eyre-id=@ta                              ::  Eyre request ID
      host=ship                                ::  host ship delivering chunks
      initiator=ship                           ::  ship that initiated this stream (src.bowl at creation); auth gate for %cancel-stream
      url=@t                                   ::  original request URL
      started=@da                              ::  src.now at stream acceptance; UI elapsed-time anchor
      total-size=@ud                           ::  Content-Length captured from Plex (correctness gate; 0 if unknown)
      received=@ud                             ::  bytes received from host
      chunk-size=@ud                           ::  bytes per chunk
      start-byte=@ud                           ::  browser-requested response start byte; 0 for normal 200 downloads
      seq=@ud                                  ::  next expected sequence number
      sent-header=?                            ::  have we sent %http-response-header?
      emitted=@ud                              ::  bytes shipped to browser (separate from received)
      display-name=@t                          ::  raw title for Content-Disposition (UTF-8 percent-encoded at emit time)
      media-path=media-path                    ::  generic art/context path for live-strip rendering
      container=@tas                           ::  file extension as @tas; %$ = unknown (no extension)
      ::  L3 parallel-chunks:
      flows=(map @ud flow-state)               ::  flow-id → flow-state; ~ on bunt
  ==
::
::  Agent state. Show → Season → Episode hierarchy lives inside
::  source-state.seasons / source-state.episodes, keyed by ship
::  (our.bowl for self-host; remote-host @p for subscriber mirrors).
::  Eager cascade now extends through episodes via %fetch-show-children
::  → %fetch-season-children; thumb URLs enqueue at each fetch level
::  for serial prefetch into Eyre cache (one in-flight at a time;
::  internal-pending tracks the in-flight rid → URL mapping).
::
+$  state
  $:  %0
      hosting=(unit plex-config)               ::  ~ if not hosting
      allowed=(map ship guest-config)          ::  subscriber → guest identity
      sources=(map ship source-state)          ::  remote hosts we subscribe to
      pending-proxies=(map @uv proxy-entry)    ::  rid → entry with timestamp
      pending=(map @t @t)                      ::  wire-hash → original URL
      invitations=(map ship invitation)        ::  received invitations
      proxy-timeout=@dr                        ::  max age for pending proxies
      pending-streams=(map @uv stream-state)   ::  rid → chunked stream
      internal-pending=(map @uv internal-fetch) ::  rid → internal fetch tracking
      thumb-queue=(list @t)                    ::  URLs to prefetch (host + subscriber)
      deferred-headers=(map @uv [eyre-id=@ta dl-rh=response-header:http])
      octs-buffer=(map @uv buffered-chunk)     ::  rid → in-flight chunk bytes
      stream-arrivals=(map @uv @da)            ::  rid → last chunk arrival time
      reassembly=(map @uv (map @ud octs))      ::  rid → seq → out-of-order parked chunks
      final-seq=(map @uv @ud)                  ::  rid → highest-seq (final sentinel)
      ::  Library cache lives in source-state.sections/items/seasons/episodes,
      ::  keyed by ship: our.bowl for self-host, src.bowl for subscriber mirrors.
      ::  INVARIANT: delete pending-streams entries ONLY via +delete-stream
      ::  in app/burn.hoon (single audit point that ALSO reaps
      ::  stream-arrivals/deferred-headers/octs-buffer/reassembly/final-seq).
      ::  Direct `del by pending-streams` orphans parallel maps.
  ==
::
::  Actions the agent accepts
::
+$  action
  $%  [%set-host =plex-config]                 ::  configure local Plex server
      [%clear-host ~]                          ::  stop hosting
      [%allow ships=(list ship)]               ::  permit subscribers
      [%deny ships=(list ship)]                ::  revoke subscribers
      [%set-guest =ship token=@t label=@t]     ::  assign guest identity
      [%remove-guest =ship]                    ::  remove guest identity
      [%subscribe =ship]                       ::  watch a remote host's plex
      [%unsubscribe =ship]                     ::  stop watching a remote host
      [%send-invitation =ship]                 ::  host→subscriber: send invite
      [%accept-invitation =ship]               ::  subscriber: accept invite
      [%revoke-invitation =ship]               ::  host: revoke invitation
      $:  %proxy-request                       ::  subscriber→host: proxy API call
          =ship                                ::  target host
          rid=@uv                              ::  request correlation id
          method=method:http                   ::  HTTP method
          url=@t                               ::  API path
          headers=header-list:http             ::  request headers
          body=(unit octs)                     ::  request body
          flow-id=@ud                          ::  L3: flow assignment (default 0 = N=1 base case)
      ==
      $:  %proxy-response                      ::  host→subscriber: proxy result
          rid=@uv                              ::  request correlation id
          status=@ud                           ::  HTTP status code
          headers=header-list:http             ::  response headers
          body=(unit octs)                     ::  response body
          flow-id=@ud                          ::  L3: which flow this response belongs to (0 = control plane)
      ==
      $:  %proxy-chunk                         ::  host→subscriber: streaming chunk
          rid=@uv                              ::  request correlation id
          seq=@ud                              ::  chunk sequence number
          data=octs                            ::  chunk payload
          has-more=?                           ::  more chunks coming?
          status=@ud                           ::  HTTP status (first chunk only)
          headers=header-list:http             ::  response headers (first chunk)
          flow-id=@ud                          ::  L3: which flow this chunk arrived on (default 0)
      ==
      $:  %invitation-offer                    ::  host→subscriber over Ames
          from=ship                            ::  the host offering
      ==
      [%fetch-sections ~]                      ::  request library sections from Plex
      [%fetch-items key=@t]                    ::  request items for a library section
      [%fetch-show-children rkey=@t]           ::  request seasons for a show
      [%fetch-season-children rkey=@t]         ::  request episodes for a season
      [%fetch-artist-children rkey=@t]         ::  request albums for an artist
      [%fetch-album-children rkey=@t]          ::  request tracks for an album
      [%clear-streams ~]                       ::  reap all in-flight subscriber streams
      [%cancel-stream rid=@uv]                 ::  reap one in-flight subscriber stream by rid
      [%clear-cache ~]                         ::  evict every known Eyre cache entry burn has written
  ==
::
::  Public status snapshot — one entry per active download in pending-
::  streams. Active-or-gone model: presence in the list IS the lifecycle
::  signal. Broadcast on /status for Oxal UI status panels and any
::  external observer; rkey and source URL are intentionally omitted
::  (library-enumeration risk).
::
+$  status-entry
  $:  title=@t                                 ::  display-name from stream-state
      publisher=ship                           ::  host ship (= our.bowl on host)
      started=@da                              ::  stream acceptance timestamp
      bytes=@ud                                ::  emitted (browser-shipped)
      total=@ud                                ::  total-size from upstream (0 if unknown)
      container=@tas                           ::  file extension hint
      last=@da                                 ::  last chunk arrival timestamp
  ==
::
+$  status-snapshot  (list status-entry)
--
