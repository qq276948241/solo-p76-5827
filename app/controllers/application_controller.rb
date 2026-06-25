class ApplicationController < ActionController::API
  include ActionController::Serialization

  before_action :authenticate_request

  attr_reader :current_user

  private

  def authenticate_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    decoded = JsonWebToken.decode(header)
    if decoded
      @current_user = User.find_by(id: decoded[:user_id])
    end
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end

  def authorize_teacher!
    render json: { error: 'Forbidden - Teacher access required' }, status: :forbidden unless current_user&.teacher? || current_user&.admin?
  end

  def authorize_member!
    render json: { error: 'Forbidden - Member access required' }, status: :forbidden unless current_user&.member? || current_user&.admin?
  end
end
