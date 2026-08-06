import { LitElement, html, css } from '/hawk-init/feather/1/lit';
import { feather } from '/hawk-init/feather/1/style?lit';
import $ from 'https://cdn.jsdelivr.net/npm/jquery@3.7.1/+esm'

/* ---------- debug ---------- */

$.fn.log = function (msg) {
  if (msg) {
    console.log(msg, this);
  } else {
    console.log(this);
  }
  return this;
};

/* ---------- web component helpers ---------- */

$.fn.shadow = function (that) {
  return $(that.shadowRoot);
};

$.fn.host = function () {
  const first = this[0];
  if (!first) return this;
  const host = first.getRootNode().host;
  return $(host);
};

/* ---------- events ---------- */

$.fn.emit = function (name, detail) {
  if (!this[0]) return this;
  this[0].dispatchEvent(
    new CustomEvent(name, {
      detail,
      bubbles: true,
      cancelable: true,
      composed: true,
    })
  );
  return this;
};

$.fn.poke = function (name, detail) {
  if (!this[0]) return this;
  this[0].dispatchEvent(
    new CustomEvent(name, {
      detail,
      bubbles: false,
      cancelable: true,
      composed: true,
    })
  );
  return this;
};

class DaTa extends LitElement {

  static properties = {
    aura: {type: String, reflect: true},
    atom: {type: String, reflect: true},
    mark: {type: String, reflect: true},
    noun: {type: String, reflect: true},
  
    root: {type: String, reflect: true},

    // changes
    del: {type: Boolean, reflect: true},
    lop: {type: Boolean, reflect: true},
    new: {type: Boolean, reflect: true},
    
    // ui state
    pag: {type: Boolean, reflect: true},
    dir: {type: Boolean, reflect: true},
    sel: {type: Boolean, reflect: true},
    edt: {type: Boolean, reflect: true},
    _kids: {type: Boolean, state: true},
  };
  
  constructor() {
    super();
    this.root = '/'
  }

  /* getters */

  get path() {
    let raw = this.root.slice(1)
    let segs = !!raw ? raw.split('/') : []
    
    return !this.atom ? segs : [...segs, this.atom]
  }
  
  get top() {
    let deep = $(this).parents('da-ta').last()
    if (deep.length) return deep;
    if (this.parentNode.tagName !== 'DA-TA') return $(this);
  }

  get nextOxal() {
    return $(this).next('da-ta')
  }
  
  get nextVisible() {
    return $([
      ...$(this).filter(() => this.dir).children('da-ta').first().get(),
      ...$(this).next('da-ta').get(),
      ...$(this).parents('da-ta').nextAll('da-ta').first().get(),
    ]).first()
  }
  
  get prevOxal() {
    return $(this).prev('da-ta')
  }

  get prevVisible() {
    return $([
      ...$(this).prev('da-ta[dir]').find('*:visible').last().get(),
      ...$(this).prev().get(),
      ...$(this).parent('da-ta').get(),
    ]).first()
  }

  /* lifecycle */
  
