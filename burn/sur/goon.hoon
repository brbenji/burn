::  /sur/goon.hoon — goon protocol type definitions
::
::  Vendored from /Users/benjaminbrown/dev/urbit/goon/urb/lib/goon.hoon
::  (canonical Hoon Native UI; see goon README at
::  /Users/benjaminbrown/dev/urbit/goon/docs/README.md).
::
::  Naming convention:
::    goad = the structure (UI tree data type)
::    goon = the process (rendering, interaction protocol)
::  This file is /sur/ because it carries types only. Arms (++has, ++scod,
::  etc.) live in /lib/goon.hoon (Run 1b). Source converters and renderers
::  live in /lib/<source>-to-goad.hoon and /lib/goad-to-<medium>.hoon.
::
::  Hint policy: omits %hint attr. The README documents it but upstream
::  goon's lib/goon.hoon doesn't ship it yet; we try the structural-
::  inference path (component-jet style) instead. Re-add when upstream
::  ships it OR when structural inference proves insufficient.
::
::  Iota note: goon's iota is the scalar-identifier subset
::  $@(@t (pair aura @)). zozo's iota is the full node type which includes
::  structural blobs (%manx, %mime, %pith, %json, %tang, %noun, %data).
::  Source converters that walk oxal trees (e.g. lib/oxal-to-goad.hoon)
::  cast zozo-node to goon-iota at the input boundary. Blob-typed keys
::  are not supported as goad iotas (they'd be unusual as tree keys
::  anyway; blobs typically appear as leaf values).
::
|%
+$  info  @t                            ::  longer description text
+$  lede  @t                            ::  short label/title text
+$  interact                            ::  per-action self-description
  [=info =lede]
+$  act
  (pair term interact)
+$  iota                                ::  node identifier
  $@(@t (pair aura @))
+$  goad                                ::  UI tree node
  $~  [*iota ~ ~]
  (trel iota (list attr) (list goad))
::
+$  blade                               ::  interaction event variant
  $%  [%act =term]
      [%edit =iota]
      [%add =iota]
  ==
::
+$  stab  (pair path blade)             ::  path-targeted interaction event
::
+$  attr                                ::  per-node UI attributes
  $%  [%lede p=lede]                    ::  short title/label
      [%info p=info]                    ::  longer description
      [%value p=iota]                   ::  typed display value
      [%edit ~]                         ::  value is editable
      [%add ~]                          ::  placeholder for new item
      [%act p=(list act)]               ::  list of named interactions
      [%click p=? q=wire]               ::  single-click action
  ==
--
