import { el } from '../../core/dom.js';

export class HeaderView {
  constructor() {
    this.el = el('div', { id: 'cd-header' });
    this.titleEl = el('h4', null, ['Command Deck']);
    this.rightEl = el('div', { id: 'cd-header-right' });
    this.el.appendChild(this.titleEl);
    this.el.appendChild(this.rightEl);
  }

  mount(parent) {
    parent.appendChild(this.el);
  }

  setTitle(text) {
    this.titleEl.textContent = text;
  }

  getRightContainer() {
    return this.rightEl;
  }
}
