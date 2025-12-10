# frozen_string_literal: true

module CommandDeck
  # Controller for executing actions
  class ActionsController < BaseController
    def create
      key = params[:key].to_s
      begin
        result = Executor.call(key: key, params: params[:params], request: request)
        render json: { ok: true, result: result }
      rescue ArgumentError => e
        render json: { ok: false, error: e.message }, status: :not_found
      rescue StandardError => e
        render json: { ok: false, error: e.message, backtrace: e.backtrace.take(8) }, status: :internal_server_error
      end
    end
  end
end