  connectedCallback() {

    super.connectedCallback()

    this.classList.add('mono');
    this.classList.add('s0');
    this.tabIndex = 0;
    

    if (this.sel) {
      this.focus();
      this.center();
      $(this).poke('select')
    }

    /* listeners */

    $(this).on('select', function(e) {
      if (!!e.detail) {
        let m = this.qs(e.detail).get(0)
        m?.focus()
        m?.setSelectionRange(0, 999)
        return
      }
      this.focus()
      if (this.sel) {
        $(this).poke('toggle-pag')
      } else {
        this.sel = true;
        $('da-ta[sel]').removeAttr('sel');
        this.sel = true;
      }
    })
    $(this).on('edit-noun', function() {
      $(this).poke('open-pag').poke('select', '#noun')
    })
    $(this).on('edit-mark', function() {
      $(this).poke('open-pag').poke('select', '#mark')
    })
    $(this).on('edit-atom', function() {
      $(this).poke('open-pag').poke('select', '#atom')
    })
    $(this).on('edit-aura', function() {
      $(this).poke('open-pag').poke('select', '#aura')
    })
    $(this).on('null-aura', function() {
      this.aura = null;
    })
    $(this).on('null-iota', function() {
      this.aura = 'n'
      this.atom = '~'
    })
    $(this).on('now-iota', function() {
      this.aura = 'da'
      this.atom = formatUrbitDate(new Date())
    })
    $(this).on('open-pag', function() {
      this.pag = true;
    })
    
    $(this).on('select-next', function() {
      this.nextVisible?.poke('select').poke('center')
    })
    $(this).on('select-prev', function() {
      this.prevVisible?.poke('select').poke('center')
    })
    $(this).on('jump-next', function() {
      $(this).next('da-ta')?.poke('select').poke('center')
    })
    $(this).on('jump-prev', function() {
      $(this).prev('da-ta')?.poke('select').poke('center')
    })
    $(this).on('select-up', function() {
      $(this).parent('da-ta').poke('select').poke('center')
    })
    $(this).on('toggle-dir', function() {
      this.dir = !this.dir
      if ($(this).find('[sel]').length > 0) {
        $(this).poke('select');
      }
    })
    $(this).on('toggle-edt', function() {
      this.edt = !this.edt
      if (this.edt) {
        this.pag = true;
      }
    })
    $(this).on('toggle-pag', function() {
      this.pag = !this.pag
    })
    $(this).on('open-up', function() {
      let r = Math.floor(Math.random() * 999)
      let n = $(`<da-ta aura="ud" atom="${r}" root="/${this.path.slice(0, -1).join('/')}"></da-ta>`)
      $(this).before(n)
      let nex = $(this).prev()
      nex.prop('new', true)
      nex.poke('select')
      if (this.pag) {
        this.pag = false;
        nex.prop('pag', true)
      }
    })
    $(this).on('open-down', function() {
      let r = Math.floor(Math.random() * 999)
      let n = $(`<da-ta aura="ud" atom="${r}" root="/${this.path.slice(0, -1).join('/')}"></da-ta>`)
      $(this).after(n)
      let nex = $(this).next()
      nex.prop('new', true)
      nex.poke('select')
      if (this.pag) {
        this.pag = false;
        nex.prop('pag', true)
      }
    })
    $(this).on('del', function() {
      this.del = !this.del;
      this.lop = null
    })
    $(this).on('lop', function() {
      this.lop = !this.lop;
      this.del = null
    })
    $(this).on('center', function() {
      this.center();
    })
    $(this).on('insert', function() {
      let r = Math.floor(Math.random() * 999)
      let n = $(`<da-ta aura="ud" atom="${r}" root="/${this.path.slice(0, -1).join('/')}/${r}"></da-ta>`)
      $(this).attr('dir', "")
      $(this).prepend(n)
      let nex = $(this).children().first()
      nex.prop('new', true)
      nex.poke('select')
      if (this.pag) {
        this.pag = false;
        nex.prop('pag', true)
      }
    })
    $(this).on('apply', function() {
      $(this).closest('form').find('button[type=submit]').click();
    })
    $(this).on('keydown', function(e) {
      let el = this.qs(`[data-key='${e.key}']`).get(0)
      if (!el) return;
      let ev = el.getAttribute('data-event');
      let dt = el.getAttribute('data-detail');
      if (!!ev && !e.metaKey && !e.ctrlKey) {
        e.preventDefault();
        e.stopPropagation();
        $(this).poke(ev, dt)
      }
    })
  }

  updated() {
    let hasfoc = this.contains(document.activeElement);
    if (this.sel && !hasfoc) {
      this.focus();
    }
    if (this === this.top.get(0) && !$(this).find('[sel]').length && !this.sel) {
      this.sel = true
    }
  }

  /* mutation methods */

  center() {
    let h = this.offsetTop - 200;
    $(this).closest('.scroll-y').get(0)?.scrollTo({
      top: h,
      behavior: "smooth",
    });
  }

  /* data methods */

  qs(id) {
    return $(this.shadowRoot.querySelector(id));
  }
  qsa(id) {
    return $(this.shadowRoot.querySelectorAll(id));
  }
  

  /* handlers */
  
  handleSlotChange(e) {
    const childNodes = e.target.assignedElements(); 
    if (childNodes.length == 0) {
      this._kids = false;
    } else {
      this._kids = true;
    }
  }
  
  /* render */
  
  render() {
    return html`
      <div class="fr">
        ${this.dirToggle}
        <div class="grow">
          <div id="bar" class="fr af b0 bd0 f0 js ${this.sel && 'active'}">
            ${this.pagToggle}
          </div>
          <div id="pag" class="fc bd1 g1" ?hidden=${!this.pag}>
            ${this.editPage}
            ${this.staticPage}
          </div>
          <div id="dir" ?hidden=${!this.dir && this != this.top.get(0)} class="${this.lop ? 'o4' : ''}">
            <slot @slotchange=${this.handleSlotChange}></slot>
          </div>
          ${this.sel ? this.actions : ''}
        </div>
      </div>
    `;
  }
  
  /* interface elements */

