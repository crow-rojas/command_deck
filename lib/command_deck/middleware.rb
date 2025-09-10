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

        body, headers = Injector.new(body, headers).inject(overlay_snippet)
        [status, headers, body]
      rescue StandardError
        # Fail open: on any injection error, return original response
        [status, headers, body]
      end
    end

    private

    def html_response?(headers)
      ctype = headers[Rack::CONTENT_TYPE].to_s
      return true if ctype.empty?

      ctype.include?("html")
    end

    def engine_request?(env)
      path = env["PATH_INFO"].to_s
      path.start_with?(self.class.mount_point)
    end

    def overlay_snippet
      mp = self.class.mount_point
      <<~HTML
        <!-- Command Deck assets (ESM) -->
        <link rel="stylesheet" href="#{mp}/assets/css/main.css" />
        <script type="module" src="#{mp}/assets/js/main.js" data-mount="#{mp}"></script>
        <!-- /Command Deck assets -->
      HTML
    end
  end
end
