::  /lib/goad-to-dei.hoon — translate a goon goad to a tui-engine dei
::
::  Pure derivation. Walks a goad recursively and emits a dei whose
::  +blits/+ansi public arms (lib/tui-engine.hoon) can render.
::
::  V1 scope (column-flow only):
::    - Text leaf:    size=[lent 1]
::    - Layer branch: size=[max-children-w sum-children-h], flow=[%col %clip]
::    - Concrete @ud sizes, computed bottom-up (no vena/as).
::    - Heading + info + child layers all stacked in n.gens of the layer.
::
::  Off-path V1 (deferred):
::    - Row flow         (no goad-side hint exists yet to drive it)
::    - Selection / nav  (T7 input round-trip)
::    - Click / act      (T7)
::    - Edit / add       (T7)
::    - Borders, colors  (no /hint vocabulary in current goad enum)
::
::  Goad shape (from /-  goon):
::    +$  goad  (trel iota (list attr) (list goad))
::    iota   = $@(@t (pair aura @))           :: name / key
::    attr   = %key %lede %info %value %edit %add %act %click
::
::  Reuses ++has door from /lib/goon.hoon for typed attr extraction.
::
/-  goon, *tui-engine
/+  *goon
=,  goon
|%
++  goad-to-dei
  |=  g=goad
  ^-  dei
  ~[(walk g)]
::
++  walk
  |=  g=goad
  ^-  deus
  =/  [i=iota attrs=(list attr) kids=(list goad)]  g
  =/  hed=tape  (heading-text i attrs)
  =/  inf=tape
    =/  u=(unit @t)  ~(info has attrs)
    ?~(u "" (trip u.u))
  =/  val=tape
    =/  u=(unit iota)  ~(value has attrs)
    ?~(u "" (iota-text u.u))
  ?~  kids
    (compose-leaf hed inf val)
  =/  child-deus=dei  (turn kids walk)
  (compose-branch hed inf child-deus)
::  +heading-text: lede attr (full text via trip) else iota-text fallback.
::
++  heading-text
  |=  [i=iota attrs=(list attr)]
  ^-  tape
  =/  u=(unit @t)  ~(lede has attrs)
  ?~  u  (iota-text i)
  (trip u.u)
::  +iota-text: print iota for display.
::
::    iota = $@(@t (pair aura @)). Bare @t → trip directly. Pair →
::    +scot the aura+atom to a printable @t, then trip.
::
++  iota-text
  |=  i=iota
  ^-  tape
  ?@  i  (trip i)
  (trip (scot p.i q.i))
::  +to-lina: tape → lina (list @c). Explicit widening from @tD to @c.
::
++  to-lina
  |=  txt=tape
  ^-  lina
  %+  turn  txt
  |=(c=@ ;;(@c c))
::
++  text-deus
  |=  txt=tape
  ^-  deus
  ::  Empty input is floored to size [1 1] with a single space row to
  ::  keep viso-pure from seeing a zero-area frame.
  ::
  =/  src=tape  ?:(=("" txt) " " txt)
  =/  w=@ud     (lent src)
  =/  ln=lina   (to-lina src)
  =/  vx=vox    ~[ln]
  =/  text-res=res
    :*  size=[w=w h=`@ud`1]
        padd=`muri`[0 0 0 0]
        marg=`muri`[0 0 0 0]
        bord=`muri`[0 0 0 0]
        flex=`modi`[0 0]
        flow=`fuga`[%col %clip]
        look=`fila`[~ ~ ~]
        sele=`acia`[~ ~ ~]
    ==
  =/  cor-val=cor
    :*  apex=[1 1]
        avis=`avis`/
        res=text-res
        ars=[%text vx]
    ==
  [cor-val [b=~ l=~ n=~]]
::
++  layer-deus
  |=  kids=dei
  ^-  deus
  ::  Column flow only (V1). Width = max child width; height = sum of
  ::  child heights. Floored at [1 1] for empty children list.
  ::
  =/  [w=@ud h=@ud]
    %+  roll  kids
    |=  [d=deus a=[w=@ud h=@ud]]
    [(max w.a w.size.res.cor.d) (add h.a h.size.res.cor.d)]
  =/  w-floor=@ud  ?:(=(0 w) 1 w)
  =/  h-floor=@ud  ?:(=(0 h) 1 h)
  =/  layer-res=res
    :*  size=[w=w-floor h=h-floor]
        padd=`muri`[0 0 0 0]
        marg=`muri`[0 0 0 0]
        bord=`muri`[0 0 0 0]
        flex=`modi`[0 0]
        flow=`fuga`[%col %clip]
        look=`fila`[~ ~ ~]
        sele=`acia`[~ ~ ~]
    ==
  =/  cor-val=cor
    :*  apex=[1 1]
        avis=`avis`/
        res=layer-res
        ars=[%layer ~]
    ==
  [cor-val [b=~ l=~ n=kids]]
::  +compose-leaf: leaf goad → deus.
::
::    Single content piece renders as a bare text deus; multiple pieces
::    stack as a layer.
::
++  compose-leaf
  |=  [hed=tape inf=tape val=tape]
  ^-  deus
  =/  pieces=dei
    %-  zing
    :~  ?:(=("" hed) ~ ~[(text-deus hed)])
        ?:(=("" val) ~ ~[(text-deus val)])
        ?:(=("" inf) ~ ~[(text-deus inf)])
    ==
  ?~  pieces  (text-deus "")
  ?~  t.pieces  i.pieces
  (layer-deus pieces)
::  +compose-branch: branch goad → deus.
::
::    Heading row + optional info row + child deus, all in n.gens of a
::    single %layer.
::
++  compose-branch
  |=  [hed=tape inf=tape kids=dei]
  ^-  deus
  =/  pieces=dei
    %-  zing
    :~  ?:(=("" hed) ~ ~[(text-deus hed)])
        ?:(=("" inf) ~ ~[(text-deus inf)])
        kids
    ==
  (layer-deus pieces)
--
