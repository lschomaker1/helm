# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :set_user, only: [:show]

  def index
    @users = policy_scope(User).includes(:division)
    authorize User
  end

  def show
    authorize @user
  end

  def new
    @user = User.new
    authorize @user
    load_divisions_and_roles
  end

  def create
    @user = User.new(user_params)
    authorize @user

    if @user.save
      redirect_to admin_users_path, notice: "User account created."
    else

      load_divisions_and_roles
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def load_divisions_and_roles
    @divisions = Division.order(:name)
    @roles     = User.roles.keys
  end

  def user_params
    params.require(:user).permit(
      :email,
      :password,
      :password_confirmation,
      :first_name,
      :last_name,
      :role,
      :division_id
    )
  end
end
