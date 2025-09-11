import { el } from '../core/dom.js';
import { store } from '../core/store.js';
import { PositionManager } from './overlay/position_manager.js';
import { ThemeManager } from './overlay/theme_manager.js';
import { ResultView } from './overlay/result_view.js';
import { ActionsView } from './overlay/actions_view.js';
import { HeaderView } from './overlay/header_view.js';
import { TabsView } from './overlay/tabs_view.js';

export class Overlay {
  constructor({ mount, panelsApi, actionsApi }) {
    this.mount = mount;
    this.panelsApi = panelsApi;
    this.actionsApi = actionsApi;
    this._loaded = false;
  }

  refreshCurrentTab() {
    this.panelsApi.fetchPanels().then((data) => {
      const panels = (data && data.panels) || [];
      this.panels = panels;
      if (this.panelSelector) this.panelSelector.setPanels(this.panels);
      const panel = this.panels.find(p => p.key === this.currentPanelKey) || this.panels[0];
      if (!panel) return;
      if (this.panelSelector) this.panelSelector.setActiveKey(panel.key);
      this.renderTabs(panel, this.currentTabIndex || 0);
    }).catch(() => {/* ignore refresh errors */});
  }

  init() {
    if (this._loaded) return; this._loaded = true;
    this.toggle = el('div', { id: 'command-deck-toggle', title: 'Command Deck' }, ['CD']);
    this.panel  = el('div', { id: 'command-deck-panel', style: { display: 'none' } });
    this.toggle.setAttribute('data-turbo-permanent', '');
    this.panel.setAttribute('data-turbo-permanent', '');
    this.toggle.setAttribute('data-turbolinks-permanent', '');
    this.panel.setAttribute('data-turbolinks-permanent', '');

    this.headerView = new HeaderView();
    this.tabsView = new TabsView((tab, i) => { this.currentTabIndex = i; this.renderActions(tab); });
    this.actionsWrap = el('div', { id: 'cd-actions-wrap' });
    this.resultView = new ResultView();
    this.actionsView = new ActionsView({
      getCurrentPanelKey: () => this.currentPanelKey,
      actionsApi: this.actionsApi,
      onRunning: () => this.resultView.setRunning(),
      onResult: (res) => this.resultView.setResult(res),
      onAfterRun: () => this.refreshCurrentTab()
    });

    this.headerView.mount(this.panel);
    this.tabsView.mount(this.panel);
    this.panel.appendChild(this.actionsWrap);
    this.resultView.mount(this.panel);

    this.actionsView.mount(this.actionsWrap);

    document.body.appendChild(this.toggle);
    document.body.appendChild(this.panel);

    this.toggle.addEventListener('click', () => {
      this.panel.style.display = (this.panel.style.display === 'none' || !this.panel.style.display) ? 'block' : 'none';
    });

    this.position = new PositionManager(this.toggle, this.panel);
    this.position.set(this.position.load());

    this.theme = new ThemeManager(this.toggle, this.panel);
    this.theme.set(this.theme.load());
  }

  attachSettings(dropdown) {
    const headerRight = this.panel.querySelector('#cd-header-right');
    dropdown.mount(headerRight);
    if (this.theme) dropdown.setTheme && dropdown.setTheme(this.theme.load());
  }

  attachPanelSelector(selector) {
    this.panelSelector = selector;
    const headerRight = this.panel.querySelector('#cd-header-right');
    selector.mount(headerRight);
  }

  loadPanels() {
    return this.panelsApi.fetchPanels().then(data => this.setPanels(data));
  }

  setPanels(data) {
    if (this.tabsView && this.tabsView.root) this.tabsView.root.textContent = '';
    this.actionsWrap.textContent = '';
    this.panels = (data && data.panels) || [];
    if (!this.panels.length) {
      if (this.tabsView && this.tabsView.root) {
        this.tabsView.root.appendChild(el('div', null, ['No panels defined. Add files under app/command_deck/**/*.rb']))
      }
      return;
    }
    if (this.panelSelector) {
      this.panelSelector.setPanels(this.panels);
    }
    const saved = store.get('panel-key');
    const exists = this.panels.find(p => p.key === saved);
    const key = exists ? saved : this.panels[0].key;
    this.selectPanel(key);
  }

  selectPanel(key) {
    const panel = (this.panels || []).find(p => p.key === key);
    if (!panel) return;
    this.currentPanelKey = key;
    store.set('panel-key', key);
    if (this.panelSelector) this.panelSelector.setActiveKey(key);

    const headerTitle = this.panel.querySelector('#cd-header h4');
    headerTitle.textContent = 'Command Deck';
    this.renderTabs(panel, this.currentTabIndex || 0);
  }

  renderTabs(panel, selectedIndex = 0) {
    if (this.tabsView && this.tabsView.root) this.tabsView.root.textContent = '';
    this.actionsWrap.textContent = '';
    this.currentTabIndex = selectedIndex;
    this.tabsView.setTabs((panel && panel.tabs) || [], selectedIndex);
  }

  renderActions(tab) {
    this.actionsView.setActions((tab && tab.actions) || []);
  }
}
