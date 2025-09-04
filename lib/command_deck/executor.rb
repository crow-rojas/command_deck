# frozen_string_literal: true

module CommandDeck
  # Executor for running actions
  class Executor
    def self.call(key:, params:)
      action = Registry.find_action(key)
      raise ArgumentError, "Unknown action #{key}" unless action

      coerced = coerce(action.params, params || {})
      action.block.call(coerced, {})
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
      when :boolean then boolean_true?(value)
      when :integer then integer_or_nil(value)
      else
        value&.to_s
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