  maybeEscapeText(e) {
    e.stopPropagation();
    if (e.key === 'Escape') {
      e.target.blur();
      this.focus();
    }
  }

  get preview() {
    if (!this.noun && !!this.mark) {
      return '!! need noun'
    }
    if (!this.noun && !this.mark) {
      return ''
    }
    if (!!this.noun && !this.mark) {
      return '%'+this.noun
    }
    if (this.mark === 'iota') {
      return this.noun
    }
    if (this.mark === 'pith') {
      return 'pith+'+this.noun
    }
    if (this.mark === 'code') {
      let l = this.noun.split('\n').length
      return `[code ${l}]`
    }
    if (['t', 'ta'].includes(this.mark)) {
      let lines = (this.noun||'').split('\n')
      let top = lines[0] || '[%t]'
      return top + ((lines.length > 1) ? '...' : '')
    }
    if (['ud', 'ux', 'uv', 'uw',
         'p', 'q', 'f', 'n',
         'da', 'dr',
        ].includes(this.mark)) {
      return html`
        <span class="o5 s-1">${this.mark}+</span><span>${this.noun}</span>
      `
    }
    return `[${this.mark}]`
  }

  get editPage() {
    return html`
      <div class="bd1 ${this.edt ? '' : 'hidden'}">
        <div class="frw">
          ${this.actionButton('del', 'del', 'd', this.del)}
          ${this.actionButton('lop', 'lop', 'D', this.lop)}
          ${this.actionButton('+ ↑', 'open-up', 'O')}
          ${this.actionButton('+ ↓', 'open-down', 'o')}
          ${this.actionButton('+ ↘', 'insert', 'i')}
          ${this.actionButton('n+~', 'null-iota', 'R')}
          ${this.actionButton('da+now', 'now-iota', 'T')}
          ${this.actionButton('@tom', 'null-aura', '@')}
          <div class="grow"></div>
        </div>
        <div class="frw">
          <label class="fc">
            <span class="p1 b1 o5 s-2 bd1 no-select">au[r]a</span>
            <input  id="aura"
              class="p2 bd1 b0"
              style="width: 60px;"
              data-key="r"
              data-event="select"
              data-detail="#aura"
              ?disabled=${this.lop || this.del}
              @input="${(e) => this.aura = e.target.value}"
              @keydown="${this.maybeEscapeText}"
              placeholder="aura"
              autocomplete="off"
              spellcheck="false"
              value="${this.aura || ''}"
            />
          </label>
          <label class="fc grow">
            <span class="p1 b1 o5 s-2 bd1 no-select">[a]tom</span>
            <input  id="atom"
              class="p2 bd1 b0 wf"
              style="min-width: 0;"
              data-key="a"
              data-event="select"
              data-detail="#atom"
              ?disabled=${this.lop || this.del}
              placeholder="atom"
              autocomplete="off"
              spellcheck="false"
              @input="${(e) => this.atom = e.target.value}"
              @keydown="${this.maybeEscapeText}"
              value="${this.atom || ''}"
            />
          </label>
          <label class="fc">
            <span class="p1 b1 o5 s-2 f3 bd1 no-select">[m]ark</span>
            <input  id="mark"
              class="p2 bd1 b0"
              style="width: 60px;"
              data-key="m"
              data-event="select"
              data-detail="#mark"
              ?disabled=${this.lop || this.del}
              placeholder="mark"
              autocomplete="off"
              spellcheck="false"
              @input="${(e) => this.mark = e.target.value}"
              @keydown="${this.maybeEscapeText}"
              value="${this.mark || ''}"
            />
          </label>
        </div>
        <label class="fc">
          <span class="p1 s-2 b1 o5 f3 bd1 no-select">[n]oun</span>
          <textarea  id="noun"
            class="p2 bd1 b0 pre mono"
            ?disabled=${this.lop || this.del}
            data-key="n"
            data-event="select"
            data-detail="#noun"
            placeholder="noun"
            autocomplete="off"
            spellcheck="false"
            rows="${(this.noun || "").split('\n').length}"
            @keydown="${this.maybeEscapeText}"
            @input="${(e) => {this.noun = e.target.value;e.target.rows=e.target.value.split('\n').length}}"
          >${this.noun || ''}</textarea>
        </label>
      </div>
    `
  }

  get staticPage() {
    return html`
      <div class="scroll-x scroll-y ${!this.edt ? '' : 'hidden'}">
        <div class="pre mono p2">${this.noun}</div>
      </div>
    `
  }

