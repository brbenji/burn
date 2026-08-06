::  /gen/oxal/poke-move: poke %oxal with %do-move and a (set chng)
::
::    `+oxal!poke-move chngs` pokes %oxal with the supplied (set chng)
::    via the %do-move mark.  intended as a temporary investigation
::    helper so external clients can mutate the oxal tree from the dojo
::    without a dedicated mark file.
::
/+  *zozo
::
:-  %say
|=  $:  [now=@da eny=@uvJ bec=beak]
        [chngs=(set chng) ~]
        ~
    ==
:-  %do-move
chngs
