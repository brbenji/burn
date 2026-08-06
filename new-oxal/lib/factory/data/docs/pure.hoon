/+  *zozo-zero
^-  data
%-  mono
:-  %manx
;section
  ;h2: Pure Views
  ;p
    ; A
    ;code: %pure
    ;  view is the simplest view type: a single function from
    ;code: data
    ;  to a rendered
    ;code: node
    ; . No routing, no POST handling, no IO. If your data changes, the view re-renders automatically.
  ==
  ;h3: File Structure
  ;pre
    ;-  %-  trip
    '''
    :-  %pure  %.n
    |=  =data
    =/  d  ~(. do data)
    :-  %manx
    ;div
      ;h1: Status
      ;p: Count is {(pib:d /count)}
    ==
    '''
  ==
  ;h3: The Header
  ;p
    ; The first line is
    ;code: :-  %pure
    ;  followed by a flag:
  ==
  ;ul
    ;li
      ;code: %.n
      ;  — private (default). Only your ship can view it.
    ==
    ;li
      ;code: %.y
      ;  — public. Anyone can view it.
    ==
  ==
  ;h3: The Gate
  ;p
    ; Your gate receives
    ;code: data
    ;  — the view's data subtree with framework state (
    ;code: #/~
    ; ) stripped out. Return a
    ;code: node
    ; :
  ==
  ;ul
    ;li
      ;code: manx
      ;  — rendered as HTML
    ==
    ;li
      ;code: @t
      ;  — rendered as preformatted text
    ==
    ;li
      ;code: tang
      ;  — rendered as an error trace
    ==
  ==
  ;h3: When to Use Pure
  ;ul
    ;li: Status dashboards that just display data
    ;li: Computed views over data managed by another view
    ;li: Quick prototypes before adding interactivity
  ==
  ;h3: When to Use Feather-1 Instead
  ;ul
    ;li: You need forms or user input (POST handling)
    ;li: You need multiple pages or URL routing
    ;li: You need background IO (timers, HTTP fetches)
    ;li
      ; You need auth-gated content (
      ;code: our
      ;  vs
      ;code: src
      ; )
    ==
  ==
  ;p
    ;code: %pure
    ;  views still get SSE live updates and SPA navigation — they are wrapped by the
    ;code: %feather-1
    ;  adapter internally.
  ==
==
