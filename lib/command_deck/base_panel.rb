# frozen_string_literal: true

module CommandDeck
  # Base class for panel definitions.
  #
  # Panels can be defined anywhere under a `command_deck` directory.
  # The gem will auto-discover panels in:
  #   - app/command_deck/**/*.rb
  #   - packs/**/command_deck/**/*.rb
  #
  # Use descriptive namespaces that match your project structure.
  #
  # Example in app/command_deck/panels/global.rb:
  #   module CommandDeck::Panels
  #     class Global < CommandDeck::BasePanel
  #       panel "Global Tools" do
  #         tab "Update" do
  #           action "Do Something", key: "global.do_something" do
  #             perform { |params, ctx| { ok: true } }
  #           end
  #         end
  #       end
  #     end
  #   end
  class BasePanel
    class << self
      def panel(title, **opts, &block)
        @panel_definition = { title: title, opts: opts, block: block }
      end

      def register!
        return unless @panel_definition

        Registry.panel(
          @panel_definition[:title],
          **@panel_definition[:opts],
          &@panel_definition[:block]
        )
      end

      def inherited(subclass)
        super
        CommandDeck.register_panel_class(subclass)
      end
    end
  end
end
