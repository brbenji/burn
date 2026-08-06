::
::  /sur/tui-engine.hoon — TUI render types
::
::  Scavenged from ~rovnys-ricfer/homunculus
::  (homunculus/desk/app/homunculus.hoon, lines 7-130).
::
::  Window-manager state types (ego, urbs, via/viae, ara/arae, frame
::  layout, hotkey routing, input event translation, sail/form data)
::  intentionally excluded — this lib is layout + render only.
::
::  Excluded (vs homunculus app file):
::    omen, zona, nota, lex, ales, aves     :: input/hotkey routing
::    data, vela, fons                       :: sail / form-data refs
::    ara, arae, via, viae, aula             :: session / frame state
::    arx, urbs, cura, acro, ego             :: agent state
::    card                                   :: Gall integration
::
::  Kept: deus/dei/gens/cor/res/ars; coord types; vox/lina text;
::  fila/acia/fuga style+flow; sol/lux render schematic; aer render
::  context (kept whole — usage-site narrows fields trivially);
::  opus render batch; dux/rex/ordo selection types (referenced by
::  lux.nav and aer.nav — keep type contract for verbatim arm lift,
::  populate as `~` at use-time); ossa/os line-intersection state;
::  crux intersection record; as/aqua/vena sizing types.
::
::  `tint`/`deco` are lull-global (see sys/lull.hoon ~lines 502, 522).
::
/-  goon
|%
+$  deus  [=cor =gens]                                                 :: an element
+$  dei   (list deus)                                                  :: elements
+$  gens  $~(~^~^~ [b=dei l=dei n=dei])                                :: elements within an element
+$  cor   [=apex =avis =res =ars]                                      :: attributes of an element
+$  res                                                                :: perceptible attributes of an element
  $:  size=[w=@ud h=@ud]                                               ::   size
      padd=muri                                                        ::   padding
      marg=muri                                                        ::   margin
      bord=muri                                                        ::   border sizes
      flex=modi                                                        ::   child element positioning: justify
      flow=fuga                                                        ::   child element positioning: sequence
      look=fila                                                        ::   style
      sele=acia                                                        ::   select style
  ==                                                                   ::
+$  ars                                                                :: element types
  $%  [%text =vox]                                                     ::
      [%pattern =vox]                                                  ::
      [%layer ~]                                                       ::
      [%scroll =equi =iter =sola]                                      ::
      [%border =ad =ora]                                               ::
      [%line =ab =ora]                                                 ::
      [%select pro=?(%submit %~)]                                      ::
      [%input de=@ud i=loci =vox]                                      ::
      [%checkbox v=? t=vox f=vox]                                      ::
      [%radio ~]                                                       ::
      [%form ~]                                                        ::
      [%$ ~]                                                           ::
  ==                                                                   ::
+$  avis  path                                                         :: identifier
+$  apex  $~([1 1] loci)                                               :: top left coordinate of an element
+$  loci  [x=@ud y=@ud]                                                :: coordinates
+$  modi  [x=@ud y=@ud]                                                :: box extent
+$  muri  [l=@ud r=@ud t=@ud b=@ud]                                    :: box sides
+$  rami  (list [=axis =ager])                                         :: element key (null is root)
+$  axis  ?(%n %l %b)                                                  :: element positioning category
+$  ager  @ud                                                          :: element list index
+$  vox   (list lina)                                                  :: rows of text
+$  lina  (list @c)                                                    :: a row of text
+$  fila  [d=(set deco) b=tint f=tint]                                 :: element style
+$  acia  [d=(unit (set deco)) b=(unit tint) f=(unit tint)]            :: alternate element style
+$  fuga  [d=?(%col %row) b=?(%wrap %clip)]                            :: positioning flow
+$  iter  modi                                                         :: scroll position
+$  sola  modi                                                         :: scroll content dimensions
+$  equi  [u=(unit as) d=(unit as)]                                    :: scroll triggers
+$  ad    ?(%l %r %t %b)                                               :: direction
+$  ab    ?(%h %v)                                                     :: orientation
+$  ora   ?(%light %heavy %double %arc %~)                             :: line style
+$  luna  (map @ud (list lux))                                         :: render blocking context (key is y)
+$  sol   (list (list lux))                                            :: render schematic matrix
+$  lux                                                                :: render token
  $:  x1=@ud                                                           ::   beginning of segment
      x2=@ud                                                           ::   end of segment
      $=  p                                                            ::   segment content
      $@  ~                                                            ::   in rendering, null p is a gap
      $:  fil=fila                                                     ::   segment style
          nav=rex                                                      ::   possible navigation point
          txt=lina                                                     ::   possible character content (else space)
  ==  ==                                                               ::
