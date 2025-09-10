# frozen_string_literal: true

# Minimal response body injector adapted from the web-console project (MIT License).
# It safely appends content before </body> when present and adjusts Content-Length.
module CommandDeck
  # Tiny middleware that injects a tiny floating UI into HTML responses.
  class Injector
    def initialize(body, headers)
      @body = "".dup
      body.each { |part| @body << part }
      body.close if body.respond_to?(:close)
      @headers = headers
    end

    def inject(content)
      @headers[Rack::CONTENT_LENGTH] = (@body.bytesize + content.bytesize).to_s if @headers[Rack::CONTENT_LENGTH]

      [
        if (position = @body.rindex("</body>"))
          [@body.insert(position, content)]
        else
          [@body << content]
        end,
        @headers
      ]
    end
  end
end
