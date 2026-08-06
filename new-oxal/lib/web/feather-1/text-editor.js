import { LitElement, html, css } from '/hawk-init/feather/1/lit';
import { feather } from '/hawk-init/feather/1/style?lit';

// XX new command: jump to line number
// XX new commands: move line (or multiple lines if selection spans more than 1) up or down

function expand({text, head, tail}) {

  const lines = text.split('\n');
  const row = text.slice(0, head).split('\n').length - 1;
  const col = head - (text.lastIndexOf('\n', head - 1) + 1);
  
  const rowText = lines[row];
  const rowIndent = rowText.match(/^ */)[0].length;

  const prevLineStart = lines.slice(0, row - 1).join('\n').length + (row > 1 ? 1 : 0);
  const prevLineEnd = prevLineStart + (lines[row - 1] || '').length;


  const nextLineStart = lines.slice(0, row + 1).join('\n').length + 1;
  const nextLineEnd = nextLineStart + (lines[row + 1] || '').length;

  
  const lineStart = text.lastIndexOf('\n', head - 1) + 1;

  let lineEndRaw = text.indexOf('\n', head);
  const lineEnd = lineEndRaw === -1 ? text.length : lineEndRaw;
  
  return {
    lines,
    row,
    rowText,
    rowIndent,
    col,
    lineStart,
    lineEnd,
    prevLineStart,
    prevLineEnd,
    nextLineStart,
    nextLineEnd,
    text,
    head,
    tail
  }
}

// XX finish these keybindings

const newKEYBINDINGS = {

  'h': 'moveLeft',
  'j': 'moveDown',
  'k': 'moveUp',
  'l': 'moveRight',
  
  'H': 'grabLeft',
  'J': 'grabDown',
  'K': 'grabUp',
  'L': 'grabRight',

  'y': 'moveChunkLeft',
  'u': 'moveChunkDown',
  'i': 'moveChunkUp',
  'o': 'moveChunkRight',
  
  'Y': 'grabChunkLeft',
  'U': 'grabChunkDown',
  'I': 'grabChunkUp',
  'O': 'grabChunkRight',
  
  //n dedent
  //m move line down
  //, move line up
  //. outdent
  
  // /
  //;
  //p
  
  //g
  //f
  //d delete line forward
  //D delete line backward
  //s save
  
  //t 
  //r
  //e
  //w

  //x cut
  //c copy
  //v paste
  //b
  
  //a
  //q
  //z undo
}