+$  aer                                                                :: branch render context
  $:  =iter                                                            ::   cumulative scroll
      =muri                                                            ::   cumulative limit coordinates
      nav=[sty=? =rex]                                                 ::   nav hierarchy (do select style, originating element)
      =rex                                                             ::   global active selection
      =ossa                                                            ::   global line intersections
      =luna                                                            ::   layer blocking
  ==                                                                   ::
+$  opus  (list [=apex =sol])                                          :: render batch (hop on null sol)
+$  dux   [n=@tas k=rami =avis muri]                                   :: navigation point
+$  rex   $@(~ dux)                                                    :: selection
+$  ordo  (list dux)                                                   :: navigation context
+$  ossa  (map rami (map rami os))                                     :: line groups for a session
+$  os                                                                 :: line data for intersections
  $%  [%h p=?(%border %line) x1=@ud x2=@ud y=@ud =ora]                 ::
      [%v p=?(%border %line) x=@ud y1=@ud y2=@ud =ora]                 ::
  ==                                                                   ::
+$  crux  [v=ab i=@ud c=ora l=ora r=ora t=ora b=ora]                   :: line intersection
+$  as    $%((pair %c @ud) (pair %p @ud) (pair %i @ud))                :: size unit
+$  aqua  (list [i=@ud size=@ud marg=@ud])                             :: geno grow sizing state
+$  vena                                                               :: geno res building state
  $:  size=[w=as h=as]                                                 ::
      padd=[l=as r=as t=as b=as]                                       ::
      marg=[l=as r=as t=as b=as]                                       ::
      flex=modi                                                        ::
      flow=fuga                                                        ::
      look=acia                                                        ::
  ==                                                                   ::
::
::  T10 (session-local navigation) — structured render output for the
::  JS-side renderer. Carries rows + per-row tree metadata (path, parent,
::  depth) so JS owns accordion / viewport-reactivity / multi-tab focus
::  without re-asking the agent. Emitted from %burn-tui on /tui
::  alongside legacy %blit during T10.0; %blit retires in T10.3. Cells
::  separate text from style so JS can re-truncate at any width without
::  losing per-row styling. See T10-SCOPE.md.
::
::  %act variant carries the goon act list so the JS dispatcher fires
::  the picked term back without the agent needing per-path %click
::  translation. See TUI-ACT-DISPATCH-SPEC.md.
::
+$  interact-kind
  $%  [%click ~]
      [%act acts=(list act:goon)]
      [%edit ~]
      [%add ~]
  ==
+$  tui-cell  [text=tape =fila]                                        :: row segment + style
+$  tui-row
  $:  path=path                                                        ::   goad path of this row
      parent=path                                                      ::   ancestor for accordion
      depth=@ud                                                        ::   tree depth (len of here)
      kind=?(%head %info %leaf)                                        ::   variant
      pad-left=@ud                                                     ::   authored indent (T9.5)
      cells=(list tui-cell)                                            ::   one cell in T10.0
      focusable=(unit interact-kind)                                   ::   ~ when non-focusable
  ==
+$  tui-frame
  $:  rows=(list tui-row)                                              ::   full tree, top-down
      authored-width=@ud                                               ::   render canon width
      total-height=@ud                                                 ::   row count
  ==
--
