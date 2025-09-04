# frozen_string_literal: true

module CommandDeck
  # Controller for serving assets
  class AssetsController < BaseController
    def js
      path = asset_path("js.js")
      send_data File.read(path), type: "application/javascript; charset=utf-8", disposition: "inline"
    end

    def css
      path = asset_path("css.css")
      send_data File.read(path), type: "text/css; charset=utf-8", disposition: "inline"
    end

    private

    def asset_path(name)
      File.expand_path(File.join(__dir__, "../../../lib/command_deck/assets", name))
    end
  end
end