const KEYBINDINGS = [
  { 
    key: 'Ctrl+Y', 
    description: 'Move head and tail to the start of the line', 
    action: ({ text, head, tail }) => {
      const lineStart = text.lastIndexOf('\n', head - 1) + 1;

      return {
        head: lineStart,
        tail: lineStart,
      };
    }
  },
  { 
    key: 'Ctrl+Shift+Y',
    description: 'Move head to the start of the line (keep tail unchanged)', 
    action: ({ text, head, tail }) => {
      const lineStart = text.lastIndexOf('\n', head - 1) + 1;

      return {
        head: lineStart,
        tail,
      };
    }
  },
  { 
    key: 'Ctrl+O', 
    description: 'Move head and tail to the end of the line', 
    action: ({ text, head, tail }) => {
      const lineEnd = text.indexOf('\n', head);
      const endPos = lineEnd === -1 ? text.length : lineEnd;

      return {
        head: endPos,
        tail: endPos,
      };
    }
  },
  { 
    key: 'Ctrl+Shift+O', 
    description: 'Move tail to the end of the line (keep head unchanged)', 
    action: ({ text, head, tail }) => {
      const lineEnd = text.indexOf('\n', head);
      const endPos = lineEnd === -1 ? text.length : lineEnd;

      return {
        head,
        tail: endPos,
      };
    }
  },
  { 
    key: 'Ctrl+B', 
    description: 'Move head and tail backward by one word', 
    action: ({ text, head, tail }) => {
      const wordStart = text.lastIndexOf(' ', head - 1);

      return {
        head: wordStart === -1 ? 0 : wordStart,
        tail: wordStart,
      };
    }
  },
  { 
    key: 'Ctrl+Shift+B', 
    description: 'Move head backward by one word (keep tail unchanged)', 
    action: ({ text, head, tail }) => {
      const wordStart = text.lastIndexOf(' ', head - 1);

      return {
        head: wordStart === -1 ? 0 : wordStart,
        tail,
      };
    }
  },
  { 
    key: 'Ctrl+F', 
    description: 'Move head and tail forward by one word', 
    action: ({ text, head, tail }) => {
      const wordEnd = text.indexOf(' ', head + 1);

      return {
        head: wordEnd === -1 ? text.length : wordEnd,
        tail: wordEnd,
      };
    }
  },
  { 
    // XX improve wordwise movements
    
    key: 'Ctrl+Shift+F', 
    description: 'Move head forward by one word (keep tail unchanged)', 
    action: ({ text, head, tail }) => {
      const wordEnd = text.indexOf(' ', head + 1);

      return {
        head: wordEnd === -1 ? text.length : wordEnd,
        tail,
      };
    }
  },
  {
    key: 'Ctrl+O',
    description: 'New line below',
    action: ({ lineEnd, rowIndent }) => {
      return {
        head: lineEnd,
        tail: lineEnd,
        text: "\n" + " ".repeat(rowIndent),
      }
    }
  },
  {
    key: 'Ctrl+Shift+O',
    description: 'New line above',
    action: ({ prevLineEnd, rowIndent }) => {
      return {
        head: prevLineEnd,
        tail: prevLineEnd,
        text: "\n" + " ".repeat(rowIndent),
      }
    }
  },
  { 
    key: 'Ctrl+K', 
    description: 'Move head and tail up by one line', 
    action: ({ text, head, tail }) => {
      const lines = text.split('\n');
      const currentLine = text.slice(0, head).split('\n').length - 1;
      if (currentLine === 0) {
        return { head, tail, inverted: false };
      }
      const col = head - (text.lastIndexOf('\n', head - 1) + 1);
      const prevLineStart = lines.slice(0, currentLine - 1).join('\n').length + (currentLine > 1 ? 1 : 0);
      const prevLineEnd = prevLineStart + (lines[currentLine - 1] || '').length;

      return {
        head: Math.min(prevLineEnd, prevLineStart + col),
        tail: Math.min(prevLineEnd, prevLineStart + col),
        inverted: false,
      };
    }
  },
  { 
    key: 'Ctrl+Shift+K', 
    description: 'Move head up by one line (keep tail unchanged)', 
    action: ({ text, head, tail }) => {
      const lines = text.split('\n');
      const currentLine = text.slice(0, head).split('\n').length - 1;
      const prevLineStart = lines.slice(0, currentLine - 1).join('\n').length + (currentLine > 1 ? 1 : 0);
      const prevLineEnd = prevLineStart + (lines[currentLine - 1] || '').length;

      return {
        head: Math.min(prevLineEnd, head - (head - prevLineStart)),
        tail,
      };
    }
  },
  { 
    key: 'Ctrl+J', 
    description: 'Move down one line', 
    action: ({ text, head, tail }) => {
      const lines = text.split('\n');
      const currentLine = text.slice(0, head).split('\n').length - 1;
      const col = head - (text.lastIndexOf('\n', head - 1) + 1);
      const nextLineStart = lines.slice(0, currentLine + 1).join('\n').length + 1;
      const nextLineEnd = nextLineStart + (lines[currentLine + 1] || '').length;

      return {
        head: Math.min(nextLineEnd, nextLineStart + col),
        tail: Math.min(nextLineEnd, nextLineStart + col),
        inverted: true,
      };
    }
  },
  { 
    key: 'Ctrl+Shift+J', 
    description: 'Move head down one line', 
    action: ({ text, head, tail }) => {
      const lines = text.split('\n');
      const currentLine = text.slice(0, head).split('\n').length - 1;
      const nextLineStart = lines.slice(0, currentLine + 1).join('\n').length + 1;
      const nextLineEnd = nextLineStart + (lines[currentLine + 1] || '').length;

      return {
        head: Math.min(nextLineEnd, head + (nextLineStart - head)),
        tail,
      };
    }
  },
  { 
    key: 'Ctrl+D', 
    description: 'Delete to end of line', 
    action: ({ text, head, tail }) => {
      const lineEnd = text.indexOf('\n', head);

      return {
        text: "",
        head,
        tail: lineEnd == head ? head + 1 : lineEnd,
      };
    }
  },
  { 
    key: 'Ctrl+I', 
    description: 'Move cursor up 16 lines', 
    action: ({ text, head, tail }) => {
      const lines = text.split('\n');
      const currentLine = text.slice(0, head).split('\n').length - 1;
      const targetLine = Math.max(0, currentLine - 16);
      const targetLineStart = lines.slice(0, targetLine).join('\n').length + (targetLine > 0 ? 1 : 0);
      const targetLineEnd = targetLineStart + (lines[targetLine] || '').length;

      return {
        head: Math.min(targetLineEnd, head - (head - targetLineStart)),
        tail: Math.min(targetLineEnd, head - (head - targetLineStart)),
inverted: true,
      };
    }
  },
  { 
    key: 'Ctrl+U', 
    description: 'Move cursor down 16 lines', 
    action: ({ text, head, tail }) => {
      const lines = text.split('\n');
      const currentLine = text.slice(0, head).split('\n').length - 1;
      const targetLine = Math.min(lines.length - 1, currentLine + 16);
      const targetLineStart = lines.slice(0, targetLine).join('\n').length + 1;
      const targetLineEnd = targetLineStart + (lines[targetLine] || '').length;

      return {
        head: Math.min(targetLineEnd, head + (targetLineStart - head)),
        tail: Math.min(targetLineEnd, head + (targetLineStart - head)),
inverted: false,
      };
    }
  },
  { 
    key: 'Ctrl+G', 
    description: 'Go to start of document', 
    action: () => {
      return {
        head: 0,
        tail: 0,
      };
    }
  },
  { 
    key: 'Ctrl+Shift+G', 
    description: 'Go to end of document', 
    action: ({ text }) => {
      return {
        head: text.length,
        tail: text.length,
      };
    }
  },
  { 
    key: 'Ctrl+H', 
    description: 'Move left one character', 
    action: ({ text, head, tail }) => {
      const newPos = Math.max(0, head - 1);

      return {
        head: newPos,
        tail: newPos,
      };
    }
  },
  { 
    key: 'Ctrl+Shift+H', 
    description: 'Move left one character (extend selection)', 
    action: ({ text, head, tail }) => {
      const newPos = Math.max(0, head - 1);

      return {
        head: newPos,
        tail,
      };
    }
  },
  { 
    key: 'Ctrl+L', 
    description: 'Move right one character', 
    action: ({ text, head, tail }) => {
      const newPos = Math.min(text.length, head + 1);

      return {
        head: newPos,
        tail: newPos,
      };
    }
  },
  { 
    key: 'Ctrl+Shift+L', 
    description: 'Move head right one character', 
    action: ({ text, head, tail }) => {
      const newPos = Math.min(text.length, head + 1);

      return {
        head: newPos,
        tail,
      };
    }
  },
];

