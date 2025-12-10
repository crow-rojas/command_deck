# frozen_string_literal: true

module CommandDeck
  # Executor for running actions
  class Executor
    def self.call(key:, params:, request: nil)
      action = Registry.find_action(key)
      raise ArgumentError, "Unknown action #{key}" unless action

      coerced = coerce(action.params, params || {})
      ctx = request ? CommandDeck.configuration.build_context(request) : {}
      action.block.call(coerced, ctx)
    end

    def self.coerce(schema, raw)
      return {} if schema.nil? || schema.empty?

      schema.each_with_object({}) do |param, out|
        name = param[:name]
        value = raw[name] || raw[name.to_s]
        out[name] = coerce_value(param[:type], value)
      end
    end

    def self.coerce_value(type, value)
      case type
      when :boolean then coerce_boolean(value)
      when :integer then coerce_integer(value)
      when :selector then coerce_selector(value)
      else coerce_string(value)
      end
    end

    def self.coerce_boolean(value) # rubocop:disable Naming/PredicateMethod
      boolean_true?(value)
    end

    def self.coerce_integer(value)
      integer_or_nil(value)
    end

    def self.coerce_selector(value)
      return symbolize_keys_shallow(value) if value.is_a?(Hash)

      value
    end

    def self.coerce_string(value)
      value&.to_s
    end

    def self.symbolize_keys_shallow(hash)
      hash.each_with_object({}) do |(k, v), out|
        key = k.respond_to?(:to_sym) ? k.to_sym : k
        out[key] = v
      end
    end

    def self.boolean_true?(value)
      return false if value.nil?

      value == true || %w[true 1 on].include?(value.to_s.strip.downcase)
    end

    def self.integer_or_nil(value)
      return nil if value.nil? || value == ""

      value.to_i
    end
  end
end
