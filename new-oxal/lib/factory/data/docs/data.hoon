/+  *zozo-zero
^-  data
%-  mono
:-  %manx
;section
  ;h2: Working with Data
  ;p
    ; All state in Hawk lives in an
    ;code: oxal
    ;  — an ordered tree with typed keys and typed values. Understanding the data
    ;  tree is the key to using Hawk effectively.
  ==
  ;h3: Node
  ;p
    ; A
    ;code: node
    ;  is the universal value type. It's a tagged union covering all common Hoon auras and some compound types:
  ==
  ;ul
    ;li
      ; Text:
      ;code: t+'hello'
      ;  (cord),
      ;code: ta/'some-knot'
      ;  (knot),
      ;code: bare-term
      ;  (term)
    ==
    ;li
      ; Numbers:
      ;code: ud+5
      ;  (unsigned),
      ;code: si+-3
      ;  (signed),
      ;code: rs+.3.14
      ;  (float),
      ;code: ux+0xdead
      ;  (hex). Full numeric aura coverage is available —
      ;code: ub
      ; ,
      ;code: ui
      ; ,
      ;code: uc
      ; , etc.
    ==
    ;li
      ; Identity:
      ;code: p+~zod
      ;  (ship),
      ;code: da+now
      ;  (date),
      ;code: dr+~s5
      ;  (duration)
    ==
    ;li
      ; Compound:
      ;code: manx+mx
      ;  (HTML),
      ;code: json+j
      ;  (JSON),
      ;code: data+d
      ;  (nested tree),
      ;code: tang+t
      ;  (error trace)
    ==
    ;li
      ; Other:
      ;code: f+%.y
      ;  (flag),
      ;code: n+~
      ;  (null),
      ;code: noun+x
      ;  (opaque noun),
      ;code: pith+p
      ;  (typed path)
    ==
  ==
  ;h3: Pith
  ;p
    ; A
    ;code: pith
    ;  is
    ;code: (list iota)
    ;  — a typed path into the tree. Unlike Hoon's
    ;code: path
    ;  (list of knots), a
    ;code: pith
    ;  can have any node type as a segment.
  ==
  ;pre
    ;-  %-  trip
    '''
    #/                       :: root (empty pith)
    #/foo                    :: bare term segment
    #/foo/bar                :: two term segments
    #/[t/'hello world']     :: cord segment
    #/[ud/5]                :: number segment
    #/[p/~zod]              :: ship segment
    #/items/[ta/item-id]    :: mixed segments
    '''
  ==
  ;h3: The +do Door
  ;p
    ; The
    ;code: +do
    ;  door is your main interface for reading and writing data. Bind it at the top of your arm:
  ==
  ;pre
    ;-  %-  trip
    '''
    =/  d  ~(. do data)
    '''
  ==
  ;h3: Typed Reads
  ;p
    ; Four families of typed accessors, available for every aura (
    ;code: t
    ; ,
    ;code: ta
    ; ,
    ;code: ud
    ; ,
    ;code: da
    ; ,
    ;code: p
    ; ,
    ;code: manx
    ; , etc.):
  ==
  ;ul
    ;li
      ;code: got-t:d
      ;  — crash if missing. Use when the value must exist.
    ==
    ;li
      ;code: gut-t:d
      ;  — fallback to a default. Use for optional values.
    ==
    ;li
      ;code: get-t:d
      ;  — returns a unit. Use when you need to branch on presence.
    ==
    ;li
      ;code: git-t:d
      ;  — returns the bunt (zero) default. Use for counters and accumulators.
    ==
  ==
  ;pre
    ;-  %-  trip
    '''
    (got-t:d #/name)             :: @t or crash
    (gut-t:d #/name 'default')   :: @t or 'default'
    (get-t:d #/name)             :: (unit @t)
    (git-ud:d #/count)           :: @ud or 0
    (gut-da:d #/~/meta/now *@da) :: current time
    '''
  ==
  ;h3: Print-to-Tape Helpers
  ;p
    ; Four arms for converting data values to
    ;code: tape
    ;  (text strings), differing in how they handle missing values:
  ==
  ;ul
    ;li
      ;code: peb:d
      ;  — returns
      ;code: (unit tape)
      ; . Safe optional — returns
      ;code: ~
      ;  if missing.
    ==
    ;li
      ;code: pib:d
      ;  — returns
      ;code: tape
      ; . Falls back to
      ;code: ""
      ;  if missing — the safe default for display.
    ==
    ;li
      ;code: pob:d
      ;  — returns
      ;code: tape
      ; . Crashes if missing — use when the value must exist.
    ==
    ;li
      ;code: pub:d
      ;  — returns
      ;code: tape
      ;  with a custom fallback. Takes
      ;code: [pith fallback-tape]
      ; .
    ==
  ==
  ;pre
    ;-  %-  trip
    '''
    (pib:d #/name)            :: tape or ""
    (pob:d #/name)            :: tape or crash
    (pub:d #/name "unknown")  :: tape or "unknown"

    :: common pattern: display data values in Sail
    ;div: Name: {(pib:d #/name)}
    ;div: Count: {(pib:d #/count)}
    '''
  ==
  ;h3: Write Arms
  ;p
    ; The
    ;code: +do
    ;  door also provides arms for building and modifying data trees:
  ==
  ;ul
    ;li
      ;code: put:d
      ;  — insert a single node at a path:
      ;code: (~(put do data) #/name t+'val')
    ==
    ;li
      ;code: gep:d
      ;  — build a
      ;code: data
      ;  tree from a list of
      ;code: [pith data]
      ;  pairs. Used with an empty base:
      ;code: (~(gep do *data) ~[[/a (mono t+'x')] ...])
    ==
    ;li
      ;code: gas:d
      ;  — insert multiple
      ;code: [pith node]
      ;  bonds into a data tree at once:
      ;code: (~(gas do *data) ~[[#/a t+'x'] [#/b ud+5]])
    ==
  ==
  ;pre
    ;-  %-  trip
    '''
    :: build structured data for an IO request
    %-  ~(gep do *data)
    :~  :-  /url    (mono t+url)
        :-  /method  (mono t+'GET')
    ==

    :: build a data tree with multiple leaves
    %-  ~(gas do *data)
    :~  :-  #/[t/'content-type']  t+'text/html'
        :-  #/[t/'accept']        t+'*/*'
    ==
    '''
  ==
  ;h3: Tree Navigation
  ;ul
    ;li
      ;code: kid-list:d
      ;  — list of
      ;code: [iota data]
      ;  children (one level deep)
    ==
    ;li
      ;code: (dip:d pith)
      ;  — descend into a subtree, returns
      ;code: data
    ==
    ;li
      ;code: (dit:d pith)
      ;  — descend and get a new
      ;code: +do
      ;  door for that subtree
    ==
    ;li
      ;code: (has:d pith)
      ;  — does a leaf exist at this path?
    ==
    ;li
      ;code: (hos:d pith)
      ;  — does anything exist here? (leaf or children)
    ==
    ;li
      ;code: tap:d
      ;  — flatten entire tree to
      ;code: (list [pith node])
      ;  pairs
    ==
  ==
  ;h3: Rendering Children
  ;p
    ;code: ren:d
    ;  iterates over a data tree's direct children, calling your gate on each one. Return
    ;code: ~
    ;  to skip, or
    ;code: `(some manx)
    ;  to include:
  ==
  ;pre
    ;-  %-  trip
    '''
    ;*
    %-  ren:d
    |=  [=iota =_data]
    ?~  leaf.data  ~
    :-  ~
    ;div: {(print-node iota)}
    '''
  ==
  ;h3: Display Helpers
  ;ul
    ;li
      ;code: (dane iota)
      ;  — render a node as a URL-safe tape (for
      ;code: href
      ;  values)
    ==
    ;li
      ;code: (print-node iota)
      ;  — render a node as a human-readable tape
    ==
    ;li
      ;code: (pate pith)
      ;  — render a full pith as a URL path tape like
      ;code: "/foo/bar"
    ==
    ;li
      ;code: (mono node)
      ;  — wrap a single value into a
      ;code: data
      ;  tree (leaf at root)
    ==
  ==
  ;p
    ;code: dane
    ;  produces URL-safe output (for links and paths), while
    ;code: print-node
    ;  produces human-readable output (for display text). Use
    ;code: dane
    ;  in
    ;code: href
    ;  attributes and
    ;code: print-node
    ;  in visible text.
  ==
==
