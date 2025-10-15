import { el, truncateLabel } from '../core/dom.js';

export class PanelSelector {
  constructor(onSelect) {
    this.onSelect = onSelect;
    this.root = el('div', { id: 'cd-panel-selector' });
    this.select = el('select', { 
      'data-select-type': 'default',
      id: 'cd-panel-select',
      name: 'panel',
      autocomplete: 'off'
    });
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
      const fullLabel = [p.group, p.title].filter(Boolean).join(' • ');
      const label = fullLabel || p.title || p.key;
      const displayLabel = truncateLabel(label, 35);
      const opt = el('option', { value: p.key, title: label }, [displayLabel]);
      this.select.appendChild(opt);
    });
  }

  setActiveKey(key) {
    if (!key) return;
    this.select.value = key;
  }
}
