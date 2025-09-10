# frozen_string_literal: true

require "test_helper"
require "command_deck/injector"

class InjectorTest < Minitest::Test
  def test_injects_before_body_and_updates_content_length
    html = "<html><head></head><body><p>Hi</p></body></html>"
    headers = { Rack::CONTENT_TYPE => "text/html; charset=utf-8", Rack::CONTENT_LENGTH => html.bytesize.to_s }
    body = StringIO.new(html)

    injected, new_headers = CommandDeck::Injector.new([body.string], headers).inject("<span>CD</span>")
    out = injected.join

    assert_includes out, "<span>CD</span></body>"
    assert_equal out.bytesize.to_s, new_headers[Rack::CONTENT_LENGTH]
  end

  def test_appends_when_no_body_tag
    html = "<html><head></head><div>No body</div></html>"
    headers = { Rack::CONTENT_TYPE => "text/html" }
    body = [html]

    injected, = CommandDeck::Injector.new(body, headers).inject("<em>CD</em>")
    out = injected.join

    assert out.end_with?("<em>CD</em>")
  end
end
