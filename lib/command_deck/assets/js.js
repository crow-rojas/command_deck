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

  onReady(function(){
    if (window.__COMMAND_DECK_LOADED__) return;
    window.__COMMAND_DECK_LOADED__ = true;

    var mount = getMount();

    var toggle = el('div', { id: 'command-deck-toggle', title: 'Command Deck' }, ['CD']);
    var panel  = el('div', { id: 'command-deck-panel', style: { display: 'none' } });

    var header = el('h4', null, ['Command Deck']);
    var tabsWrap = el('div', { id: 'cd-tabs-wrap' });
    var actionsWrap = el('div', { id: 'cd-actions-wrap' });
    var resultPre = el('pre', { id: 'command-deck-output' });

    panel.appendChild(header);
    panel.appendChild(tabsWrap);
    panel.appendChild(actionsWrap);
    panel.appendChild(resultPre);

    document.body.appendChild(toggle);
    document.body.appendChild(panel);

    toggle.addEventListener('click', function(){
      panel.style.display = (panel.style.display === 'none' || !panel.style.display) ? 'block' : 'none';
    });

    function setRunning(){ resultPre.textContent = 'Running...'; }
    function setResult(obj){ resultPre.textContent = jsonPretty(obj); }

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

    fetchPanels().then(renderPanels).catch(function(e){ setResult({ ok: false, error: String(e) }); });
  });
})();
