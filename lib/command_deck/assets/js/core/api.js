export class PanelsApi {
  constructor(mount) { this.mount = mount; }
  fetchPanels() {
    return fetch(this.mount + '/panels', { credentials: 'same-origin' }).then(r => r.json());
  }
}

export class ActionsApi {
  constructor(mount) { this.mount = mount; }
  submit(key, params) {
    const tokenEl = document.querySelector('meta[name="csrf-token"]');
    const token = tokenEl ? tokenEl.getAttribute('content') : '';
    return fetch(this.mount + '/actions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
      body: JSON.stringify({ key, params }),
      credentials: 'same-origin'
    }).then(r => r.json());
  }
}
