/+  *zozo-zero
^-  data
%-  mono
:-  %manx
;section
  ;h2: Hawk Overview
  ;p
    ; Hawk is a reactive web framework for Urbit. You write small programs called
    ;code: views
    ;  that render a data tree as HTML. When the data changes, every connected browser
    ;  updates instantly — no polling, no manual refresh, no JavaScript required.
  ==
  ;p
    ; The core idea is simple:
    ;code: data tree + views = live web app
    ; . Your data tree is an
    ;code: oxal
    ;  — an ordered, typed tree that acts as both your database and your URL namespace.
    ;  Views read from this tree to produce HTML, and write back to it to change state.
    ;  The framework handles everything else: HTTP serving, live updates via SSE,
    ;  SPA-style navigation, and multi-ship distribution.
  ==
  ;h3: What Makes Hawk Different
  ;ul
    ;li
      ; No separate database — the filesystem IS your app state. Every piece of data has a path, a type, and is URL-addressable.
    ==
    ;li
      ; Real-time by default — all connected browsers see changes the instant they happen, via server-sent events.
    ==
    ;li
      ; SPA navigation is automatic — link clicks are intercepted and served over SSE. No client-side router needed.
    ==
    ;li
      ; Distributed by default — views can read data from other ships. Multi-player apps work out of the box.
    ==
    ;li
      ; No build step — write a
      ;code: .hoon
      ;  file, install it, and it's live. The framework compiles and serves it.
    ==
  ==
  ;h3: Views
  ;p
    ; A view is a Hoon source file that gets installed at a path in the data tree.
    ;  When a browser hits that path, the framework compiles the view, calls its
    ;  render arm, and serves HTML. When the view's data changes, all connected
    ;  browsers update instantly via SSE.
  ==
  ;h3: The Data Tree
  ;p
    ; All state lives in an
    ;code: oxal
    ;  — an ordered tree with typed keys. Each view has its own subtree. Keys can
    ;  be any node type (terms, cords, numbers, dates, ships). Values are also nodes.
    ;  There is no separate database — the data tree is both your storage and your namespace.
  ==
  ;h3: View Types
  ;ul
    ;li
      ;code: %feather-1
      ;  — The standard view type. GET/POST routing, forms, background IO, live
      ;  updates. Use this for most apps.
    ==
    ;li
      ;code: %pure
      ;  — A single function from data to HTML. No routing, no POST. Use for
      ;  dashboards and status displays.
    ==
    ;li
      ;code: %profile
      ;  — A remote profile viewer. Wraps a ship identity and fetches/displays
      ;  that ship's public data via remote scry. Automatically handles polling
      ;  and live updates.
    ==
    ;li
      ;code: %mantis
      ;  — Low-level view with direct wire/move control. For advanced use cases.
    ==
    ;li
      ;code: %raw
      ;  — Full Gall-level control over HTTP, Arvo signs, and change propagation.
    ==
  ==
  ;h3: How It Works
  ;ol
    ;li
      ; You write a view file (e.g.
      ;code: my-app.hoon
      ; ) starting with
      ;code: :-  %feather-1
    ==
    ;li
      ; Install it at a path via the admin UI or programmatically with the
      ;code: %install
      ;  action
    ==
    ;li
      ; A browser navigates to
      ;code: /oxal/my-app
      ;  — the framework calls
      ;code: ++get
      ;  and serves HTML
    ==
    ;li
      ; A user submits a form — the framework calls
      ;code: ++post
      ; , applies data changes, and pushes a live update
    ==
    ;li
      ; A timer fires or HTTP response arrives — the framework calls
      ;code: ++on
      ; , applies changes, and pushes an update
    ==
    ;li
      ; All connected browsers see changes in real time via SSE (no polling, no manual refresh)
    ==
  ==
  ;h3: File Layout
  ;ul
    ;li
      ; Views live in the data tree, installed from source code (plain text)
    ==
    ;li
      ; Each view has a root path — e.g.
      ;code: /my-app
    ==
    ;li
      ; Data below that path belongs to the view — e.g.
      ;code: /my-app/items/foo
    ==
    ;li
      ; Framework state lives under
      ;code: /~/
      ;  — things like
      ;code: /~/meta/now
      ;  (current time),
      ;code: /~/session/*
      ;  (session data). These are managed by the framework, not your view.
    ==
    ;li
      ; Views can read their own data, and changes propagate to ancestor/descendant views
    ==
  ==
  ;h3: Getting Started
  ;p: Here's a minimal hello-world view:
  ;pre
    ;-  %-  trip
    '''
    :-  %feather-1
    |%
    ++  title
      |=  [here=pith =data]
      "hello"
    ++  get
      |=  [our=@p src=@p =data =stem =query]
      ^-  node
      :-  %manx
      ;div
        ;h1: Hello, World!
        ;p: You are {<our>}
      ==
    ++  post
      |=  [our=@p src=@p =data =stem =query =body]
      :-  ~
      ~
    ++  on
      |=  [=prov =move =file]
      ~
    --
    '''
  ==
  ;p
    ; Save this as a file, navigate to
    ;code: /oxal
    ;  on your ship, and install it from the admin UI. It will be live immediately.
  ==
  ;h3: What You'll Need
  ;ul
    ;li: Basic Hoon knowledge — arms, cores, gates, faces, and Sail (Hoon's XML syntax)
    ;li: An Urbit ship — a fakeship works fine for development
    ;li: The Hawk desk installed on your ship
  ==
==
