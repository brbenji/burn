::  /lib/vines/new-oxal--plex-tui: GET /new-oxal/plex-tui renders the xterm page.
::
::  Returns the manx for an xterm.js terminal mounted in the browser.
::  Page-side JS opens an Eyre channel and subscribes to %burn-tui
::  on path /tui; SSE delivers %tui-frame facts.
::
::  Architecture:
::    - JS consumes %tui-frame, renders structured rows with local
::      focus + scroll + editing-draft + repaint.
::    - Nav cursor walks "interesting" rows: focusable OR with siblings.
::      Sibling-cyclic ↑/↓; ←/→ depth nav (ancestor / descendant).
::      %info rows filtered out of nav via isNavable().
::    - Intent pokes via POST /new-oxal/tui-here. Form-encoded {path, blade,
::      value?} → stab → poke [our %burn] %goon-event. Same wire
::      format as web UI sibling at lib/vines/oxal--plex.hoon's
::      +handle-post.
::    - EDIT mode lives in bootChannel closure ({path, draft, kind}).
::      Escape/Backspace/printable handled JS-local; Enter commits via
::      pokeIntent.
::    - Library-item Enter: JS derives the download URL from path's
::      last segment, opens in a new tab.
::    - xterm.js v6.0.0 vendored on %hawk; loaded from
::      /new-oxal-init/xterm/6/{lib,style}.
::
/-  goon
/+  *vineio
=,  goon
::
=<
=/  m  (strand ,vase)
;<  bowl=http-bowl  bind:m  init
=/  vio  ~(. server bowl)
^-  form:m
::
::  T10.2: POST /new-oxal/tui-here delivers a form-encoded {path, blade,
::  value?} which the vine forwards as a %goon-event poke against
::  %burn. Same wire format as the web UI sibling's handle-post
::  (lib/vines/oxal--plex.hoon:522).
::
?:  =('POST' method.bowl)
  (handle-post bowl)
