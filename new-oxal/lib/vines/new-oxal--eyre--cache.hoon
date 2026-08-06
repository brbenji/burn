::  /ted/http-oxal--eyre-cache  :  render summary of eyre bindings
::
/+  *vineio, *zozo
::
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
;<  cache=(map @t [aeon=@ud val=(unit cache-entry:eyre)])  bind:m
  %+  scry  ,(map @t [aeon=@ud val=(unit cache-entry:eyre)])
  /e/cache
::
=/  hymn=manx
  :::
  ;html
    ;head
      ;meta(charset "UTF-8");
      ;meta
        =name  "viewport"
        =content  "width=device-width, ".
                  "initial-scale=1, ".
                  "maximum-scale=1, ".
                  "user-scalable=no, ".
                  "viewport-fit=cover"
        ;*  ~
      ==
      ;title: eyre cache
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
    ==
    ;body.p5.fc.g5.pb15
      ;div.fc.bbv
        ;strong.pb4: cache
        ;*
        =/  pathified
          %+  sort
            %+  murn  ~(tap by cache)
            |=  [=cord aeon=@ud val=(unit cache-entry:eyre)]
            ?.  (starts-with (spat rest.bowl) cord)  ~
            `[cord aeon val]
          |=  [a=[=cord *] b=[=cord *]]
          (aor cord.a cord.b)
        %+  turn  pathified
        |=  [url=cord aeon=@ud val=(unit cache-entry:eyre)]
        %^  add-class-if  ?=(~ val)  "o3"
        ;a.fr.p2.g4.b2.hover
          =href  (trip url)
          ;span: {(trip url)}
          ;span.o5: {<aeon>}
          ;span.grow;
          ;*  ?~  val  ~
              =/  pl  simple-payload.body.u.val
              ;=
                ;span
                  ;-  ?:  auth.u.val  "private"  "public"
                ==
                ;span: {<status-code.response-header.pl>}
              ==
        ==
      ==
    ==
  ==
::
;<  ~  bind:m
  %-  send-simple-payload:vio
  %+  node-to-simple-payload  %manx
  hymn
::
(pure:m !>(~))