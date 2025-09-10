import { el, jsonPretty } from '../core/dom.js';
import { store } from '../core/store.js';
import { PositionManager } from './position_manager.js';
import { ThemeManager } from './theme_manager.js';

export class Overlay {
  constructor({ mount, panelsApi, actionsApi }) {
    this.mount = mount;
    this.panelsApi = panelsApi;
    this.actionsApi = actionsApi;
    this._loaded = false;
  }

  refreshCurrentTab() {
    // Re-fetch panels and re-render current panel/tab without changing selection
    this.panelsApi.fetchPanels().then((data) => {
      const panels = (data && data.panels) || [];
      this.panels = panels;
      if (this.panelSelector) this.panelSelector.setPanels(this.panels);
      const panel = this.panels.find(p => p.key === this.currentPanelKey) || this.panels[0];
      if (!panel) return;
      if (this.panelSelector) this.panelSelector.setActiveKey(panel.key);
      this.renderTabs(panel, this.currentTabIndex || 0);
    }).catch(() => {/* ignore refresh errors */});
  }

  init() {
    if (this._loaded) return; this._loaded = true;
    // Root pieces
    this.toggle = el('div', { id: 'command-deck-toggle', title: 'Command Deck' }, ['CD']);
    this.panel  = el('div', { id: 'command-deck-panel', style: { display: 'none' } });
    // Keep these nodes across Turbo Drive navigations
    this.toggle.setAttribute('data-turbo-permanent', '');
    this.panel.setAttribute('data-turbo-permanent', '');

    const headerWrap = el('div', { id: 'cd-header' });
    const title = el('h4', null, ['Command Deck']);
    headerWrap.appendChild(title);
    const headerRight = el('div', { id: 'cd-header-right' });
    headerWrap.appendChild(headerRight);

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

    this.theme = new ThemeManager(this.toggle, this.panel);
    this.theme.set(this.theme.load());
  }

  attachSettings(dropdown) {
    // Append settings into right side of header
    const headerRight = this.panel.querySelector('#cd-header-right');
    dropdown.mount(headerRight);
    if (this.theme) dropdown.setTheme && dropdown.setTheme(this.theme.load());
  }

  attachPanelSelector(selector) {
    this.panelSelector = selector;
    const headerRight = this.panel.querySelector('#cd-header-right');
    selector.mount(headerRight);
  }

  loadPanels() {
    return this.panelsApi.fetchPanels().then(data => this.setPanels(data));
  }

  setPanels(data) {
    this.tabsWrap.textContent = '';
    this.actionsWrap.textContent = '';
    this.panels = (data && data.panels) || [];
    if (!this.panels.length) {
      this.tabsWrap.appendChild(el('div', null, ['No panels defined. Add files under app/command_deck/**/*.rb']))
      return;
    }
    // Initialize selector
    if (this.panelSelector) {
      this.panelSelector.setPanels(this.panels);
    }
    const saved = store.get('panel-key');
    const exists = this.panels.find(p => p.key === saved);
    const key = exists ? saved : this.panels[0].key;
    this.selectPanel(key);
  }

  selectPanel(key) {
    const panel = (this.panels || []).find(p => p.key === key);
    if (!panel) return;
    this.currentPanelKey = key;
    store.set('panel-key', key);
    if (this.panelSelector) this.panelSelector.setActiveKey(key);

    const headerTitle = this.panel.querySelector('#cd-header h4');
    headerTitle.textContent = 'Command Deck';
    this.renderTabs(panel, this.currentTabIndex || 0);
  }

  renderTabs(panel, selectedIndex = 0) {
    this.tabsWrap.textContent = '';
    this.actionsWrap.textContent = '';
    this.currentTabIndex = selectedIndex;
    (panel.tabs || []).forEach((tab, i) => {
      const btn = el('button', { class: 'cd-tab-btn' }, [tab.title]);
      btn.addEventListener('click', () => { this.currentTabIndex = i; this.renderActions(tab); });
      this.tabsWrap.appendChild(btn);
      if (i === selectedIndex) this.renderActions(tab);
    });
  }

