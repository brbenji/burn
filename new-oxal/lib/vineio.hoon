/-  *vine
/+  *strandio
/+  *zozo
|%
++  init
  ::
  =/  m  (strand ,http-bowl)
  ;<  args=vase  bind:m  (take-poke %http-bowl)
  %-  pure:m
  !<  http-bowl  args
  ::
++  server
  |_  http-bowl
  ++  get-header
    ::
    |=  header=@t
    ^-  (unit @t)
    (get-header:http header header-list)
    ::
  ++  poke-our
    ::
    |=  =cage
    =/  m  (strand ,~)
    ^-  form:m
    ;<  ~  bind:m  (^poke-our dap cage)
    (sleep ~s0)
    ::
  ++  soft-poke-our
    ::
    ::  poke our own agent and return the nack tang, if any: ~ on ack,
    ::  [~ tang] on nack.  does not crash the thread on nack, so callers
    ::  can render an error response.
    ::
    |=  =cage
    =/  m  (strand ,(unit tang))
    ^-  form:m
    =/  =card:agent:gall  [%pass /poke %agent [our dap] %poke cage]
    ;<  ~  bind:m  (send-raw-card card)
    |=  tin=strand-input:strand
    ?+  in.tin  `[%skip ~]
        ~  `[%wait ~]
        [~ %agent * %poke-ack *]
      ?.  =(/poke wire.u.in.tin)
        `[%skip ~]
      `[%done p.sign.u.in.tin]
    ==
    ::
  ++  soft-watch-our
    ::
    ::  watch our own agent and return the nack tang, if any: ~ on ack,
    ::  [~ tang] on nack.  does not crash the thread on nack, so callers
    ::  can render an error response.
    ::
    |=  [=wire =path]
    =/  m  (strand ,(unit tang))
    ^-  form:m
    =/  =card:agent:gall  [%pass watch+wire %agent [our dap] %watch path]
    ;<  ~  bind:m  (send-raw-card card)
    |=  tin=strand-input:strand
    ?+  in.tin  `[%skip ~]
        ~  `[%wait ~]
        [~ %agent * %watch-ack *]
      ?.  =(watch+wire wire.u.in.tin)
        `[%skip ~]
      `[%done p.sign.u.in.tin]
    ==
    ::
  ++  send-head
    ::
    |=  =response-header:http
    =/  m  (strand ,~)
    ^-  form:m
    =/  paths  ~[/http-response/[rid]]
    %-  send-raw-card
    [%give %fact paths %http-response-header !>(response-header)]
    ::
  ++  send-data
    ::
    |=  =(unit octs)
    =/  m  (strand ,~)
    ^-  form:m
    =/  paths  ~[/http-response/[rid]]
    %-  send-raw-card
    [%give %fact paths %http-response-data !>(unit)]
    ::
  ++  send-kick
    ::
    =/  m  (strand ,~)
    ^-  form:m
    =/  paths  ~[/http-response/[rid]]
    %-  send-raw-card
    [%give %kick paths ~]
    ::
  ++  send-simple-payload
    ::
    |=  pl=simple-payload:http
    =/  m  (strand ,~)
    ^-  form:m
    =/  paths  ~[/http-response/[rid]]
    %-  send-raw-cards
    :~  [%give %fact paths %http-response-header !>(-.pl)]
        [%give %fact paths %http-response-data !>(+.pl)]
        [%give %kick paths ~]
    ==
    ::
  ++  send-html-payload
    ::
    |=  =manx
    %+  send-simple-payload
      [200 ['content-type' 'text/html']~]
    :-  ~
    %-  as-octt:mimes:html
    %+  welp
      ?.  ?=(%html n.g.manx)  ""
      "<!doctype html>"
    %-  en-xml:html
    manx
    ::
  ++  open-sse
    ::
    ::  send the text/event-stream response headers
    ::
    =/  m  (strand ,~)
    ^-  form:m
    =/  paths  ~[/http-response/[rid]]
    =/  =response-header:http
      :-  200
      :~  ['content-type' 'text/event-stream']
          ['cache-control' 'no-cache']
          ['Connection' 'keep-alive']
      ==
    %-  send-raw-card
    [%give %fact paths %http-response-header !>(response-header)]
    ::
  ++  close-sse
    ::
    ::  end the SSE stream with a kick
    ::
    =/  m  (strand ,~)
    ^-  form:m
    %-  send-raw-card
    [%give %kick ~[/http-response/[rid]] ~]
    ::
  ++  keep-alive
    ::
    ::  send an SSE keep-alive comment
    ::
    =/  m  (strand ,~)
    ^-  form:m
    %-  send-raw-card
    :*  %give  %fact  ~[/http-response/[rid]]  %http-response-data
        !>(`(unit octs)``(as-octs:mimes:html ': keep-alive\0a\0a'))
    ==
    ::
  ++  patch
    ::
    ::  send signals and fragments in a single datastar response.  emits a
    ::  datastar-patch-signals event followed by one datastar-patch-elements
    ::  event per fragment.
    ::
    |=  [sig-list=(list (pair @t @t)) fragments=(list datastar-fragment)]
    =/  m  (strand ,~)
    ^-  form:m
    =/  body=octs
      (as-octs:mimes:html (datastar-response-body sig-list fragments))
    %-  send-raw-card
    :*  %give  %fact  ~[/http-response/[rid]]  %http-response-data
        !>(`(unit octs)``body)
    ==
    ::
  ++  patch-signals
    ::
    ::  send a datastar-patch-signals event with the given signals
    ::
    |=  sig-list=(list (pair @t @t))
    (patch sig-list ~)
    ::
  ++  patch-elements
    ::
    ::  send a datastar-patch-elements event for each fragment
    ::
    |=  fragments=(list datastar-fragment)
    (patch ~ fragments)
    ::
  ++  patch-element
    ::
    ::  send a single fragment with the given mode, optional selector, and manx
    ::
    |=  fragment=datastar-fragment
    (patch ~ ~[fragment])
    ::
  ++  morph
    ::
    ::  send a single manx with mode "outer" — datastar's default,
    ::  which morphs the matching top-level element by id
    ::
    |=  =manx
    (patch ~ ~[["outer" ~ manx]])
    ::
  ++  formencoded-body
    ::
    ^-  (map @t @t)
    %-  fall  :_  ~
    %-  mole  |.
    (malt (rash +:(need body) yquy:de-purl:html))
    ::
  --
--