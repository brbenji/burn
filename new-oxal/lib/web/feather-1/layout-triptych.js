// feather-layout-triptych
//
// Three-pane responsive layout (bush / leaf / view) with toggleable panels.
// Each pane collapses to a vertical opener button when closed; on narrow
// viewports the panes stack vertically. The view pane embeds an iframe
// driven by the `lens` property.

import { feather } from '/hawk-init/feather/1/style?&lit';
import { LitElement, html, css } from '/hawk-init/feather/1/lit';

class FeatherLayoutTriptych extends LitElement {

  static properties = {
    bush: { type: Boolean, reflect: true },
    leaf: { type: Boolean, reflect: true },
    view: { type: Boolean, reflect: true },
    
    base: { type: String, reflect: true },
    stem: { type: String, reflect: true },
    lens: { type: String, reflect: true },

    listing: { type: Object },
  };

  constructor() {
    super();
    this.bush = false
    this.view = false
    this.leaf = false

    this.stem = ''
    this.lens = ''
    // this.base = ''
    
    this.listing = ''
  }

  connectedCallback() {
    super.connectedCallback()
    // this.saveLocalState()
  }

  firstUpdated () {
    this.classList.remove('hidden')
  }

  emit(prop) {
    this.dispatchEvent(new CustomEvent(`change-${prop}`, {
      detail: this[prop]
    }))
  }

  updated(ch) {
    ['bush', 'leaf', 'view'].forEach(p => {
      if (ch.has(p)) {
        this.emit(p)
      }
    })
  }

  static styles = [feather,
    css`
      :host {
        display: flex;
        flex-grow: 1;
        font-family: monospace;
        overflow: hidden;
      }
      
      #view {
        grid-area: view;
      }
      #leaf {
        grid-area: leaf;
      }
      #bush {
        grid-area: bush;
      }
      #bush, #leaf, #view {
        display: flex;
        flex-direction: column;
        overflow: hidden;
      }
      
      section {
        background: var(--b0);
        width: 100%;
        height: 100%;
        overflow: hidden;
        display: grid;
        gap: 8px;
        padding: 8px;
      }
      section header {
        display: flex;
        grid-area: head;
      }


      @media(min-width: 700px) {
        .opener {
          writing-mode: vertical-rl;
          text-orientation: mixed;
        }
        
        section:not(.bush):not(.view):not(.leaf),
        section.bush.view.leaf {
          & {
            grid-template:
              "bush leaf view" 1fr / 1fr 1fr 1fr;
          }
          .opener {
            writing-mode: horizontal-tb;
          }
        }
        
        section.bush.view:not(.leaf) {
          & {
            grid-template:
              "bush leaf view" 1fr / 1fr auto 1fr;
          }
        }
        
        section.view:not(.bush):not(.leaf) {
          & {
            grid-template:
              "bush leaf view" 1fr / auto auto 1fr;
          }
        }
        
        section.bush:not(.view):not(.leaf) {
          & {
            grid-template:
              "bush leaf view" 1fr / 1fr auto auto;
          }
        }
        
        section.bush.leaf:not(.view) {
          & {
            grid-template:
              "bush leaf view" 1fr / 1fr 1fr auto;
          }
        }
        
        section.view.leaf:not(.bush) {
          & {
            grid-template:
              "bush leaf view" 1fr / auto 1fr 1fr;
          }
        }
        
        section.leaf:not(.bush):not(.view) {
          & {
            grid-template:
              "bush leaf view" 1fr / auto 1fr auto;
          }
        }
      }
      
      @media(max-width: 700px) {
        section:not(.bush):not(.view):not(.leaf),
        section.bush.view.leaf {
          & {
            grid-template:
              "bush" 1fr
              "leaf" 1fr
              "view" 1fr / 1fr;
          }
        }
        section.bush.view:not(.leaf) {
          & {
            grid-template:
              "bush" 1fr
              "leaf" auto
              "view" 1fr / 1fr;
          }
        }
        
        section.view:not(.bush):not(.leaf) {
          & {
            grid-template:
              "bush" auto
              "leaf" auto
              "view" 1fr / 1fr;
          }
        }
        
        section.bush:not(.view):not(.leaf) {
          & {
            grid-template:
              "bush" 1fr
              "leaf" auto
              "view" auto / 1fr;
          }
        }
        
        section.bush.leaf:not(.view) {
          & {
            grid-template:
              "bush" 1fr
              "leaf" 1fr
              "view" auto / 1fr;
          }
        }
        
        section.view.leaf:not(.bush) {
          & {
            grid-template:
              "bush" auto
              "leaf" 1fr
              "view" 1fr / 1fr;
          }
        }
        
        section.leaf:not(.bush):not(.view) {
          & {
            grid-template:
              "bush" auto
              "leaf" 1fr
              "view" auto / 1fr;
          }
        }
      }

      
      .mode-btn {
        background: var(--b0);
      }
      .bush #bush-btn {
        background: var(--b2);
        color: var(--f1);
      }
      .view #view-btn {
        background: var(--b2);
        color: var(--f1);
      }
      .leaf #leaf-btn {
        background: var(--b2);
        color: var(--f1);
      }
    `,
  ]

