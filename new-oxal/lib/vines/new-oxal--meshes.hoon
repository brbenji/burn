::  /ted/http-oxal--meshes  :  list page (CRUD over all meshes in the acer)
::
::    GET   /new-oxal/meshes   list of meshes + create form
::    POST  /new-oxal/meshes   op=new-mesh / reinstall-mesh poke oxal with
::                         %load-mesh; op=delete-mesh pokes %drop-mesh.
::
/+  *vineio, *zozo
::
=<
::
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
?:  =('POST' method.bowl)
  =/  form=(map @t @t)  formencoded-body:vio
  =/  op=@t  (~(gut by form) 'op' '')
  ?:  =('new-mesh' op)
    =/  name=term   (~(got by form) 'name')
    =/  src=@t      (fix-newlines (~(got by form) 'source'))
    ;<  ~  bind:m  (poke-our:vio %load-mesh !>([name `mesh-source`[%mono src]]))
    ;<  ~  bind:m
      %+  send-simple-payload:vio
        [303 ['location' '/new-oxal/meshes']~]
      ~
    (pure:m !>(~))
  ?:  =('new-poly-mesh' op)
    =/  name=term  (~(got by form) 'name')
    ;<  ~  bind:m  (poke-our:vio %load-mesh !>([name `mesh-source`[%poly ~]]))
    ;<  ~  bind:m
      %+  send-simple-payload:vio
        [303 ['location' (crip "/new-oxal/mesh/{(trip name)}")]~]
      ~
    (pure:m !>(~))
  ?:  =('delete-mesh' op)
    =/  name=term  (~(got by form) 'name')
    ;<  ~  bind:m  (poke-our:vio %drop-mesh !>(name))
    ;<  ~  bind:m
      %+  send-simple-payload:vio
        [303 ['location' '/new-oxal/meshes']~]
      ~
    (pure:m !>(~))
  ?:  =('reinstall-mesh' op)
    ::
    ::  ux convenience: read stored source and re-poke %load-mesh.
    ::
    =/  name=term  (~(got by form) 'name')
    ;<  ax=acer  bind:m  (scry ,acer /gx/new-oxal/acer/noun)
    =/  =mesh  (got-mesh ax name)
    ;<  ~  bind:m  (poke-our:vio %load-mesh !>([name mesh-source.mesh]))
    ;<  ~  bind:m
      %+  send-simple-payload:vio
        [303 ['location' '/new-oxal/meshes']~]
      ~
    (pure:m !>(~))
  ::  unknown op: bounce back unchanged.
  ::
  ;<  ~  bind:m
    %+  send-simple-payload:vio
      [303 ['location' (spat (welp [prefix rest]:bowl))]~]
    ~
  (pure:m !>(~))
::
;<  =acer  bind:m  (scry ,acer /gx/new-oxal/acer/noun)
;<  ~  bind:m
  %-  send-simple-payload:vio
  %+  node-to-simple-payload  %manx
  (render-list bowl meshes.acer)
(pure:m !>(~))
::
|%
++  render-list
  ::
  ::  list page: header, mesh rows, create form.
  ::
  |=  [bowl=http-bowl aps=(list [name=term =mesh])]
  ^-  manx
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
      ;title: oxal meshes
      ;link(rel "icon", href "data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\"/>");
      ;link(rel "stylesheet", href "/hawk-init/feather/1/style");
      ;script(type "module", src "/hawk-init/feather/1/textarea");
    ==
    ;body.p5.fc.g5.pb15
      ;h1: meshes
      ;div.fr.g3.f4.o6
        ;span
          ;-  "{(scow %ud (lent aps))} mesh"
          ;-  ?:(=(1 (lent aps)) "" "es")
        ==
      ==
      ;div.fc.g3
        ;*
        =;  =marl  ?^  marl  marl
          ;=
            ;div.p3.bd1.br2.o6: no meshes
          ==
        %+  turn  aps
        |=  [name=term =mesh]
        (render-row bowl name mesh)
      ==
      ;div.fc.g3.bdt1.pt5
        ;h2: create mesh
        ;form.fc.g2(method "post")
          ;input(type "hidden", name "op", value "new-mesh");
          ;label.fc.g2
            ;span: name
            ;input.p-2.br2.bd1.mono
              =type  "text"
              =name  "name"
              =placeholder  "my-mesh"
              =required  ""
              =spellcheck  "false"
              ;*  ~
            ==
          ==
          ;label.fc.g2
            ;span: source
            ;feather-textarea.p3.mono.br2.bd1.fs-2
              =name  "source"
              =rows  "18"
              =placeholder  "|_  [our=@p name=term]  ++  forms  ...  ++  load  |=(=prior-forms ...)  ++  drop  |=(=prior-forms ...)  --"
              =required  ""
              =spellcheck  "false"
              ;*  ~
            ==
          ==
          ;div.fr.g2.ac
            ;button.p-2.br2.bd1.b2.hover: create
          ==
        ==
      ==
      ;div.fc.g3.bdt1.pt5
        ;h2: create poly mesh
        ;form.fc.g2(method "post")
          ;input(type "hidden", name "op", value "new-poly-mesh");
          ;label.fc.g2
            ;span: name
            ;input.p-2.br2.bd1.mono
              =type  "text"
              =name  "name"
              =placeholder  "my-poly-mesh"
              =required  ""
              =spellcheck  "false"
              ;*  ~
            ==
          ==
          ;div.fr.g2.ac
            ;button.p-2.br2.bd1.b2.hover: create
          ==
        ==
      ==
    ==
  ==
::
++  render-row
  ::
  ::  one row in the meshes list: link, view-count, delete form.
  ::
  |=  [bowl=http-bowl name=term =mesh]
  ^-  manx
  =/  href=tape  (trip (spat /new-oxal/mesh/[name]))
  =/  views=@ud  ~(wyt by views.mesh)
  ;div.fr.g3.p3.bd1.br2.b2.ac
    ;a.bold.mono.grow.hover
      =href  href
      ;-  (trip name)
    ==
    ;span.o6.fs-2
      ;-  "{(scow %ud views)} view"
      ;-  ?:(=(1 views) "" "s")
    ==
    ;form(method "post")
      ;input(type "hidden", name "op", value "reinstall-mesh");
      ;input(type "hidden", name "name", value (trip name));
      ;button.p-2.br2.bd1.b2.hover.f-1: reinstall
    ==
    ;form(method "post")
      ;input(type "hidden", name "op", value "delete-mesh");
      ;input(type "hidden", name "name", value (trip name));
      ;button.p-2.br2.bd1.b3.hover.f-1: delete
    ==
  ==
--