  get pagToggle() {
    return html`
      <button
        @click="${() => $(this).poke('select')}"
        class="no-outline p-1 tl grow ${this.lop || this.del ? 'o7' : ''}"
        >
        <div class="hanging-indent">
          <span class="bold ${this.lop ? 'f-1' : ''}">${this.printIota}</span>
          <span class="inline" style="width: 1px;"></span>
          <span class="${this.del ? 'f-1' : this.lop ? 'f-1' : 'o6'} ${this.pag ? 'hidden' : ''}">${this.preview}</span>
        </div>
      </button>
      <button
        data-event="toggle-edt"
        data-key="e"
        class="${(this.pag && this.sel) ? '' : 'hidden'} action block hover mono p-1 ${this.edt ? 'toggled':''}"
        @click="${() => $(this).poke('toggle-edt')}"
        >
        [e]dit
      </button>
    `
  }

  get dirToggle() {
    let circleColor =
      this.lop ? "var(--f-1)" :
      this.del ? "var(--f-2)" :
      !this._kids ? "var(--f4)" :
      "var(--f4)"
    let lineColor = this.lop ? "var(--f-1)" : "var(--b4)"
    if (this == this.top.get(0)) return;  // hide root dir toggle
    return html`
      <button
        @click="${() => $(this).poke('toggle-dir')}"
        style="width: 3ch; flex-shrink: 0;"
        class="fr af relative b0 hover no-outline ${!this._kids && !(this.del || this.lop)  ? 'o3' : ''}"
        >
        <div class="absolute br1 ${(this.dir && this._kids) ? '' : 'hidden'}"
          style="width: 2px; background: ${lineColor}; top: 0.7em; left: calc(1.5ch - 1px); bottom: 0.3em;"
        ></div>
        <div class="absolute br1"
          style="width: 6px; height: 6px; background: ${circleColor}; top: 0.7em; left: calc(1.5ch - 3px);"
        ></div>
      </button>
    `
  }

  get printIota() {
    if (this.aura == 'n') {
      return html`<span class="o4 bold">~</span>`
    }
    return html`
      <span class="o5 s-1">${this.aura ? this.aura+'/' : this.atom ? '' : '/'}</span><span class="o9">${this.atom}</span>
    `
  }

  get loped() {
    return html`
      <div class="f-1 bold p-1 bd1 bc-1 grow">lop'ed</div>
    `
  }
  get deled() {
    return html`
      <div class="f-2 bold p-1 bd1 bc-2 grow">del'ed</div>
    `
  }

  get actions() {
    return html`
      <div id="actions" class="wfc absolute z2"
        style="bottom: 25px; left: 20px; right: 20px;"
        >
        <div class="frw">
        ${this.actionButton('next', 'select-next', 'j')}
        ${this.actionButton('prev', 'select-prev', 'k')}
        ${this.actionButton('jump up', 'jump-next', 'J')}
        ${this.actionButton('jump dn', 'jump-prev', 'K')}
        ${this.actionButton('parent', 'select-up', 'u')}
        ${this.actionButton('show kids', 'toggle-dir', 'Tab')}
        ${this.actionButton('show page', 'toggle-pag', ' ')}
        ${this.actionButton('apply', 'apply', 's')}
        </div>
      </div>
    `;
  }

  actionButton(label, event, key, tog) {
    let hint = !this.sel ? '' :
      html`
        <span class="o5">${key==' ' ? 'Spc' : key}</span>
      `
    return html`
      <button
        data-event="${event}"
        data-key="${key}"
        class="action bd1 block hover mono b1 p-1 ${tog ? 'toggled':''}"
        @click="${() => $(this).poke(event)}"
      >${label} ${hint}</button>
    `;
  }


  /* styling */
  
  static styles = [feather,
    css`
      #aura:focus,
      #atom:focus,
      #noun:focus,
      #mark:focus {
        background: var(--b1);
      }
      .hanging-indent {
        text-indent : -2ch ;
        margin-left :  2ch ;
      }
    `
  ];
}

if (!customElements.get('da-ta')) {
  customElements.define('da-ta', DaTa)
}

function formatUrbitDate(now) {
    
    const year = now.getUTCFullYear();
    const month = now.getUTCMonth() + 1;
    const day = now.getUTCDate();
    const hours = now.getUTCHours();
    const minutes = now.getUTCMinutes();
    const seconds = now.getUTCSeconds();
    
    // Format with leading zeros where needed
    const pad = (num) => num.toString().padStart(2, '0');
    
    const urbitDate = `~${year}.${month}.${day}..${pad(hours)}.${pad(minutes)}.${pad(seconds)}`;
    return urbitDate;
}