class FeatherTextEditor extends LitElement {
  static properties = {
    value: { type: String },
    placeholder: { type: String },
    autoIndent: { type: Boolean, attribute: "auto-indent" },
    startLine: { type: Number, attribute: "start-line" },
    _lines: { type: Number, state: true },
    _inverted: { type: Boolean, state: true },
    _showKeybindings: { state: true },
  };

  static styles = [feather, css`
    :host {
      display: flex;
      flex-direction: column;
      flex-grow: 1;
      overflow: hidden;
      position: relative;
      background: inherit;
    }
    .editor {
      display: flex;
      flex: 1 1 auto;
      min-height: 0;
      font-family: var(--font-mono);
      overflow: hidden;
    }
    .line-numbers {
      box-sizing: border-box;
      padding-top: 0.5rem;
      padding-bottom: 12rem;
      text-align: right;
      user-select: none;
      border-right: 1px solid var(--b3);
      line-height: 1.2;
      width: fit-content;
      min-width: fit-content;
      font-family: var(--font-mono);
      white-space: pre;
      color: var(--f4);
      overflow-y: hidden;
      overflow-x: scroll;
      flex-shrink: 0;
    }
    .line-numbers .bold {
      font-weight: bold;
      color: var(--f0);
    }
    textarea {
      flex: 1 1 auto;
      padding: 0.5rem 0.5rem 12rem 0.5rem;
      border: none;
      outline: none;
      resize: none;
      line-height: 1.2;
      font-family: inherit;
      white-space: pre;     /* disable wrapping */
      overflow: auto;
      caret-color: var(--f0);
    }
  `];

  static formAssociated = true;

