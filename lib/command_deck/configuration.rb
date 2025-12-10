# frozen_string_literal: true

# Command Deck configuration module.
# Configure context providers and other global settings here.
module CommandDeck
  # Configuration for Command Deck
  #
  # Example usage in an initializer:
  #
  #   # config/initializers/command_deck.rb
  #   CommandDeck.configure do |config|
  #     config.context_provider = ->(request) do
  #       {
  #         current_user: request.env['warden']&.user,
  #         session: request.session
  #       }
  #     end
  #   end
  class Configuration
    # A proc that receives the ActionDispatch::Request and returns a hash
    # to be passed as the `ctx` parameter in perform blocks.
    #
    # @example
    #   config.context_provider = ->(request) do
    #     { current_user: request.env['warden']&.user }
    #   end
    attr_accessor :context_provider

    def initialize
      @context_provider = ->(_request) { {} }
    end

    # Builds the context hash from the given request
    #
    # @param request [ActionDispatch::Request] the current request
    # @return [Hash] context to pass to perform blocks
    def build_context(request)
      return {} unless context_provider.respond_to?(:call)

      context_provider.call(request) || {}
    rescue StandardError => e
      Rails.logger.warn "[CommandDeck] Context provider error: #{e.message}" if defined?(Rails)
      {}
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
