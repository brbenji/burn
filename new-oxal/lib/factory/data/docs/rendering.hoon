/+  *zozo-zero
^-  data
%-  mono
:-  %manx
;section
  ;h2: Rendering HTML
  ;p
    ; Hawk views produce HTML using Sail, Hoon's built-in XML syntax. Sail compiles to
    ;code: manx
    ;  (Hoon's XML type) at compile time.
  ==
  ;h3: Sail Basics
  ;pre
    ;-  %-  trip
    '''
    ;div: text content              :: element with text
    ;div.foo.bar: classed           :: CSS classes with dots
    ;div#main: with id              :: id with hash
    ;a(href "/path"): click me      :: attributes in parens
    ;div  ;span: nested  ==         :: nesting, closed with ==
    ;input(type "text");            :: self-closing with ;
    '''
  ==
  ;h3: Interpolation
  ;pre
    ;-  %-  trip
    '''
    ;div: hello {name}              :: tape interpolation
    ;a(href "{url}"): link          :: in attributes too
    '''
  ==
  ;h3: Children Modes
  ;pre
    ;-  %-  trip
    '''
    ;*  list-of-manx               :: splice a marl (list manx)
    ;+  single-manx                :: insert one computed manx
    ;-  tape-value                  :: text node from tape
    ;=  ;div; ;span;  ==           :: inline marl literal
    '''
  ==
  ;p
    ; Use
    ;code: ;*
    ;  to splice a list of elements (like from
    ;code: ren:d
    ;  or
    ;code: turn
    ; ). Use
    ;code: ;+
    ;  when you compute a single element inline. Use
    ;code: ;-
    ;  for dynamic text content.
  ==
  ;h3: Conditional Rendering
  ;pre
    ;-  %-  trip
    '''
    ;+
    ?:  show-it
      ;div: visible content
    ;span;                          :: empty element if false
    '''
  ==
  ;h3: Fallback Rendering with =;
  ;p
    ; Use
    ;code: =;
    ;  (tisgal) to compute a value and then decide how to render it. This is useful for empty-list fallbacks:
  ==
  ;pre
    ;-  %-  trip
    '''
    ;*  =;  =marl  ?~  marl  ~[;p: No items yet.]
        marl
    %+  turn  items
    |=  item=@t
    ;li: {(trip item)}
    '''
  ==
  ;p
    ; Here
    ;code: =;  =marl
    ;  binds the result of the
    ;code: turn
    ;  expression below, then the code after
    ;code: =;
    ;  checks if the list is empty and substitutes a placeholder if so.
  ==
  ;h3: List Rendering
  ;p
    ; Render data tree children with
    ;code: ren:d
    ; :
  ==
  ;pre
    ;-  %-  trip
    '''
    ;*
    %-  ren:d
    |=  [=iota =_data]
    ?~  leaf.data  ~
    :-  ~
    ;a(href (dane iota))
      ;-  (print-node iota)
    ==
    '''
  ==
  ;p
    ; Render a plain list with
    ;code: turn
    ; :
  ==
  ;pre
    ;-  %-  trip
    '''
    ;*
    %+  turn  items
    |=  item=@t
    ;li: {(trip item)}
    '''
  ==
  ;h3: Manx Helpers
  ;p
    ; Programmatic HTML manipulation from the
    ;code: zozo
    ;  library:
  ==
  ;ul
    ;li
      ;code: (add-class "name" manx)
      ;  — append a CSS class
    ==
    ;li
      ;code: (add-class-if flag "name" manx)
      ;  — conditional class
    ==
    ;li
      ;code: (add-attribute [%id "val"] manx)
      ;  — add an HTML attribute
    ==
    ;li
      ;code: (add-attribute-if flag [%id "val"] manx)
      ;  — conditional attribute
    ==
    ;li
      ;code: (get-attribute %href manx)
      ;  — read an attribute (returns unit)
    ==
    ;li
      ;code: (find-element %div manx)
      ;  — find first descendant by tag
    ==
    ;li
      ;code: (find-elements %li manx)
      ;  — find all descendants by tag
    ==
    ;li
      ;code: (find-child-text %title manx)
      ;  — text of a direct child element
    ==
    ;li
      ;code: (text-content manx)
      ;  — extract all text from a tree
    ==
  ==
  ;h3: Forms
  ;p
    ; HTML forms post to your
    ;code: ++post
    ;  arm. Use
    ;code: method="post"
    ;  and query params on the action for routing:
  ==
  ;pre
    ;-  %-  trip
    '''
    ;form(method "post", action "?action=create")
      ;input(name "title", required "");
      ;button: Submit
    ==
    '''
  ==
  ;p: The framework intercepts form submissions and sends them via fetch(), so the page updates live without a full reload.
  ;h3: Debugging
  ;p
    ; Add
    ;code: !:
    ;  at the very top of your view file (before
    ;code: :-  %feather-1
    ; ) to enable stack traces. When your view crashes, you'll get line numbers instead of opaque errors:
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
