/+  *vineio
::
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
;<  bindings=(list [=binding:eyre =duct action=action:eyre])  bind:m
  %+  scry
    ,(list [binding:eyre duct action:eyre])
  /e/bindings
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
      ;title: eyre bindings
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
    ==
    ;body.fc.bbv.p5.pb15
      ::
      ;h1.pb3: eyre bindings
      ::
      ;*
      %+  turn  bindings
      |=  [=binding:eyre =duct action=action:eyre]
      ;div.fr.g3.py2
        ;span.o6.f4
          ;-  ?~  site.binding  "host:*"
              (weld "host:" (trip u.site.binding))
        ==
        ;span.bold
          ;-  (spud path.binding)
        ==
        ;span.o6
          ;-  <action>
        ==
      ==
    ==
  ==
::
(pure:m !>(~))