# frozen_string_literal: true

module CommandDeck
  # Base controller for the Command Deck engine.
  #
  # Dev-only: requests are guarded via `ensure_development!` and CSRF is skipped
  # because forms are internal to the overlay UI and this engine is intended for
  # development environments only.
  class BaseController < ActionController::Base
    before_action :ensure_development!
    skip_forgery_protection

    private

    def ensure_development!
      head :not_found unless Rails.env.development?
    end
  end
end