::
;<  ~  bind:m  (send-html-payload:vio (render-page our.bowl))
(pure:m !>(~))
::
|%
++  tui-js
  ^-  tape
  %-  trip
  '''
  (function () {
    var TERM_ROWS = 24, TERM_COLS = 80;
    var APP = 'burn-tui', WATCH_PATH = '/tui';
    var TINT_CODE = { k: '0', r: '1', g: '2', y: '3', b: '4', m: '5', c: '6', w: '7' };

    function csi(cmd) {
      var a = [].slice.call(arguments, 1);
      return '\x1b[' + a.join(';') + cmd;
    }

    function tintCode(t) {
      if (t === null) return '9';
      if (typeof t === 'string') return TINT_CODE[t] || '9';
      return '8;2;' + (t.r % 256) + ';' + (t.g % 256) + ';' + (t.b % 256);
    }

    function filaToAnsi(fila) {
      var parts = [];
      if (fila.d && fila.d.length > 0) {
        fila.d.forEach(function (d) {
          if (d === 'br') parts.push('1');
          else if (d === 'un') parts.push('4');
          else if (d === 'bl') parts.push('5');
          else console.warn('tui-here: weird deco', d);
        });
      }
      if (fila.b !== null) parts.push('4' + tintCode(fila.b));
      if (fila.f !== null) parts.push('3' + tintCode(fila.f));
      return parts.length === 0 ? '' : '\x1b[' + parts.join(';') + 'm';
    }

    function focusedFila(orig) {
      return { d: orig.d || [], b: 'w', f: 'k' };
    }

    function renderRow(row, isFocused, editing) {
      var pad = ' '.repeat(row.padLeft || 0);
      if (editing && pathEq(row.path, editing.path)) {
        var editFila = { d: [], b: 'c', f: 'k' };
        var promptLabel = editing.label ? editing.label + ': ' : '';
        return filaToAnsi(editFila) + pad + '> ' + promptLabel + editing.draft + '_' + csi('m', 0);
      }
      if (row.cells.length === 0) return pad;
      // Focused row uses one fila (white-bg/black-fg, retaining first cell\'s
      // deco) across all cells so the highlight runs unbroken across pad +
      // text + any trailing cells; non-focused uses each cell\'s own fila.
      var forced = isFocused ? focusedFila(row.cells[0].fila) : null;
      var out = forced ? filaToAnsi(forced) + pad : pad;
      for (var i = 0; i < row.cells.length; i++) {
        var c = row.cells[i];
        out += (forced ? '' : filaToAnsi(c.fila)) + c.text;
        if (!forced) out += csi('m', 0);
      }
      if (forced) out += csi('m', 0);
      return out;
    }

    function showFrame(term, state) {
      if (!state.frame) return;
      var rows = state.frame.rows;
      var sy = state.scrollY;
      var focusY = state.focusRowIdx === null ? -1 : state.focusRowIdx;
      // Reserve last terminal row for the status overlay when set.
      var rowsCap = state.statusLine ? TERM_ROWS - 1 : TERM_ROWS;
      // Home → clear → home: paint top-down once. Trailing rows of the
      // viewport stay blank-on-default (no need to space-fill).
      var out = csi('H', 1, 1) + csi('2J') + csi('H', 1, 1);
      for (var i = 0; i < rowsCap; i++) {
        var y = sy + i;
        if (y >= rows.length) break;
        if (i > 0) out += '\r\n';
        out += renderRow(rows[y], y === focusY, state.editing);
      }
      if (state.statusLine) {
        out += csi('H', TERM_ROWS, 1) + csi('m', 7) + state.statusLine + csi('m', 0);
      }
      term.write(out);
    }

    function computeScrollY(focusY) {
      if (focusY < 0 || focusY < 12) return 0;
      return focusY - 12;
    }

    function pathEq(a, b) {
      if (!a || !b || a.length !== b.length) return false;
      for (var i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
      return true;
    }

    // Shared URL-encoding idiom with the web UI's goon-nav.js. Both
    // renderers produce byte-identical ?focus= strings for the same
    // node so a URL minted in one view restores in the other (after
    // swapping /new-oxal/tui-here ↔ /new-oxal/plex in the pathname).
    function parsePath(s) {
      if (!s || s === '/') return [];
      return s.split('/').filter(Boolean).map(decodeURIComponent);
    }
    function stringifyPath(segs) {
      return '/' + segs.map(encodeURIComponent).join('/');
    }
    function readURL() {
      var p = new URLSearchParams(window.location.search);
      return { focus: p.has('focus') ? parsePath(p.get('focus')) : null };
    }
    // replaceState (not pushState) — nav per ArrowKey shouldn't pollute
    // browser history; one history entry per session, not per keystroke.
    function writeURL(focus) {
      var p = new URLSearchParams(window.location.search);
      if (focus && focus.length) p.set('focus', stringifyPath(focus));
      else p.delete('focus');
      var qs = p.toString();
      var url = qs ? window.location.pathname + '?' + qs : window.location.pathname;
      history.replaceState(null, '', url);
    }

    // a strictly contains b (b shorter, b is prefix of a).
    function pathStartsWith(a, b) {
      if (!a || !b || b.length >= a.length) return false;
      for (var i = 0; i < b.length; i++) if (a[i] !== b[i]) return false;
      return true;
    }

    // Nav cursor walks any "interesting" row. A row is interesting iff
    // it's focusable (Enter does something) OR has a sibling (↑/↓ has
    // somewhere to go from there). Non-focusable singletons — like
    // "sections" under "library" or "items" under "movies" — are
    // skipped: there's no Enter behavior and no peers to cycle through,
    // so they're transit-only labels that just waste keypresses.
    //
    // %info rows (body-text continuation under a leaf, sharing the
    // leaf's path) are never interesting.
    function isNavable(row) { return row.kind !== 'info'; }

    // Precomputed per-frame: one bool per row. Pre-pass counts navable
    // children per parent-path; a row is interesting iff focusable or
    // its parent-bucket has > 1 navable member.
    function computeInteresting(rows) {
      var counts = {};
      for (var i = 0; i < rows.length; i++) {
        var r = rows[i];
        if (!isNavable(r)) continue;
        var k = r.parent.join('\x00');
        counts[k] = (counts[k] || 0) + 1;
      }
      var out = new Array(rows.length);
      for (var j = 0; j < rows.length; j++) {
        var rr = rows[j];
        if (!isNavable(rr)) { out[j] = false; continue; }
        if (rr.focusable) { out[j] = true; continue; }
        out[j] = counts[rr.parent.join('\x00')] > 1;
      }
      return out;
    }

    function siblingRowIndices(rowIdx, rows, interesting) {
      var focus = rows[rowIdx];
      var n = focus.parent.length;
      var out = [];
      for (var i = 0; i < rows.length; i++) {
        if (!interesting[i]) continue;
        var r = rows[i];
        if (r.parent.length !== n) continue;
        var same = true;
        for (var j = 0; j < n; j++) if (r.parent[j] !== focus.parent[j]) { same = false; break; }
        if (same) out.push(i);
      }
      return out;
    }

    function findDescendantRow(rowIdx, rows, interesting) {
      var focus = rows[rowIdx];
      for (var i = 0; i < rows.length; i++) {
        if (i === rowIdx) continue;
        if (!interesting[i]) continue;
        if (pathStartsWith(rows[i].path, focus.path)) return i;
      }
      return null;
    }

    function findAncestorRow(rowIdx, rows, interesting) {
      var focus = rows[rowIdx];
      var best = null, bestDepth = -1;
      for (var i = 0; i < rows.length; i++) {
        if (i === rowIdx) continue;
        if (!interesting[i]) continue;
        var p = rows[i].path;
        if (pathStartsWith(focus.path, p) && p.length > bestDepth) {
          bestDepth = p.length;
          best = i;
        }
      }
      return best;
    }

    function firstInterestingRow(interesting) {
      for (var i = 0; i < interesting.length; i++) if (interesting[i]) return i;
      return null;
    }

    function reattachFocus(prevPath, rows, interesting) {
      if (!rows || rows.length === 0) return null;
      var fallback = firstInterestingRow(interesting);
      if (!prevPath) return fallback;
      for (var i = 0; i < rows.length; i++) {
        if (!interesting[i]) continue;
        if (pathEq(rows[i].path, prevPath)) return i;
      }
      // Nearest-survivor: interesting row with deepest shared prefix to prev.
      var best = fallback, bestDepth = -1;
      for (var j = 0; j < rows.length; j++) {
        if (!interesting[j]) continue;
        var p = rows[j].path;
        var d = 0;
        while (d < p.length && d < prevPath.length && p[d] === prevPath[d]) d++;
        if (d > bestDepth) { bestDepth = d; best = j; }
      }
      return best;
    }

    function isLibraryDownload(focusable, path) {
      return focusable && focusable.kind === 'click' && path && path[0] === 'library';
    }

    // Same wire format as web UI sibling at lib/vines/oxal--plex.hoon:522.
    function pokeIntent(path, blade, value) {
      var pathStr = '/' + path.join('/');
      var body = new URLSearchParams();
      body.set('path', pathStr);
      body.set('blade', blade);
      if (value !== undefined && value !== null) body.set('value', value);
      return fetch('/new-oxal/plex-tui', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString(),
        credentials: 'include'
      });
    }

    function uid() {
      return Date.now() + '-' + Math.floor(Math.random() * 1e9).toString(16);
    }

    function ourShip() {
      if (window.ship) return '~' + window.ship;
      var m = document.cookie.match(/urbauth-(~[^=]+)=/);
      return m ? m[1] : null;
    }

    function bootChannel(term) {
      var ship = ourShip();
      if (!ship) {
        term.write('\x1b[31mno ship cookie; log in first\x1b[0m\r\n');
        return;
      }
      var channelId = uid();
      var url = '/~/channel/' + channelId;
      var idCounter = { next: 1 };
      var es = null;
      var dataDisposer = null;
      var torn = false;

      // Session-local nav state. Lives at this closure scope so a
      // teardown + reboot resets focus (intentional — a dead channel
      // means we missed redraws and can\'t trust focusBeforePath).
      // `editing` is null when not editing; otherwise { path, draft,
      // kind: 'edit'|'add' } accumulated browser-side until Enter
      // submits it as a %goon-event via pokeIntent.
      var state = {
        frame: null,
        interesting: null,
        focusRowIdx: null,
        focusBeforePath: null,
        scrollY: 0,
        editing: null,
        statusLine: null
      };
      var statusTimer = null;

      // Transient bottom-row message; auto-clears after 3s. Used by the
      // multi-act warn-stub until a real picker exists; reusable for
      // any future status surfacing.
      function setStatus(msg) {
        state.statusLine = msg;
        if (statusTimer) clearTimeout(statusTimer);
        statusTimer = setTimeout(function () {
          state.statusLine = null;
          statusTimer = null;
          repaint();
        }, 3000);
        repaint();
      }

      var popHandler = null;

      function cleanup() {
        if (torn) return;
        torn = true;
        if (dataDisposer) { try { dataDisposer.dispose(); } catch (_) {} dataDisposer = null; }
        if (es) { try { es.close(); } catch (_) {} es = null; }
        if (popHandler) { window.removeEventListener('popstate', popHandler); popHandler = null; }
        if (statusTimer) { clearTimeout(statusTimer); statusTimer = null; }
      }
      function retryAfter(ms) {
        cleanup();
        setTimeout(function () { bootChannel(term); }, ms);
      }

      function repaint() { showFrame(term, state); }

      function rememberFocus() {
        state.focusBeforePath = state.focusRowIdx === null
          ? null
          : state.frame.rows[state.focusRowIdx].path;
      }

      // ?focus= from the boot URL is one-shot: consumed by the first
      // applyFrame, after which reattach-by-prior-path takes over.
      var pendingUrlFocus = readURL().focus;

      function findRowByPath(target, rows, interesting) {
        for (var i = 0; i < rows.length; i++) {
          if (interesting[i] && pathEq(rows[i].path, target)) return i;
        }
        return null;
      }

      function pickFocus(rows, interesting) {
        if (pendingUrlFocus) {
          var seed = pendingUrlFocus;
          pendingUrlFocus = null;
          var hit = findRowByPath(seed, rows, interesting);
          if (hit !== null) return hit;
          console.warn('tui-here: ?focus= path not found in frame; falling back');
        }
        return reattachFocus(state.focusBeforePath, rows, interesting);
      }

      function applyFrame(frame) {
        state.frame = frame;
        state.interesting = computeInteresting(frame.rows);
        state.focusRowIdx = pickFocus(frame.rows, state.interesting);
        rememberFocus();
        state.scrollY = computeScrollY(state.focusRowIdx === null ? -1 : state.focusRowIdx);
        syncURL();
        repaint();
      }

      function syncURL() {
        var p = state.focusRowIdx === null ? null : state.frame.rows[state.focusRowIdx].path;
        writeURL(p);
      }

      function snapTo(rowIdx) {
        if (rowIdx === null || rowIdx === state.focusRowIdx) return;
        state.focusRowIdx = rowIdx;
        rememberFocus();
        state.scrollY = computeScrollY(rowIdx);
        syncURL();
        repaint();
      }

      // ↑/↓ wrap within the sibling set, ←/→ change tree level.
      function moveSibling(delta) {
        if (!state.frame || state.focusRowIdx === null) return;
        var sibs = siblingRowIndices(state.focusRowIdx, state.frame.rows, state.interesting);
        if (sibs.length <= 1) return;
        var here = sibs.indexOf(state.focusRowIdx);
        var next = (here + delta + sibs.length) % sibs.length;
        snapTo(sibs[next]);
      }

      function moveIn() {
        if (!state.frame || state.focusRowIdx === null) return;
        snapTo(findDescendantRow(state.focusRowIdx, state.frame.rows, state.interesting));
      }
      function moveOut() {
        if (!state.frame || state.focusRowIdx === null) return;
        snapTo(findAncestorRow(state.focusRowIdx, state.frame.rows, state.interesting));
      }

      function enterEditMode(kind, row) {
        var firstText = row && row.cells.length > 0 ? row.cells[0].text : '';
        // walk-frame emits "> {body}" for focusables — drop the marker.
        // Use the displayed text as the prompt label, never the draft seed,
        // because for empty values the displayed text IS the label.
        var label = firstText.indexOf('> ') === 0 ? firstText.slice(2) : firstText;
        state.editing = {
          path: row.path,
          label: label,
          draft: '',
          kind: kind
        };
        repaint();
      }

      // Enter is gated on row.focusable. Non-focusable nav-cursor
      // positions (headings, categories) are silent no-ops until
      // accordion collapse-on-Enter ships.
      //
      // Dispatch table per TUI-ACT-DISPATCH-SPEC.md section 5:
      //   click + library  → window.open download URL
      //   click + non-lib  → pokeIntent(path, "act", "click")  (legacy
      //                       fallback; goon `+$ blade` has no %click
      //                       variant so the act-channel carries it)
      //   act, |acts| = 1  → pokeIntent(path, "act", acts[0].term)
      //   act, |acts| ≥ 2  → warn + status overlay (picker deferred)
      //   edit / add       → enterEditMode
      function activateFocus() {
        if (!state.frame || state.focusRowIdx === null) return;
        var row = state.frame.rows[state.focusRowIdx];
        var f = row.focusable;
        if (!f) return;
        if (isLibraryDownload(f, row.path)) {
          var rkey = row.path[row.path.length - 1];
          window.open('/apps/burn/download/' + rkey, '_blank');
          return;
        }
        if (f.kind === 'edit' || f.kind === 'add') {
          enterEditMode(f.kind, row);
          return;
        }
        if (f.kind === 'click') {
          pokeIntent(row.path, 'act', 'click').catch(function (e) {
            console.warn('tui-here: click intent poke failed', e);
          });
          return;
        }
        if (f.kind === 'act') {
          if (f.acts.length === 1) {
            pokeIntent(row.path, 'act', f.acts[0].term).catch(function (e) {
              console.warn('tui-here: act intent poke failed', e);
            });
            return;
          }
          // |acts| >= 2: picker not yet built. Surface a status-line
          // message so the dead Enter has a UI signal.
          console.warn('tui-here: multi-act not yet supported on path', row.path, f.acts);
          setStatus('multi-act not yet supported (' + f.acts.length + ' choices)');
          return;
        }
      }

      function handleEditKey(data) {
        var e = state.editing;
        // Bare ESC exits EDIT mode. Arrow keys (`\x1b[A` etc.) share the
        // \x1b prefix but are length > 1 — swallow them silently so the
        // user can hold Arrow without it tearing down their draft.
        if (data === '\x1b') {
          state.editing = null;
          repaint();
          return;
        }
        if (data.charCodeAt(0) === 0x1b) return;
        if (data === '\x7f' || data === '\x08') {
          e.draft = e.draft.slice(0, -1);
          repaint();
          return;
        }
        if (data === '\r' || data === '\n') {
          pokeIntent(e.path, e.kind, e.draft).catch(function (err) {
            console.warn('tui-here: edit submit failed', err);
          });
          // Optimistic clear; the agent\'s subsequent %goon-redraw →
          // fresh %tui-frame confirms the new value in the tree.
          state.editing = null;
          repaint();
          return;
        }
        // Paste arrives as a single onData with data.length > 1; loop
        // so paste and typing share the same accumulator path.
        var added = '';
        for (var i = 0; i < data.length; i++) {
          var c = data.charCodeAt(i);
          if (c >= 0x20 && c <= 0x7e) added += data[i];
        }
        if (added.length) {
          e.draft += added;
          repaint();
        }
      }

      function handleKey(data) {
        if (state.editing) { handleEditKey(data); return; }
        if (data === '\x1b[A') { moveSibling(-1); return; }
        if (data === '\x1b[B') { moveSibling(1); return; }
        if (data === '\x1b[D') { moveOut(); return; }
        if (data === '\x1b[C') { moveIn(); return; }
        if (data === '\r' || data === '\n') { activateFocus(); return; }
      }

      var subscribeMsg = [{
        id: idCounter.next++,
        action: 'subscribe',
        ship: ship.replace(/^~/, ''),
        app: APP,
        path: WATCH_PATH
      }];
      fetch(url, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(subscribeMsg),
        credentials: 'include'
      }).then(function () {
        es = new EventSource(url, { withCredentials: true });
        es.onmessage = function (ev) {
          try {
            var msg = JSON.parse(ev.data);
            if (!msg.json) return;
            applyFrame(msg.json);
          } catch (e) {
            console.warn('tui-here: parse error', e, ev.data);
          }
        };
        es.onerror = function (e) {
          if (torn) return;
          console.warn('tui-here: SSE error; reconnecting fresh channel', e);
          retryAfter(500);
        };
        dataDisposer = term.onData(handleKey);
        // External URL change (URL-bar edit, back/forward) snaps focus
        // to the new path. Skip while editing — popstate during a draft
        // would lose unsaved text.
        popHandler = function () {
          if (state.editing || !state.frame) return;
          var target = readURL().focus;
          if (!target) return;
          var hit = findRowByPath(target, state.frame.rows, state.interesting);
          if (hit !== null) snapTo(hit);
        };
        window.addEventListener('popstate', popHandler);
      }).catch(function (e) {
        console.error('tui-here: subscribe failed; retrying', e);
        retryAfter(2000);
      });
    }

    function boot() {
      var term = new Terminal({
        rows: TERM_ROWS,
        cols: TERM_COLS,
        convertEol: true,
        cursorBlink: false
      });
      term.open(document.getElementById('term'));
      term.write(csi('?25l'));
      // Grab keystrokes immediately so the URL-seeded focus is
      // navigable without a Tab/click warmup.
      term.focus();
      bootChannel(term);
    }

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', boot);
    } else {
      boot();
    }
  })();
  '''
