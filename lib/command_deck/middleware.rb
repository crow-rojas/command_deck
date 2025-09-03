# frozen_string_literal: true

require "rack"
require_relative "injector"

module CommandDeck
  # Dev-only middleware that injects a tiny floating UI into HTML responses.
  class Middleware
    class << self
      attr_accessor :mount_point
    end
    self.mount_point = "/command_deck"

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)

      begin
        return [status, headers, body] unless html_response?(headers)
        return [status, headers, body] if engine_request?(env)

        snippet = overlay_snippet
        body, headers = Injector.new(body, headers).inject(snippet)
        [status, headers, body]
      rescue StandardError => _e
        # Fail open: on any injection error, return original response
        [status, headers, body]
      end
    end

    private

    def html_response?(headers)
      headers[Rack::CONTENT_TYPE].to_s.include?("html")
    end

    def engine_request?(env)
      path = env["PATH_INFO"].to_s
      path.start_with?(self.class.mount_point)
    end

    def overlay_snippet
      mp = self.class.mount_point
      # Minimal inline CSS/HTML/JS to toggle a tiny drawer and call the engine endpoint.
      <<~HTML
        <!-- Command Deck (POC) injected overlay -->
        <style>
          #command-deck-toggle{position:fixed;z-index:2147483000;right:16px;bottom:16px;width:44px;height:44px;border-radius:22px;background:#111;color:#fff;display:flex;align-items:center;justify-content:center;font:600 14px system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;box-shadow:0 6px 20px rgba(0,0,0,.25);cursor:pointer;}
          #command-deck-panel{position:fixed;z-index:2147483000;right:16px;bottom:72px;width:340px;max-width:90vw;background:#fff;color:#111;border-radius:10px;box-shadow:0 12px 40px rgba(0,0,0,.28);padding:12px 12px 10px;border:1px solid rgba(0,0,0,.06)}
          #command-deck-panel *{font:500 13px/1.35 system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif}
          #command-deck-panel h4{margin:0 0 8px;font-size:14px}
          #command-deck-panel label{display:block;margin:6px 0 2px;color:#555}
          #command-deck-panel input{width:100%;box-sizing:border-box;padding:8px 10px;border:1px solid #ddd;border-radius:6px}
          #command-deck-panel button{margin-top:10px;padding:8px 10px;border:0;border-radius:6px;background:#0d6efd;color:#fff;cursor:pointer}
          #command-deck-output{white-space:pre-wrap;background:#0b102114;color:#0b1d30;border-radius:6px;padding:8px;margin-top:10px;max-height:180px;overflow:auto}
        </style>
        <div id="command-deck-toggle" title="Command Deck">CD</div>
        <div id="command-deck-panel" style="display:none">
          <h4>Command Deck • General upsert (POC)</h4>
          <label>Name</label>
          <input id="cd-name" placeholder="e.g. prueba" />
          <label>Value</label>
          <input id="cd-value" placeholder="e.g. true" />
          <button id="cd-run">Update General</button>
          <pre id="command-deck-output"></pre>
        </div>
        <script>
        (function(){
          var mp = '#{mp.gsub("'", "\\'")}';
          var toggle = document.getElementById('command-deck-toggle');
          var panel  = document.getElementById('command-deck-panel');
          var nameI  = document.getElementById('cd-name');
          var valueI = document.getElementById('cd-value');
          var runBtn = document.getElementById('cd-run');
          var out    = document.getElementById('command-deck-output');

          if (!toggle || !panel) return;

          toggle.addEventListener('click', function(){
            panel.style.display = (panel.style.display === 'none' || !panel.style.display) ? 'block' : 'none';
          });

          runBtn.addEventListener('click', function(){
            var tokenEl = document.querySelector('meta[name="csrf-token"]');
            var token = tokenEl ? tokenEl.getAttribute('content') : '';
            var payload = { key: 'general.upsert', params: { name: nameI.value, value: valueI.value } };

            out.textContent = 'Running...';

            fetch(mp + '/actions', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
              body: JSON.stringify(payload),
              credentials: 'same-origin'
            }).then(function(resp){
              return resp.text().then(function(text){
                try { return { status: resp.status, json: JSON.parse(text) }; }
                catch(_) { return { status: resp.status, json: { ok:false, error: text } }; }
              });
            }).then(function(res){
              out.textContent = JSON.stringify(res.json, null, 2);
            }).catch(function(err){
              out.textContent = 'Request failed: ' + (err && err.message || String(err));
            });
          });
        })();
        </script>
        <!-- /Command Deck injected overlay -->
      HTML
    end
  end
end
