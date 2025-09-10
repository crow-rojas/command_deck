import { el } from '../core/dom.js';

export class PanelSelector {
  constructor(onSelect) {
    this.onSelect = onSelect;
    this.root = el('div', { id: 'cd-panel-selector' });
    this.select = el('select');
    this.root.appendChild(this.select);

    this.select.addEventListener('change', () => {
      const key = this.select.value;
      this.onSelect && this.onSelect(key);
    });
  }

  mount(container) { container.appendChild(this.root); }

  setPanels(panels) {
    // panels: [{ key, title, owner, group }]
    this.select.textContent = '';
    (panels || []).forEach(p => {
      const label = [p.group, p.title].filter(Boolean).join(' • ');
      const opt = el('option', { value: p.key }, [label || p.title || p.key]);
      this.select.appendChild(opt);
    });
  }

  setActiveKey(key) {
    if (!key) return;
    this.select.value = key;
  }
}
