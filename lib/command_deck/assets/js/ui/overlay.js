import { el, jsonPretty } from '../core/dom.js';
import { PositionManager } from './position_manager.js';

export class Overlay {
  constructor({ mount, panelsApi, actionsApi }) {
    this.mount = mount;
    this.panelsApi = panelsApi;
    this.actionsApi = actionsApi;
    this._loaded = false;
  }

  init() {
    if (this._loaded) return; this._loaded = true;
    // Root pieces
    this.toggle = el('div', { id: 'command-deck-toggle', title: 'Command Deck' }, ['CD']);
    this.panel  = el('div', { id: 'command-deck-panel', style: { display: 'none' } });

    const headerWrap = el('div', { id: 'cd-header' });
    const title = el('h4', null, ['Command Deck']);
    headerWrap.appendChild(title);

    this.tabsWrap = el('div', { id: 'cd-tabs-wrap' });
    this.actionsWrap = el('div', { id: 'cd-actions-wrap' });
    this.resultPre = el('pre', { id: 'command-deck-output' });

    this.panel.appendChild(headerWrap);
    this.panel.appendChild(this.tabsWrap);
    this.panel.appendChild(this.actionsWrap);
    this.panel.appendChild(this.resultPre);

    document.body.appendChild(this.toggle);
    document.body.appendChild(this.panel);

    this.toggle.addEventListener('click', () => {
      this.panel.style.display = (this.panel.style.display === 'none' || !this.panel.style.display) ? 'block' : 'none';
    });

    this.position = new PositionManager(this.toggle, this.panel);
    this.position.set(this.position.load());
  }

  attachSettings(dropdown) {
    // Append settings into header
    const header = this.panel.querySelector('#cd-header');
    dropdown.mount(header);
  }

  loadPanels() {
    return this.panelsApi.fetchPanels().then(data => this.renderPanels(data));
  }

  renderPanels(data) {
    this.tabsWrap.textContent = '';
    this.actionsWrap.textContent = '';

    const panels = (data && data.panels) || [];
    if (!panels.length) {
      this.tabsWrap.appendChild(el('div', null, ['No panels defined. Add files under app/command_deck/**/*.rb']));
      return;
    }

    const panel0 = panels[0];
    const headerTitle = this.panel.querySelector('#cd-header h4');
    headerTitle.textContent = 'Command Deck • ' + panel0.title;

    panel0.tabs.forEach((tab, i) => {
      const btn = el('button', { class: 'cd-tab-btn' }, [tab.title]);
      btn.addEventListener('click', () => this.renderActions(tab));
      this.tabsWrap.appendChild(btn);
      if (i === 0) this.renderActions(tab);
    });
  }

  renderActions(tab) {
    this.actionsWrap.textContent = '';
    (tab.actions || []).forEach(action => {
      const box = el('div', { class: 'cd-action' });
      box.appendChild(el('div', { class: 'cd-action-title' }, [action.title]));
      const form = el('div', { class: 'cd-form' });

      const inputs = {};
      (action.params || []).forEach(p => {
        const label = el('label', null, [p.label || p.name]);
        let input;
        if (p.type === 'boolean') {
          input = el('input', { type: 'checkbox' });
        } else if (p.type === 'integer') {
          input = el('input', { type: 'number', step: '1' });
        } else {
          input = el('input', { type: 'text' });
        }
        form.appendChild(label);
        form.appendChild(input);
        inputs[p.name] = input;
      });

      const run = el('button', { class: 'cd-run' }, ['Run']);
      run.addEventListener('click', () => {
        const payload = {};
        Object.keys(inputs).forEach(k => {
          const inp = inputs[k];
          payload[k] = (inp.type === 'checkbox') ? !!inp.checked : inp.value;
        });
        this.setRunning();
        this.actionsApi.submit(action.key, payload).then((res) => this.setResult(res)).catch((e) => this.setResult({ ok:false, error: String(e) }));
      });
      form.appendChild(run);

      box.appendChild(form);
      this.actionsWrap.appendChild(box);
    });
  }

  setRunning(){ this.resultPre.textContent = 'Running...'; }
  setResult(obj){ this.resultPre.textContent = jsonPretty(obj); }
}
