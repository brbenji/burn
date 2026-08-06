::  /lib/goon.hoon — goon protocol arms
::
::  Operates on goad attrs imported from /-  goon (sur/goon.hoon).
::  The web renderer that consumes goad-shaped data trees lives in
::  /lib/goad-to-manx.hoon.
::
::  Vendored subset of upstream goon's lib/goon.hoon (canonical at
::  /Users/benjaminbrown/dev/urbit/goon/urb/lib/goon.hoon). Add arms
::  here as their first downstream caller is introduced.
::
/-  goon
=,  goon
|%
::  has — door over a node's attr list. Each arm extracts the typed
::  payload of one attr kind (or default).
::
++  has
  |_  attrs=(list attr)
  ::
  ++  lede
    |-  ^-  (unit @t)
    ?~  attrs  ~
    ?:  ?=(%lede -.i.attrs)
      `p.i.attrs
    $(attrs t.attrs)
  ::
  ++  act
    |-  ^-  (list ^act)
    ?~  attrs  ~
    ?:  ?=(%act -.i.attrs)
      p.i.attrs
    $(attrs t.attrs)
  ::
  ++  info
    |-  ^-  (unit @t)
    ?~  attrs  ~
    ?:  ?=(%info -.i.attrs)
      `p.i.attrs
    $(attrs t.attrs)
  ::
  ++  edit
    |-  ^-  ?
    ?~  attrs  |
    ?:  ?=(%edit -.i.attrs)  &
    $(attrs t.attrs)
  ::
  ++  add
    |-  ^-  ?
    ?~  attrs  |
    ?:  ?=(%add -.i.attrs)  &
    $(attrs t.attrs)
  ::
  ++  value
    |-  ^-  (unit iota)
    ?~  attrs  ~
    ?:  ?=(%value -.i.attrs)
      `p.i.attrs
    $(attrs t.attrs)
  --
--
