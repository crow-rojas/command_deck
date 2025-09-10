import { el } from '../core/dom.js';

export class SettingsDropdown {
  constructor(onSelectPosition, onThemeChange) {
    this.onSelectPosition = onSelectPosition;
    this.onThemeChange = onThemeChange;

    this.root = el('div', { id: 'cd-settings-panel', style: { display: 'none' } });
    this.button = el('button', { id: 'cd-settings-btn', title: 'Settings' }, ['\u2699']);

    // Position section
    const titlePos = el('div', { class: 'cd-settings-title' }, ['Position']);
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

    // Theme toggle (no title/label; just icon button)
    this.themeBtn = el('button', { id: 'cd-theme-toggle', title: 'Toggle theme' }, ['\u2600']); // sun
    this.themeBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      const next = (this.currentTheme === 'dark') ? 'light' : 'dark';
      this.setTheme(next);
      this.onThemeChange && this.onThemeChange(next);
    });

    this.root.appendChild(titlePos);
    this.root.appendChild(menu);
    this.root.appendChild(this.themeBtn);

    this.button.addEventListener('click', (e) => {
      e.stopPropagation();
      this.toggle();
    });
    this.root.addEventListener('click', (e) => e.stopPropagation());
    document.addEventListener('click', () => this.hide());
  }

  setTheme(theme) {
    this.currentTheme = theme === 'dark' ? 'dark' : 'light';
    if (this.themeBtn) this.themeBtn.textContent = (this.currentTheme === 'dark') ? '\u263D' : '\u2600';
    // ☽ (U+263D) for moon, ☀ (U+2600) for sun
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
