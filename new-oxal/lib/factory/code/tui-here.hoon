::  /views/tui-here.hoon — browser surface for the TUI track.
::
::  Loads xterm.js v6.0.0 vendored on %hawk desk via /new-oxal-init/xterm/6/{lib,style},
::  opens an Eyre channel, and subscribes to %plex-hawk-tui on path /tui.
::  Each %blit fact arrives as JSON over SSE and is dispatched to xterm via
::  a port of webterm's showBlit (urbit/webterm/ui/lib/blit.ts).
::
::  Static assets served from Eyre cache by hawk-init.hoon. See
::  META-PRD-TUI.md "xterm.js vendoring" for the hawk-init delta.
::
::  V1 (this run, T6):
::    - Receive-only.  One blit fact per subscribe (T5 host emits once).
::    - csi/tint/stye/showBlit ported verbatim from webterm.
::    - file-saver replaced with native Blob + anchor download trick.
::    - Hardcoded viewport 80x24 matches T5 host's `(blits dei [80 24])`.
::
::  V1 deferred (T7):
::    - Input round-trip (xterm `onData` → belt poke → host re-render).
::    - Reconnect on EventSource error.
::    - Per-tab session id (T7 path becomes `/tui/<session>`).
::
=>
|%
::  +tui-js: the inline JS body served inside the page's <script> tag.
::  Built as a single tape via `zing` over a list of source chunks so
::  each ported function reads in isolation.
::
++  tui-js
  ^-  tape
  %-  zing
  :~
    ::  ─── 0. globals ────────────────────────────────────────────
    "(function () {\0a"
    "  var TERM_ROWS = 24, TERM_COLS = 80;\0a"
    "  var APP = 'plex-hawk-tui', WATCH_PATH = '/tui';\0a"
    "\0a"
    ::  ─── 1. csi helper (blit.ts:6-8) ───────────────────────────
    "  function csi(cmd) {\0a"
    "    var a = [].slice.call(arguments, 1);\0a"
    "    return '\\x1b[' + a.join(';') + cmd;\0a"
    "  }\0a"
    "\0a"
    ::  ─── 2. tint port (stye.ts:3-15) ───────────────────────────
    "  function tint(t) {\0a"
    "    if (t === null) return '9';\0a"
    "    if (typeof t === 'string') {\0a"
    "      switch (t) {\0a"
    "        case 'k': return '0';\0a"
    "        case 'r': return '1';\0a"
    "        case 'g': return '2';\0a"
    "        case 'y': return '3';\0a"
    "        case 'b': return '4';\0a"
    "        case 'm': return '5';\0a"
    "        case 'c': return '6';\0a"
    "        case 'w': return '7';\0a"
    "      }\0a"
    "    }\0a"
    "    return '8;2;' + (t.r % 256) + ';' + (t.g % 256) + ';' + (t.b % 256);\0a"
    "  }\0a"
    "\0a"
    ::  ─── 3. stye port (stye.ts:17-50) ──────────────────────────
    "  function stye(s) {\0a"
    "    var out = '';\0a"
    "    if (s.deco && s.deco.length > 0) {\0a"
    "      out += s.deco.map(function (d) {\0a"
    "        if (d === null) return 0;\0a"
    "        if (d === 'br') return 1;\0a"
    "        if (d === 'un') return 4;\0a"
    "        if (d === 'bl') return 5;\0a"
    "        console.log('weird deco', d);\0a"
    "        return 0;\0a"
    "      }).join(';');\0a"
    "    }\0a"
    "    if (s.back !== null) {\0a"
    "      if (out !== '') out += ';';\0a"
    "      out += '4' + tint(s.back);\0a"
    "    }\0a"
    "    if (s.fore !== null) {\0a"
    "      if (out !== '') out += ';';\0a"
    "      out += '3' + tint(s.fore);\0a"
    "    }\0a"
    "    if (out === '') return out;\0a"
    "    return '\\x1b[' + out + 'm';\0a"
    "  }\0a"
    "\0a"
    ::  ─── 4. saveAs (file-saver replacement, vanilla) ───────────
    "  function saveAs(blob, name) {\0a"
    "    var url = URL.createObjectURL(blob);\0a"
    "    var a = document.createElement('a');\0a"
    "    a.href = url; a.download = name;\0a"
    "    document.body.appendChild(a);\0a"
    "    a.click();\0a"
    "    document.body.removeChild(a);\0a"
    "    setTimeout(function () { URL.revokeObjectURL(url); }, 1000);\0a"
    "  }\0a"
    "\0a"
    ::  ─── 5. base64 → Uint8Array helper for sag/sav ─────────────
    "  function b64ToBytes(b64) {\0a"
    "    var bin = atob(b64);\0a"
    "    var n = bin.length;\0a"
    "    var out = new Uint8Array(n);\0a"
    "    for (var i = 0; i < n; i++) out[i] = bin.charCodeAt(i);\0a"
    "    return out;\0a"
    "  }\0a"
    "\0a"
    ::  ─── 6. showBlit dispatch (blit.ts:10-58) ──────────────────
    "  function showBlit(term, blit) {\0a"
    "    var out = '';\0a"
    "    if ('mor' in blit) {\0a"
    "      blit.mor.forEach(function (b) { showBlit(term, b); });\0a"
    "      return;\0a"
    "    } else if ('bel' in blit) {\0a"
    "      out += '\\x07';\0a"
    "    } else if ('clr' in blit) {\0a"
    "      term.clear();\0a"
    "      out += csi('u');\0a"
    "    } else if ('hop' in blit) {\0a"
    "      if (typeof blit.hop === 'number') {\0a"
    "        out += csi('H', term.rows, blit.hop + 1);\0a"
    "      } else {\0a"
    "        out += csi('H', blit.hop.y + 1, blit.hop.x + 1);\0a"
    "      }\0a"
    "      out += csi('s');\0a"
    "    } else if ('put' in blit) {\0a"
    "      out += blit.put.join('');\0a"
    "      out += csi('u');\0a"
    "    } else if ('klr' in blit) {\0a"
    "      out += blit.klr.reduce(function (lin, p) {\0a"
    "        lin += stye(p.stye);\0a"
    "        lin += p.text.join('');\0a"
    "        lin += csi('m', 0);\0a"
    "        return lin;\0a"
    "      }, '');\0a"
    "      out += csi('u');\0a"
    "    } else if ('nel' in blit) {\0a"
    "      out += '\\n';\0a"
    "    } else if ('sag' in blit || 'sav' in blit) {\0a"
    "      var sav = ('sag' in blit) ? blit.sag : blit.sav;\0a"
    "      var parts = sav.path.split('/');\0a"
    "      var name = parts.slice(-2).join('.');\0a"
    "      var bytes = b64ToBytes(sav.file);\0a"
    "      var blob = new Blob([bytes], { type: 'application/octet-stream' });\0a"
    "      saveAs(blob, name);\0a"
    "    } else if ('url' in blit) {\0a"
    "      window.open(blit.url);\0a"
    "    } else if ('wyp' in blit) {\0a"
    "      out += '\\r' + csi('K');\0a"
    "      out += csi('u');\0a"
    "    } else {\0a"
    "      console.log('weird blit', blit);\0a"
    "    }\0a"
    "    term.write(out);\0a"
    "  }\0a"
    "\0a"
    ::  ─── 7. Eyre channel: open + subscribe + dispatch ──────────
    "  function uid() {\0a"
    "    return Date.now() + '-' + Math.floor(Math.random() * 1e9).toString(16);\0a"
    "  }\0a"
    "\0a"
    "  function ourShip() {\0a"
    "    if (window.ship) return '~' + window.ship;\0a"
    "    var m = document.cookie.match(/urbauth-(~[^=]+)=/);\0a"
    "    return m ? m[1] : null;\0a"
    "  }\0a"
    "\0a"
    "  function bootChannel(term) {\0a"
    "    var ship = ourShip();\0a"
    "    if (!ship) {\0a"
    "      term.write('\\x1b[31mno ship cookie; log in first\\x1b[0m\\r\\n');\0a"
    "      return;\0a"
    "    }\0a"
    "    var channelId = uid();\0a"
    "    var url = '/~/channel/' + channelId;\0a"
    "    var nextId = 1;\0a"
    "    var subscribeMsg = [{\0a"
    "      id: nextId++,\0a"
    "      action: 'subscribe',\0a"
    "      ship: ship.replace(/^~/, ''),\0a"
    "      app: APP,\0a"
    "      path: WATCH_PATH\0a"
    "    }];\0a"
    "    fetch(url, {\0a"
    "      method: 'PUT',\0a"
    "      headers: { 'Content-Type': 'application/json' },\0a"
    "      body: JSON.stringify(subscribeMsg),\0a"
    "      credentials: 'include'\0a"
    "    }).then(function () {\0a"
    "      var es = new EventSource(url, { withCredentials: true });\0a"
    "      es.onmessage = function (ev) {\0a"
    "        try {\0a"
    "          var msg = JSON.parse(ev.data);\0a"
    "          if (msg.json) showBlit(term, msg.json);\0a"
    "        } catch (e) {\0a"
    "          console.warn('tui-here: parse error', e, ev.data);\0a"
    "        }\0a"
    "      };\0a"
    "      es.onerror = function (e) {\0a"
    "        console.warn('tui-here: SSE error', e);\0a"
    "      };\0a"
    "    }).catch(function (e) {\0a"
    "      console.error('tui-here: subscribe failed', e);\0a"
    "      term.write('\\x1b[31msubscribe failed\\x1b[0m\\r\\n');\0a"
    "    });\0a"
    "  }\0a"
    "\0a"
    ::  ─── 8. boot: xterm.js is `defer`red, so it has loaded before
    ::         DOMContentLoaded fires; no polling needed.
    "  function boot() {\0a"
    "    var term = new Terminal({\0a"
    "      rows: TERM_ROWS,\0a"
    "      cols: TERM_COLS,\0a"
    "      convertEol: true\0a"
    "    });\0a"
    "    term.open(document.getElementById('term'));\0a"
    "    bootChannel(term);\0a"
    "  }\0a"
    "\0a"
    "  if (document.readyState === 'loading') {\0a"
    "    document.addEventListener('DOMContentLoaded', boot);\0a"
    "  } else {\0a"
    "    boot();\0a"
    "  }\0a"
    "})();\0a"
  ==
--
:-  %feather-1
|%
++  title
  |=  [here=pith =data]
  "TUI"
::
++  get
  |=  [our=@p src=@p =data =stem =query]
  ^-  node
  =/  js=tape  tui-js
  :-  %manx
  ;html
    ;head
      ;title: TUI
      ;meta(charset "utf-8");
      ;link(rel "stylesheet", href "/new-oxal-init/xterm/6/style");
      ;script(defer "defer", src "/new-oxal-init/xterm/6/lib");
    ==
    ;body(style "margin:0; padding:0; background:#000")
      ;div(id "term", style "width:100vw; height:100vh");
      ;script
        ;+  ;/  js
      ==
    ==
  ==
::
++  post
  |=  [our=@p src=@p =data =stem =query =body]
  ^-  [(unit [^stem ^query]) (list move)]
  [~ ~]
::
++  on
  |=  [=prov =move =file]
  ~
--
