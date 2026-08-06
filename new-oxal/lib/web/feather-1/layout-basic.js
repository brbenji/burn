import { LitElement, html, css } from '/hawk-init/feather/1/lit';
import { feather } from '/hawk-init/feather/1/style?lit'

// todo:
//  allow multiple sidebars, each with a cooresponding header toggle button

class FeatherLayoutBasic extends LitElement {

  static properties = {
    // "main"    : only main
    // non-""    : both (priority main)
    // ""        : both (priority nav)
    mode: { type: String, reflect: true },
    
    openLabel: { type: String, reflect: true, attribute: "open-label"},
    closeLabel: { type: String, reflect: true, attribute: "close-label" },
  };

  constructor() {
    super();
  }

  connectedCallback() {
    super.connectedCallback()
  }

  firstUpdated () {
  }

  emit(vent, tail) {
    this.dispatchEvent(new CustomEvent(vent, {
      detail: tail
    }))
  }

  static styles = [feather,
    css`
      :host {
        display: flex;
        flex-direction: column;
        height: 100%;
        width: 100%;
        flex-grow: 1;
        overflow: hidden;
      }
      :host(:focus) {
        outline: none;
        box-shadow: unset !important;
      }
      .side {
        width: 100%;
      }
      
      /*  rules for mobile */
      
      @media(max-width: 620px) {
        :host(:not([mode=''])) .side {
          display: none;
        }
        
        #desktop-btn {
          display: none;
        }
        #mobile-btn {
          display: flex;
          width: fit-content;
        }
        /*
        :host([mode='']) header {
          display: none;
        }
        :host([mode='']) #mobile-btn {
          width: 100%;
          border: 0;
        }
        :host([mode='main']) #mobile-btn {
          width: fit-content;
        }
        */
      }
      
      /*  rules for desktop */
      
      @media(min-width: 620px) {
        .side {
          max-width: 330px;
          border-right: 1px solid var(--f8);
        }
        :host([mode='main']) .side {
          display: none;
        }
        #mobile-btn {
          display: none;
        }
        #desktop-btn {
          display: flex;
        }
        :host([mode]) #desktop-btn {
          width: 330px;
        }
        :host([mode='']) #desktop-btn {
          width: 330px;
        }
        :host([mode='main']) #desktop-btn {
          width: fit-content;
        }
      }
    `,
  ]

  get mobileActive() {
    if (this.mode === '') {
      return true
    } else if (this.mode === 'main') {
      return false
    } else {
      return false
    }
  }
  
  get desktopActive() {
    if (this.mode === '') {
      return true
    } else if (this.mode === 'main') {
      return false
    } else {
      return true
    }
  }

  get oLabel() { return this.openLabel || "=" }
  get cLabel() { return this.closeLabel || "x" }

  get mobileLabel() {
    return this.mobileActive ? this.cLabel : this.oLabel;
  }
  
  get desktopLabel() {
    return this.desktopActive ? this.cLabel : this.oLabel;
  }
  
  mobileToggle() {
    if (this.mode === 'main') {
      this.mode = ''
    } else if (this.mode == '' || this.mode == null) {
      this.mode = 'main'
    } else {
      this.mode = ''
    }
  }

  desktopToggle() {
    if (this.mode === 'main') {
      this.mode = ''
    } else if (this.mode == '' || this.mode == null) {
      this.mode = 'main'
    } else {
      this.mode = 'main'
    }
  }

  render () {
    return html`
      <div class="h7 fr bdb1 scroll-none shrink-0 b1">
        <button
          id="mobile-btn"
          class="pl4 pr4 fc ac jc b1 hover bdr1 mono ${this.mobileActive ? 'active' : ''}"
          @click="${() => { this.mobileToggle(); this.emit('toggle', this.mode); }}"
          >
          ${this.mobileLabel}
        </button>
        <button
          id="desktop-btn"
          class="pl4 pr4 fc ac jc b1 hover bdr1 mono ${this.desktopActive ? 'active' : ''}"
          @click="${() => { this.desktopToggle(); this.emit('toggle', this.mode); }}"
          >
          ${this.desktopLabel}
        </button>
        <header class="grow fr ac jc">
          <slot name="header"></slot>
        </div>
      </div>
      <div class="grow hf fr af scroll-none">
        <div class="side shrink-0 scroll-none wf hf fc">
          <slot name="side"></slot>
        </div>
        <main class="grow hf wf scroll-none fc">
          <slot></slot>
        </main>
      </div>
    `
  }
}

customElements.define('feather-layout-basic', FeatherLayoutBasic)