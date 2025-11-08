# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :set_current_division

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_current_division
    @current_division = current_user&.division
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referer || root_path)
  end
end
