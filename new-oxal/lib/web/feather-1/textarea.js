import {LitElement, html, css} from '/hawk-init/feather/1/lit';
import { feather } from '/hawk-init/feather/1/style?lit';

class FeatherTextarea extends LitElement {
  static formAssociated = true;
  static shadowRootOptions = { ...LitElement.shadowRootOptions, delegatesFocus: true };

  static properties = {
    value: { type: String, state: true },
    name: { type: String, reflect: true },
    placeholder: { type: String, reflect: true },
    disabled: { type: Boolean, reflect: true },
    required: { type: Boolean, reflect: true },
    maxlength: { type: Number, reflect: true },
    autofocus: { type: Boolean, reflect: true },
    rows: { type: Number, reflect: true },
  };

  constructor() {
    super();
    this._internals = this.attachInternals();
    this._value = '';
    this._defaultValue = '';
    this.rows = 1;
    // Watchers used to defer resize until visible
    this._visibilityRO = null;
    this._visibilityWatching = false;
  }

  // Keep a stable ref to the inner textarea
  get _textarea() {
    return this.renderRoot?.querySelector('textarea') || null;
  }

  get value() {
    return this._value;
  }
  set value(val) {
    const old = this._value;
    val = (val ?? '').toString();
    if (old === val) return;
    this._value = val;

    // update the value of the textarea
    if (this._textarea && this._textarea.value !== val) {
      this._textarea.value = val;
    }

    // update height to be as small as possible without scrolling
    this._autoResize();

    // update the form data
    this._internals?.setFormValue(val);

    // record default value the first time value is set (for form reset)
    if (this._defaultValue === '') this._defaultValue = val;

    // Ensure validity reflects required/maxlength after value changes
    this._syncValidity();

    this.requestUpdate('value', old);
  }

  // Input/change handlers keep value in sync and re-dispatch events from the host
  _onInput(e) {
    const t = e.target;
    this.value = t.value;
    this.dispatchEvent(new Event('input', { bubbles: true, composed: true }));
  }
  _onChange(e) {
    const t = e.target;
    this.value = t.value;
    this.dispatchEvent(new Event('change', { bubbles: true, composed: true }));
  }

  // Auto-resize to content height
  _autoResize() {
    const el = this._textarea;
    if (!el) return;

    // If not laid out (e.g., ancestor display:none), defer until visible
    if (!this._isLaidOut()) {
      this._setupVisibilityWatchers();
      return;
    }

    el.style.height = 'auto';
    el.style.overflowY = 'hidden';
    el.style.height = `${Math.max(20, el.scrollHeight || 0)}px`;
  }

  // Keep validity on the ElementInternals in sync with the inner textarea
  _syncValidity() {
    const el = this._textarea;
    const val = this.value ?? '';
    const isTooLong = typeof this.maxlength === 'number' && this.maxlength > 0 && val.length > this.maxlength;
    const isRequiredMissing = !!this.required && val.trim() === '';

    if (!this._internals) return;

    if (isTooLong) {
      this._internals.setValidity({ tooLong: true }, `Exceeds maximum length of ${this.maxlength}`, el || undefined);
      return;
    }
    if (isRequiredMissing) {
      this._internals.setValidity({ valueMissing: true }, 'Please fill out this field.', el || undefined);
      return;
    }
    if (el && !el.validity.valid) {
      this._internals.setValidity({ customError: true }, el.validationMessage, el);
    } else {
      this._internals.setValidity({});
    }
  }

  checkValidity() {
    this._syncValidity();
    return this._internals ? this._internals.checkValidity() : true;
  }
  reportValidity() {
    this._syncValidity();
    return this._internals ? this._internals.reportValidity() : true;
  }

  // Form-associated callbacks
  formResetCallback() {
    this.value = this._defaultValue || '';
  }
  formStateRestoreCallback(state, _mode) {
    this.value = state ?? this._defaultValue ?? '';
  }

  render() {
    return html`
      <textarea
        .value=${this.value}
        rows=${this.rows}
        name=${this.name ?? ''}
        placeholder=${this.placeholder ?? ''}
        ?disabled=${this.disabled}
        ?required=${this.required}
        ?autofocus=${this.autofocus}
        maxlength=${this.maxlength ?? ''}
        @input=${this._onInput}
        @change=${this._onChange}
      ></textarea>
      <slot hidden @slotchange=${this.handleSlotChange}></slot>
    `;
  }

  static styles = [feather, css`
    :host {
      display: inline-block;
      width: 100%;
    }
    textarea {
      width: 100%;
      display: block;
      box-sizing: border-box;
      resize: none;
      overflow: hidden;
      line-height: 1.4;
      border: none;
      background: transparent;
      outline: none;
    }
  `];

  handleSlotChange(e) {
    const childNodes = e.target.assignedNodes({ flatten: true });
    const text = childNodes.map((node) => node.textContent ? node.textContent : '').join('');
    this.value = text;
  }
  
  firstUpdated() {
    this._internals?.setFormValue(this.value);
    this._autoResize();
    this._syncValidity();
  }

  // Keep height/validity aligned after first render and when properties change externally
  updated(changed) {
    if (changed.has('value')) {
      this._autoResize();
      this._syncValidity();
    }
    if (changed.has('required') || changed.has('maxlength') || changed.has('disabled')) {
      this._syncValidity();
    }
  }

  // Determine if the host is currently laid out (not hidden via display:none)
  _isLaidOut() {
    if (!this.isConnected) return false;
    const rect = this.getBoundingClientRect?.();
    return !!rect && (rect.width > 0 || rect.height > 0);
  }

  // Set up a ResizeObserver to trigger auto-resize once visible
  _setupVisibilityWatchers() {
    if (this._visibilityWatching) return;
    this._visibilityWatching = true;

    if (window.ResizeObserver) {
      this._visibilityRO = new ResizeObserver(() => {
        if (this._isLaidOut()) {
          this._teardownVisibilityWatchers();
          requestAnimationFrame(() => this._autoResize());
        }
      });
      this._visibilityRO.observe(this);
    }
  }

  _teardownVisibilityWatchers() {
    if (this._visibilityRO) {
      this._visibilityRO.disconnect();
      this._visibilityRO = null;
    }
    this._visibilityWatching = false;
  }

  disconnectedCallback() {
    super.disconnectedCallback?.();
    this._teardownVisibilityWatchers();
  }
}
customElements.define('feather-textarea', FeatherTextarea)