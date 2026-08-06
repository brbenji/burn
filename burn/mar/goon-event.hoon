::  /mar/goon-event.hoon — canonical Hoon Native UI input event mark
::
::  Per goon README (/Users/benjaminbrown/dev/urbit/goon/docs/README.md):
::  agents process pokes of mark %goon-event whose payload is a stab —
::  (pair path blade) where path identifies a goad node and blade is
::  the interaction kind: %act %edit or %add.
::
/-  goon
|_  =stab:goon
++  grab
  |%
  ++  noun  stab:goon
  --
++  grow
  |%
  ++  noun  stab
  --
++  grad  %noun
--
