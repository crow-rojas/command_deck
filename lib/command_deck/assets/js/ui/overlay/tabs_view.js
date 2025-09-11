import { el } from '../../core/dom.js';

export class TabsView {
  constructor(onSelect) {
    this.onSelect = onSelect;
    this.root = el('div', { id: 'cd-tabs-wrap' });
    this.buttons = [];
    this.currentIndex = 0;
    this.tabs = [];
  }

  mount(container) {
    container.appendChild(this.root);
  }

  setTabs(tabs, selectedIndex = 0) {
    this.tabs = tabs || [];
    this.root.textContent = '';
    this.buttons = [];
    this.currentIndex = selectedIndex || 0;

    this.tabs.forEach((tab, i) => {
      const btn = el('button', { class: 'cd-tab-btn' }, [tab.title]);
      btn.addEventListener('click', () => {
        this.currentIndex = i;
        this.onSelect && this.onSelect(this.tabs[i], i);
      });
      this.root.appendChild(btn);
      this.buttons.push(btn);
    });

    // Trigger initial selection
    if (this.tabs[this.currentIndex]) {
      this.onSelect && this.onSelect(this.tabs[this.currentIndex], this.currentIndex);
    }
  }

  setActiveIndex(i) {
    this.currentIndex = i;
  }
}
