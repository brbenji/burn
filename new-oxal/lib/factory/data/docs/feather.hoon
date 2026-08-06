/+  *zozo-zero
^-  data
%-  mono
:-  %manx
;section
  ;h2: Feather-1 Views
  ;p
    ;code: %feather-1
    ;  is the standard view type. It gives you GET/POST routing, form handling,
    ;  background IO, and live updates with minimal boilerplate.
  ==
  ;h3: File Structure
  ;pre
    ;-  %-  trip
    '''
    :-  %feather-1
    |%
    ++  title
      |=  [here=pith =data]
      "my app"
    ++  get
      |=  [our=@p src=@p =data =stem =query]
      ^-  node
      :-  %manx
      ;div: hello world
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
  ;h3: The Four Arms
  ;p: Every feather-1 view has exactly four arms:
  ;ul
    ;li
      ;code: ++title
      ;  — A gate:
      ;code: |=  [here=pith =data]
      ; . Returns a
      ;code: tape
      ;  shown in the browser tab.
      ;code: here
      ;  is the current URL path and
      ;code: data
      ;  is the view's data tree, so you can build dynamic titles:
    ==
  ==
  ;pre
    ;-  %-  trip
    '''
    ++  title
      |=  [here=pith =data]
      ?~  here  "my app"
      "{(print-node (rear here))} - my app"
    '''
  ==
  ;ul
    ;li
      ;code: ++get
      ;  — Render a page. Receives
      ;code: [our src data stem query]
      ; , returns a
      ;code: node
      ;  (usually
      ;code: %manx
      ; ).
    ==
    ;li
      ;code: ++post
      ;  — Handle form submission. Receives
      ;code: [our src data stem query body]
      ; , returns an optional redirect and a list of data moves.
    ==
    ;li
      ;code: ++on
      ;  — Handle background events (timers, HTTP responses). Receives
      ;code: [prov move file]
      ; , returns a list of moves.
      ;code: prov
      ;  is provenance metadata,
      ;code: move
      ;  is the incoming event (with a wire, stem, and action), and
      ;code: file
      ;  is the full current state of this view's data tree.
    ==
  ==
  ;h3: Routing
  ;p
    ; The
    ;code: stem
    ;  is the URL path below your view's root, as a
    ;code: pith
    ; . Match it with a switch:
  ==
  ;pre
    ;-  %-  trip
    '''
    ?+  route=((pole iota) stem)  !!  :: crash on unknown
        ~                              :: root page
      ;div: index
    ::
        [name=* ~]                     :: one-segment path
      ;div: detail {(print-node name.route)}
    ::
        [%settings ~]                  :: exact match
      ;div: settings
    ==
    '''
  ==
  ;p
    ; Navigation uses relative links. Use
    ;code: (dane iota)
    ;  to render a node as a URL segment, and
    ;code: ".."
    ;  to go back. The framework handles SPA-style navigation automatically — link
    ;  clicks are intercepted and served via SSE without full page reloads.
  ==
  ;h3: Auth Check
  ;p
    ; The
    ;code: our
    ;  and
    ;code: src
    ;  arguments let you check who is viewing the page. A common pattern:
  ==
  ;pre
    ;-  %-  trip
    '''
    =/  auth  ?:  =(our src)  %admin  %other
    ?+  route=((pole iota) [auth stem])  !!
        [%admin ~]  ...  :: logged-in view
        [%other ~]  ...  :: public view
    ==
    '''
  ==
  ;h3: Helper Arms
  ;p: If you need helper functions, put them in a context core before the main core:
  ;pre
    ;-  %-  trip
    '''
    :-  %feather-1
    =>
    |%
    ++  my-helper
      |=  x=@ud  (add x 1)
    --
    |%
    ++  title  ...
    ++  get    ...
    ++  post   ...
    ++  on     ...
    --
    '''
  ==
  ;h3: Metadata
  ;p
    ; The framework provides metadata under
    ;code: #/~/meta/
    ; :
  ==
  ;ul
    ;li
      ; Current time:
      ;code: (gut-da:d #/~/meta/now *@da)
    ==
    ;li
      ; Our ship is the
      ;code: our
      ;  argument to
      ;code: ++get
      ;  and
      ;code: ++post
      ;  directly.
    ==
  ==
  ;h3: Return Types
  ;p
    ;code: ++get
    ;  returns a
    ;code: node
    ; . Usually
    ;code: %manx
    ;  for HTML, but other types work too:
  ==
  ;ul
    ;li
      ;code: manx+mx
      ;  — rendered as HTML (the common case)
    ==
    ;li
      ;code: json+j
      ;  — served as application/json
    ==
    ;li
      ;code: tang+t
      ;  — rendered as an error trace page
    ==
    ;li
      ;code: t+'text'
      ;  — rendered as preformatted text
    ==
  ==
  ;h3: Datastar Client-Side Reactivity
  ;p
    ; Hawk uses Datastar for client-side interactivity. You add special
    ;code: data-
    ;  attributes to your Sail elements to create reactive behavior without writing JavaScript.
  ==
  ;h4: Event Handlers
  ;p
    ; Respond to browser events with
    ;code: data-on_EVENT
    ;  attributes:
  ==
  ;pre
    ;-  %-  trip
    '''
    :: click handler — toggle a signal
    ;button(data-on_click "$_open = !$_open")
      ; Toggle
    ==

    :: input handler
    ;input(data-on_input "$_query = evt.target.value");

    :: form submit — post to your ++post arm
    ;form(data-on_submit "@post('?action=create')")
      ;input(name "title");
      ;button: Create
    ==

    :: after a POST completes
    ;form(data-on_post-complete "$_editing = false")
    '''
  ==
  ;h4: Conditional Classes and Attributes
  ;p
    ; Toggle CSS classes or HTML attributes based on signal expressions:
  ==
  ;pre
    ;-  %-  trip
    '''
    :: add .toggled class when $_open is true
    ;div(data-class_toggled "$_open")

    :: add .o3 (30% opacity) when $_debug is false
    ;div(data-class_o3 "!$_debug")

    :: disable a button based on a signal
    ;button(data-attr_disabled "!$_valid")
    '''
  ==
  ;h4: Signals
  ;p
    ; Client-side state variables use the
    ;code: $_name
    ;  convention. They are local to the browser and reset on page reload. Use them for UI state like toggles, menus, and input tracking:
  ==
  ;pre
    ;-  %-  trip
    '''
    :: toggle debug panel
    ;button(data-on_click "$_debug = !$_debug"): Debug
    ;div(data-show "$_debug")
      ; debug content
    ==
    '''
  ==
  ;h4: Programmatic Fetches
  ;p
    ; Use
    ;code: @get('url')
    ;  and
    ;code: @post('url')
    ;  in event handlers for programmatic navigation and form submission:
  ==
  ;pre
    ;-  %-  trip
    '''
    :: navigate via GET on click
    ;button(data-on_click "@get('/oxal/my-app/details')"): View

    :: POST with action query param
    ;button(data-on_click "@post('?action=delete')"): Delete
    '''
  ==
  ;h3: Debugging
  ;p
    ; Add
    ;code: !:
    ;  at the top of your view file to enable stack traces on crash. This makes
    ;  error messages much more useful during development:
  ==
  ;pre
    ;-  %-  trip
    '''
    !:
    :-  %feather-1
    |%
    ...
    '''
  ==
==