  renderActions(tab) {
    this.actionsWrap.textContent = '';
    (tab.actions || []).forEach(action => {
      const box = el('div', { class: 'cd-action' });
      box.appendChild(el('div', { class: 'cd-action-title' }, [action.title]));
      const form = el('div', { class: 'cd-form' });

      const inputs = {};
      const paramsMeta = {};
      (action.params || []).forEach(p => {
        const labelChildren = [p.label || p.name];
        if (p.required === true) {
          labelChildren.push(el('span', { class: 'cd-required', title: 'Required' }, ['*']));
        }
        const label = el('label', null, labelChildren);
        let input;
        if (p.type === 'boolean') {
          input = el('input', { type: 'checkbox' });
        } else if (p.type === 'integer') {
          input = el('input', { type: 'number', step: '1' });
        } else if (p.type === 'selector' || (p.choices && p.choices.length)) {
          input = el('select');
          if (p.include_blank) {
            input.appendChild(el('option', { value: '' }, ['']));
          }
          (p.choices || []).forEach(ch => {
            const attrs = { 'data-val': JSON.stringify(ch.value) };
            if (ch.meta != null) attrs['data-meta'] = JSON.stringify(ch.meta);
            const opt = el('option', attrs, [ch.label != null ? String(ch.label) : String(ch.value)]);
            input.appendChild(opt);
          });

          // Restore last selection (per panel/action/param)
          const selKey = `sel:${this.currentPanelKey || ''}:${action.key}:${p.name}`;
          const savedRaw = store.get(selKey);
          if (savedRaw != null) {
            let matched = false;
            for (let i = 0; i < input.options.length; i++) {
              const o = input.options[i];
              const raw = o.getAttribute('data-val');
              if (raw === savedRaw) {
                input.selectedIndex = i;
                matched = true;
                break;
              }
            }
            if (!matched && p.include_blank && savedRaw === '') {
              for (let i = 0; i < input.options.length; i++) {
                if (input.options[i].value === '') { input.selectedIndex = i; break; }
              }
            }
          }
        } else {
          input = el('input', { type: 'text' });
        }
        if (p.required === true && input) {
          input.setAttribute('aria-required', 'true');
          input.setAttribute('required', '');
        }
        form.appendChild(label);
        form.appendChild(input);

        // Optional hint below inputs (used for selector current value display)
        let hint;
        if (input.tagName === 'SELECT') {
          hint = el('div', { class: 'cd-param-hint' });
          const updateHint = () => {
            const sel = input.options[input.selectedIndex];
            if (!sel) { hint.textContent = ''; return; }
            const metaRaw = sel.getAttribute('data-meta');
            if (!metaRaw) { hint.textContent = ''; return; }
            try {
              const meta = JSON.parse(metaRaw);
              if (typeof meta.enabled === 'boolean') {
                const status = meta.enabled ? 'ON' : 'OFF';
                hint.textContent = 'Current: ';
                const badge = el('span', { class: `cd-badge ${meta.enabled ? 'cd-on' : 'cd-off'}` }, [status]);
                hint.appendChild(badge);
              } else {
                hint.textContent = '';
              }
            } catch(_) { hint.textContent = ''; }
          };
          input.addEventListener('change', () => {
            // Persist selection
            const sel = input.options[input.selectedIndex];
            const raw = sel ? sel.getAttribute('data-val') : '';
            const selKey = `sel:${this.currentPanelKey || ''}:${action.key}:${p.name}`;
            store.set(selKey, raw || '');
            updateHint();
            validate();
          });
          // Initialize after options are appended
          setTimeout(updateHint, 0);
          form.appendChild(hint);
        }

        inputs[p.name] = input;
        paramsMeta[p.name] = p;
      });

      // Validation helpers
      const requiredParams = (action.params || []).filter(p => p.required === true);
      const isFilled = (p) => {
        const inp = inputs[p.name];
        if (!inp) return false;
        if (p.type === 'integer') return inp.value !== '';
        if (p.type === 'selector' || (p.choices && p.choices.length)) {
          if (p.include_blank) return inp.value !== '' && inp.selectedIndex > -1;
          return inp.selectedIndex > -1; // any selection counts
        }
        if (p.type === 'boolean') return true; // checkbox always provides a value
        // string or others
        return String(inp.value || '').trim() !== '';
      };
      const validate = () => {
        const ok = requiredParams.every(isFilled);
        const running = run.classList.contains('loading');
        run.disabled = !ok || running;
      };

      const run = el('button', { class: 'cd-run', title: 'Run' }, ['\u25B6']); // ▶
      run.addEventListener('click', () => {
        if (run.disabled) return;
        run.classList.add('loading');
        run.setAttribute('aria-busy', 'true');
        run.disabled = true;
        const payload = {};
        Object.keys(inputs).forEach(k => {
          const inp = inputs[k];
          const meta = paramsMeta[k] || {};
          if (inp.tagName === 'SELECT') {
            const sel = inp.options[inp.selectedIndex];
            const raw = sel && sel.getAttribute('data-val');
            const label = sel ? sel.textContent : '';
            let value;
            try { value = raw != null ? JSON.parse(raw) : inp.value; } catch(_) { value = inp.value; }

            if (meta.return === 'label') {
              payload[k] = label;
            } else if (meta.return === 'both' || meta.return === 'object') {
              payload[k] = { label: label, value: value };
            } else {
              payload[k] = value; // default: value
            }

            // Persist selection on run as well
            const selKey = `sel:${this.currentPanelKey || ''}:${action.key}:${k}`;
            store.set(selKey, raw || '');
          } else {
            payload[k] = (inp.type === 'checkbox') ? !!inp.checked : inp.value;
          }
        });
        this.setRunning();
        this.actionsApi
          .submit(action.key, payload)
          .then((res) => { this.setResult(res); this.refreshCurrentTab(); })
          .catch((e) => this.setResult({ ok:false, error: String(e) }))
          .finally(() => { run.classList.remove('loading'); run.removeAttribute('aria-busy'); validate(); });
      });
      const actionsRow = el('div', { class: 'cd-actions-row' });
      actionsRow.appendChild(run);
      form.appendChild(actionsRow);

      box.appendChild(form);
      this.actionsWrap.appendChild(box);

      // Hook up validation listeners
      (action.params || []).forEach(p => {
        const inp = inputs[p.name];
        if (!inp) return;
        const evt = (inp.tagName === 'SELECT' || inp.type === 'checkbox') ? 'change' : 'input';
        inp.addEventListener(evt, validate);
      });
      // Initial state
      validate();
    });
  }

  setRunning(){ this.resultPre.textContent = 'Running...'; }
  setResult(obj){ this.resultPre.textContent = jsonPretty(obj); }
}
