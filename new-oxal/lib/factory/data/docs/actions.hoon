/+  *zozo-zero
^-  data
%-  mono
:-  %manx
;section
  ;h2: Mutations and IO
  ;p
    ; Hawk views change state by returning moves from
    ;code: ++post
    ;  and
    ;code: ++on
    ; . A move is a triple:
    ;code: [wire stem action]
    ; . The
    ;code: wire
    ;  identifies the callback channel,
    ;code: stem
    ;  is the data path to act on, and
    ;code: action
    ;  is what to do.
  ==
  ;h3: Actions
  ;ul
    ;li
      ;code: %ins
      ;  — insert or overwrite a leaf:
      ;code: [/ #/name %ins t+'value']
    ==
    ;li
      ;code: %ins [%data ...]
      ;  — insert structured data as an opaque leaf:
      ;code: [/ #/tree %ins [%data my-data]]
    ==
    ;li
      ;code: %del
      ;  — delete a single leaf:
      ;code: [/ #/name %del ~]
    ==
    ;li
      ;code: %lop
      ;  — delete an entire subtree:
      ;code: [/ #/tree %lop ~]
    ==
    ;li
      ;code: %bind
      ;  — bind data across views. Establishes a data link so one view can reference another's data.
    ==
    ;li
      ;code: %install
      ;  — programmatically install a view at a path from source code. Used by the admin UI and can be used in
      ;code: ++post
      ;  or
      ;code: ++on
      ;  to install views dynamically.
    ==
    ;li
      ;code: %uninstall
      ;  — remove an installed view from a path.
    ==
  ==
  ;p
    ; The
    ;code: wire
    ;  (first element) is
    ;code: /
    ;  for simple data writes. IO moves use special wire prefixes — see below.
  ==
  ;h3: The Move Triple
  ;p
    ; Every move has the shape
    ;code: [wire stem action]
    ; :
  ==
  ;ul
    ;li
      ;code: wire
      ;  — a
      ;code: pith
      ;  identifying the callback. Use
      ;code: /
      ;  for fire-and-forget data writes. Use
      ;code: [%out %behn ...]
      ;  or
      ;code: [%out %iris ...]
      ;  for IO that expects a response in
      ;code: ++on
      ; .
    ==
    ;li
      ;code: stem
      ;  — a
      ;code: pith
      ;  specifying where in the data tree to apply the action. E.g.
      ;code: #/name
      ;  or
      ;code: #/items/[ta/id]
      ; .
    ==
    ;li
      ;code: action
      ;  — what to do:
      ;code: %ins
      ;  to write,
      ;code: %del
      ;  to delete, etc.
    ==
  ==
  ;h3: POST Handling
  ;p
    ; When a user submits a form,
    ;code: ++post
    ;  receives the form data as
    ;code: body
    ; . Read it with the
    ;code: +do
    ;  door:
  ==
  ;pre
    ;-  %-  trip
    '''
    ++  post
      |=  [our=@p src=@p =data =stem =query =body]
      =/  d  ~(. do data)
      =/  b  ~(. do body)
      =/  action  (crip (~(gut by (malt query)) 'action' ""))
      ?+  action  [~ ~]
          %create
        =/  name  (got-t:b #/[t/'name'])
        :-  `[#/[t/name] ~]            :: redirect to /name
        :~  [/ #/[t/name] %ins t+'']   :: create the entry
        ==
          %delete
        :-  `[/ ~]                     :: redirect to index
        :~  [/ #/[name] %del ~]        :: delete the entry
        ==
      ==
    '''
  ==
  ;h3: POST Return Value
  ;p
    ;code: ++post
    ;  returns
    ;code: [(unit [stem query]) (list move)]
    ; :
  ==
  ;ul
    ;li
      ; The unit is a redirect destination.
      ;code: ~
      ;  means stay on the current page.
      ;code: `[#/new-page ~]
      ;  navigates to
      ;code: /new-page
      ;  after the POST.
    ==
    ;li
      ; The list of moves changes data. All connected browsers see updates automatically.
    ==
  ==
  ;h3: Behn Timers
  ;p
    ; Schedule a timer by writing a date to a
    ;code: behn
    ;  wire path:
  ==
  ;pre
    ;-  %-  trip
    '''
    :: schedule a timer 15 minutes from now
    =/  next  (add now ~m15)
    :-  [%out %behn %tick ~]       :: wire
    :-  #/~/behn/tick              :: stem (date stored here)
    [%ins da+next]                 :: the @da to fire at
    '''
  ==
  ;p
    ; When the timer fires,
    ;code: ++on
    ;  receives it:
  ==
  ;pre
    ;-  %-  trip
    '''
    ++  on
      |=  [=prov =move =file]
      ?+  wir=((pole iota) wire.move)  ~
          [%in %behn %tick ~]
        :: timer fired
        :~  [/ #/last-tick %ins da+now]  ==
      ==
    '''
  ==
  ;h3: Iris HTTP Requests
  ;p: Make outbound HTTP requests by writing URL data to an iris wire path:
  ;pre
    ;-  %-  trip
    '''
    :: fetch a URL
    =/  fid  'my-req'
    :-  [%out %iris %fetch ta/fid ~]
    :-  #/~/iris/fetch/[ta/fid]
    :-  %ins  :-  %data
    %-  ~(gep do *data)
    :~  :-  /url  %-  mono  t+url  ==
    '''
  ==
  ;p
    ; The response arrives in
    ;code: ++on
    ;  with status, headers, and body at the stem:
  ==
  ;pre
    ;-  %-  trip
    '''
        [%in %iris %fetch fid=[%ta @] ~]
      =/  d  ~(. do (~(got-data do data.file) stem.move))
      =/  status  (gut-ud:d /status 0)
      =/  body    (gut-t:d /body '')
      :: process the response...
    '''
  ==
  ;h3: Wire Conventions
  ;ul
    ;li
      ;code: /
      ;  — no callback (simple data writes)
    ==
    ;li
      ;code: [%out %behn ...]
      ;  — outbound timer request
    ==
    ;li
      ;code: [%out %iris ...]
      ;  — outbound HTTP request
    ==
    ;li
      ;code: [%in %behn ...]
      ;  — inbound timer fire (in
      ;code: ++on
      ; )
    ==
    ;li
      ;code: [%in %iris ...]
      ;  — inbound HTTP response (in
      ;code: ++on
      ; )
    ==
  ==
==
