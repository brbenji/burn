::  /mar/goon-redraw.hoon — canonical Hoon Native UI redraw notification.
::
::  Per goon README: facts on /goon carry mark %goon-redraw to tell the
::  renderer that the /x/goon scry has changed. The fact body is just a
::  notification; the renderer re-scries to get the new tree.
::
|_  non=*
++  grab
  |%
  ++  noun  *
  --
++  grow
  |%
  ++  noun  non
  --
++  grad  %noun
--
