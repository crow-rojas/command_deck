import { el, truncateLabel } from '../../core/dom.js';
import { store } from '../../core/store.js';

export class ActionForm {
  constructor({ action, getCurrentPanelKey, actionsApi, onRunning, onResult, onAfterRun }) {
    this.action = action;
    this.getCurrentPanelKey = getCurrentPanelKey;
    this.actionsApi = actionsApi;
    this.onRunning = onRunning || (() => {});
    this.onResult = onResult || (() => {});
    this.onAfterRun = onAfterRun || (() => {});
  }

  mount(parentNode) {
    const box = el('div', { class: 'cd-action' });
    const title = el('div', { class: 'cd-action-title' }, [this.action.title]);
    const form = el('div', { class: 'cd-form' });

    box.appendChild(title);
    box.appendChild(form);

    const inputs = {};
    const paramsMeta = {};

    (this.action.params || []).forEach((p, paramIndex) => {
      const inputId = `cd-input-${this.action.key}-${p.name}-${paramIndex}`;
      const labelChildren = [p.label || p.name];
      if (p.required === true) {
        labelChildren.push(el('span', { class: 'cd-required', title: 'Required' }, ['*']));
      }
      const label = el('label', { for: inputId }, labelChildren);
      let input;
      if (p.type === 'boolean') {
        input = el('input', { type: 'checkbox', id: inputId, name: p.name, autocomplete: 'off' });
      } else if (p.type === 'integer') {
        input = el('input', { type: 'number', step: '1', id: inputId, name: p.name, autocomplete: 'off' });
      } else if (p.type === 'selector' || (p.choices && p.choices.length)) {
        input = el('select', { 'data-select-type': 'default', id: inputId, name: p.name, autocomplete: 'off' });
        if (p.include_blank) {
          input.appendChild(el('option', { value: '' }, ['']));
        }
        (p.choices || []).forEach(ch => {
          const attrs = { 'data-val': JSON.stringify(ch.value) };
          if (ch.meta != null) attrs['data-meta'] = JSON.stringify(ch.meta);
          const fullLabel = ch.label != null ? String(ch.label) : String(ch.value);
          const displayLabel = truncateLabel(fullLabel, 50);
          attrs['title'] = fullLabel;
          const opt = el('option', attrs, [displayLabel]);
          input.appendChild(opt);
        });

        const selKey = `sel:${this.getCurrentPanelKey() || ''}:${this.action.key}:${p.name}`;
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
        input = el('input', { type: 'text', id: inputId, name: p.name, autocomplete: 'off' });
      }
      if (p.required === true && input) {
        input.setAttribute('aria-required', 'true');
        input.setAttribute('required', '');
      }
      form.appendChild(label);
      form.appendChild(input);

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
        
        const populateRelatedInput = () => {
          const sel = input.options[input.selectedIndex];
          if (!sel) return;
          const metaRaw = sel.getAttribute('data-meta');
          if (!metaRaw) return;
          try {
            const meta = JSON.parse(metaRaw);
            if (meta.value != null && typeof meta.enabled !== 'boolean') {
              // Find the next string/number input after this selector
              const currentParamIndex = (this.action.params || []).findIndex(param => param.name === p.name);
              if (currentParamIndex >= 0 && currentParamIndex < (this.action.params || []).length - 1) {
                const nextParam = this.action.params[currentParamIndex + 1];
                // Only auto-populate if the next param has auto_populate explicitly enabled (defaults to false)
                const shouldAutoPopulate = nextParam.auto_populate === true;
                const nextInput = inputs[nextParam.name];
                if (shouldAutoPopulate && nextInput && (nextInput.type === 'text' || nextInput.type === 'number')) {
                  nextInput.value = String(meta.value);
                }
              }
            }
          } catch(_) { }
        };
        
        input.addEventListener('change', () => {
          const sel = input.options[input.selectedIndex];
          const raw = sel ? sel.getAttribute('data-val') : '';
          const selKey = `sel:${this.getCurrentPanelKey() || ''}:${this.action.key}:${p.name}`;
          store.set(selKey, raw || '');
          updateHint();
          populateRelatedInput();
          validate();
        });
        setTimeout(() => {
          updateHint();
          populateRelatedInput();
        }, 0);
        form.appendChild(hint);
      }

      inputs[p.name] = input;
      paramsMeta[p.name] = p;
    });

    const requiredParams = (this.action.params || []).filter(p => p.required === true);
    const isFilled = (p) => {
      const inp = inputs[p.name];
      if (!inp) return false;
      if (p.type === 'integer') return inp.value !== '';
      if (p.type === 'selector' || (p.choices && p.choices.length)) {
        if (p.include_blank) return inp.value !== '' && inp.selectedIndex > -1;
        return inp.selectedIndex > -1;
      }
      if (p.type === 'boolean') return true;
      return String(inp.value || '').trim() !== '';
    };
    const validate = () => {
      const ok = requiredParams.every(isFilled);
      const running = run.classList.contains('loading');
      run.disabled = !ok || running;
    };

    const run = el('button', { class: 'cd-run', title: 'Run' }, ['\u25B6']);
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
            payload[k] = value;
          }

          const selKey = `sel:${this.getCurrentPanelKey() || ''}:${this.action.key}:${k}`;
          store.set(selKey, raw || '');
        } else {
          payload[k] = (inp.type === 'checkbox') ? !!inp.checked : inp.value;
        }
      });

      this.onRunning();
      this.actionsApi
        .submit(this.action.key, payload)
        .then((res) => { this.onResult(res); this.onAfterRun(); })
        .catch((e) => this.onResult({ ok:false, error: String(e) }))
        .finally(() => { run.classList.remove('loading'); run.removeAttribute('aria-busy'); validate(); });
    });

    const actionsRow = el('div', { class: 'cd-actions-row' });
    actionsRow.appendChild(run);
    form.appendChild(actionsRow);

    // Hook up validation listeners
    (this.action.params || []).forEach(p => {
      const inp = inputs[p.name];
      if (!inp) return;
      const evt = (inp.tagName === 'SELECT' || inp.type === 'checkbox') ? 'change' : 'input';
      inp.addEventListener(evt, validate);
    });
    validate();

    parentNode.appendChild(box);
  }
}
