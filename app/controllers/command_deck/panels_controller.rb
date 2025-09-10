# frozen_string_literal: true

module CommandDeck
  # Controller for serving panels
  class PanelsController < BaseController
    def index
      render json: { panels: serialize_panels }
    end

    private

    def serialize_panels
      Registry.panels.map { |panel| serialize_panel(panel) }
    end

    def serialize_panel(panel)
      {
        key: panel.key,
        title: panel.title,
        owner: panel.owner,
        group: panel.group,
        tabs: serialize_tabs(panel.tabs)
      }
    end

    def serialize_tabs(tabs)
      tabs.map { |tab| serialize_tab(tab) }
    end

    def serialize_tab(tab)
      { title: tab.title, actions: serialize_actions(tab.actions) }
    end

    def serialize_actions(actions)
      actions.map { |action| serialize_action(action) }
    end

    def serialize_action(action)
      { title: action.title, key: action.key, params: serialize_params(action.params) }
    end

    def serialize_params(params)
      (params || []).map { |p| serialize_param(p) }
    end

    def serialize_param(param)
      base = base_param(param)

      choices = extract_choices(param)
      if choices
        base[:choices] = normalize_choices(choices)
        base[:include_blank] = param[:include_blank] if param.key?(:include_blank)
      end

      base[:return] = param[:return] if param.key?(:return)
      base
    end

    def normalize_choices(choices)
      arrayify(choices).map { |item| normalize_choice_item(item) }
    end

    def base_param(param)
      {
        name: param[:name],
        type: param[:type].to_s,
        label: param[:label] || param[:name].to_s.tr("_", " ").capitalize,
        required: param.key?(:required) ? param[:required] : false
      }
    end

    def extract_choices(param)
      return param[:options] if param.key?(:options)

      collection = param[:collection]
      collection.respond_to?(:call) ? collection.call : nil
    end

    def arrayify(obj)
      obj.is_a?(Array) ? obj : obj.to_a
    end

    def normalize_choice_item(item)
      return normalize_choice_hash(item)  if item.is_a?(Hash)
      return normalize_choice_array(item) if item.is_a?(Array)

      normalize_choice_default(item)
    end

    def normalize_choice_hash(item)
      out = {}
      out[:label] = item[:label].to_s if item.key?(:label)
      out[:value] = item[:value] if item.key?(:value)
      out[:meta]  = item[:meta]  if item.key?(:meta)
      out
    end

    def normalize_choice_array(item)
      return normalize_choice_default(item) if item.size < 2

      { label: item[0].to_s, value: item[1] }
    end

    def normalize_choice_default(item)
      { label: item.to_s, value: item }
    end
  end
end
