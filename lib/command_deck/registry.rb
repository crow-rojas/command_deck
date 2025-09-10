# frozen_string_literal: true

# Command Deck
module CommandDeck
  # Registry for actions and panels
  class Registry
    Action = Struct.new(:title, :key, :params, :block, keyword_init: true)
    Tab    = Struct.new(:title, :actions, keyword_init: true)
    Panel  = Struct.new(:title, :tabs, :owner, :group, :key, keyword_init: true)

    class << self
      def panels
        @panels ||= []
      end

      def clear!
        @panels = []
      end

      def panel(title, **opts, &blk)
        PanelBuilder.new(title, **opts).tap { |pb| pb.instance_eval(&blk) if blk }.build.then { panels << _1 }
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
      def initialize(title, **opts)
        @title = title
        @tabs = []
        @owner = opts[:owner]
        @group = opts[:group]
        @key   = opts[:key] || slugify(title)
      end

      def tab(title, &blk)
        @tabs << TabBuilder.new(title).tap { |tb| tb.instance_eval(&blk) if blk }.build
      end

      def build
        Panel.new(title: @title, tabs: @tabs, owner: @owner, group: @group, key: @key)
      end

      private

      def slugify(str)
        str.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      end
    end

    # Tab builder
    class TabBuilder
      def initialize(title)
        @title = title
        @actions = []
      end

      def action(title, key:, &blk)
        @actions << ActionBuilder.new(title, key).tap { |ab| ab.instance_eval(&blk) if blk }.build
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

  def self.panel(title, **opts, &blk)
    Registry.panel(title, **opts, &blk)
  end
end
