import { store } from '../../core/store.js';

export class ThemeManager {
  constructor(toggle, panel) {
    this.toggle = toggle;
    this.panel = panel;
  }

  load() {
    const saved = store.get('theme');
    if (saved) return saved;
    try {
      if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
        return 'dark';
      }
    } catch(_) {}
    return 'light';
  }

  save(theme) { store.set('theme', theme); }

  apply(theme) {
    const isDark = theme === 'dark';
    [this.toggle, this.panel].forEach(node => {
      node.classList.toggle('cd-theme-dark', isDark);
    });
  }

  set(theme) {
    if (theme !== 'light' && theme !== 'dark') return;
    this.save(theme);
    this.apply(theme);
  }
}
