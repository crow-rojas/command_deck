import { el } from '../core/dom.js';

export class SettingsDropdown {
  constructor(onSelectPosition) {
    this.onSelectPosition = onSelectPosition;
    this.root = el('div', { id: 'cd-settings-panel', style: { display: 'none' } });
    this.button = el('button', { id: 'cd-settings-btn', title: 'Settings' }, ['\u2699']);
    const title = el('div', { class: 'cd-settings-title' }, ['Position']);
    const menu = el('div', { class: 'cd-menu' });
    const items = [
      ['tl','\u2196  Top-left'],
      ['tr','\u2197  Top-right'],
      ['bl','\u2199  Bottom-left'],
      ['br','\u2198  Bottom-right']
    ];
    items.forEach(([key, label]) => {
      const item = el('button', { class: 'cd-menu-item', 'data-pos': key }, [label]);
      item.addEventListener('click', (e) => { e.stopPropagation(); this.onSelectPosition(key); this.hide(); });
      menu.appendChild(item);
    });
    this.root.appendChild(title);
    this.root.appendChild(menu);

    this.button.addEventListener('click', (e) => {
      e.stopPropagation();
      this.toggle();
    });
    this.root.addEventListener('click', (e) => e.stopPropagation());
    document.addEventListener('click', () => this.hide());
  }

  mount(container) {
    container.appendChild(this.button);
    container.appendChild(this.root);
  }

  toggle() {
    const willOpen = (this.root.style.display === 'none' || !this.root.style.display);
    this.root.style.display = willOpen ? 'block' : 'none';
    this.button.classList.toggle('open', willOpen);
  }
  hide() { this.root.style.display = 'none'; this.button.classList.remove('open'); }
}
