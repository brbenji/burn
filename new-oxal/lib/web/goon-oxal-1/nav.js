// goon-nav.js — Generic JRPG-style structural tree walker
//
// Attribute contract:
//   data-goon="root"                — nav root (one per page).
//   data-goon-children="N"          — branch node. N>0 means drillable.
//   data-goon-portal-in="id"        — drill jumps to this DOM id, then drills again.
//   data-goon-portal-out="id"       — backOut jumps to this DOM id.
//   data-goon-pane="id"             — async leaf declares which palm-stage child
//                                     to activate on trigger; nav.js applies
//                                     palm-active immediately and routes post-
//                                     morph focus into that pane. Distinct from
//                                     portal-in: waits for fetch, doesn't drill.
//   class="goon-nav-async"          — leaf that triggers a fetch; nav waits for DOM mutation.
//   data-goon-interact="edit|action|link|text"  — leaf activation semantics.

(function () {
  const ROOT_SEL = '[data-goon="root"]';
  const NODE_SEL = '[data-goon-children]';
  const ACTIVE_ATTR = 'data-goon-active';
  const ACTIVE_VISUAL_ATTR = 'data-goon-active-visual';
  const NAV_ATTR = 'data-goon-nav';
  const ACCORDION_LS_PREFIX = 'goon-accordion:';

  let root = null;
  let activeNode = null;
  let activeVisualNode = null;
  let editMode = false;
  let editInput = null;
  let cursorMemory = new Map();
  let idCounter = 0;
  let asyncPending = null;
  let paginatedContainers = [];
  // Logical path of the active node, captured at setActive time. Survives
  // morphs that detach activeNode — observer reanchors via resolveCursorPath
  // before falling through to id-getElementById then activateFirst.
  let lastCursorPath = null;
  // container → ResizeObserver. Disconnected when the container leaves the
  // document, lazily during the rAF debounce callback.
  const paginationObservers = new Map();
  const paginationHeightFloors = new Map();
  const PAGINATION_LS_PREFIX = 'goon-page:';
  const CURSOR_LS_KEY = 'goon-cursor-path';
  const PAGINATION_DEBUG_KEY = 'goon-debug-pagination';
  let paginationViewportRaf = false;
  let lastPaginationViewportHeight = 0;
  // id of the palm-item the user drilled FROM into the current swapped
  // palm-stage pane. Used to return focus to the origin when backing out
  // via palm-back / Escape / Left. Cleared after a successful restore.
  let palmDrillOrigin = null;
  let statusLiveEl = null;
  let downloadPendingAnchor = null;
  let downloadPendingHref = null;
  let downloadPendingTimeout = null;
  const pendingPulses = new Map();
  let passModalLastFocus = null;

  // — JS-owned DOM state registry —
  //
  // Idiomorph strips attrs and classes JS has set on morphed elements
  // unless the server payload also emits them. Every callsite that owns a
  // morph-survivable attr or class writes through these helpers, and the
  // MutationObserver calls restoreJSState() to re-assert them after every
  // morph batch.
  //
  // Keyed by DOM element reference, NOT by id. Reason: many elements JS
  // owns state on lack server-stable ids (accordion-header, accordion-
  // content, palm-back span, edit-field). Idiomorph morphs unkeyed
  // elements in place — DOM node identity is preserved even when the id
  // is stripped — so the element reference outlives the id. Iter-1 used
  // id-keyed Maps and silently failed for these elements: ensureId
  // generated `goon-N` ids that morph stripped, leaving the registry
  // unable to relocate them.
  //
  // Caller contract: only register state JS owns end-to-end. Never mirror
  // server-emitted attrs through here, and never register morph hints
  // (data-ignore-morph, data-goon-paginate).
  const jsState = {
    entries: new Map(),  // element → { attrs: Map(name → value), classes: Set(className) }
    misses: new Map(),   // element → consecutive-miss count (lazy GC)
  };
  const GC_MISS_THRESHOLD = 10;

  function ensureId(el) {
    if (!el.id) el.id = 'goon-' + (idCounter++);
    return el.id;
  }

  // Encode a logical path from the nearest [data-goon-path] ancestor down to
  // node. Survives morphs that replace DOM nodes — hops are matched by
  // semantic attributes (role, palmIdx, palmId) with childIdx as tiebreaker.
  function encodeCursorPath(node) {
    const hops = [];
    let el = node;
    while (el && el !== root) {
      if (el.hasAttribute('data-goon-path')) {
        return { anchorPath: el.getAttribute('data-goon-path'), hops };
      }
      const parent = el.parentElement;
      const role     = el.getAttribute('data-goon') || null;
      const palmIdx  = el.getAttribute('data-goon-palm-idx') || null;
      const palmId   = el.getAttribute('data-palm-id') || null;
      const childIdx = parent ? Array.from(parent.children).indexOf(el) : -1;
      hops.unshift({ role, palmIdx, palmId, childIdx });
      el = parent;
    }
    return null;
  }

  function resolveCursorPath(encoded) {
    if (!encoded) return null;
    const anchor = document.querySelector('[data-goon-path="' + encoded.anchorPath + '"]');
    if (!anchor) return null;
    let el = anchor;
    for (const hop of encoded.hops) {
      const children = Array.from(el.children);
      let match = children.find(c =>
        (hop.role    === null || c.getAttribute('data-goon')          === hop.role) &&
        (hop.palmIdx === null || c.getAttribute('data-goon-palm-idx') === hop.palmIdx) &&
        (hop.palmId  === null || c.getAttribute('data-palm-id')       === hop.palmId)
      );
      if (!match && hop.childIdx >= 0 && hop.childIdx < children.length) {
        match = children[hop.childIdx];
      }
      if (!match) return null;
      el = match;
    }
    return el;
  }

  function ensureEntry(el) {
    let entry = jsState.entries.get(el);
    if (!entry) {
      entry = { attrs: new Map(), classes: new Set() };
      jsState.entries.set(el, entry);
    }
    return entry;
  }

  function setAttr(el, name, value) {
    el.setAttribute(name, value);
    ensureEntry(el).attrs.set(name, value);
  }

  function clearAttr(el, name) {
    el.removeAttribute(name);
    const entry = jsState.entries.get(el);
    if (!entry) return;
    entry.attrs.delete(name);
    if (entry.attrs.size === 0 && entry.classes.size === 0) jsState.entries.delete(el);
  }

  function addClass(el, className) {
    el.classList.add(className);
    ensureEntry(el).classes.add(className);
  }

  function removeClass(el, className) {
    el.classList.remove(className);
    const entry = jsState.entries.get(el);
    if (!entry) return;
    entry.classes.delete(className);
    if (entry.attrs.size === 0 && entry.classes.size === 0) jsState.entries.delete(el);
  }

  function clearDownloadPending() {
    if (downloadPendingHref) {
      document
        .querySelectorAll('a[data-goon-native="download"]')
        .forEach(el => {
          if (el.getAttribute('href') === downloadPendingHref) clearPendingPulse(el);
        });
      downloadPendingHref = null;
    }
    if (downloadPendingAnchor) {
      clearPendingPulse(downloadPendingAnchor);
      downloadPendingAnchor = null;
    }
    if (downloadPendingTimeout) {
      clearTimeout(downloadPendingTimeout);
      downloadPendingTimeout = null;
    }
  }

  function clearPendingPulse(el) {
    if (!el) return;
    const timeout = pendingPulses.get(el);
    if (timeout) clearTimeout(timeout);
    pendingPulses.delete(el);
    removeClass(el, 'pulse');
  }

  function pulsePending(el, ms = 30000) {
    if (!el) return;
    clearPendingPulse(el);
    addClass(el, 'pulse');
    pendingPulses.set(el, ms === null ? null : setTimeout(() => clearPendingPulse(el), ms));
  }

  function pulseTargetFromEvent(e) {
    if (e.target.closest('[data-goon="page-controls"], [data-goon="palm-back"]')) return null;
    const el = e.target.closest('button, a, [data-goon-interact="action"], [data-goon-interact="link"], .goon-nav-async');
    if (!el) return null;
    if (el.matches('a[data-goon-native="download"]')) return null;
    const role = el.getAttribute('data-goon');
    const interact = el.getAttribute('data-goon-interact');
    if (el.classList.contains('goon-nav-async')) return el;
    if (role === 'action' || role === 'action-destructive' || role === 'link' || role === 'auth') return el;
    if (interact === 'action' || interact === 'link') return el;
    const nested = el.querySelector('[data-goon="action"], [data-goon="action-destructive"], [data-goon="link"], [data-goon="auth"], [data-goon-interact="action"], [data-goon-interact="link"], .goon-nav-async');
    return nested || null;
  }

  function passModal() {
    return document.getElementById('burn-pass-modal');
  }

  function isPassModalOpen() {
    const modal = passModal();
    return !!(modal && modal.classList.contains('is-open'));
  }

  function isBurnAuthenticated() {
    return document.body && document.body.getAttribute('data-burn-authenticated') === 'true';
  }

  function openPassModal(downloadUrl) {
    const modal = passModal();
    if (!modal) return false;
    const redirect = modal.querySelector('#burn-pass-redirect');
    const input = modal.querySelector('#burn-pass-code');
    if (redirect) redirect.value = downloadUrl || '';
    if (input) input.value = '';
    passModalLastFocus = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    modal.classList.add('is-open');
    modal.setAttribute('aria-hidden', 'false');
    if (input) {
      window.requestAnimationFrame(() => input.focus());
    }
    return true;
  }

  function closePassModal() {
    const modal = passModal();
    if (!modal) return false;
    modal.classList.remove('is-open');
    modal.setAttribute('aria-hidden', 'true');
    const input = modal.querySelector('#burn-pass-code');
    if (input) input.value = '';
    if (passModalLastFocus && document.contains(passModalLastFocus)) {
      passModalLastFocus.focus();
    }
    passModalLastFocus = null;
    return true;
  }

  // Re-assert any registered attr whose live value drifted, and any
  // registered class missing from its element. Lazy mark-and-sweep GC:
  // a registry entry whose element has been detached from the document
  // for GC_MISS_THRESHOLD consecutive calls is evicted.
  function restoreJSState() {
    jsState.entries.forEach((entry, el) => {
      const contained = document.contains(el);
      if (!contained) {
        const n = (jsState.misses.get(el) || 0) + 1;
        if (n >= GC_MISS_THRESHOLD) {
          jsState.entries.delete(el);
          jsState.misses.delete(el);
        } else {
          jsState.misses.set(el, n);
        }
        return;
      }
      jsState.misses.delete(el);
      entry.attrs.forEach((value, name) => {
        if (el.getAttribute(name) !== value) el.setAttribute(name, value);
      });
      entry.classes.forEach(className => {
        if (!el.classList.contains(className)) el.classList.add(className);
      });
    });
    if (downloadPendingHref && !document.getElementById('status-live')?.firstElementChild) {
      const anchor = Array
        .from(document.querySelectorAll('a[data-goon-native="download"]'))
        .find(el => el.getAttribute('href') === downloadPendingHref);
      if (anchor) {
        downloadPendingAnchor = anchor;
        if (!anchor.classList.contains('pulse')) addClass(anchor, 'pulse');
      }
    }
  }

  // Debug hook — inspect registry from browser console: `window.__jsState`
  if (typeof window !== 'undefined') window.__jsState = jsState;

  function getTraversableChildren(el) {
    // Infinite depth search: query all NODE_SEL and filter out those that are
    // nested inside another logical NODE_SEL.
    const nodes = el.querySelectorAll(NODE_SEL);
    return Array.from(nodes).filter(n => {
      // Boundary isolation: Do not let top-level containment scans peer into
      // collapsed accordion contents unless the query root itself is that content panel.
      const content = n.closest('[data-goon="accordion-content"]');
      if (content && el !== content && !content.contains(el)) return false;

      let p = n.parentElement;
      while (p && p !== el) {
        if (p.matches(NODE_SEL)) return false;
        p = p.parentElement;
      }
      return p === el;
    });
  }

  function getSiblings(node) {
    if (!node || !node.parentElement) return [];
    // Renderer-declared no-siblings: a swap-in pane (palm-detail) has no
    // useful peers — its DOM siblings are hidden detail panels for other
    // items. Up/Down on it becomes a no-op until the user drills in.
    if (node.hasAttribute('data-goon-no-siblings')) return [];
    let container = node.parentElement;
    while (container && container !== root) {
      const kids = getTraversableChildren(container);
      if (kids.length > 1) return kids;
      container = container.parentElement;
    }
    return getTraversableChildren(container || root);
  }

  function getParentNode(node) {
    if (!node) return null;
    let el = node.parentElement;
    while (el && el !== root) {
      if (el.matches(NODE_SEL)) return el;
      el = el.parentElement;
    }
    return null;
  }

  // — Palm-stage swap —
  //
  // CSS contract: palm-stage children with data-palm-id are display:none by
  // default; the primary pane (first data-palm-id child, by document order)
  // is shown when the stage has no data-active-palm attribute, otherwise
  // whichever child has class .palm-active is shown. nav.js owns both —
  // server never emits them.

  function applyPalmActive(stage, palmId) {
    if (!stage) return;
    setAttr(stage, 'data-active-palm', palmId);
    let activePane = null;
    Array.from(stage.children).forEach(child => {
      if (!child.hasAttribute('data-palm-id')) return;
      if (child.getAttribute('data-palm-id') === palmId) {
        addClass(child, 'palm-active');
        activePane = child;
      } else {
        removeClass(child, 'palm-active');
      }
    });
    if (activePane) setupPaginationInPane(activePane);
  }

  function clearPalmActive(stage) {
    if (!stage) return;
    clearAttr(stage, 'data-active-palm');
    Array.from(stage.children).forEach(child => {
      if (child.hasAttribute('data-palm-id')) removeClass(child, 'palm-active');
    });
  }

  // Pre-activate a palm-stage child when an async leaf is triggered. The
  // contract is generic: the leaf (or any ancestor up to the enclosing
  // palm-stage) declares data-goon-pane="<id>" pointing at the pane that
  // should become active after the morph. Nav.js applies palm-active
  // immediately so the user sees the destination (placeholder content if
  // not yet loaded) and routes post-morph focus into that pane. No
  // knowledge of any specific palm-id values.
  //
  // Distinct from data-goon-portal-in (instant-drill semantics) so it can
  // co-exist on the same node without colliding with drillIn's portal-in
  // branch — the async-fetch flow needs to wait for the morph, not jump
  // immediately to a placeholder.
  function maybePalmStageSwap(triggerEl) {
    const paneAncestor = triggerEl.closest('[data-goon-pane]');
    if (!paneAncestor) return null;
    const paneId = paneAncestor.getAttribute('data-goon-pane');
    if (!paneId) return null;
    const pane = document.getElementById(paneId);
    if (!pane) return null;
    const stage = pane.closest('[data-goon="palm-stage"]');
    if (!stage) return null;
    const palmId = pane.getAttribute('data-palm-id');
    if (!palmId) return null;
    applyPalmActive(stage, palmId);
    const originDetail = triggerEl.closest('[data-goon="palm-detail"]');
    if (originDetail) {
      const originItemId = originDetail.getAttribute('data-goon-portal-out');
      if (originItemId) palmDrillOrigin = originItemId;
    }
    return pane;
  }

  // Walk activeNode → enclosing palm-stage → clear palm-active. Restores
  // focus to the originating palm-item (palmDrillOrigin) when available;
  // otherwise falls back to the first palm-item in the palm-stage's first
  // data-palm-id child (by document order — vine emits the primary pane
  // first by convention).
  function handlePalmBack(fromNode = activeNode) {
    if (!fromNode) return false;
    const stage = fromNode.closest('[data-goon="palm-stage"]');
    if (!stage) return false;
    clearPalmActive(stage);
    let target = palmDrillOrigin ? document.getElementById(palmDrillOrigin) : null;
    if (!target) {
      const primary = stage.querySelector(':scope > [data-palm-id]');
      if (primary) target = primary.querySelector('[data-goon="palm-item"]');
    }
    palmDrillOrigin = null;
    if (target) setActive(target);
    return true;
  }

  // — Generic Palm Visual Sync (Powered by Portals) —
  function syncPalmVisuals(node) {
    if (!node) return;
    let item = node;
    let detail = null;

    if (node.getAttribute('data-goon') === 'palm-detail') {
      detail = node;
      const portalOut = node.getAttribute('data-goon-portal-out');
      item = portalOut ? document.getElementById(portalOut) : null;
    } else {
      const portalIn = node.getAttribute('data-goon-portal-in');
      if (!portalIn) return null;
      detail = document.getElementById(portalIn);
    }

    if (!item || !detail) return null;
    if (detail.getAttribute('data-goon') !== 'palm-detail') return null;

    const layout = detail.closest('[data-goon="palm-layout"]');
    if (!layout) return null;

    layout.querySelectorAll('[data-goon-palm-active]').forEach(el => {
      clearAttr(el, 'data-goon-palm-active');
    });

    setAttr(item, 'data-goon-palm-active', 'true');
    setAttr(detail, 'data-goon-palm-active', 'true');
    return item;
  }

  function isVisualControl(el) {
    if (!el) return false;
    if (el.matches('input[type="hidden"]')) return false;
    if (!el.matches('button, a, input, select, textarea, [contenteditable="true"]')) return false;
    return el.getClientRects().length > 0;
  }

  function activeVisualTarget(node) {
    if (!node) return null;
    if (isVisualControl(node)) return node;
    if (node.matches('[data-goon="palm-item"].goon-cover')) {
      const shape = node.querySelector(':scope > shape');
      if (shape) return shape;
    }
    if (node.getAttribute('data-goon') === 'palm-detail') {
      const card = node.querySelector(':scope > [data-goon="card"]');
      if (card) return card;
    }
    if (node.getAttribute('data-goon') === 'article-full') return node;
    if (node.getAttribute('data-goon') === 'form') {
      const layout = node.querySelector(':scope > cluster, :scope > stack, :scope > box');
      if (layout) return layout;
    }
    const childCount = parseInt(node.getAttribute('data-goon-children') || '0', 10);
    if (childCount > 0) return node;
    const controls = node.querySelectorAll('button, a, input, select, textarea, [contenteditable="true"]');
    for (const control of controls) {
      if (isVisualControl(control)) return control;
    }
    return node;
  }

  function clearActiveVisual() {
    if (!activeVisualNode) return;
    clearAttr(activeVisualNode, ACTIVE_VISUAL_ATTR);
    activeVisualNode = null;
  }

  function setActiveVisual(node) {
    clearActiveVisual();
    activeVisualNode = activeVisualTarget(node);
    if (activeVisualNode) setAttr(activeVisualNode, ACTIVE_VISUAL_ATTR, '');
  }

  function rememberCursor(node) {
    const par = getParentNode(node);
    if (par) cursorMemory.set(ensureId(par), ensureId(node));
  }

  function visibleElement(el) {
    if (!el) return false;
    const rect = el.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0;
  }

  function previousVisibleSibling(el) {
    let sib = el ? el.previousElementSibling : null;
    while (sib) {
      if (visibleElement(sib)) return sib;
      sib = sib.previousElementSibling;
    }
    return null;
  }

  function accordionHeader(section) {
    return section ? section.querySelector(':scope > [data-goon="accordion-header"]') : null;
  }

  function followingPageControls(layout) {
    const sidebar = layout ? layout.closest('sidebar') : null;
    let sib = sidebar ? sidebar.nextElementSibling : null;
    while (sib) {
      if (sib.getAttribute('data-goon') === 'page-controls' && visibleElement(sib)) return sib;
      if (visibleElement(sib)) return null;
      sib = sib.nextElementSibling;
    }
    return null;
  }

  function scrollParent(el, axis = 'y') {
    let p = el ? el.parentElement : null;
    const overflowProp = axis === 'x' ? 'overflowX' : 'overflowY';
    const scrollSize = axis === 'x' ? 'scrollWidth' : 'scrollHeight';
    const clientSize = axis === 'x' ? 'clientWidth' : 'clientHeight';
    while (p) {
      const style = getComputedStyle(p);
      const overflow = style[overflowProp];
      if ((overflow === 'auto' || overflow === 'scroll' || overflow === 'overlay') &&
          p[scrollSize] > p[clientSize] + 1) {
        return p;
      }
      p = p.parentElement;
    }
    return document.scrollingElement || document.body;
  }

  function scrollViewport(scroller) {
    if (!scroller || scroller === document.scrollingElement || scroller === document.documentElement || scroller === document.body) {
      return {
        top: 0,
        bottom: window.innerHeight || document.documentElement.clientHeight,
      };
    }
    const rect = scroller.getBoundingClientRect();
    return { top: rect.top, bottom: rect.bottom };
  }

  function scrollByAmount(scroller, top) {
    if (!top) return;
    if (!scroller || scroller === document.scrollingElement || scroller === document.documentElement) {
      window.scrollBy({ top, left: 0, behavior: 'smooth' });
      return;
    }
    scroller.scrollBy({ top, left: 0, behavior: 'smooth' });
  }

  function scheduleEnsureActiveVisible(node) {
    if (!node) return;
    if (node.getAttribute('data-goon') === 'article-full') {
      window.setTimeout(() => {
        requestAnimationFrame(() => ensureActiveVisible(node));
      }, 175);
      return;
    }
    requestAnimationFrame(() => ensureActiveVisible(node));
  }

  function scrollElementIntoContainer(el, container, axis = 'x') {
    if (!el || !container) return;
    const er = el.getBoundingClientRect();
    const cr = container.getBoundingClientRect();
    if (axis === 'x') {
      const targetLeft = container.scrollLeft + (er.left - cr.left) - ((cr.width - er.width) / 2);
      container.scrollTo({ left: targetLeft, behavior: 'smooth' });
    } else {
      if (er.top < cr.top) container.scrollBy({ top: er.top - cr.top, behavior: 'smooth' });
      else if (er.bottom > cr.bottom) container.scrollBy({ top: er.bottom - cr.bottom, behavior: 'smooth' });
    }
  }

  function scrollContextFor(node) {
    const visual = activeVisualTarget(node) || node;
    const section = node.closest('[data-goon="accordion-section"]');
    if (section) {
      const palmLayout = node.closest('[data-goon="palm-layout"]');
      const header = accordionHeader(section);
      return {
        anchor: header || section,
        target: palmLayout || section,
        extent: followingPageControls(palmLayout),
        visual,
      };
    }
    const rootSection = node.closest('[data-goon="root-section"], [data-goon="header"]');
    if (rootSection) {
      return {
        anchor: previousVisibleSibling(rootSection) || rootSection.parentElement || rootSection,
        target: rootSection,
        visual,
      };
    }
    return {
      anchor: getParentNode(node) || node,
      target: visual,
      extent: null,
      visual,
    };
  }

  function ensureActiveVisible(node) {
    if (!node || !document.contains(node)) return;

    const visual = node === activeNode && activeVisualNode && document.contains(activeVisualNode)
      ? activeVisualNode
      : activeVisualTarget(node);

    const reel = visual && visual.closest('reel');
    if (reel) scrollElementIntoContainer(visual, reel, 'x');

    const context = scrollContextFor(node);
    const anchor = context.anchor;
    const target = context.target || visual || node;
    const extent = context.extent;
    const required = context.visual || visual || node;

    if (!visibleElement(target) || !visibleElement(required)) return;

    const scroller = scrollParent(target, 'y');
    const viewport = scrollViewport(scroller);
    const viewportTop = viewport.top;
    const viewportBottom = viewport.bottom;
    const viewportHeight = viewportBottom - viewportTop;
    const pad = Math.max(12, Math.min(48, viewportHeight * 0.04));
    const ar = anchor && visibleElement(anchor) ? anchor.getBoundingClientRect() : null;
    const tr0 = target.getBoundingClientRect();
    const er = extent && visibleElement(extent) ? extent.getBoundingClientRect() : null;
    const tr = er ? {
      top: Math.min(tr0.top, er.top),
      bottom: Math.max(tr0.bottom, er.bottom),
      height: Math.max(tr0.bottom, er.bottom) - Math.min(tr0.top, er.top),
    } : tr0;
    const rr = required.getBoundingClientRect();
    let delta = 0;

    if (tr.height + (pad * 2) <= viewportHeight) {
      if (tr.top < viewportTop + pad) {
        const desiredTop = ar ? Math.min(ar.top, tr.top) : tr.top;
        delta = desiredTop - pad;
      } else if (tr.bottom > viewportBottom - pad) {
        delta = tr.bottom - (viewportBottom - pad);
      }
    } else {
      if (rr.top < viewportTop + pad) {
        delta = rr.top - pad;
      } else if (rr.bottom > viewportBottom - pad) {
        delta = rr.bottom - (viewportBottom - pad);
      }
      if (delta === 0 && tr.top < viewportTop + pad) {
        delta = tr.top - pad;
      }
    }

    if (delta !== 0) {
      scrollByAmount(scroller, delta);
    }
  }

  function setActive(node, direction) {
    if (node && node === activeNode) {
      if (root) setAttr(root, NAV_ATTR, 'active');
      if (!activeVisualNode || !document.contains(activeVisualNode)) setActiveVisual(node);
      lastCursorPath = encodeCursorPath(node);
      rememberCursor(node);
      const palmItem = syncPalmVisuals(node);
      if (direction === 'nav') paginateForNode(palmItem || node);
      scheduleEnsureActiveVisible(node);
      return;
    }
    if (editMode) exitEditMode();
    clearActiveVisual();
    if (activeNode) {
      clearAttr(activeNode, ACTIVE_ATTR);
      clearAttr(activeNode, 'aria-current');
    }
    activeNode = node;
    if (!node) return;
    lastCursorPath = encodeCursorPath(node);
    rememberCursor(node);
    if (lastCursorPath) {
      try { localStorage.setItem(CURSOR_LS_KEY, JSON.stringify(lastCursorPath)); } catch (_) {}
    }

    setAttr(node, ACTIVE_ATTR, '');
    setAttr(node, 'aria-current', 'true');
    setActiveVisual(node);
    const palmItem = syncPalmVisuals(node);
    if (direction === 'nav') paginateForNode(palmItem || node);
    scheduleEnsureActiveVisible(node);
  }

  function enterEditMode(input) {
    if (!input) return;
    editMode = true;
    editInput = input;
    if (root) setAttr(root, 'data-goon-editing', 'true');
    input.focus();
    if (typeof input.select === 'function') input.select();
  }

  function exitEditMode() {
    if (!editMode) return;
    const input = editInput;
    editMode = false;
    editInput = null;
    if (root) clearAttr(root, 'data-goon-editing');
    if (input && document.activeElement === input) input.blur();
  }

  function insertIntoActive() {
    if (!activeNode) return false;
    let editNode = activeNode.getAttribute('data-goon-interact') === 'edit'
      ? activeNode
      : activeNode.querySelector('[data-goon-interact="edit"]');
    if (!editNode) return false;
    const input = editNode.querySelector('input[type="text"], input:not([type]), textarea');
    if (!input) return false;
    if (editNode !== activeNode && editNode.matches(NODE_SEL)) setActive(editNode);
    enterEditMode(input);
    return true;
  }

  // — Accordion Logic —
  function isAccordionHeader(node) {
    return node && node.getAttribute('data-goon') === 'accordion-header';
  }

  function toggleAccordion(headerBtn, expand, persist = true) {
    const section = headerBtn.closest('[data-goon="accordion-section"]');
    if (!section) return;
    const content = section.querySelector('[data-goon="accordion-content"]');
    if (!content) return;
    const val = expand ? 'true' : 'false';
    if (persist) {
      setAttr(headerBtn, 'data-goon-accordion-expanded', val);
      setAttr(content, 'data-goon-accordion-expanded', val);
      setAttr(section, 'data-goon-accordion-expanded', val);
      const path = section.getAttribute('data-goon-path');
      if (path) {
        try { localStorage.setItem(ACCORDION_LS_PREFIX + path, val); } catch (_) {}
      }
    } else {
      headerBtn.setAttribute('data-goon-accordion-expanded', val);
      content.setAttribute('data-goon-accordion-expanded', val);
      section.setAttribute('data-goon-accordion-expanded', val);
    }

    if (expand && persist) setupPaginationInPane(content);
  }

  function getAccordionHeaders(node) {
    const shell = node.closest('[data-goon="accordion-shell"]');
    if (!shell) return [];
    return Array.from(shell.children)
      .filter(el => el.getAttribute('data-goon') === 'accordion-section')
      .map(sec => sec.querySelector(':scope > [data-goon="accordion-header"]'))
      .filter(Boolean);
  }

  // — Navigation actions —

  function movePrev() {
    if (!activeNode) return activateFirst();
    if (isAccordionHeader(activeNode)) {
      const headers = getAccordionHeaders(activeNode);
      const idx = headers.indexOf(activeNode);
      if (idx <= 0) return;
      setActive(headers[idx - 1], 'nav');
      return;
    }
    const sibs = getSiblings(activeNode);
    const idx = sibs.indexOf(activeNode);
    if (idx < 0) return;
    setActive(idx === 0 ? sibs[sibs.length - 1] : sibs[idx - 1], 'nav');
  }

  function moveNext() {
    if (!activeNode) return activateFirst();
    if (isAccordionHeader(activeNode)) {
      const headers = getAccordionHeaders(activeNode);
      const idx = headers.indexOf(activeNode);
      if (idx < 0 || idx === headers.length - 1) return;
      setActive(headers[idx + 1], 'nav');
      return;
    }
    const sibs = getSiblings(activeNode);
    const idx = sibs.indexOf(activeNode);
    if (idx < 0) return;
    setActive(idx === sibs.length - 1 ? sibs[0] : sibs[idx + 1], 'nav');
  }

  function drillIn() {
    if (!activeNode) return activateFirst();

    // 0. Palm-back: clear palm-active and restore focus to drill origin.
    if (activeNode.getAttribute('data-goon') === 'palm-back') {
      if (handlePalmBack()) return;
    }

    // 1. Portal-in: jump to target DOM id. Single-step — Right again drills in.
    // Symmetric with portal-out (backOut step 1) which is also single-step.
    const portalIn = activeNode.getAttribute('data-goon-portal-in');
    if (portalIn) {
      const target = document.getElementById(portalIn);
      if (target) {
        const par = getParentNode(activeNode);
        if (par) cursorMemory.set(ensureId(par), ensureId(activeNode));
        setActive(target);
        return;
      }
    }

    // 2. Accordion header: expand and enter content.
    if (isAccordionHeader(activeNode)) {
      toggleAccordion(activeNode, true);
      const section = activeNode.closest('[data-goon="accordion-section"]');
      const content = section ? section.querySelector('[data-goon="accordion-content"]') : null;
      if (content) {
        const kids = getTraversableChildren(content);
        if (kids.length > 0) {
          const mem = section && section.id ? cursorMemory.get(section.id) : null;
          const remembered = mem ? document.getElementById(mem) : null;
          setActive((remembered && content.contains(remembered)) ? remembered : kids[0]);
        }
      }
      return;
    }

    // 3. Branch: drill into first/remembered/preferred child.
    // Precedence: cursorMemory (return-visit) > data-goon-prefer-child role > kids[0].
    const childCount = parseInt(activeNode.getAttribute('data-goon-children') || '0');
    if (childCount > 0) {
      const par = getParentNode(activeNode);
      if (par) cursorMemory.set(ensureId(par), ensureId(activeNode));
      const kids = getTraversableChildren(activeNode);
      if (kids.length === 0) return;
      const rememberedId = cursorMemory.get(ensureId(activeNode));
      const remembered = rememberedId ? document.getElementById(rememberedId) : null;
      let target = (remembered && kids.includes(remembered)) ? remembered : null;
      if (!target) {
        // data-goon-prefer-child accepts a comma-separated fallback list of
        // data-goon role values, tried in order. Lets the renderer cover
        // structural variants in one attribute (e.g. "actions,form,link"
        // matches a multi-action wrapper OR a singleton form/anchor that
        // bypasses the wrapper).
        const preferAttr = activeNode.getAttribute('data-goon-prefer-child');
        if (preferAttr) {
          const roles = preferAttr.split(',').map(r => r.trim()).filter(Boolean);
          for (const r of roles) {
            target = kids.find(k => k.getAttribute('data-goon') === r);
            if (target) break;
          }
        }
      }
      target = target || kids[0];
      if (target && target.getAttribute('data-goon-skip-single') === 'true') {
        const targetKids = getTraversableChildren(target);
        if (targetKids.length === 1) target = targetKids[0];
      }
      setActive(target);
      return;
    }

    // ——— LEAF INTERACTIONS ONLY BELOW THIS LINE ———

    if (activeNode.getAttribute('data-goon') === 'article-full') return;

    // 4. Async leaf: submit the fetch, suspend nav until MutationObserver fires.
    const isAsync = activeNode.classList.contains('goon-nav-async') || activeNode.querySelector('.goon-nav-async');
    if (isAsync) {
      const btn = activeNode.matches('.goon-nav-async') ? activeNode : activeNode.querySelector('.goon-nav-async');

      // Async pane drill: if this leaf declares data-goon-pane, pre-activate
      // the corresponding palm-stage child so the user sees the destination
      // immediately (placeholder content until the morph arrives), and route
      // post-morph focus into that pane instead of the origin palm-detail.
      const preActivatedPane = maybePalmStageSwap(activeNode);

      btn.click();
      asyncPending = preActivatedPane
                  || activeNode.closest('[data-goon-portal-out]')
                  || getParentNode(activeNode);
      document.body.classList.add('goon-nav-waiting');
      if (asyncPending && document.contains(asyncPending)) {
        const kids = getTraversableChildren(asyncPending);
        if (kids.length > 0) {
          document.body.classList.remove('goon-nav-waiting');
          setActive(kids[0]);
          asyncPending = null;
        }
      }
      return;
    }

    // 5. Edit interact: enter the input.
    const interact = activeNode.getAttribute('data-goon-interact');
    if (interact === 'edit') {
      const input = activeNode.querySelector('input[type="text"]');
      if (input) { enterEditMode(input); return; }
    }

    // 6. Default leaf click. Action buttons (renderer-tagged data-goon="action"
    // or "action-destructive") and download anchors (data-goon="link") are
    // gated to Enter only — Right traversal should never fire a server-
    // mutating action like download or delete. activate() (Enter) does not
    // gate and still fires these via its own step 5.
    const btn = activeNode.matches('button, a') ? activeNode : activeNode.querySelector('button, a');
    if (btn) {
      const role = btn.getAttribute('data-goon');
      const btnInteract = btn.getAttribute('data-goon-interact') || interact;
      if (role === 'action' || role === 'action-destructive' || role === 'link' || btnInteract === 'action' || btnInteract === 'link') return;
      btn.click();
    }
  }

  function activate() {
    if (!activeNode) return;

    // 1. Accordion Header
    if (isAccordionHeader(activeNode)) { drillIn(); return; }

    // 2. Branch Check
    const childCount = parseInt(activeNode.getAttribute('data-goon-children') || '0');
    if (childCount > 0) { drillIn(); return; }

    // ——— LEAF INTERACTIONS ONLY BELOW THIS LINE ———

    if (activeNode.getAttribute('data-goon') === 'article-full') return;

    // 3. Async Leaf
    const isAsync = activeNode.classList.contains('goon-nav-async') || activeNode.querySelector('.goon-nav-async');
    if (isAsync) {
      const btn = activeNode.matches('.goon-nav-async') ? activeNode : activeNode.querySelector('.goon-nav-async');
      btn.click();
      asyncPending = activeNode.closest('[data-goon-portal-out]') || getParentNode(activeNode);
      document.body.classList.add('goon-nav-waiting');
      return;
    }

    // 4. Edit Field
    const interact = activeNode.getAttribute('data-goon-interact');
    if (interact === 'edit') {
      const input = activeNode.querySelector('input[type="text"]');
      if (input) { enterEditMode(input); return; }
    }

    // 5. Default Leaf
    const btn = activeNode.matches('button, a') ? activeNode : activeNode.querySelector('button, a');
    if (btn) btn.click();
  }

  function backOut() {
    if (!activeNode) return;

    // 1. Portal-out: only fires when standing ON the portal-out node itself.
    // Symmetric with portal-in: one keypress = one stop crossed. Left from
    // inside the container falls through to the standard parent climb below,
    // walking the same stops Right walked on the way in.
    if (activeNode.hasAttribute('data-goon-portal-out')) {
      const targetId = activeNode.getAttribute('data-goon-portal-out');
      const target = targetId ? document.getElementById(targetId) : null;
      if (target) { setActive(target); return; }
    }

    // 1b. Palm-stage pane exit: if no portal-out applied and the parent
    // climb would take us out of the data-palm-id pane we're currently
    // inside, AND the enclosing palm-stage is in a swapped state (has
    // data-active-palm), treat the exit as palm-back. Generic — no
    // knowledge of any specific palm-id values.
    const palmPane = activeNode.closest('[data-palm-id]');
    if (palmPane) {
      const stage = palmPane.closest('[data-goon="palm-stage"]');
      if (stage && stage.hasAttribute('data-active-palm')) {
        const par = getParentNode(activeNode);
        if (!par || !palmPane.contains(par)) {
          if (handlePalmBack()) return;
        }
      }
    }

    // 2. Accordion header: first Left collapses, second Left climbs.
    if (isAccordionHeader(activeNode)) {
      const section = activeNode.closest('[data-goon="accordion-section"]');
      const path = section ? section.getAttribute('data-goon-path') : null;
      let lsExpanded = false;
      if (path) { try { lsExpanded = localStorage.getItem(ACCORDION_LS_PREFIX + path) === 'true'; } catch(_) {} }
      const expanded = activeNode.getAttribute('data-goon-accordion-expanded') === 'true' ||
                       (section && section.getAttribute('data-goon-accordion-expanded') === 'true') ||
                       lsExpanded;
      if (expanded) { toggleAccordion(activeNode, false); return; }
      const parent = getParentNode(activeNode);
      if (parent && parent !== root) {
        cursorMemory.set(ensureId(parent), ensureId(activeNode));
        setActive(parent);
      } else {
        deactivateNav();
      }
      return;
    }

    // 3. Accordion exit: accordion-header is a sibling of accordion-content,
    // so getParentNode would walk past it and skip the collapse stop. When the
    // standard climb would exit a content boundary, land on the enclosing
    // accordion-header first — second Left then collapses, third Left climbs.
    const enclosingContent = activeNode.closest('[data-goon="accordion-content"]');
    const parent = getParentNode(activeNode);
    if (enclosingContent && (!parent || !enclosingContent.contains(parent))) {
      const section = enclosingContent.closest('[data-goon="accordion-section"]');
      const header = section ? section.querySelector(':scope > [data-goon="accordion-header"]') : null;
      if (header) {
        if (section && section.id) cursorMemory.set(section.id, ensureId(activeNode));
        setActive(header);
        return;
      }
    }

    // 4. Standard parent climb.
    if (!parent || parent === root) {
      deactivateNav();
      return;
    }
    cursorMemory.set(ensureId(parent), ensureId(activeNode));
    setActive(parent);
  }

  function activateFirst() {
    if (!root) return;
    setAttr(root, NAV_ATTR, 'active');
    if (tryRestoreCursor()) return;
    const kids = getTraversableChildren(root);
    if (kids.length > 0) setActive(kids[0]);
  }

  function deactivateNav() {
    if (!root) return;
    clearActiveVisual();
    if (activeNode) {
      clearAttr(activeNode, ACTIVE_ATTR);
      clearAttr(activeNode, 'aria-current');
      activeNode = null;
    }
    lastCursorPath = null;
    setAttr(root, NAV_ATTR, 'dormant');
    cursorMemory.clear();
  }

  function onKeyDown(e) {
    if (isPassModalOpen()) {
      if (e.key === 'Escape' || e.key === 'ArrowLeft') {
        e.preventDefault();
        closePassModal();
      }
      return;
    }

    if (!root) return;

    if (editMode) {
      if (e.key === 'Escape') {
        e.preventDefault();
        exitEditMode();
      }
      return;
    }

    const navState = root.getAttribute(NAV_ATTR);
    const isActive = navState === 'active';
    const keyAction = {
      ArrowUp: 'up', ArrowDown: 'down', ArrowLeft: 'left', ArrowRight: 'right',
      k: 'up', j: 'down', h: 'left', l: 'right',
      w: 'up', s: 'down', a: 'left', d: 'right',
    };

    let action = null;
    if (!e.metaKey && !e.ctrlKey && !e.altKey && keyAction[e.key]) action = keyAction[e.key];
    else if (e.key === 'Enter' && isActive) {
      e.preventDefault(); activate(); return;
    } else if (e.key === 'i' && isActive) {
      if (insertIntoActive()) {
        e.preventDefault();
        return;
      }
    } else if (e.key === 'Escape' && isActive) {
      e.preventDefault();
      backOut();
      return;
    } else {
      return;
    }

    e.preventDefault();
    if (!isActive) {
      if (activeNode && document.contains(activeNode)) {
        setAttr(root, NAV_ATTR, 'active');
      } else {
        activateFirst();
      }
      return;
    }

    switch (action) {
      case 'up':    movePrev(); break;
      case 'down':  moveNext(); break;
      case 'right': drillIn();  break;
      case 'left':  backOut();  break;
    }
  }

  // — Viewport Pagination (Restored) —

  function initPagination() {
    paginatedContainers = [];
    if (!root) return;
    const candidates = root.querySelectorAll('[data-goon-paginate], [data-goon="palm-list"]');
    candidates.forEach(el => {
      if (!el.hasAttribute('data-goon-paginate')) el.setAttribute('data-goon-paginate', '');
      setupPagination(el);
    });
  }

  function isSidebarWrapped(palmLayout) {
    const list = palmLayout.querySelector('[data-goon="palm-list"]');
    const aside = palmLayout.querySelector('[data-goon="palm"]');
    if (!list || !aside) return false;
    return aside.getBoundingClientRect().top >= list.getBoundingClientRect().bottom - 1;
  }

  function paginationKey(container) {
    const pathEl = container.closest('[data-goon-path]');
    if (!pathEl) return null;
    const path   = pathEl.getAttribute('data-goon-path');
    const palmEl = container.closest('[data-palm-id]');
    const palmId = palmEl ? palmEl.getAttribute('data-palm-id') : '';
    return PAGINATION_LS_PREFIX + path + ':' + palmId + ':palm-list';
  }

  function paginationHeightKey(container, pageSize, lsKey) {
    if (!lsKey) return null;
    const width = container.getBoundingClientRect().width;
    if (width <= 0) return null;
    const widthBucket = Math.round(width / 16) * 16;
    return lsKey + ':w' + widthBucket + ':p' + pageSize;
  }

  function paginationDebugEnabled() {
    try { return localStorage.getItem(PAGINATION_DEBUG_KEY) === 'true'; }
    catch (_) { return false; }
  }

  function paginationLabel(container) {
    const key = paginationKey(container);
    if (key) return key.replace(PAGINATION_LS_PREFIX, '');
    const pathEl = container.closest('[data-goon-path]');
    return pathEl ? pathEl.getAttribute('data-goon-path') : '(unknown palm-list)';
  }

  function paginationDebug(label, detail) {
    if (!paginationDebugEnabled()) return;
    console.log('[goon-pagination] ' + label, detail || {});
  }

  function paginationViewportHeight() {
    const vv = window.visualViewport;
    return (vv && vv.height) || window.innerHeight || document.documentElement.clientHeight || 0;
  }

  function outerBlockSize(el) {
    if (!el) return 0;
    const rect = el.getBoundingClientRect();
    const style = getComputedStyle(el);
    const before = parseFloat(style.marginBlockStart || style.marginTop || '0') || 0;
    const after = parseFloat(style.marginBlockEnd || style.marginBottom || '0') || 0;
    return rect.height + before + after;
  }

  function paginationAvailableHeight(container, controls, wrapped) {
    const viewportHeight = paginationViewportHeight();
    const rect = container.getBoundingClientRect();
    const bottomPad = Math.max(12, Math.min(40, viewportHeight * 0.04));
    let available = viewportHeight - Math.max(0, rect.top) - outerBlockSize(controls) - bottomPad;

    const palmLayout = container.closest('[data-goon="palm-layout"]');
    if (wrapped && palmLayout) {
      const layoutStyle = getComputedStyle(palmLayout);
      const gap = parseFloat(layoutStyle.rowGap || layoutStyle.gap || '0') || 0;
      const palm = palmLayout.querySelector(':scope > [data-goon="palm"]');
      available -= outerBlockSize(palm) + gap;
    }

    if (!Number.isFinite(available) || available <= 0) {
      return viewportHeight * (wrapped ? 0.55 : 0.75);
    }
    return Math.max(80, available);
  }

  function removePaginationControls(container) {
    const sidebar = container.closest('sidebar');
    if (sidebar) {
      let next = sidebar.nextElementSibling;
      while (next && next.getAttribute('data-goon') === 'page-controls') {
        const current = next;
        next = next.nextElementSibling;
        current.parentElement.removeChild(current);
      }
      return;
    }
    container.querySelectorAll(':scope > [data-goon="page-controls"]').forEach(controls => {
      controls.parentElement.removeChild(controls);
    });
  }

  function createPaginationControls(owner) {
    const controls = document.createElement('cluster');
    controls.setAttribute('data-goon', 'page-controls');
    controls.setAttribute('data-ignore-morph', '');
    controls.setAttribute('data-goon-pagination-for', owner);
    controls.style.cssText = 'justify-content: center; padding-block-start: 0.5rem;';

    const prevBtn = document.createElement('button');
    prevBtn.setAttribute('data-goon', 'action');
    prevBtn.setAttribute('data-goon-page-action', 'prev');
    prevBtn.textContent = '← prev';

    const pageInfo = document.createElement('span');
    pageInfo.style.cssText = 'font-size: 0.8125rem; min-width: 5rem; text-align: center; color: var(--f2)';
    pageInfo.textContent = '1 / 1';

    const nextBtn = document.createElement('button');
    nextBtn.setAttribute('data-goon', 'action');
    nextBtn.setAttribute('data-goon-page-action', 'next');
    nextBtn.textContent = 'next →';

    controls.appendChild(prevBtn);
    controls.appendChild(pageInfo);
    controls.appendChild(nextBtn);
    return { controls, prevBtn, nextBtn, pageInfo };
  }

  function nodeIsPaginationControl(node) {
    if (!node || node.nodeType !== 1) return false;
    return node.getAttribute('data-goon') === 'page-controls'
        || !!node.closest('[data-goon="page-controls"]');
  }

  function mutationIsPaginationOnly(mutation) {
    if (nodeIsPaginationControl(mutation.target)) return true;
    const changed = [...mutation.addedNodes, ...mutation.removedNodes];
    return changed.length > 0 && changed.every(node => {
      if (node.nodeType === 3) return !node.textContent || node.textContent.trim() === '';
      return nodeIsPaginationControl(node);
    });
  }

  function setupPagination(container) {
    // Idempotency guard: disconnect any live observer and remove stale controls
    // before re-measuring. Prevents observer accumulation when setupPagination
    // is called more than once for the same container (e.g. accordion re-expand
    // after a morph stripped data-goon-paginate).
    const existingRo = paginationObservers.get(container);
    if (existingRo) { existingRo.disconnect(); paginationObservers.delete(container); }
    paginatedContainers = paginatedContainers.filter(s => {
      if (s.el !== container) return true;
      if (s.controls.parentElement) s.controls.parentElement.removeChild(s.controls);
      return false;
    });
    removePaginationControls(container);

    const items = Array.from(container.children).filter(c => !c.matches('cluster[data-goon="page-controls"]'));
    if (items.length === 0) return;
    const label = paginationLabel(container);

    const palmLayout = container.closest('[data-goon="palm-layout"]');
    const wrapped = palmLayout ? isSidebarWrapped(palmLayout) : false;

    const controlsParts = createPaginationControls(ensureId(container));
    const { controls, prevBtn, nextBtn, pageInfo } = controlsParts;
    const sidebar = container.closest('sidebar');
    if (sidebar) sidebar.after(controls);
    else container.appendChild(controls);

    const availableHeight = paginationAvailableHeight(container, controls, wrapped);

    items.forEach(item => item.style.display = '');

    let pageSize = 0;
    let accHeight = 0;
    const containerStyle = getComputedStyle(container);
    const isGrid = containerStyle.display === 'grid';
    const gap = parseFloat(containerStyle.rowGap || '0') || 0;
    let lastTop = null;
    let rows = 0;

    for (const item of items) {
      const itemRect = item.getBoundingClientRect();
      if (isGrid && lastTop !== null && Math.abs(itemRect.top - lastTop) < 1) {
        pageSize++; continue;
      }
      if (isGrid) {
        rows++;
        if (wrapped && rows > 2) break;
      }
      lastTop = itemRect.top;
      accHeight += itemRect.height + (pageSize > 0 ? gap : 0);
      if (accHeight > availableHeight && pageSize > 0) break;
      pageSize++;
    }

    if (pageSize > 8) pageSize = 8;
    if (pageSize < 1) pageSize = 1;

    if (items.length <= pageSize) {
      paginationDebug('setup:unpaginated', {
        label, items: items.length, pageSize, width: container.getBoundingClientRect().width,
      });
      if (controls.parentElement) controls.parentElement.removeChild(controls);
      container.removeAttribute('data-goon-paginate');
      container.style.removeProperty('min-height');
      return;
    }

    const totalPages = Math.ceil(items.length / pageSize);
    setAttr(container, 'data-ignore-morph', '');

    const lsKey = paginationKey(container);
    let startPage = 0;
    let hasStoredPage = false;
    if (lsKey) {
      try {
        const stored = localStorage.getItem(lsKey);
        if (stored !== null) {
          const parsed = parseInt(stored, 10);
          if (!isNaN(parsed)) {
            startPage = Math.max(0, Math.min(parsed, totalPages - 1));
            hasStoredPage = true;
          }
        }
      } catch (_) {}
    }

    if (activeNode && !hasStoredPage) {
      const directAncestor = items.find(c => c === activeNode || c.contains(activeNode));
      if (directAncestor) startPage = Math.floor(items.indexOf(directAncestor) / pageSize);
    }

    const heightKey = paginationHeightKey(container, pageSize, lsKey);
    const state = { el: container, items, pageSize, currentPage: 0, totalPages, controls, prevBtn, nextBtn, pageInfo, lsKey, heightKey };
    paginatedContainers.push(state);
    paginationDebug('setup', {
      label, items: items.length, pageSize, totalPages, startPage, wrapped,
      width: container.getBoundingClientRect().width,
      availableHeight, accHeight, gap, heightKey,
    });

    prevBtn.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      paginateTo(state, state.currentPage - 1);
    });
    nextBtn.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      paginateTo(state, state.currentPage + 1);
    });

    paginateTo(state, startPage);
    applyMeasuredPageHeight(state);

    items.forEach((item, itemIndex) => {
      item.querySelectorAll('img').forEach((img, imgIndex) => {
        if (img.dataset.goonPaginationImgDebug === 'true') return;
        img.dataset.goonPaginationImgDebug = 'true';
        const imgLabel = { label, itemIndex, imgIndex, src: img.currentSrc || img.src };
        if (img.complete) {
          paginationDebug('img:already-complete', {
            ...imgLabel,
            naturalWidth: img.naturalWidth,
            naturalHeight: img.naturalHeight,
            itemHeight: item.getBoundingClientRect().height,
          });
          return;
        }
        img.addEventListener('load', () => {
          paginationDebug('img:load:no-remeasure', {
            ...imgLabel,
            naturalWidth: img.naturalWidth,
            naturalHeight: img.naturalHeight,
            itemHeight: item.getBoundingClientRect().height,
            pageHeight: container.style.getPropertyValue('--goon-page-height'),
          });
        }, { once: true });
        img.addEventListener('error', () => {
          paginationDebug('img:error:no-remeasure', imgLabel);
        }, { once: true });
      });
    });

    // Re-measure when layout changes width; debounced via rAF to avoid loops.
    let rafPending = false;
    let lastObservedWidth = container.getBoundingClientRect().width;
    const ro = new ResizeObserver(() => {
      if (rafPending) return;
      rafPending = true;
      requestAnimationFrame(() => {
        // Second rAF: let the browser paint the new width first so aspect-ratio
        // items report settled heights before we measure pageSize.
        requestAnimationFrame(() => {
          rafPending = false;
          if (!document.contains(container)) {
            const existing = paginationObservers.get(container);
            if (existing) { existing.disconnect(); paginationObservers.delete(container); }
            return;
          }
          const newWidth = container.getBoundingClientRect().width;
          // Skip if container is hidden (e.g. inside a non-active palm-stage pane).
          // A display:none ancestor collapses width to 0 — re-measuring then
          // computes pageSize from 0-height items and corrupts pagination state.
          if (newWidth === 0) return;
          if (Math.abs(newWidth - lastObservedWidth) < 1) return;
          paginationDebug('resize-rebuild', {
            label,
            oldWidth: lastObservedWidth,
            newWidth,
            currentPage: state.currentPage,
            pageHeight: container.style.getPropertyValue('--goon-page-height'),
          });
          lastObservedWidth = newWidth;
          // Disconnect before re-measure so the new setupPagination call doesn't
          // inherit a live observer that would fire again on the layout change.
          ro.disconnect();
          paginationObservers.delete(container);
          paginatedContainers = paginatedContainers.filter(s => s.el !== container);
          if (state.controls.parentElement) state.controls.parentElement.removeChild(state.controls);
          clearAttr(container, 'data-ignore-morph');
          // Clear stale height so the old min-height doesn't skew item measurement.
          container.style.removeProperty('--goon-page-height');
          container.style.removeProperty('min-height');
          setupPagination(container);
        });
      });
    });
    ro.observe(container);
    paginationObservers.set(container, ro);
  }

  function measureMaxPageHeight(state) {
    const displays = state.items.map(item => item.style.display);
    let maxHeight = 0;
    const pages = [];
    for (let page = 0; page < state.totalPages; page++) {
      const start = page * state.pageSize;
      const end = start + state.pageSize;
      state.items.forEach((item, i) => {
        item.style.display = (i >= start && i < end) ? '' : 'none';
      });
      const height = state.el.scrollHeight;
      maxHeight = Math.max(maxHeight, height);
      pages.push({ page, start, end: Math.min(end, state.items.length), height });
    }
    state.items.forEach((item, i) => {
      item.style.display = displays[i];
    });
    paginationDebug('measure-max-height', {
      label: paginationLabel(state.el),
      currentPage: state.currentPage,
      pageSize: state.pageSize,
      totalPages: state.totalPages,
      maxHeight,
      pages,
    });
    return maxHeight;
  }

  function applyMeasuredPageHeight(state) {
    const currentPage = state.currentPage;
    const previous = state.el.style.getPropertyValue('--goon-page-height');
    const previousPx = previous && previous.endsWith('px') ? parseFloat(previous) : 0;
    const floorPx = state.heightKey ? (paginationHeightFloors.get(state.heightKey) || 0) : 0;
    state.el.style.removeProperty('--goon-page-height');
    const h = measureMaxPageHeight(state);
    if (h > 0) {
      const next = Math.max(h, previousPx, floorPx);
      if (state.heightKey) paginationHeightFloors.set(state.heightKey, next);
      state.el.style.setProperty('--goon-page-height', next + 'px');
      state.el.style.setProperty('min-height', next + 'px');
      paginationDebug('apply-height', {
        label: paginationLabel(state.el),
        measured: h,
        previousPx,
        floorPx,
        applied: next,
        heightKey: state.heightKey,
        currentPage,
      });
    } else if (previous) {
      state.el.style.setProperty('--goon-page-height', previous);
      state.el.style.setProperty('min-height', previous);
      paginationDebug('apply-height:restore-previous', {
        label: paginationLabel(state.el),
        previous,
        currentPage,
      });
    }
    paginateTo(state, currentPage);
  }

  // Re-measure all palm-lists inside a pane that just became visible.
  // Call whenever a hidden container is revealed (accordion expand,
  // palm-stage activation, or any future reveal pattern) so that
  // --goon-page-height is captured from a live layout rather than 0.
  function setupPaginationInPane(pane) {
    requestAnimationFrame(() => {
      pane.querySelectorAll('[data-goon="palm-list"]').forEach(list => {
        if (!list.hasAttribute('data-goon-paginate')) list.setAttribute('data-goon-paginate', '');
        setupPagination(list);
      });
    });
  }

  function rebuildPaginationState(state, reason) {
    if (!state || !state.el || !document.contains(state.el)) return;
    if (state.el.getBoundingClientRect().width === 0) return;

    const observer = paginationObservers.get(state.el);
    if (observer) { observer.disconnect(); paginationObservers.delete(state.el); }
    paginatedContainers = paginatedContainers.filter(s => s.el !== state.el);
    if (state.controls && state.controls.parentElement) state.controls.parentElement.removeChild(state.controls);
    removePaginationControls(state.el);
    clearAttr(state.el, 'data-ignore-morph');
    state.el.style.removeProperty('--goon-page-height');
    state.el.style.removeProperty('min-height');
    if (!state.el.hasAttribute('data-goon-paginate')) state.el.setAttribute('data-goon-paginate', '');
    paginationDebug('viewport-rebuild', { label: paginationLabel(state.el), reason });
    setupPagination(state.el);
  }

  function shouldViewportRebuildPagination(state) {
    if (!state || !state.el || !document.contains(state.el)) return false;
    const palmLayout = state.el.closest('[data-goon="palm-layout"]');
    return !!(palmLayout && isSidebarWrapped(palmLayout));
  }

  function schedulePaginationViewportRebuild(reason) {
    const nextHeight = paginationViewportHeight();
    const force = reason === 'orientation' || reason === 'init-active';
    if (!force && Math.abs(nextHeight - lastPaginationViewportHeight) < 1) return;
    const states = [...paginatedContainers].filter(shouldViewportRebuildPagination);
    if (states.length === 0) {
      lastPaginationViewportHeight = nextHeight;
      return;
    }
    lastPaginationViewportHeight = nextHeight;
    if (paginationViewportRaf) return;
    paginationViewportRaf = true;
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        paginationViewportRaf = false;
        states.forEach(state => rebuildPaginationState(state, reason));
      });
    });
  }

  function paginateTo(state, page) {
    if (page < 0) page = state.totalPages - 1;
    if (page >= state.totalPages) page = 0;
    state.currentPage = page;
    if (!state.el.hasAttribute('data-goon-paginate')) {
      state.el.setAttribute('data-goon-paginate', '');
    }

    const start = page * state.pageSize;
    const end = start + state.pageSize;

    state.items.forEach((item, i) => {
      item.style.display = (i >= start && i < end) ? '' : 'none';
    });

    // Guard: textContent write is a childList mutation that would re-trigger the
    // MutationObserver and cause an infinite loop when called from its callback.
    const pageLabel = (page + 1) + ' / ' + state.totalPages;
    if (state.pageInfo.textContent !== pageLabel) state.pageInfo.textContent = pageLabel;

    if (state.lsKey) {
      try { localStorage.setItem(state.lsKey, String(page)); } catch (_) {}
    }
    paginationDebug('paginate-to', {
      label: paginationLabel(state.el),
      page,
      pageSize: state.pageSize,
      totalPages: state.totalPages,
      start,
      end: Math.min(end, state.items.length),
      pageHeight: state.el.style.getPropertyValue('--goon-page-height'),
      inlineMinHeight: state.el.style.getPropertyValue('min-height'),
      hasPaginateAttr: state.el.hasAttribute('data-goon-paginate'),
      scrollHeight: state.el.scrollHeight,
    });
  }

  function paginateForNode(node) {
    for (const state of paginatedContainers) {
      const idx = state.items.indexOf(node);
      if (idx >= 0) {
        const targetPage = Math.floor(idx / state.pageSize);
        if (targetPage !== state.currentPage) paginateTo(state, targetPage);
        return;
      }
    }
    // Stale-ref fallback: items array may have been captured before a morph
    // replaced the nodes. Re-query live children to find the right page.
    for (const state of paginatedContainers) {
      if (!state.el.contains(node)) continue;
      const liveItems = Array.from(state.el.children).filter(c => !c.matches('cluster[data-goon="page-controls"]'));
      const directAncestor = liveItems.find(c => c === node || c.contains(node));
      if (!directAncestor) continue;
      state.items = liveItems; // heal stale refs
      const liveIdx = liveItems.indexOf(directAncestor);
      const targetPage = Math.floor(liveIdx / state.pageSize);
      if (targetPage !== state.currentPage) paginateTo(state, targetPage);
      return;
    }
  }

  // — Burn Live Strip Client-Side Animation —
  const burnStripState = {
    focusedRid: null, rids: new Map()
  };

  function burnRidState(rid, now = performance.now()) {
    if (!burnStripState.rids.has(rid)) {
      burnStripState.rids.set(rid, {
        startTime: now,
        startWall: Date.now(),
        completed: false,
        completedMs: null,
        lastEmitted: null,
        lastReceived: null,
        lastSeq: null,
        lastTime: null,
        reserveMax: 0,
        visualReserve: 0,
        ewmaBps: 0,
        trickleTimer: null,
      });
    }
    return burnStripState.rids.get(rid);
  }

  function burnPulse(el, className, ms) {
    if (!el) return;
    el.classList.remove(className);
    void el.offsetWidth;
    el.classList.add(className);
    window.setTimeout(() => el.classList.remove(className), ms);
  }

  function burnSetStyleVar(el, name, value) {
    if (!el) return;
    const next = String(value);
    if (el.style.getPropertyValue(name).trim() !== next) {
      el.style.setProperty(name, next);
    }
  }

  function burnSetWidthPct(el, pct) {
    if (!el) return;
    const next = Math.max(0, Math.min(100, pct)) + '%';
    if (el.style.width !== next) el.style.width = next;
  }

  function burnScrollStripIntoView(strip) {
    if (!strip || !document.contains(strip)) return;
    const rect = strip.getBoundingClientRect();
    const viewportHeight = window.innerHeight || document.documentElement.clientHeight;
    const pad = Math.max(12, Math.min(48, viewportHeight * 0.04));
    const pageY = window.scrollY || document.documentElement.scrollTop || 0;
    let targetY = pageY;
    if (rect.height + (pad * 2) >= viewportHeight) {
      targetY = pageY + rect.top - pad;
    } else if (rect.top < pad || rect.bottom > viewportHeight - pad) {
      targetY = pageY + rect.top - pad;
    }
    targetY = Math.max(0, targetY);
    if (Math.abs(targetY - pageY) > 1) {
      window.scrollTo({ top: targetY, left: 0, behavior: 'smooth' });
    }
  }

  function burnFormatDuration(ms) {
    const totalSec = Math.max(0, Math.round(ms / 1000));
    if (totalSec < 60) return totalSec + 's';
    const m = Math.floor(totalSec / 60);
    const s = totalSec % 60;
    if (m < 60) return s ? m + 'm ' + s + 's' : m + 'm';
    const h = Math.floor(m / 60);
    const mm = m % 60;
    return mm ? h + 'h ' + mm + 'm' : h + 'h';
  }

  function burnParseDaMs(da) {
    const match = String(da || '').match(/^~?(\d+)\.(\d+)\.(\d+)\.\.(\d+)\.(\d+)\.(\d+)/);
    if (!match) return 0;
    const [, y, mo, d, h, mi, s] = match.map(Number);
    return Date.UTC(y, mo - 1, d, h, mi, s);
  }

  function burnStartedWall(strip) {
    return burnParseDaMs(strip && strip.getAttribute('data-started')) || Date.now();
  }

  function burnUpdateElapsedClock(strip = document.getElementById('status-live')) {
    if (!strip || !strip.firstElementChild) return;
    const rid = strip.getAttribute('data-rid') || '';
    if (!rid) return;
    const slot = strip.querySelector('.burn-strip-elapsed');
    if (!slot) return;
    const ridState = burnRidState(rid);
    ridState.startWall = burnStartedWall(strip);
    const completed = strip.getAttribute('data-completed') === 'true';
    if (completed && ridState.completedMs == null) ridState.completedMs = Date.now() - ridState.startWall;
    const elapsedMs = ridState.completedMs == null ? Date.now() - ridState.startWall : ridState.completedMs;
    const text = (completed ? 'completed in ' : 'elapsed ') + burnFormatDuration(elapsedMs);
    if (slot.textContent !== text) slot.textContent = text;
  }

  function burnStripUpdate() {
    const strip = document.getElementById('status-live');
    if (!strip || !strip.firstElementChild) {
      burnStripState.focusedRid = null; burnStripState.rids.clear();
      return;
    }
    if (downloadPendingAnchor) clearDownloadPending();
    if (isPassModalOpen()) closePassModal();
    const rid = strip.getAttribute('data-rid') || '';
    const emitted = parseInt(strip.getAttribute('data-emitted') || '0', 10);
    const received = parseInt(strip.getAttribute('data-received') || '0', 10);
    const seq = parseInt(strip.getAttribute('data-seq') || '0', 10);
    const completed = strip.getAttribute('data-completed') === 'true';
    const now = performance.now();
    const startedWall = burnStartedWall(strip);
    const reserveBytes = Math.max(0, received - emitted);

    if (rid && burnStripState.focusedRid !== rid) {
      burnStripState.focusedRid = rid;
      setActive(strip);
      requestAnimationFrame(() => burnScrollStripIntoView(strip));
    }

    const ridState = burnRidState(rid, now);
    ridState.startWall = startedWall;
    if (completed && ridState.completedMs == null) ridState.completedMs = Date.now() - ridState.startWall;
    burnUpdateElapsedClock(strip);

    const firstSample = ridState.lastTime == null;
    const dBytes = firstSample ? 0 : emitted - ridState.lastEmitted;
    const dReceived = firstSample ? 0 : received - ridState.lastReceived;
    const dSeq = firstSample ? 0 : seq - ridState.lastSeq;

    if (firstSample) {
      ridState.lastEmitted = emitted;
      ridState.lastReceived = received;
      ridState.lastSeq = seq;
      ridState.lastTime = now;
      ridState.visualReserve = reserveBytes;
    } else {
      const dtMs = now - ridState.lastTime;
      if (dtMs > 0 && dBytes >= 0) {
        const instantBps = (dBytes * 1000) / dtMs;
        const alpha = dtMs / (1500 + dtMs);
        ridState.ewmaBps = ridState.ewmaBps * (1 - alpha) + instantBps * alpha;
      }
      ridState.lastEmitted = emitted;
      ridState.lastReceived = received;
      ridState.lastSeq = seq;
      ridState.lastTime = now;
      if (dReceived > 0) {
        ridState.visualReserve = Math.max(reserveBytes, dReceived);
      } else {
        ridState.visualReserve = Math.max(0, (ridState.visualReserve || 0) - Math.max(0, dBytes));
      }
      if (reserveBytes > ridState.visualReserve) ridState.visualReserve = reserveBytes;
    }

    const chev = strip.querySelector('.burn-chevrons');
    if (chev) {
      if (completed && ridState.trickleTimer) {
        window.clearTimeout(ridState.trickleTimer);
        ridState.trickleTimer = null;
      }
      const bpsKb = completed ? 0 : Math.max(0, Math.round(ridState.ewmaBps / 1024));
      const nextBps = String(bpsKb);
      burnSetStyleVar(chev, '--burn-bps', nextBps);
      if (!completed && dBytes > 0) {
        burnPulse(chev, 'burn-trickle-tick', 2200);
        if (ridState.trickleTimer) window.clearTimeout(ridState.trickleTimer);
        ridState.trickleTimer = window.setTimeout(() => {
          const live = document.getElementById('status-live');
          if (live && live.getAttribute('data-rid') === rid) {
            const liveChev = live.querySelector('.burn-chevrons');
            burnSetStyleVar(liveChev, '--burn-bps', '0');
          }
          ridState.trickleTimer = null;
        }, 1800);
      }
    }

    const relayBar = strip.querySelector('.burn-relay .burn-bar');
    if (relayBar) {
      const visualReserve = completed ? 0 : Math.max(0, ridState.visualReserve || reserveBytes);
      if (visualReserve > ridState.reserveMax) ridState.reserveMax = visualReserve;
      const reserveDenom = Math.max(1, ridState.reserveMax);
      const reservePct = completed ? 0 : Math.max(0, Math.min(100, Math.round((visualReserve * 100) / reserveDenom)));
      const nextReservePct = String(reservePct);
      burnSetStyleVar(relayBar, '--burn-bar-pct', nextReservePct);
      const relayFill = relayBar.querySelector('.burn-bar-fill');
      burnSetStyleVar(relayFill, '--burn-bar-pct', nextReservePct);
      burnSetWidthPct(relayFill, reservePct);
      relayBar.setAttribute('data-reserve-pct', nextReservePct);
      relayBar.setAttribute('data-reserve-bytes', String(visualReserve));
      const relay = strip.querySelector('.burn-relay');
      if (relay) {
        relay.classList.toggle('burn-reserve-empty', !completed && visualReserve === 0 && ridState.reserveMax > 0);
        relay.classList.toggle('burn-reserve-active', !completed && visualReserve > 0);
      }
    }

    if (!completed && (dSeq > 0 || dReceived > 0)) {
      const proxyDot = strip.querySelector('.burn-proxy .burn-entity-dot');
      burnPulse(proxyDot, 'burn-proxy-tick', 650);
      const ames = strip.querySelector('.burn-ames-chunks');
      burnPulse(ames, 'burn-ames-tick', 650);
    }

    if (completed && !ridState.completed) {
      if (ridState.completedMs == null) ridState.completedMs = Date.now() - ridState.startWall;
      burnUpdateElapsedClock(strip);
      ridState.completed = true;
    }
  }

  // — Observers & Init —

  // SSE morphs strip JS-owned attrs/classes (data-goon-active, .palm-active,
  // accordion-expanded, etc.) and occasionally detach activeNode when an
  // unkeyed wrapper is recreated. Order of operations per morph batch:
  //   1. restoreJSState: re-assert every JS-owned attr/class the morph stripped.
  //   2. Resolve a pending goon-nav-async submit's awaited subtree, if any.
  //   3. If activeNode detached, try document.getElementById(activeNode.id)
  //      before falling back to activateFirst (the "UI restart" fallback).
  const observer = new MutationObserver((mutations) => {
    if (!root) root = document.querySelector(ROOT_SEL);
    if (!root) return;

    statusLiveEl = document.getElementById('status-live');

    if (mutations.every(mutationIsPaginationOnly)) return;

    if (statusLiveEl && mutations.every(m => statusLiveEl === m.target || statusLiveEl.contains(m.target))) {
      restoreJSState();
      requestAnimationFrame(burnStripUpdate);
      return;
    }

    restoreJSState();
    // Re-assert item visibility in case Datastar morph wiped style.display.
    // data-ignore-morph is restored by restoreJSState above, but the items'
    // inline display that paginateTo set is not in jsState and can be reset.
    // Snapshot: setupPagination mutates paginatedContainers (filter+push),
    // so iterating the live array while calling it would corrupt the loop.
    for (const state of [...paginatedContainers]) {
      if (!state.controls.parentElement && state.el.getBoundingClientRect().height > 0) setupPagination(state.el);
      else paginateTo(state, state.currentPage);
    }
    // Pick up any new visible palm-lists that appeared since last init
    // (e.g. season episode list upgrading from placeholder via SSE morph).
    root.querySelectorAll('[data-goon="palm-list"]').forEach(el => {
      if (el.getBoundingClientRect().height > 0 && !paginatedContainers.some(s => s.el === el)) {
        if (!el.hasAttribute('data-goon-paginate')) el.setAttribute('data-goon-paginate', '');
        setupPagination(el);
      }
    });

    if (asyncPending && document.contains(asyncPending)) {
      const kids = getTraversableChildren(asyncPending);
      if (kids.length > 0) {
        document.body.classList.remove('goon-nav-waiting');
        document
          .querySelectorAll('.goon-nav-async.pulse:not(a[data-goon-native="download"])')
          .forEach(clearPendingPulse);
        setActive(kids[0]);
        asyncPending = null;
      }
      return;
    }

    if (!activeNode) return;

    if (document.contains(activeNode)) {
      if (!activeVisualNode || !document.contains(activeVisualNode)) setActiveVisual(activeNode);
      syncPalmVisuals(activeNode);
      return;
    }

    const reanchored = lastCursorPath && resolveCursorPath(lastCursorPath);
    if (reanchored) {
      setActive(reanchored);
      return;
    }

    if (activeNode.id) {
      const replacement = document.getElementById(activeNode.id);
      if (replacement) {
        setActive(replacement);
        return;
      }
    }

    if (tryRestoreCursor()) return;
    activateFirst();
  });

  const stripObserver = new MutationObserver((mutations) => {
    const jsOnly = mutations.every(m => (
      m.type === 'attributes'
      && (m.attributeName === 'class' || m.attributeName === 'style')
    ));
    if (!jsOnly) requestAnimationFrame(burnStripUpdate);
  });

  // — Mouse & Click Interaction Handlers (Restored) —

  function onClick(e) {
    if (!root) return;
    if (e.target.closest('[data-goon="page-controls"]')) return;
    if (e.target.closest('[data-goon="palm-back"]')) return;
    const node = e.target.closest(NODE_SEL);
    if (node && root.contains(node)) {
      setAttr(root, NAV_ATTR, 'active');
      setActive(node);
      const portalIn = node.getAttribute('data-goon-portal-in');
      const target = portalIn ? document.getElementById(portalIn) : null;
      if (target && target.getAttribute('data-goon') !== 'palm-detail') drillIn();
    }
  }

  function onFocusIn(e) {
    if (!root) return;
    if (root.contains(e.target)) {
      if (e.target.closest('[data-goon="page-controls"]')) return;
      if (e.target.closest('[data-goon="palm-back"]')) return;
      const navState = root.getAttribute(NAV_ATTR);
      const node = e.target.closest(NODE_SEL);
      if (node && root.contains(node)) {
        setAttr(root, NAV_ATTR, 'active');
        setActive(node);
      } else if (navState === 'dormant') {
        setAttr(root, NAV_ATTR, 'active');
      }
    }
  }

  function onClickOutside(e) {
    if (!root) return;
    if (!root.contains(e.target)) {
      const navState = root.getAttribute(NAV_ATTR);
      if (navState === 'active') deactivateNav();
    }
  }

  function onPalmBackClick(e) {
    if (!root) return;
    const palmBack = e.target.closest('[data-goon="palm-back"]');
    if (!palmBack || !root.contains(palmBack)) return;
    e.preventDefault();
    e.stopPropagation();
    setAttr(root, NAV_ATTR, 'active');
    handlePalmBack(palmBack);
  }

  function onAccordionClick(e) {
    const header = e.target.closest('[data-goon="accordion-header"]');
    if (!header) return;
    e.preventDefault();
    const expanded = header.getAttribute('data-goon-accordion-expanded') === 'true';
    toggleAccordion(header, !expanded);
  }

  // Mouse-only async click path. Keyboard drillIn() runs maybePalmStageSwap
  // for the user; mouse clicks bypass drillIn entirely (onClick early-returns
  // on button targets), so the palm-stage swap never fires. This listener
  // mirrors the keyboard path: pre-activate the destination pane and arm
  // asyncPending so the observer routes focus into the pane post-morph.
  // Does NOT call btn.click — the native button click handles the fetch.
  function onAsyncClick(e) {
    if (!root) return;
    const asyncEl = e.target.closest('.goon-nav-async');
    if (!asyncEl || !root.contains(asyncEl)) return;
    if (asyncPending) return;
    const triggerNode = asyncEl.closest('[data-goon-children]') || asyncEl;
    const preActivatedPane = maybePalmStageSwap(triggerNode);
    asyncPending = preActivatedPane
                || triggerNode.closest('[data-goon-portal-out]')
                || getParentNode(triggerNode);
    document.body.classList.add('goon-nav-waiting');
    if (asyncPending && document.contains(asyncPending)) {
      const kids = getTraversableChildren(asyncPending);
      if (kids.length > 0) {
        document.body.classList.remove('goon-nav-waiting');
        setActive(kids[0]);
        asyncPending = null;
      }
    }
  }

  function onDownloadClick(e) {
    const anchor = e.target.closest('a[data-goon="link"][data-goon-native="download"]');
    if (!anchor) return;
    if (!isBurnAuthenticated()) {
      e.preventDefault();
      e.stopPropagation();
      clearDownloadPending();
      openPassModal(anchor.getAttribute('href'));
      return;
    }
    clearDownloadPending();
    window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
    pulsePending(anchor, null);
    downloadPendingAnchor = anchor;
    downloadPendingHref = anchor.getAttribute('href') || '';
  }

  function onPendingClick(e) {
    const el = pulseTargetFromEvent(e);
    if (!el) return;
    pulsePending(el, el.classList.contains('goon-nav-async') ? 5000 : 30000);
  }

  function onPendingSubmit(e) {
    const form = e.target.closest('form');
    if (!form) return;
    const target = form.querySelector('button[type="submit"], [data-goon=\"action\"], [data-goon-interact=\"action\"]') || form;
    pulsePending(target, target.classList.contains('goon-nav-async') ? 5000 : null);
    if (form.getAttribute('action') === '/~/login') {
      document.body.classList.add('goon-auth-pending');
    }
  }

  function onPassModalClick(e) {
    const close = e.target.closest('[data-burn-pass-close]');
    if (!close) return;
    e.preventDefault();
    closePassModal();
  }

  function restoreAccordionState() {
    if (!root) return;
    const headers = root.querySelectorAll('[data-goon="accordion-header"]');
    let anyRestored = false;
    headers.forEach(header => {
      const section = header.closest('[data-goon="accordion-section"]');
      if (!section) return;
      const path = section.getAttribute('data-goon-path');
      if (!path) return;
      let stored = null;
      try { stored = localStorage.getItem(ACCORDION_LS_PREFIX + path); } catch (_) {}
      if (stored !== 'true') return;
      const content = section.querySelector('[data-goon="accordion-content"]');
      setAttr(header, 'data-goon-accordion-expanded', 'true');
      if (content) setAttr(content, 'data-goon-accordion-expanded', 'true');
      setAttr(section, 'data-goon-accordion-expanded', 'true');
      anyRestored = true;
    });
    // First visit: expand the first accordion-section so the page isn't blank.
    if (!anyRestored && headers.length > 0) {
      const first = headers[0];
      const section = first.closest('[data-goon="accordion-section"]');
      if (section) {
        const content = section.querySelector('[data-goon="accordion-content"]');
        setAttr(first, 'data-goon-accordion-expanded', 'true');
        if (content) setAttr(content, 'data-goon-accordion-expanded', 'true');
        setAttr(section, 'data-goon-accordion-expanded', 'true');
      }
    }
  }

  function tryRestoreCursor() {
    try {
      const raw = localStorage.getItem(CURSOR_LS_KEY);
      if (!raw) return false;
      const encoded = JSON.parse(raw);
      const node = resolveCursorPath(encoded);
      if (!node || !document.contains(node)) return false;
      const content = node.closest('[data-goon="accordion-content"]');
      if (content && content.getAttribute('data-goon-accordion-expanded') !== 'true') return false;
      if (root) setAttr(root, NAV_ATTR, 'active');
      setActive(node);
      return true;
    } catch (_) {
      return false;
    }
  }

  function init() {
    root = document.querySelector(ROOT_SEL);
    if (!root) return;
    if (!root.hasAttribute(NAV_ATTR)) setAttr(root, NAV_ATTR, 'dormant');

    statusLiveEl = document.getElementById('status-live');
    restoreAccordionState(); // must run before initPagination so expanded content has real heights
    initPagination();
    lastPaginationViewportHeight = paginationViewportHeight();
    if (!tryRestoreCursor()) activateFirst();
    schedulePaginationViewportRebuild('init-active');
    observer.observe(root, { childList: true, subtree: true });

    const stripEl = document.getElementById('status-live');
    if (stripEl) stripObserver.observe(stripEl, { childList: true, subtree: true, attributes: true });
    requestAnimationFrame(burnStripUpdate);
  }

  // — Event Registry —

  document.addEventListener('keydown', onKeyDown);
  document.addEventListener('click', onClick);
  document.addEventListener('focusin', onFocusIn);
  document.addEventListener('click', onClickOutside, true);
  document.addEventListener('click', onPalmBackClick);
  document.addEventListener('click', onAccordionClick);
  document.addEventListener('click', onAsyncClick);
  document.addEventListener('click', onDownloadClick, true);
  document.addEventListener('click', onPendingClick, true);
  document.addEventListener('submit', onPendingSubmit, true);
  document.addEventListener('click', onPassModalClick, true);
  window.addEventListener('resize', () => schedulePaginationViewportRebuild('window-resize'));
  window.addEventListener('orientationchange', () => schedulePaginationViewportRebuild('orientation'));
  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', () => schedulePaginationViewportRebuild('visual-viewport'));
  }
  window.setInterval(() => {
    const strip = document.getElementById('status-live');
    if (strip && strip.firstElementChild) burnUpdateElapsedClock(strip);
  }, 1000);

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