  clickMode(m) {
    if (this[m]) {
      this.bush = false;
      this.view = false;
      this.leaf = false;
      this[m] = true
    } else {
      this[m] = true
    }
  }

  setLens(z) {
    this.lens = z;
    this.emit('lens')
  }
  submitLens(e) {
    e.preventDefault();
    let data = new FormData(e.target)
    this.lens = data.get('lens') || '';
    this.emit('lens')
  }

  reloadView() {
    let frame = this.shadowRoot.getElementById('view-frame')
    frame?.contentWindow?.location?.reload();
  }

  get makeIframe() {
    if (!this.lens) {
      return html`
        <div class="fc ac jc o5 bd1 bdt0 bbrr2 bblr2 grow">none</div>
      `
    }
    return html`
      <iframe id="view-frame" class="grow bd0" src="/-${this.print(this.lens)}"></iframe>
    `
  }

  print(pith) {
    if (pith == '/') {
      return ""
    }
    return pith
  }

  printBush(bush, pith = '') {
    let iota = bush?.iota ? ('/' + bush.iota) : ''
    pith = pith + iota
    
    let rec = (typeof bush?.kids == "string") ?
      html`<div class="underlined">more</div>`
      :
      bush?.kids?.map(k => this.printBush(k, pith))

    if (!!this.base && !pith?.startsWith(this.base)) {
      return rec
    }
    
    let nod = html`
      <div class="fr g2">
        <button class="f4">+</button>
        <a class="b0 hover grow frw g2 af pl1 pr1"
           href="/==${pith}"
           @click="${() => this.leaf = true}"
          >
          <span>${bush?.iota || '/'}</span>
          <span class="f4">${bush?.mark}</span>
        </a>
      </div>
    `
    let kid = html`
      <div class="pl4">
        ${rec}
      </div>
    `
    return html`
      <div>
        ${nod}
        ${kid}
      </div>
    `
  }

  opener(id, were) {
    return html`
      <button
        id="${id}"
        class="p-2 fc ac jc b2 f4 br2 bd1 hover nh5 nw5 opener"
        @click="${() => this[id] = true }"
      >
        ${were}
      </button>
    `
  }
  pannel(id, top, bod) {
    return html`
      <div id="${id}" class="fc scroll-none grow">
        <div class="fr bd1 btrr2 btlr2 scroll-none shrink-0">
          ${top}
        </div>
        <div class="grow bd1 bdt0 bbrr2 bblr2 scroll-none fc">
          ${bod}
        </div>
      </div>
    `
  }
  
  render () {
    return html`
      <section
        class="${this.bush ? 'bush' : ''} ${this.leaf ? 'leaf' : ''} ${this.view ? 'view' : ''}"
        >
        ${this.bush ? '' : this.opener('bush', this.base)}
        ${!this.bush ? '' : this.pannel('bush', html`
          <button
            class="p-1 b2 hover btrr2 btlr2 grow"
            @click="${() => this.bush = !this.bush}"
            ><span class="o3">-</span></button>
        `, html`
          <div class="grow fc scroll-y p2">
            <slot name="bush"></slot>
          </div>
        `)}
        
        ${this.leaf ? '' : this.opener('leaf', this.stem)}
        ${!this.leaf ? '' : this.pannel('leaf', html`
          <button
            class="p-1 b2 hover grow btlr2 btrr2"
            @click="${() => this.leaf = !this.leaf}"
            ><span class="o3">-</span></button>
        `, html`
          <slot name="leaf"></slot>
        `)}
        
        ${this.view ? '' : this.opener('view', this.lens)}
        ${!this.view ? '' : this.pannel('view', html`
          <button
            class="p-1 b2 hover btlr2"
            @click="${() => this.setLens(window.location.pathname.slice(3)) }"
            ><span class="o3">|</span></button>
          <form class="fr grow"
            @submit="${this.submitLens}"
            >
            <input
              name="lens"
              class="p-1 grow b1 w0"
              autocomplete="off"
              spellcheck="false"
              placeholder="/stem"
              .value="${this.lens}"
            />
          </form>
          <a
            href="/-${this.print(this.lens)}"
            class="p-1 b2 hover ${!this.lens?.length ? 'hidden' : ''}"
            target="_blank"
            >o</a>
          <button
            type="button"
            class="p-1 b2 hover ${!this.lens?.length ? 'hidden' : ''}"
            @click="${() => { this.reloadView() }}"
            >r</button>
          <button
            type="button"
            class="p-1 b2 hover ${!this.lens?.length ? 'hidden' : ''}"
            @click="${() => { this.setLens(''); this.view = false; }}"
            >x</button>
          <button
            class="p-1 b2 hover btrr2"
            @click="${() => this.view = !this.view}"
            ><span class="o3">-</span></button>
        `,
        this.makeIframe
        )}
      </section>
    `
  }
}

customElements.define('feather-layout-triptych', FeatherLayoutTriptych)