class HeartbeatController < ActionController::API
  include HTTParty

  def ping
    render body: "PONG"
  end

  def healthcheck
    checks = {
        teacher_training_api: api_alive?,
    }

    render status: (checks.values.all? ? :ok : :bad_gateway), json: {
      checks: checks,
    }
  end

private

  def api_alive?
    response = HeartbeatController.get("#{Settings.teacher_training_api.base_url}/healthcheck")
    response.success?
  rescue StandardError
    false
  end
end