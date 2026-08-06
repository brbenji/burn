/+  *zozo-zero
^-  data
%-  mono
:-  %manx
;section
  ;h2: Zozo CSS
  ;p
    ;code: %feather-1
    ;  views automatically load a utility CSS stylesheet. All classes use short, composable names.
  ==
  ;h3: Layout
  ;ul
    ;li
      ;code: .fc
      ;  — flex column
    ==
    ;li
      ;code: .fr
      ;  — flex row
    ==
    ;li
      ;code: .frw
      ;  — flex row, wrap
    ==
    ;li
      ;code: .fcr
      ;  — flex column, reverse
    ==
    ;li
      ;code: .grow
      ;  — flex-grow: 1
    ==
    ;li
      ;code: .shrink-none
      ;  — flex-shrink: 0
    ==
    ;li
      ;code: .shrink-1
      ;  — flex-shrink: 1
    ==
  ==
  ;h3: Alignment
  ;ul
    ;li
      ;code: .jc
      ;  — justify-content: center
    ==
    ;li
      ;code: .jb
      ;  — justify-content: space-between
    ==
    ;li
      ;code: .ac
      ;  — align-items: center
    ==
    ;li
      ;code: .af
      ;  — align-items: stretch
    ==
  ==
  ;h3: Spacing
  ;p
    ; Padding (
    ;code: .pN
    ; ), margin (
    ;code: .mN
    ; ), and gap (
    ;code: .gN
    ; ) where N ranges from 0 to 10. Directional variants:
  ==
  ;ul
    ;li
      ;code: .p2
      ;  — padding all sides, scale 2
    ==
    ;li
      ;code: .p-3
      ;  — asymmetric padding (smaller x, larger y)
    ==
    ;li
      ;code: .px2
      ; ,
      ;code: .py2
      ;  — horizontal/vertical padding
    ==
    ;li
      ;code: .pl2
      ; ,
      ;code: .pr2
      ; ,
      ;code: .pt2
      ; ,
      ;code: .pb2
      ;  — directional padding
    ==
    ;li
      ;code: .m2
      ; ,
      ;code: .mx2
      ; ,
      ;code: .my2
      ; ,
      ;code: .ml2
      ; ,
      ;code: .mr2
      ; ,
      ;code: .mt2
      ; ,
      ;code: .mb2
      ;  — same for margin
    ==
    ;li
      ;code: .g4
      ;  — gap between flex children
    ==
  ==
  ;h3: Sizing
  ;ul
    ;li
      ;code: .wN
      ; ,
      ;code: .hN
      ;  — width/height (N=0-20, scaled)
    ==
    ;li
      ;code: .wf
      ; ,
      ;code: .hf
      ;  — width/height 100%
    ==
    ;li
      ;code: .min-wN
      ; ,
      ;code: .max-wN
      ; ,
      ;code: .min-hN
      ; ,
      ;code: .max-hN
      ;  — min/max constraints
    ==
  ==
  ;h3: Typography
  ;ul
    ;li
      ;code: .mono
      ; ,
      ;code: .serif
      ; ,
      ;code: .sans
      ;  — font family
    ==
    ;li
      ;code: .bold
      ; ,
      ;code: .italic
      ; ,
      ;code: .underline
      ;  — text style
    ==
    ;li
      ;code: .pre
      ; ,
      ;code: .nowrap
      ;  — whitespace handling
    ==
    ;li
      ;code: .fsN
      ;  — font size (N from -4 to 10)
    ==
    ;li
      ;code: .lhN
      ;  — line height (N from 0 to 4)
    ==
    ;li
      ;code: .tl
      ; ,
      ;code: .tc
      ; ,
      ;code: .tr
      ;  — text-align left/center/right
    ==
  ==
  ;h3: Colors
  ;ul
    ;li
      ;code: .fN
      ;  — foreground color (0=darkest, 10=lightest)
    ==
    ;li
      ;code: .bN
      ;  — background color (0=lightest, 10=darkest)
    ==
    ;li
      ;code: .f-1
      ; ,
      ;code: .b-1
      ;  — red (semantic)
    ==
    ;li
      ;code: .f-2
      ; ,
      ;code: .b-2
      ;  — orange
    ==
    ;li
      ;code: .f-3
      ; ,
      ;code: .b-3
      ;  — green
    ==
    ;li
      ;code: .f-4
      ; ,
      ;code: .b-4
      ;  — blue
    ==
    ;li
      ;code: .oN
      ;  — opacity (0=transparent, 10=opaque)
    ==
  ==
  ;h3: Borders
  ;ul
    ;li
      ;code: .bdN
      ;  — border width (1-3)
    ==
    ;li
      ;code: .bdtN
      ; ,
      ;code: .bdbN
      ; ,
      ;code: .bdlN
      ; ,
      ;code: .bdrN
      ;  — directional borders
    ==
    ;li
      ;code: .brN
      ;  — border-radius (0-10)
    ==
    ;li
      ;code: .bcN
      ;  — border color (0-10)
    ==
    ;li
      ;code: .bbv
      ;  — vertical dividers between children
    ==
    ;li
      ;code: .bbh
      ;  — horizontal dividers between children
    ==
  ==
  ;h3: Interactive
  ;ul
    ;li
      ;code: .hover
      ;  — highlight on hover
    ==
    ;li
      ;code: .focus
      ;  — ring outline on focus
    ==
    ;li
      ;code: .pulser
      ;  — pulse animation on hover
    ==
    ;li
      ;code: .active
      ;  — active press state
    ==
    ;li
      ;code: .disabled
      ;  — dimmed, non-interactive
    ==
    ;li
      ;code: .pointer
      ;  — cursor: pointer
    ==
    ;li
      ;code: .toggled
      ;  — inverted colors (selected state)
    ==
  ==
  ;h3: Containers and Positioning
  ;ul
    ;li
      ;code: .page
      ;  — max-width 750px, centered
    ==
    ;li
      ;code: .page-wide
      ;  — max-width 880px, centered
    ==
    ;li
      ;code: .prose
      ;  — auto-styles headings, paragraphs, lists, code, tables
    ==
    ;li
      ;code: .scroll-y
      ; ,
      ;code: .scroll-x
      ; ,
      ;code: .scroll-none
      ;  — overflow control
    ==
    ;li
      ;code: .relative
      ; ,
      ;code: .absolute
      ; ,
      ;code: .fixed
      ; ,
      ;code: .sticky
      ;  — positioning
    ==
    ;li
      ;code: .sh1
      ; ,
      ;code: .sh2
      ; ,
      ;code: .sh3
      ;  — box shadows (light to heavy)
    ==
  ==
  ;h3: Themes
  ;p: Apply a theme class to any element to change the color hue:
  ;ul
    ;li: (default) — neutral gray-blue
    ;li
      ;code: .spring
      ;  — green
    ==
    ;li
      ;code: .summer
      ;  — warm red-orange
    ==
    ;li
      ;code: .autumn
      ;  — golden orange
    ==
    ;li
      ;code: .winter
      ;  — cool blue
    ==
  ==
  ;p
    ; Dark mode is automatic via
    ;code: prefers-color-scheme
    ; .
  ==
==
