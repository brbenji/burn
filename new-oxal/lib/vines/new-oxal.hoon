::  /lib/vines/new-oxal  :  bare-prefix homepage for /new-oxal
::
/+  *vineio
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
;<  ~  bind:m
  %-  send-simple-payload:vio
  %+  node-to-simple-payload  %manx
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
      ;title: new-oxal
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;link(rel "stylesheet", href "/new-oxal-init/feather/1/style");
    ==
    ;body.p4.pb15.fc.g6
      ;strong: new-oxal
      ;div.fc.bbv
        ;*
        %+  turn
          ^-  (list path)
          :~
            /meshes
            /gall/sky
            /gall/sup
            /eyre/cache
            /eyre/bindings
            /plex
            /plex-tui
            /goon
          ==
        |=  =path
        ;a.underline.py3.b1.hover
          =href  (spud :(welp prefix.bowl rest.bowl path))
          ;-  (spud path)
        ==
      ==
    ==
  ==
::
(pure:m !>(~))
