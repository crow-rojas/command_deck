# frozen_string_literal: true

# Command Deck
module CommandDeck
  # Registry for actions and panels
  class Registry
    Action = Struct.new(:title, :key, :params, :block, keyword_init: true)
    Tab    = Struct.new(:title, :actions, keyword_init: true)
    Panel  = Struct.new(:title, :tabs, keyword_init: true)

    class << self
      def panels
        @panels ||= []
      end

      def clear!
        @panels = []
      end

      def panel(title, &blk)
        PanelBuilder.new(title).tap { _1.instance_eval(&blk) }.build.then { panels << _1 }
      end

      def find_action(key)
        panels.each do |p|
          p.tabs.each do |t|
            t.actions.each do |a|
              return a if a.key == key
            end
          end
        end
        nil
      end
    end

    # Panel builder
    class PanelBuilder
      def initialize(title)
        @title = title
        @tabs = []
      end

      def tab(title, &blk)
        @tabs << TabBuilder.new(title).tap { _1.instance_eval(&blk) }.build
      end

      def build
        Panel.new(title: @title, tabs: @tabs)
      end
    end

    # Tab builder
    class TabBuilder
      def initialize(title)
        @title = title
        @actions = []
      end

      def action(title, key:, &blk)
        @actions << ActionBuilder.new(title, key).tap { _1.instance_eval(&blk) }.build
      end

      def build
        Tab.new(title: @title, actions: @actions)
      end
    end

    # Action builder
    class ActionBuilder
      def initialize(title, key)
        @title  = title
        @key    = key
        @params = []
        @block  = nil
      end

      def param(name, type, **opts)
        @params << { name: name, type: type, **opts }
      end

      def perform(&block)
        @block = block
      end

      def build
        Action.new(title: @title, key: @key, params: @params, block: @block)
      end
    end
  end

  def self.panel(title, &blk)
    Registry.panel(title, &blk)
  end
end
