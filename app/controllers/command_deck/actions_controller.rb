# frozen_string_literal: true

module CommandDeck
  class ActionsController < BaseController
    def create
      key = params[:key].to_s

      unless key == "general.upsert"
        render json: { ok: false, error: "Unknown action: #{key}" }, status: :not_found and return
      end

      begin
        klass = "General".safe_constantize
        unless klass
          render json: { ok: false, error: "Model 'General' is not defined in the host app" },
                 status: :unprocessable_entity and return
        end

        columns = klass.column_names
        name_col  = if columns.include?("name")
                      "name"
                    else
                      (columns.include?("nombre") ? "nombre" : nil)
                    end
        value_col = if columns.include?("value")
                      "value"
                    else
                      (columns.include?("valor") ? "valor" : nil)
                    end

        unless name_col && value_col
          render json: { ok: false, error: "General must have name/nombre and value/valor columns" },
                 status: :unprocessable_entity and return
        end

        raw = params[:params] || {}
        name  = raw[:name].presence  || raw[:nombre]
        value = raw[:value].presence || raw[:valor]

        unless name
          render json: { ok: false, error: "Missing required param: name (or nombre)" },
                 status: :unprocessable_entity and return
        end

        record = klass.find_or_initialize_by({ name_col => name })
        record.update!({ value_col => value })

        render json: { ok: true, id: record.id, name_col => record.public_send(name_col),
                       value_col => record.public_send(value_col) }
      rescue StandardError => e
        render json: { ok: false, error: e.message, backtrace: e.backtrace.take(5) }, status: :internal_server_error
      end
    end
  end
end
