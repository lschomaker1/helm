class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  private

  def require_admin!
    unless current_user&.admin?
      flash[:alert] = "You must be an administrator to access that page."
      redirect_to root_path
    end
  end
end
