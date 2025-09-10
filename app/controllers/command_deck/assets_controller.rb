# frozen_string_literal: true

module CommandDeck
  # Controller for serving assets
  class AssetsController < BaseController
    def js
      rel = params[:path].presence || "main"
      ext = params[:format].presence || "js"
      rel = "#{rel}.#{ext}" unless rel.end_with?(".#{ext}")
      path = safe_asset_path("js", rel)
      return head :not_found unless path && File.file?(path)

      send_data File.binread(path), type: js_mime_for(path), disposition: "inline"
    end

    def css
      rel = params[:path].presence || "main"
      ext = params[:format].presence || "css"
      rel = "#{rel}.#{ext}" unless rel.end_with?(".#{ext}")
      path = safe_asset_path("css", rel)
      return head :not_found unless path && File.file?(path)

      send_data File.binread(path), type: "text/css; charset=utf-8", disposition: "inline"
    end

    private

    def base_assets_root
      @base_assets_root ||= File.expand_path(File.join(__dir__, "../../../lib/command_deck/assets"))
    end

    def safe_asset_path(kind, rel)
      # Prevent traversal and restrict to known roots (js/ or css/)
      rel = rel.to_s.sub(%r{^/+}, "")
      rel = rel.gsub("..", "")
      root = File.join(base_assets_root, kind)
      full = File.expand_path(File.join(root, rel))
      return nil unless full.start_with?(root)

      full
    end

    def js_mime_for(*)
      # All ESM served as application/javascript
      "application/javascript; charset=utf-8"
    end
  end
end
