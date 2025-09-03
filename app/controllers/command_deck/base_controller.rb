# frozen_string_literal: true

module CommandDeck
  class BaseController < ActionController::Base
    # POC: dev-only
    before_action :ensure_development!

    # Simpler for the POC; we can wire CSRF later if needed.
    skip_forgery_protection

    private

    def ensure_development!
      head :not_found unless Rails.env.development?
    end
  end
end
