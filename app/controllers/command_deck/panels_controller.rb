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
      {
        name: param[:name],
        type: param[:type].to_s,
        label: param[:label] || param[:name].to_s.tr("_", " ").capitalize,
        required: (param.key?(:required) ? param[:required] : true)
      }
    end
  end
end
