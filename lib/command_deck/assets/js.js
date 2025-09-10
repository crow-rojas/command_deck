(function(){
  function onReady(fn){
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', fn);
    } else {
      fn();
    }
    document.addEventListener('turbo:load', fn);
  }

  function getMount(){
    var s = document.querySelector('script[data-mount]') || document.currentScript;
    var m = s && s.getAttribute('data-mount');
    return m || '/command_deck';
  }

  function el(tag, attrs, children){
    var e = document.createElement(tag);
    if (attrs) for (var k in attrs) {
      if (k === 'style' && typeof attrs[k] === 'object') {
        Object.assign(e.style, attrs[k]);
      } else if (k === 'class') {
        e.className = attrs[k];
      } else if (k.startsWith('on') && typeof attrs[k] === 'function') {
        e.addEventListener(k.slice(2), attrs[k]);
      } else {
        e.setAttribute(k, attrs[k]);
      }
    }
    (children || []).forEach(function(c){ e.appendChild(typeof c === 'string' ? document.createTextNode(c) : c); });
    return e;
  }

  function jsonPretty(obj){ return JSON.stringify(obj, null, 2); }

  // Position management
  var POSITIONS = ['tl','tr','bl','br'];
  function loadPosition(){
    try { return localStorage.getItem('command-deck-position') || 'br'; }
    catch(_) { return 'br'; }
  }
  function savePosition(pos){
    try { localStorage.setItem('command-deck-position', pos); } catch(_) {}
  }
  function applyPosition(pos, toggle, panel){
    ['cd-pos-tl','cd-pos-tr','cd-pos-bl','cd-pos-br'].forEach(function(c){
      toggle.classList.remove(c); panel.classList.remove(c);
    });
    var cls = 'cd-pos-' + pos;
    toggle.classList.add(cls); panel.classList.add(cls);
  }

  onReady(function(){
    if (window.__COMMAND_DECK_LOADED__) return;
    window.__COMMAND_DECK_LOADED__ = true;

    var mount = getMount();

    var toggle = el('div', { id: 'command-deck-toggle', title: 'Command Deck' }, ['CD']);
    var panel  = el('div', { id: 'command-deck-panel', style: { display: 'none' } });

    var headerWrap = el('div', { id: 'cd-header' });
    var header = el('h4', null, ['Command Deck']);
    var settingsBtn = el('button', { id: 'cd-settings-btn', title: 'Settings' }, ['\u2699']); // ⚙
    headerWrap.appendChild(header);
    headerWrap.appendChild(settingsBtn);

    var settingsPanel = el('div', { id: 'cd-settings-panel', style: { display: 'none' } });
    var settingsTitle = el('div', { class: 'cd-settings-title' }, ['Position']);
    var menu = el('div', { class: 'cd-menu' });
    var tabsWrap = el('div', { id: 'cd-tabs-wrap' });
    var actionsWrap = el('div', { id: 'cd-actions-wrap' });
    var resultPre = el('pre', { id: 'command-deck-output' });

    panel.appendChild(headerWrap);
    // Settings dropdown with position controls
    var currentPos = loadPosition();
    var btnMap = {};
    [['tl','\u2196  Top-left'], ['tr','\u2197  Top-right'], ['bl','\u2199  Bottom-left'], ['br','\u2198  Bottom-right']].forEach(function(pair){
      var key = pair[0], label = pair[1];
      var item = el('button', { class: 'cd-menu-item', 'data-pos': key }, [label]);
      item.addEventListener('click', function(e){ e.stopPropagation(); setPos(key); settingsPanel.style.display = 'none'; settingsBtn.classList.remove('open'); });
      btnMap[key] = item;
      menu.appendChild(item);
    });
    settingsPanel.appendChild(settingsTitle);
    settingsPanel.appendChild(menu);
    headerWrap.appendChild(settingsPanel);
    panel.appendChild(tabsWrap);
    panel.appendChild(actionsWrap);
    panel.appendChild(resultPre);

    document.body.appendChild(toggle);
    document.body.appendChild(panel);

    toggle.addEventListener('click', function(){
      panel.style.display = (panel.style.display === 'none' || !panel.style.display) ? 'block' : 'none';
    });

    settingsBtn.addEventListener('click', function(e){
      e.stopPropagation();
      var willOpen = (settingsPanel.style.display === 'none' || !settingsPanel.style.display);
      settingsPanel.style.display = willOpen ? 'block' : 'none';
      settingsBtn.classList.toggle('open', willOpen);
    });
    settingsPanel.addEventListener('click', function(e){ e.stopPropagation(); });
    document.addEventListener('click', function(){
      settingsPanel.style.display = 'none';
      settingsBtn.classList.remove('open');
    });

    function setRunning(){ resultPre.textContent = 'Running...'; }
    function setResult(obj){ resultPre.textContent = jsonPretty(obj); }

    function setPos(pos){
      if (POSITIONS.indexOf(pos) === -1) return;
      savePosition(pos);
      applyPosition(pos, toggle, panel);
      Object.keys(btnMap).forEach(function(k){ btnMap[k].classList.toggle('active', k === pos); });
    }

    function fetchPanels(){
      return fetch(mount + '/panels', { credentials: 'same-origin' })
        .then(function(r){ return r.json(); });
    }

    function submitAction(key, params){
      var tokenEl = document.querySelector('meta[name="csrf-token"]');
      var token = tokenEl ? tokenEl.getAttribute('content') : '';
      return fetch(mount + '/actions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
        body: JSON.stringify({ key: key, params: params }),
        credentials: 'same-origin'
      }).then(function(resp){ return resp.json(); });
    }

    function renderPanels(data){
      tabsWrap.textContent = '';
      actionsWrap.textContent = '';

      var panels = (data && data.panels) || [];
      if (!panels.length) {
        tabsWrap.appendChild(el('div', null, ['No panels defined. Add files under app/command_deck/**/*.rb']));
        return;
      }

      var panel0 = panels[0];
      header.textContent = 'Command Deck • ' + panel0.title;

      panel0.tabs.forEach(function(tab, i){
        var btn = el('button', { class: 'cd-tab-btn' }, [tab.title]);
        btn.addEventListener('click', function(){ renderActions(tab); });
        tabsWrap.appendChild(btn);
        if (i === 0) renderActions(tab);
      });
    }

    function renderActions(tab){
      actionsWrap.textContent = '';
      (tab.actions || []).forEach(function(action){
        var box = el('div', { class: 'cd-action' });
        box.appendChild(el('div', { class: 'cd-action-title' }, [action.title]));
        var form = el('div', { class: 'cd-form' });

        var inputs = {};
        (action.params || []).forEach(function(p){
          var label = el('label', null, [p.label || p.name]);
          var input;
          if (p.type === 'boolean') {
            input = el('input', { type: 'checkbox' });
          } else if (p.type === 'integer') {
            input = el('input', { type: 'number', step: '1' });
          } else {
            input = el('input', { type: 'text' });
          }
          form.appendChild(label);
          form.appendChild(input);
          inputs[p.name] = input;
        });

        var run = el('button', { class: 'cd-run' }, ['Run']);
        run.addEventListener('click', function(){
          var payload = {};
          Object.keys(inputs).forEach(function(k){
            var inp = inputs[k];
            if (inp.type === 'checkbox') payload[k] = !!inp.checked;
            else payload[k] = inp.value;
          });
          setRunning();
          submitAction(action.key, payload).then(setResult).catch(function(e){ setResult({ ok:false, error: String(e) }); });
        });
        form.appendChild(run);

        box.appendChild(form);
        actionsWrap.appendChild(box);
      });
    }

    // Initialize position
    setPos(currentPos);

    fetchPanels().then(renderPanels).catch(function(e){ setResult({ ok: false, error: String(e) }); });
  });
})();
