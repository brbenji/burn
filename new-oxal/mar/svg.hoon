
::
::::  /hoon/png/mar
  ::
/?    310
=,  eyre
=,  mimes:html
|_  mud=@t
++  grow                                                ::  convert to
  |%  
  ++  mime  [/image/svg (as-octs mud)]               ::  convert to %mime
  --
++  grab
  |%                                                    ::  convert from
  ++  mime  |=([p=mite q=octs] q.q)
  ++  noun  @t                                         ::  clam from %noun
  --
++  grad  %mime
--
