::  /mar/tui-frame.hoon — T10 structured render frame.
::
::  Per T10-SCOPE.md, carries the full pre-rendered tree as data so JS
::  owns ephemeral UI state (focus / scroll / editing / accordion).
::  Emitted on /tui alongside legacy %blit during T10.0 (dual-emit);
::  %blit retires in T10.3. Type lives in /sur/tui-engine.hoon.
::
::  JSON shape (consumed by xterm.js renderer in T10.1):
::    { rows: [ { path: [..], parent: [..], depth, kind, padLeft,
::                cells: [ { text, fila: { d, b, f } } ],
::                focusable: null
::                         | { kind: "click" }
::                         | { kind: "act", acts: [{term, lede, info}, ..] }
::                         | { kind: "edit" }
::                         | { kind: "add" } } ],
::      authoredWidth, totalHeight }
::
::  Tint encoding: lull-atoms (%r %g %b %c %m %y %k %w) as single-char
::  strings; the %~ "no color" variant emits JSON null; 24-bit tints
::  emit { r, g, b } objects. Deco set emits an array of "bl"|"br"|"un".
::
/-  *tui-engine, goon
|_  frame=tui-frame
++  grab
  |%
  ++  noun  tui-frame
  --
++  grow
  |%
  ++  noun  frame
  ++  json  (en-frame frame)
  --
++  grad  %noun
::
++  en-frame
  |=  f=tui-frame
  ^-  json
  =,  enjs:format
  %-  pairs
  :~  ['rows' a+(turn rows.f en-row)]
      ['authoredWidth' (numb authored-width.f)]
      ['totalHeight' (numb total-height.f)]
  ==
::
++  en-row
  |=  r=tui-row
  ^-  json
  =,  enjs:format
  %-  pairs
  :~  ['path' (en-path path.r)]
      ['parent' (en-path parent.r)]
      ['depth' (numb depth.r)]
      ['kind' (en-row-kind kind.r)]
      ['padLeft' (numb pad-left.r)]
      ['cells' a+(turn cells.r en-cell)]
      ['focusable' ?~(focusable.r ~ (en-focusable u.focusable.r))]
  ==
::
++  en-cell
  |=  c=tui-cell
  ^-  json
  =,  enjs:format
  %-  pairs
  :~  ['text' s+(crip text.c)]
      ['fila' (en-fila fila.c)]
  ==
::
++  en-fila
  |=  fi=fila
  ^-  json
  =,  enjs:format
  %-  pairs
  :~  ['d' a+(turn ~(tap in d.fi) en-deco)]
      ['b' (en-tint b.fi)]
      ['f' (en-tint f.fi)]
  ==
::
::  tint + deco encoding mirrors lib/dill.hoon:46-53 — `s+tas` for atom
::  variants, `~` for the %~ no-color and ~ no-deco sentinels, object for
::  24-bit tints.
::
++  en-tint
  |=  t=tint
  ^-  json
  ?@  t  ?~(t ~ s+t)
  =,  enjs:format
  (pairs ~[['r' (numb r.t)] ['g' (numb g.t)] ['b' (numb b.t)]])
::
++  en-deco
  |=  d=deco
  ^-  json
  ?~(d ~ s+d)
::
::  +en-focusable: serialize the unwrapped interact-kind tagged union.
::    All variants emit { kind: "<tag>" }; %act additionally emits
::    `acts` as an array of { term, lede, info } objects so the JS
::    dispatcher knows which act-term to send back on Enter.
::
++  en-focusable
  |=  k=interact-kind
  ^-  json
  =,  enjs:format
  ?-  -.k
      %click
    (pairs ~[['kind' s+'click']])
  ::
      %edit
    (pairs ~[['kind' s+'edit']])
  ::
      %add
    (pairs ~[['kind' s+'add']])
  ::
      %act
    %-  pairs
    :~  ['kind' s+'act']
        ['acts' a+(turn acts.k en-act)]
    ==
  ==
::
++  en-act
  |=  a=act:goon
  ^-  json
  =,  enjs:format
  %-  pairs
  :~  ['term' s+p.a]
      ['lede' s+lede.q.a]
      ['info' s+info.q.a]
  ==
::
++  en-row-kind
  |=  k=?(%head %info %leaf)
  ^-  json
  ?-  k
    %head  s+'head'
    %info  s+'info'
    %leaf  s+'leaf'
  ==
::
++  en-path
  |=  p=path
  ^-  json
  [%a (turn p |=(s=@ta s+s))]
--
