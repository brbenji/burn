// <feather-slide-panels>
//
// Horizontal split layout with draggable dividers between child panels.
// On narrow viewports (<=700px) collapses to a tabbed view, using each
// child's `tab-name` attribute as the tab label.
//
import { LitElement, html, css, nothing } from '/hawk-init/feather/1/lit';
import { feather } from '/hawk-init/feather/1/style?lit';

class FeatherSlidePanels extends LitElement {

  static properties = {
    tab: { type: String, reflect: true },
    _panels: { type: Array, state: true },
    _ratios: { type: Array, state: true },
    _dragging: { state: true },
    _mobile: { type: Boolean, state: true },
  };

  constructor() {
    super();
    this.tab = null;
    this._panels = [];
    this._ratios = [];
    this._dragging = null;
    this._observer = null;
    this._mobile = false;
    this._mql = null;
    this._mqlHandler = null;
  }

  connectedCallback() {
    super.connectedCallback();
    this._observer = new MutationObserver(() => this._distribute());
    this._observer.observe(this, {
      childList: true,
      attributes: true,
      attributeFilter: ['tab-name', 'hidden', 'style', 'class'],
      subtree: true,
    });
    this._distribute();
    this._mql = window.matchMedia('(max-width: 700px)');
    this._mqlHandler = (e) => { this._mobile = e.matches; };
    this._mobile = this._mql.matches;
    this._mql.addEventListener('change', this._mqlHandler);
  }

  disconnectedCallback() {
    super.disconnectedCallback();
    if (this._observer) {
      this._observer.disconnect();
      this._observer = null;
    }
    if (this._mql && this._mqlHandler) {
      this._mql.removeEventListener('change', this._mqlHandler);
      this._mql = null;
      this._mqlHandler = null;
    }
  }

  _distribute() {
    const children = [...this.children].filter(n => {
      if (n.nodeType !== 1) return false;
      if (n.hidden) return false;
      const cs = getComputedStyle(n);
      if (cs.display === 'none' || cs.visibility === 'hidden') return false;
      return true;
    });
    const panels = children.map((el, i) => {
      const slot = `p${i}`;
      if (el.slot !== slot) el.slot = slot;
      return { slot, tabName: el.getAttribute('tab-name') || `${i + 1}` };
    });
    this._panels = panels;
    const n = panels.length;
    if (n > 1) {
      const old = this._ratios;
      if (old.length !== n - 1) {
        const fresh = [];
        for (let i = 0; i < n - 1; i++) fresh.push((i + 1) / n);
        this._ratios = fresh;
      }
    } else {
      this._ratios = [];
    }
    if (this.tab == null && panels.length > 0) {
      this.tab = panels[0].tabName;
    }
  }

  _panelFlex(i) {
    const n = this._panels.length;
    if (n <= 1) return '1 1 0%';
    const lo = i === 0 ? 0 : this._ratios[i - 1];
    const hi = i === n - 1 ? 1 : this._ratios[i];
    return `${hi - lo} 1 0%`;
  }

  _startDrag(i, e) {
    e.preventDefault();
    this._dragging = i;
    if (e.pointerId != null) e.currentTarget.setPointerCapture(e.pointerId);
    this.classList.add('dragging');
  }

  _onDrag(e) {
    if (this._dragging == null) return;
    const container = this.renderRoot.querySelector('.container');
    if (!container) return;
    const rect = container.getBoundingClientRect();
    const pos = (e.clientX - rect.left) / rect.width;
    const i = this._dragging;
    const n = this._panels.length;
    const min = i === 0 ? 0.05 : this._ratios[i - 1] + 0.05;
    const max = i === n - 2 ? 0.95 : this._ratios[i + 1] - 0.05;
    const clamped = Math.max(min, Math.min(max, pos));
    const next = [...this._ratios];
    next[i] = clamped;
    this._ratios = next;
  }

  _stopDrag(e) {
    if (this._dragging == null) return;
    this._dragging = null;
    if (e.pointerId != null) e.currentTarget.releasePointerCapture(e.pointerId);
    this.classList.remove('dragging');
  }

  _setTab(tabName) {
    this.tab = tabName;
  }

  static styles = [feather, css`
    :host {
      display: flex;
      width: 100%;
      height: 100%;
      overflow: hidden;
    }
    .container {
      display: flex;
      width: 100%;
      height: 100%;
      overflow: hidden;
    }
    .mobile-container {
      display: flex;
      flex-direction: column;
      width: 100%;
      height: 100%;
      overflow: hidden;
    }
    .panel {
      overflow: hidden;
      min-width: 0;
      min-height: 0;
      width: 100%;
      height: 100%;
    }
    .panel.solo {
      flex: 1 1 0%;
    }
    .panel.mobile-hidden {
      display: none;
    }
    .panel.mobile-active {
      flex: 1 1 0%;
    }
    .divider {
      flex: 0 0 auto;
      width: 10px;
      cursor: col-resize;
      background: var(--f5);
      user-select: none;
      -webkit-user-select: none;
      touch-action: none;
      position: relative;
      z-index: 1;
    }
    .divider:hover, .divider.active {
      background: var(--f3);
    }
    :host(.dragging) .panel {
      pointer-events: none;
      user-select: none;
      -webkit-user-select: none;
    }
    .tabs {
      display: flex;
      flex: 0 0 auto;
      border-bottom: 1px solid var(--f5);
    }
    .tab {
      flex: 1 1 0%;
      padding: 8px 0;
      text-align: center;
      font-size: 13px;
      cursor: pointer;
      color: var(--f3);
      background: var(--b1);
      border: none;
      transition: color 0.15s ease, background 0.15s ease;
    }
    .tab.active {
      color: var(--f1);
      background: var(--b0);
    }
  `];

  render() {
    const n = this._panels.length;
    const solo = n <= 1;
    const mob = this._mobile && n >= 2;

    if (mob) {
      const activeTab = this.tab || (this._panels[0]?.tabName);
      return html`
        <slot hidden @slotchange=${this._distribute}></slot>
        <div class="mobile-container">
          <div class="tabs">
            ${this._panels.map(p => html`
              <button
                class="tab ${p.tabName === activeTab ? 'active' : ''}"
                @click=${() => this._setTab(p.tabName)}
              >${p.tabName}</button>
            `)}
          </div>
          ${this._panels.map(p => html`
            <div class="panel mobile-active" style="${p.tabName === activeTab ? '' : 'display:none'}">
              <slot name="${p.slot}" @slotchange=${this._distribute}></slot>
            </div>
          `)}
        </div>
      `;
    }

    return html`
      <slot hidden @slotchange=${this._distribute}></slot>
      <div class="container">
        ${this._panels.map((p, i) => html`
          ${i > 0 ? html`
            <div
              class="divider ${this._dragging === i - 1 ? 'active' : ''}"
              @pointerdown=${(e) => this._startDrag(i - 1, e)}
              @pointermove=${this._onDrag}
              @pointerup=${this._stopDrag}
              @pointercancel=${this._stopDrag}
            ></div>
          ` : nothing}
          <div class="panel ${solo ? 'solo' : ''}" style="flex:${this._panelFlex(i)}">
            <slot name="${p.slot}" @slotchange=${this._distribute}></slot>
          </div>
        `)}
      </div>
    `;
  }
}

customElements.define('feather-slide-panels', FeatherSlidePanels)
