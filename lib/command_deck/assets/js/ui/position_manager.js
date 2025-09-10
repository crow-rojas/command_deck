import { store } from '../core/store.js';

const POSITIONS = ['tl','tr','bl','br'];

export class PositionManager {
  constructor(toggle, panel) {
    this.toggle = toggle;
    this.panel = panel;
  }
  load() { return store.get('position', 'br'); }
  save(pos) { store.set('position', pos); }
  apply(pos) {
    ['cd-pos-tl','cd-pos-tr','cd-pos-bl','cd-pos-br'].forEach(c => {
      this.toggle.classList.remove(c);
      this.panel.classList.remove(c);
    });
    const cls = 'cd-pos-' + pos;
    this.toggle.classList.add(cls);
    this.panel.classList.add(cls);
  }
  set(pos) {
    if (!POSITIONS.includes(pos)) return;
    this.save(pos);
    this.apply(pos);
  }
}