  constructor() {
    super();
    this.value = '';
    this.placeholder = '';
    this._lines = 1;
    this._internals = this.attachInternals();
    this._isLoaded = false;
    this._showKeybindings = false;
    
    this._hasHadFocus = false;
  }

  _getTA() {
    return this.shadowRoot.querySelector('textarea');
  }

  _getCaretInfo() {
    const ta = this._getTA();
    if (!ta) return {start: 0, end: 0, line: 0, co: 0}
    const start = ta?.selectionStart || 0;
    const end = ta?.selectionEnd || 0;
    const before = ta.value.slice(0, start);
    const line = before.split("\n").length - 1;
    const col = before.length - before.lastIndexOf("\n") - 1;
    return { start, end, line, col };
  }

  _keepCursorCentered() {
    const ta = this._getTA();
    const start = ta?.selectionStart || 0;
    const end = ta?.selectionEnd || 0;
    const linePos = this._inverted ? start : end;
    const before = ta.value.slice(0, linePos);
    const line = before.split("\n").length - 1;
    this._scrollToLine(line);
  }

  _scrollToLine(line) {
    const ta = this._getTA();
    if (ta) {
      const totalLines = ta.value.split('\n').length;
      const percentage = Math.min((line - 1) / totalLines, 1);
      ta.scrollTo({
        top: (percentage * ta.scrollHeight) - (ta.offsetHeight / 2),
        behavior: "smooth",
      });
    }
  }

  _onInput(e) {
    this.value = e.target.value;
  }

  _onScroll(e) {
    const ln = this.renderRoot?.querySelector('.line-numbers');
    if (ln) ln.scrollTop = e.target.scrollTop;
  }

  _onSlotChange(e) {
    const childNodes = e.target.assignedNodes({ flatten: true });
    let text = childNodes.map((node) => {
      return node.textContent ? node.textContent : '';
    }).join('');
    let ta = this._getTA();
    ta.value = text;
    this.value = text;
    if (this.startLine && this.startLine > 0) {
      this._scrollToLine(this.startLine);
    }
  }

  firstUpdated() {
    const ta = this._getTA();
    ta.addEventListener('focusin', (e) => {
      if (
        ta.selectionStart == ta.selectionEnd
        && ta.selectionEnd == ta.value.length 
        && !this._hasHadFocus
      ) {
        ta.selectionStart = 0;
        ta.selectionEnd = 0;
        ta.scrollTop = 0;
      }
      this._hasHadFocus = true;
    })
  }


  updated(changed) {
    if (changed.has('value') && !!this.value) {
      this._isLoaded = true;
    }
  }

  willUpdate(changed) {
    if (changed.has('value')) {
      this._lines = (this.value?.split('\n').length) || 1;
      this._internals.setFormValue(this.value);
      if (this._isLoaded && changed.get('value') !== this.value) {
        this.dispatchEvent(new CustomEvent('change', { detail: this.value }));
        this.dispatchEvent(new CustomEvent('input', { detail: this.value }));
      }
    }
  }

