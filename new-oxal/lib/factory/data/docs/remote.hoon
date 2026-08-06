/+  *zozo-zero
^-  data
%-  mono
:-  %manx
;section
  ;h2: Binding and Remote Data
  ;p
    ; Hawk views can publish parts of their data tree to a global namespace,
    ;  making them readable by other ships via remote scry. Views can also
    ;  read data from remote ships using mirrors and keens. This is the
    ;  mechanism behind Hawk's "distributed by default" design.
  ==
  ;h3: The Big Picture
  ;ol
    ;li
      ; A view
      ;code: %bind
      ; s parts of its data tree — marking them as publicly readable in
      ;  the Urbit namespace.
    ==
    ;li
      ; Another ship's view starts a
      ;code: %mirror
      ;  — a long-lived subscription that continuously polls for new data
      ;  via remote scry (keen).
    ==
    ;li
      ; The framework handles all the plumbing: keens, retries with exponential
      ;  backoff, timeout detection, and delivering the data to your view's
      ;code: ++on
      ;  arm.
    ==
  ==
  ;h3: Publishing Data with %bind
  ;p
    ; The
    ;code: %bind
    ;  action tells the framework which aspects of your view's data tree to
    ;  publish to the Urbit namespace. Other ships can then read this data
    ;  via remote scry.
  ==
  ;p
    ; A binding has three independently controllable facets:
  ==
  ;ul
    ;li
      ;code: leaf
      ;  — the value at the view's root path
    ==
    ;li
      ;code: kids
      ;  — the direct children (one level deep)
    ==
    ;li
      ;code: cone
      ;  — the entire subtree (leaf + all descendants)
    ==
  ==
  ;p
    ; Each facet can be independently enabled, and each has two options:
  ==
  ;ul
    ;li
      ;code: auth
      ;  — an optional term for access control. When
      ;code: ~
      ; , the data is fully public. When set, the reader must present a matching
      ;  authentication token.
    ==
    ;li
      ;code: past
      ;  — a flag. When
      ;code: %.y
      ; , old versions of the data are retained so readers
      ;  can catch up from any point. When
      ;code: %.n
      ; , only the latest version is kept.
    ==
  ==
  ;h4: Binding from ++on
  ;p
    ; The easiest way to bind is from your
    ;code: ++on
    ;  arm when the view is installed. React to the
    ;code: %install
    ;  action:
  ==
  ;pre
    ;-  %-  trip
    '''
    ++  on
      |=  [=prov =move =file]
      ?:  ?=(%install -.action.move)
        ::  bind the entire subtree, publicly, no history
        :~  :+  /  /
            :-  %bind
            :*  ~           :: leaf: unbound
                ~           :: kids: unbound
                `[~ %.n]    :: cone: public, no past
                ~           :: http: none
            ==
        ==
      ~
    '''
  ==
  ;h4: Binding from the Admin UI
  ;p
    ; You can also configure bindings from the admin UI at
    ;code: /oxal
    ; . Select a view, and the binding panel lets you toggle leaf, kids, and cone
    ;  independently, set auth tokens, and enable past-version retention.
  ==
  ;h4: Bind Options Reference
  ;pre
    ;-  %-  trip
    '''
    :: fully public cone, no history
    [%bind ~ ~ `[~ %.n] ~]

    :: public cone with history (readers can catch up)
    [%bind ~ ~ `[~ %.y] ~]

    :: public leaf only
    [%bind `[~ %.n] ~ ~ ~]

    :: public kids only
    [%bind ~ `[~ %.n] ~ ~]

    :: auth-gated cone (readers need matching token)
    [%bind ~ ~ `[`%my-token %.n] ~]
    '''
  ==
  ;h3: Reading Remote Data with Mirrors
  ;p
    ; A
    ;code: %mirror
    ;  is a long-lived subscription to a path on another ship. The framework
    ;  continuously polls for new data using remote scry (keen), handles retries
    ;  with exponential backoff on failure, and delivers each new version to
    ;  your
    ;code: ++on
    ;  arm.
  ==
  ;h4: Starting a Mirror
  ;p
    ; Emit a move with a
    ;code: [%out %mirror ...]
    ;  wire. The stem points to a config path, and the action inserts
    ;  a data tree describing what to mirror:
  ==
  ;pre
    ;-  %-  trip
    '''
    :: start mirroring ~sampel's /blog data
    :+  [%out %mirror ta/'my-mirror' ~]
        #/mirror-cfg/my-mirror
    :-  %ins
    :-  %data
    %-  ~(gas do *data)
    :~  [#/ship p+~sampel]
        [#/path pith+/blog]
        [#/care %cone]
    ==
    '''
  ==
  ;p
    ; The config fields:
  ==
  ;ul
    ;li
      ;code: ship
      ;  — the remote ship to read from (
      ;code: p+~sampel-palnet
      ; )
    ==
    ;li
      ;code: path
      ;  — the path on that ship to mirror (
      ;code: pith+/blog
      ; )
    ==
    ;li
      ;code: care
      ;  — what facet to read:
      ;code: %leaf
      ; ,
      ;code: %kids
      ; , or
      ;code: %cone
      ;  (default). Must match what the remote view has bound.
    ==
  ==
  ;h4: Mirror State
  ;p
    ; The framework manages the mirror's state under
    ;code: #/~/mirror/[name]/
    ;  in your data tree:
  ==
  ;ul
    ;li
      ;code: state
      ;  — current status:
      ;code: %loading
      ; ,
      ;code: %success
      ; ,
      ;code: %error
      ; , or
      ;code: %timeout
    ==
    ;li
      ;code: case
      ;  — monotonically increasing version counter
    ==
    ;li
      ;code: attempt
      ;  — consecutive failure count (resets to 0 on success)
    ==
    ;li
      ;code: data
      ;  — the actual mirrored data tree (available after first success)
    ==
  ==
  ;h4: Receiving Mirror Updates
  ;p
    ; Each time new data arrives, your
    ;code: ++on
    ;  arm receives it on the
    ;code: [%in %mirror name ~]
    ;  wire:
  ==
  ;pre
    ;-  %-  trip
    '''
    ++  on
      |=  [=prov =move =file]
      =/  d  ~(. do data.file)
      ?+  wir=((pole iota) wire.move)  ~
          [%in %mirror [%ta @] ~]
        =/  name=@ta  ta.i.t.t.wir
        :: mirror data lives at #/~/mirror/[name]/data
        =/  md  (fall (get-data:d #/~/mirror/[ta/name]/data) *data)
        :: process the data...
        ~
      ==
    '''
  ==
  ;h4: Reading Mirror State in ++get
  ;p
    ; You can read the mirror's status to show loading/error states:
  ==
  ;pre
    ;-  %-  trip
    '''
    ++  get
      |=  [our=@p src=@p =data =stem =query]
      =/  d  ~(. do data)
      =/  mp  #/~/mirror/[ta/'my-mirror']
      =/  state   (gut-tas:d (welp mp /state) %idle)
      =/  attempt (gut-ud:d (welp mp /attempt) 0)
      ^-  node
      :-  %manx
      ;div
        ;div: status: {<state>} (attempt {<attempt>})
        ;+
        ?.  (hos:d (welp mp /data))
          ;div: waiting for data...
        ;div: data loaded!
      ==
    '''
  ==
  ;h4: Stopping a Mirror
  ;p
    ; Cancel a mirror by emitting
    ;code: %lop
    ;  on the same wire:
  ==
  ;pre
    ;-  %-  trip
    '''
    :+  [%out %mirror ta/'my-mirror' ~]
        #/~/mirror/[ta/'my-mirror']
    [%lop ~]
    '''
  ==
  ;h3: One-Shot Fetch with Keen
  ;p
    ; For one-time reads (not continuous polling), use a
    ;code: %keen
    ;  instead of a
    ;code: %mirror
    ; . A keen fetches a specific version of data and delivers it once.
  ==
  ;pre
    ;-  %-  trip
    '''
    :: fetch case 5 of ~sampel's /blog data
    :+  [%out %keen ta/'my-fetch' ~]
        #/fetch-cfg/my-fetch
    :-  %ins
    :-  %data
    %-  ~(gas do *data)
    :~  [#/ship p+~sampel]
        [#/path pith+/blog]
        [#/care %cone]
        [#/case ud+5]
    ==
    '''
  ==
  ;p
    ; The response arrives in
    ;code: ++on
    ;  on wire
    ;code: [%in %keen name ~]
    ; . State is managed at
    ;code: #/~/keen/[name]/
    ;  with the same fields as mirrors (
    ;code: state
    ; ,
    ;code: attempt
    ; ,
    ;code: data
    ; ).
  ==
  ;h3: The %profile View Type
  ;p
    ; The
    ;code: %profile
    ;  view type is a built-in pattern that combines mirrors and keens
    ;  to display another ship's public data. You just specify the ship:
  ==
  ;pre
    ;-  %-  trip
    '''
    :-  %profile
    ~sampel-palnet
    '''
  ==
  ;p
    ; This single line creates a complete view that mirrors the remote ship's
    ;  index, lets users browse individual items, handles caching, and shows
    ;  loading/error states. It's the easiest way to read another ship's data.
  ==
  ;h3: Full Example: Publishing and Mirroring
  ;p
    ; Here's a complete publisher/subscriber pattern. Ship A publishes a counter,
    ;  and Ship B mirrors it.
  ==
  ;h4: Ship A — Publisher
  ;pre
    ;-  %-  trip
    '''
    :-  %feather-1
    |%
    ++  title  |=  [here=pith =data]  "publisher"
    ++  get
      |=  [our=@p src=@p =data =stem =query]
      =/  d  ~(. do data)
      ^-  node  :-  %manx
      ;div
        ;div: count: {(pib:d /count)}
        ;form(method "post", action "?action=inc")
          ;button: increment
        ==
      ==
    ++  post
      |=  [our=@p src=@p =data =stem =query =body]
      :-  ~
      :~  [/ /count %ins ud++(~(git-ud do data) /count)]
      ==
    ++  on
      |=  [=prov =move =file]
      ?:  ?=(%install -.action.move)
        :: bind cone publicly on install
        :~  [/ / %bind ~ ~ `[~ %.n] ~]
        ==
      ~
    --
    '''
  ==
  ;h4: Ship B — Subscriber
  ;pre
    ;-  %-  trip
    '''
    :-  %feather-1
    |%
    ++  title  |=  [here=pith =data]  "subscriber"
    ++  get
      |=  [our=@p src=@p =data =stem =query]
      =/  d  ~(. do data)
      =/  mp  #/~/mirror/[ta/'source']
      =/  state  (gut-tas:d (welp mp /state) %idle)
      ^-  node  :-  %manx
      ;div
        ;div: state: {<state>}
        ;+
        ?.  (hos:d (welp mp /data))
          ;div: connecting...
        =/  md  ~(. do (dip:d (welp mp /data)))
        ;div: remote count: {(pib:md /count)}
      ==
    ++  post
      |=  [our=@p src=@p =data =stem =query =body]
      [~ ~]
    ++  on
      |=  [=prov =move =file]
      ?:  ?=(%install -.action.move)
        :: start mirroring on install
        :~  :+  [%out %mirror ta/'source' ~]
                #/mirror-cfg/source
            :-  %ins
            :-  %data
            %-  ~(gas do *data)
            :~  [#/ship p+~ship-a]
                [#/path pith+/publisher]
                [#/care %cone]
            ==
        ==
      ~
    --
    '''
  ==
  ;h3: Wire Reference
  ;ul
    ;li
      ;code: [%out %mirror name ~]
      ;  — start or update a mirror (outbound)
    ==
    ;li
      ;code: [%in %mirror name ~]
      ;  — mirror data arrived (inbound, in
      ;code: ++on
      ; )
    ==
    ;li
      ;code: [%out %keen name ~]
      ;  — start a one-shot fetch (outbound)
    ==
    ;li
      ;code: [%in %keen name ~]
      ;  — keen data arrived (inbound, in
      ;code: ++on
      ; )
    ==
  ==
  ;h3: Retry Behavior
  ;p
    ; On failure or timeout, the framework automatically retries with
    ;  exponential backoff: 4s, 8s, 16s, ... up to a 5-minute cap.
    ;  The
    ;code: attempt
    ;  counter tracks consecutive failures and resets to 0 on success.
    ;  Mirrors resume polling for the next version after each success.
    ;  Keens retry the same version until it succeeds or is cancelled.
  ==
==