::
++  render-page
  |=  =@p
  ^-  manx
  =/  js=tape  tui-js
  ::  Bake the serving ship into the page so ourShip() never has to guess
  ::  from the cookie jar. Cookies are scoped by host, not host+port, so
  ::  a browser that has visited both 8080 and 8081 carries both
  ::  urbauth-~ship cookies; the previous regex-fallback picked the
  ::  first match, which could be the wrong ship and routed PUT subscribe
  ::  cross-ship into a 400 (missing).
  =/  ship-script=tape
    ;:  weld
      "window.ship='"
      `tape`(slag 1 (scow %p p))
      "';"
    ==
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
        ;+  ;/  ship-script
      ==
      ;script
        ;+  ;/  js
      ==
    ==
  ==
::
::  +handle-post: form-encoded body {path, blade, value?} → stab → poke
::  [our %burn] %goon-event. Mirrors lib/vines/oxal--plex.hoon:522
::  exactly; the TUI route uses the same wire format as the web UI sibling
::  so burn's poke handler sees identical traffic from either.
::
++  handle-post
  |=  =http-bowl
  =/  m  (strand ,vase)
  ^-  form:m
  =/  vio  ~(. server http-bowl)
  =/  body=(map @t @t)  formencoded-body:vio
  =/  path-cord=@t   (~(gut by body) 'path' '')
  =/  blade-cord=@t  (~(gut by body) 'blade' '')
  =/  value-cord=@t  (~(gut by body) 'value' '')
  =/  =path  (rash path-cord stap)
  =/  =blade
    ?+  blade-cord  [%edit value-cord]
      %edit   [%edit value-cord]
      %add    [%add value-cord]
      %act    [%act `term`(slav %tas value-cord)]
    ==
  =/  =stab  [path blade]
  ;<  ~  bind:m  (poke [our.http-bowl %burn] %goon-event !>(stab))
  ;<  ~  bind:m  (send-html-payload:vio post-ack)
  (pure:m !>(~))
::
++  post-ack
  ^-  manx
  ;div: ok
--
