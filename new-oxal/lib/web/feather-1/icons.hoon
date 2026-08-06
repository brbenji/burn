|%
::  svg icons
::
::    https://lucide.dev/
::
::    remove the height and width attributes
::    from the <svg> element after pasting in
::
++  import  :: put this in the html ;body
  ^~
  ;div
    ;svg
      =style  "display:none"
      =xmlns  "http://www.w3.org/2000/svg"
      ;*  (turn symbols make)
      ::
    ==
    ;style
      ;-  %-  trip
      '''
      @keyframes iconspin {
        from { transform: rotate(0deg); }
        to { transform: rotate(360deg); }
      }
      .icon-spinning {
        animation: iconspin 1s linear infinite;
        transform-origin: center;
        transform-box: fill-box;
      }
      .icon {
        vertical-align: middle;
        height: 1lh;
        width: 1.7ch;
      }
      '''
    ==
  ==
++  use
  |=  name=tape
  =/  spinner
    ?.  =(name "spinner")  ""
    "icon-spinning"
  ;svg
    =class  "icon {spinner}"
    ;use(href "#{name}");
  ==
++  make
  |=  =cord
  ^-  manx
  =/  base  (need (de-xml:html cord))
  %=  base
    n.g  %symbol
    a.g  :_  a.g.base
         style+"vertical-align:middle; height: 1lh;"
  ==
