import { ActionForm } from './action_form.js';

export class ActionsView {
  constructor({ getCurrentPanelKey, actionsApi, onRunning, onResult, onAfterRun }) {
    this.getCurrentPanelKey = getCurrentPanelKey;
    this.actionsApi = actionsApi;
    this.onRunning = onRunning || (() => {});
    this.onResult = onResult || (() => {});
    this.onAfterRun = onAfterRun || (() => {});
    this.container = null;
  }

  mount(container) {
    this.container = container;
  }

  setActions(actions) {
    if (!this.container) return;
    this.container.textContent = '';
    (actions || []).forEach(action => {
      const form = new ActionForm({
        action,
        getCurrentPanelKey: this.getCurrentPanelKey,
        actionsApi: this.actionsApi,
        onRunning: this.onRunning,
        onResult: this.onResult,
        onAfterRun: this.onAfterRun
      });
      form.mount(this.container);
    });
  }
}