  _onKeydown(e) {
    const ta = this._getTA();
    
    const state = {
      text: ta.value,
      head: this._inverted ? ta.selectionStart : ta.selectionEnd,
      tail: this._inverted ? ta.selectionEnd : ta.selectionStart,
    };

    const binding = KEYBINDINGS.find(b => b.key.toLowerCase() === `${e.ctrlKey ? 'ctrl+' : ''}${e.shiftKey ? 'shift+' : ''}${e.key.toLowerCase()}`);
    if (binding) {
      const newState = binding.action(expand(state));

      if (newState.head !== undefined && newState.tail !== undefined) {
        const selectionStart = Math.min(newState.head, newState.tail);
        const selectionEnd = Math.max(newState.head, newState.tail);
        ta.selectionStart = selectionStart;
        ta.selectionEnd = selectionEnd;
      }

      if (newState.text !== undefined) {
        document.execCommand('insertText', false, newState.text);
        this.value = ta.value;
      }
      this._inverted = newState.inverted === undefined ? this._inverted : newState.inverted;
      this._keepCursorCentered();
      e.preventDefault();
    }
    else if (e.key == 's' && (e.metaKey || e.ctrlKey)) {
      // attempt to save the file
      e.preventDefault();
      this._internals.form?.requestSubmit();
    }
    else if (
      this.autoIndent &&
      e.key === 'Enter' &&
      !e.metaKey &&
      !e.ctrlKey &&
      !e.shiftKey
    ) {
      const textarea = e.target;
      const start = textarea.selectionStart;
      const end = textarea.selectionEnd;
      const text = textarea.value;

      const lineStart = text.lastIndexOf('\n', start - 1) + 1;
      const currentLine = text.slice(lineStart, start);

      const indentMatch = currentLine.match(/^[ \t]*/);
      const indent = indentMatch ? indentMatch[0] : '';

      e.preventDefault();

      document.execCommand('insertText', false, '\n'+indent);
      this.value = textarea.value;
    }
    else if (e.key === 'Tab' && !e.metaKey && !e.ctrlKey) {
      // XX make indent/outdent undo-able via builtin cmd+z
      e.preventDefault();

      const textarea = e.target;
      const start = textarea.selectionStart;
      const end = textarea.selectionEnd;
      const text = textarea.value;

      const isShift = e.shiftKey;
      const lineStart = text.lastIndexOf('\n', start - 1) + 1;
      const lineEnd = text[end - 1] === '\n' ? end - 1 : text.indexOf('\n', end);
      const selectionEnd = lineEnd === -1 ? text.length : lineEnd;

      const selectedLines = text.slice(lineStart, selectionEnd).split('\n');
      const modifiedLines = selectedLines.map(line => {
        if (isShift) {
          // Dedent: Remove up to 2 spaces or 1 tab
          return line.replace(/^( {1,2}|\t)/, '');
        } else {
          // Indent: Add 2 spaces
          return '  ' + line;
        }
      });

      const newText = text.slice(0, lineStart) + modifiedLines.join('\n') + text.slice(selectionEnd);

      // Adjust selection to preserve the selected region
      const newStart = start - (isShift ? Math.min(2, selectedLines[0].match(/^( {1,2}|\t)/)?.[0]?.length || 0) : -2);
      const newEnd = end + (isShift ? -selectedLines.reduce((acc, line) => acc + Math.min(2, line.match(/^( {1,2}|\t)/)?.[0]?.length || 0), 0) : selectedLines.length * 2);

      textarea.value = newText;
      textarea.selectionStart = newStart;
      textarea.selectionEnd = newEnd;
      this.value = newText;
    }
  }

  _toggleKeybindings() {
    this._showKeybindings = !this._showKeybindings;
  }

  renderKeybindings() {
    return html`
      <div class="keybindings fc af g2 p10 pb20">
        <h2 class="mb4">Keybindings Documentation</h2>
        ${KEYBINDINGS.map(binding => html`
          <div class="fr g4 as">
            <span class="bold">${binding.key}</span>
            <span>${binding.description}</span>
          </div>
        `)}
      </div>
    `;
  }

  render() {
    const numbers = Array.from({ length: this._lines }, (_, i) => i + 1);
    const digits = String(this._lines).length;
    const chWidth = Math.max(2, digits) + 1;
    const lineNums = numbers.map((num) => {
      return html`<span class="${this.startLine === num ? 'bold' : ''}">${num}\n</span>`;
    });
    return html`
      <button
        class="toggle-button hover b3 btrr3 py3 px3 fc ac jc h8 absolute left0 bottom0 pointer ${this._showKeybindings ? 'toggled' : ''}"
        style="width: ${chWidth}ch;"
        @click=${this._toggleKeybindings}
      >
        <span>${this._showKeybindings ? '✕' : '?'}</span>
      </button>
      <div class="editor ${this._showKeybindings ? 'hidden' : ''}">
        <pre class="line-numbers px3" style="width: ${chWidth}ch;">${lineNums}</pre>
        <textarea
          .value=${this.value}
          placeholder=${this.placeholder}
          spellcheck="false"
          autocomplete="off"
          wrap="off"
          @keydown=${this._onKeydown.bind(this)}
          @input=${this._onInput.bind(this)}
          @scroll=${this._onScroll.bind(this)}
          name=${Math.random().toString().slice(2)}
        ></textarea>
        <slot hidden="" @slotchange=${this._onSlotChange.bind(this)}></slot>
      </div>
      <div class="keybindings scroll-y fc js af ${this._showKeybindings ? '' : 'hidden'}">
        ${this.renderKeybindings()}
      </div>
    `;
  }
}

// class SpineCodeEditor extends FeatherTextEditor {}
// customElements.define('spine-code-editor', SpineCodeEditor);
customElements.define('feather-text-editor', FeatherTextEditor);
