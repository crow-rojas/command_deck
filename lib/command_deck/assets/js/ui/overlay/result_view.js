import { el, jsonPretty } from '../../core/dom.js';
import { store } from '../../core/store.js';

export class ResultView {
  constructor() {
    this.wrap = el('div', { id: 'cd-result-wrap' });
    this.toolbar = el('div', { class: 'cd-result-toolbar' });
    this.copyBtn = el('button', { class: 'cd-icon-btn', id: 'cd-copy-result', title: 'Copy result' }, ['📋']);
    this.toggleBtn = el('button', { class: 'cd-icon-btn', id: 'cd-toggle-result', title: 'Hide results' }, ['▾']);
    this.pre = el('pre', { id: 'command-deck-output' });

    this.toolbar.appendChild(this.copyBtn);
    this.toolbar.appendChild(this.toggleBtn);
    this.wrap.appendChild(this.toolbar);
    this.wrap.appendChild(this.pre);

    this.toggleBtn.addEventListener('click', () => {
      const visible = this.pre.style.display === 'none' ? false : true;
      this.setVisible(!visible);
    });

    this.copyBtn.addEventListener('click', async () => {
      const text = this.pre.textContent || '';
      try {
        if (navigator.clipboard && navigator.clipboard.writeText) {
          await navigator.clipboard.writeText(text);
        } else {
          const ta = document.createElement('textarea');
          ta.value = text;
          ta.style.position = 'fixed';
          ta.style.opacity = '0';
          document.body.appendChild(ta);
          ta.select();
          document.execCommand('copy');
          document.body.removeChild(ta);
        }
        const prev = this.copyBtn.textContent;
        this.copyBtn.textContent = '✓';
        setTimeout(() => { this.copyBtn.textContent = prev; }, 1000);
      } catch(_) { /* ignore */ }
    });

    const initialVis = store.get('results-visible', '1') !== '0';
    this.setVisible(initialVis);
  }

  mount(parentNode) {
    parentNode.appendChild(this.wrap);
  }

  setVisible(show) {
    this.pre.style.display = show ? 'block' : 'none';
    this.toggleBtn.textContent = show ? '▾' : '▸';
    this.toggleBtn.setAttribute('title', show ? 'Hide results' : 'Show results');
    store.set('results-visible', show ? '1' : '0');
  }

  setRunning() {
    this.setVisible(true);
    this.pre.innerHTML = '<span class="cd-spinner"></span> Running...';
  }

  setResult(obj) {
    this.setVisible(true);
    this.pre.textContent = jsonPretty(obj);
  }
}
