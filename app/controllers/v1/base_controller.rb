class V1::BaseController < ApplicationController
  
  rescue_from ::ActiveRecord::ActiveRecordError, with: :record_exception
  rescue_from ::ActionController::ParameterMissing, with: :params_missing

  def auth_user
    # not login
    render json: message_error(
      "Please sign in", 
      "Please sign in" 
    ) and return unless current_user

    # not have api token on header
    render json: message_error(
      "Please send api token on header", 
      "Please send api token on header" 
    ) and return unless api_token?

    # Token client not match with session on server
    render json: message_error(
      "api token invalid", 
      "api token invalid" 
    ) and return unless same_token?

    # Token expired
    render json: message_error(
      "api token expired", 
      "api token expired"
    ) and return if token_expire?
  end

  def message_success(message, content)
    ResponseTemplate.success(message, content)
  end

  def message_error(message, content)
    ResponseTemplate.error(message, content)
  end

  private
  # Check has api-token on header
  def api_token?
    request.headers["Api-Token"].present?
  end

  # Get api token from client request
  def api_token
    request.headers["Api-Token"]
  end

  # Check token in session map with token send from client
  def same_token?
    current_user.api_token == api_token
  end

  # Check token time expired
  def token_expire?
    current_user.expire_at < Time.current.to_i
  end

  def record_exception(exception)
    render json: message_error(
      exception.message, 
      (defined? exception.record).present? ?  exception.record.errors.to_hash : exception.message
    ) and return
  end

  def params_missing(exception)
    render json: message_error("You missing params", exception.param) and return
  end

  protected
  def permit_params(array_permit)
    params_permited = params_permited(array_permit)
    raise ActionController::ParameterMissing.new(missing_params(array_permit, params_permited.keys)) unless permit?(params_permited.keys, array_permit)
    return params_permited
  end

  def params_permited(array_permit)
    params.permit(array_permit)
  end

  def missing_params(array_require, array_permited)
    array_require - array_permited
  end

  def permit?(array_require, array_permited)
    array_require == array_permited
  end
end
