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

  def test_closes_body_if_responds_to_close
    html = "<html><body></body></html>"
    closable_body = Class.new do
      def initialize(content)
        @content = content
        @closed = false
      end

      def each
        yield @content
      end

      def close
        @closed = true
      end

      def closed?
        @closed
      end
    end.new(html)

    headers = { Rack::CONTENT_TYPE => "text/html" }
    CommandDeck::Injector.new(closable_body, headers)

    assert_predicate closable_body, :closed?
  end

  def test_does_not_update_content_length_if_not_present
    html = "<html><body></body></html>"
    headers = { Rack::CONTENT_TYPE => "text/html" }
    body = [html]

    _injected, new_headers = CommandDeck::Injector.new(body, headers).inject("<em>CD</em>")

    refute new_headers.key?(Rack::CONTENT_LENGTH)
  end

  def test_handles_multiple_body_parts
    headers = { Rack::CONTENT_TYPE => "text/html" }
    body = ["<html>", "<body>", "<p>Hi</p>", "</body>", "</html>"]

    injected, = CommandDeck::Injector.new(body, headers).inject("<span>CD</span>")
    out = injected.join

    assert_includes out, "<span>CD</span></body>"
  end
end