::
++  spinner   ^~  (use "spinner")
++  terminal  ^~  (use "terminal")
++  list-tree  ^~  (use "list-tree")
++  arrow-down  ^~  (use "arrow-down")
++  arrow-right  ^~  (use "arrow-right")
++  arrow-left  ^~  (use "arrow-left")
++  settings  ^~  (use "settings")
++  close  ^~  (use "close")
++  vertical-ellipsis  ^~  (use "vertical-ellipsis")
++  chevrons-right  ^~  (use "chevrons-right")
++  check  ^~  (use "check")
++  search  ^~  (use "search")
++  corner-down-right  ^~  (use "corner-down-right")
++  corner-down-right-many  ^~  (use "corner-down-right-many")
++  chevron-down  ^~  (use "chevron-down")
++  chevron-up  ^~  (use "chevron-up")
++  chevron-left  ^~  (use "chevron-left")
++  chevron-right  ^~  (use "chevron-right")
++  pin  ^~  (use "pin")
++  lock  ^~  (use "lock")
++  arrow-up  ^~  (use "arrow-up")
::
++  symbols
  ^-  (list cord)
  :~
    '''
    <svg id="spinner" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M21 12a9 9 0 1 1-6.219-8.56" class="icon-spinning">
      </path>
    </svg>
    '''
    ::
    '''
    <svg id="terminal" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19h8"/><path d="m4 17 6-6-6-6"/></svg>
    '''
    ::
    '''
    <svg id="list-tree" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-list-tree-icon lucide-list-tree"><path d="M8 5h13"/><path d="M13 12h8"/><path d="M13 19h8"/><path d="M3 10a2 2 0 0 0 2 2h3"/><path d="M3 5v12a2 2 0 0 0 2 2h3"/></svg>
    '''
    ::
    '''
    <svg id="check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-check-icon lucide-check"><path d="M20 6 9 17l-5-5"/></svg>
    '''
    ::
    '''
    <svg id="search" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21 21-4.34-4.34"/><circle cx="11" cy="11" r="8"/></svg>
    '''
    ::
    '''
    <svg id="close" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
    '''
    ::
    ::
    '''
    <svg id="vertical-ellipsis" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="1"/><circle cx="12" cy="5" r="1"/><circle cx="12" cy="19" r="1"/></svg>
    '''
    ::
    '''
    <svg id="chevrons-right" viewBox="0 0 18 17" fill="none">
      <path fill="currentColor" d="M7.64293 8.50605L7.05692 7.89283L3.52258 4.36965L4.38108 3.5L9.37598 8.50605L4.38108 13.5009L3.52258 12.6536L7.05692 9.11926L7.64293 8.50605Z" fill="#A3A3A3"/>
      <path fill="currentColor" d="M12.0111 8.50605L11.4251 7.89283L7.89075 4.36965L8.74924 3.5L13.7441 8.50605L8.74924 13.5009L7.89075 12.6536L11.4251 9.11926L12.0111 8.50605Z" fill="#A3A3A3"/>
    </svg>
    '''
    ::
    '''
    <svg id="corner-down-right" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 10 5 5-5 5"/><path d="M4 4v7a4 4 0 0 0 4 4h12"/></svg>
    '''
    ::
    '''
    <svg id="corner-down-right-many" viewBox="0 0 24 24" fill="none"
      stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
      class="lucide lucide-reply-all-icon lucide-reply-all">
      <path d="m12 7 5 5-5 5"/>
      <path d="M2 6v2a4 4 0 0 0 4 4h11"/>
      <path d="m17 7 5 5-5 5"/>
    </svg>
    '''
    ::
    '''
    <svg id="chevron-down" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></svg>
    '''
    ::
    '''
    <svg id="chevron-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m18 15-6-6-6 6"/></svg>
    '''
    ::
    '''
    <svg id="chevron-left" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>
    '''
    ::
    '''
    <svg id="chevron-right" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 18 6-6-6-6"/></svg>
    '''
    ::
    '<svg id="pin" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 17v5"/><path d="M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V7a1 1 0 0 1 1-1 2 2 0 0 0 0-4H8a2 2 0 0 0 0 4 1 1 0 0 1 1 1z"/></svg>'
    ::
    '<svg id="lock" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>'
    ::
    '''
    <svg id="arrow-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m5 12 7-7 7 7"/><path d="M12 19V5"/></svg>
    '''
    ::
    '''
    <svg id="arrow-down" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14"/><path d="m19 12-7 7-7-7"/></svg>
    '''
    ::
    '''
    <svg id="arrow-right" viewBox="0 0 18 17" fill="none">
      <path fill="currentColor" d="M10.237 13.591L9.36204 12.7274L12.9643 9.12509H3.63477V7.87509H12.9643L9.36204 4.28418L10.237 3.40918L15.3279 8.50009L10.237 13.591Z" fill="#A3A3A3"/>
    </svg>
    '''
    ::
    '''
    <svg id="arrow-left" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>
    '''
    ::
    '''
    <svg id="settings" viewBox="0 0 12 12" fill="none"><g clip-path="url(#clip0_791_6511)"><path d="M6.11 1H5.89C5.62478 1 5.37043 1.10536 5.18289 1.29289C4.99536 1.48043 4.89 1.73478 4.89 2V2.09C4.88982 2.26536 4.84353 2.43759 4.75577 2.58942C4.66801 2.74124 4.54187 2.86732 4.39 2.955L4.175 3.08C4.02298 3.16777 3.85054 3.21397 3.675 3.21397C3.49946 3.21397 3.32702 3.16777 3.175 3.08L3.1 3.04C2.87053 2.90763 2.59792 2.87172 2.342 2.94015C2.08608 3.00859 1.86778 3.17577 1.735 3.405L1.625 3.595C1.49263 3.82447 1.45672 4.09708 1.52515 4.353C1.59359 4.60892 1.76077 4.82722 1.99 4.96L2.065 5.01C2.21614 5.09726 2.34181 5.22254 2.42953 5.37342C2.51724 5.52429 2.56395 5.69549 2.565 5.87V6.125C2.5657 6.30121 2.51983 6.47448 2.43202 6.62725C2.34422 6.78003 2.21761 6.9069 2.065 6.995L1.99 7.04C1.76077 7.17278 1.59359 7.39108 1.52515 7.647C1.45672 7.90292 1.49263 8.17553 1.625 8.405L1.735 8.595C1.86778 8.82423 2.08608 8.99141 2.342 9.05985C2.59792 9.12828 2.87053 9.09237 3.1 8.96L3.175 8.92C3.32702 8.83223 3.49946 8.78603 3.675 8.78603C3.85054 8.78603 4.02298 8.83223 4.175 8.92L4.39 9.045C4.54187 9.13268 4.66801 9.25876 4.75577 9.41058C4.84353 9.56241 4.88982 9.73464 4.89 9.91V10C4.89 10.2652 4.99536 10.5196 5.18289 10.7071C5.37043 10.8946 5.62478 11 5.89 11H6.11C6.37522 11 6.62957 10.8946 6.81711 10.7071C7.00464 10.5196 7.11 10.2652 7.11 10V9.91C7.11018 9.73464 7.15647 9.56241 7.24423 9.41058C7.33199 9.25876 7.45813 9.13268 7.61 9.045L7.825 8.92C7.97702 8.83223 8.14946 8.78603 8.325 8.78603C8.50054 8.78603 8.67298 8.83223 8.825 8.92L8.9 8.96C9.12947 9.09237 9.40208 9.12828 9.658 9.05985C9.91392 8.99141 10.1322 8.82423 10.265 8.595L10.375 8.4C10.5074 8.17053 10.5433 7.89792 10.4748 7.642C10.4064 7.38608 10.2392 7.16778 10.01 7.035L9.935 6.995C9.7824 6.9069 9.65578 6.78003 9.56798 6.62725C9.48018 6.47448 9.4343 6.30121 9.435 6.125V5.875C9.4343 5.69879 9.48018 5.52552 9.56798 5.37275C9.65578 5.21997 9.7824 5.0931 9.935 5.005L10.01 4.96C10.2392 4.82722 10.4064 4.60892 10.4748 4.353C10.5433 4.09708 10.5074 3.82447 10.375 3.595L10.265 3.405C10.1322 3.17577 9.91392 3.00859 9.658 2.94015C9.40208 2.87172 9.12947 2.90763 8.9 3.04L8.825 3.08C8.67298 3.16777 8.50054 3.21397 8.325 3.21397C8.14946 3.21397 7.97702 3.16777 7.825 3.08L7.61 2.955C7.45813 2.86732 7.33199 2.74124 7.24423 2.58942C7.15647 2.43759 7.11018 2.26536 7.11 2.09V2C7.11 1.73478 7.00464 1.48043 6.81711 1.29289C6.62957 1.10536 6.37522 1 6.11 1Z" stroke="#A3A3A3" stroke-linecap="round" stroke-linejoin="round"/><path d="M6 7.5C6.82843 7.5 7.5 6.82843 7.5 6C7.5 5.17157 6.82843 4.5 6 4.5C5.17157 4.5 4.5 5.17157 4.5 6C4.5 6.82843 5.17157 7.5 6 7.5Z" stroke="#A3A3A3" stroke-linecap="round" stroke-linejoin="round"/></g><defs><clipPath id="clip0_791_6511"><rect width="12" height="12" fill="white"/></clipPath></defs></svg>
    '''
  ==
--