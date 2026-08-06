import { LitElement, html, css } from '/hawk-init/feather/1/lit';
class FeatherIframe extends LitElement {
  static properties = {
    src: { type: String, reflect: true },
  };

  constructor() {
    super();
    this._suppressIframeSrcUpdate = false;
    this._lastIframeUrl = null;
    this._onIframeLoad = this._onIframeLoad.bind(this);
    this._skipInitialLoadEvent = true;
  }

  get iframe() {
    return this.renderRoot?.querySelector('iframe') ?? null;
  }

  firstUpdated() {
    const iframe = this.iframe;
    if (!iframe) return;
    iframe.addEventListener('load', this._onIframeLoad);
    if (this.src) {
      try {
        iframe.src = this.src;
        this._lastIframeUrl = this.src;
      } catch (_) {}
    } else {
      this._lastIframeUrl = iframe.src || null;
    }
  }

  disconnectedCallback() {
    super.disconnectedCallback();
    const iframe = this.iframe;
    if (iframe) iframe.removeEventListener('load', this._onIframeLoad);
  }

  _onIframeLoad() {
    const iframe = this.iframe;
    if (!iframe) return;

    let current = null;
    try {
      current = iframe.contentWindow?.location?.href || iframe.src || null;
    } catch (_) {
      current = iframe.src || null;
    }

    const prev = this._lastIframeUrl;

    // Skip emitting on initial mount; just sync state.
    if (this._skipInitialLoadEvent) {
      this._skipInitialLoadEvent = false;
      this._lastIframeUrl = current;
      if (current && this.src !== current) {
        this._suppressIframeSrcUpdate = true;
        this.src = current;
      }
      return;
    }

    if (current && current !== prev) {
      this._lastIframeUrl = current;
      if (this.src !== current) {
        this._suppressIframeSrcUpdate = true; // internal nav; don't write back to iframe.src
        this.src = current;
      }
      this.emit('iframe-url-changed', {
        pathname: this._pathnameFrom(current),
        previousPathname: this._pathnameFrom(prev),
      });
    }
  }

  updated(changed) {
    if (changed.has('src')) {
      const iframe = this.iframe;
      if (!iframe) return;

      if (this._suppressIframeSrcUpdate) {
        this._suppressIframeSrcUpdate = false;
        return; // internal navigation already applied by the iframe
      }

      const newSrc = this.src;
      if (!newSrc) return; // never blank the iframe

      if (iframe.src !== newSrc) {
        try {
          iframe.src = newSrc;
          this._lastIframeUrl = newSrc;
        } catch (_) {}
      }
    }
  }

  emit(vent, tail) {
    this.dispatchEvent(new CustomEvent(vent, { detail: tail }));
  }

  // Extract a safe pathname from a URL-like value.
  _pathnameFrom(urlLike) {
    try {
      if (!urlLike) return null;
      const u = new URL(String(urlLike), window.location.href);
      return u.pathname || '/';
    } catch (_) {
      try {
        const a = document.createElement('a');
        a.href = String(urlLike);
        return a.pathname || '/';
      } catch (_) {
        return null;
      }
    }
  }

  // Force a refresh of the current iframe content without triggering a double-load.
  refresh() {
    const iframe = this.iframe;
    if (!iframe) return;
    try {
      const win = iframe.contentWindow;
      if (win && win.location) {
        try {
          win.location.reload();
        } catch (_) {
          iframe.src = iframe.src; // cross-origin fallback
        }
      } else {
        iframe.src = iframe.src;
      }
      // Emit only pathname on refresh
      this.emit('iframe-refreshed', { pathname: this._pathnameFrom(iframe.src) });
    } catch (_) {}
  }

  static styles = [
    css`
      :host {
        display: flex;
        flex-direction: column;
        flex-grow: 1;
      }
      iframe {
        border: none;
        flex-grow: 1;
      }
    `,
  ];

  render() {
    // No src binding to avoid Lit-triggered reloads.
    return html`<iframe></iframe>`;
  }
}

customElements.define('feather-iframe', FeatherIframe)