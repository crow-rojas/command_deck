import { onReady } from './core/dom.js';
import { PanelsApi, ActionsApi } from './core/api.js';
import { Overlay } from './ui/overlay.js';
import { SettingsDropdown } from './ui/settings_dropdown.js';

function getMount() {
  const s = document.querySelector('script[data-mount]') || document.currentScript;
  const m = s && s.getAttribute('data-mount');
  return m || '/command_deck';
}

onReady(() => {
  function ensureOverlay() {
    const existingToggle = document.getElementById('command-deck-toggle');
    const existingPanel  = document.getElementById('command-deck-panel');
    if (existingToggle && existingPanel) return;

    const mount = getMount();
    const panelsApi = new PanelsApi(mount);
    const actionsApi = new ActionsApi(mount);

    const overlay = new Overlay({ mount, panelsApi, actionsApi });
    overlay.init();

    const dropdown = new SettingsDropdown((pos) => overlay.position.set(pos));
    overlay.attachSettings(dropdown);

    overlay.loadPanels();
  }

  ensureOverlay();
});
