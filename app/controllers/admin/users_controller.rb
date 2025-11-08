class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.includes(:division).order(:last_name, :first_name, :email)
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      flash[:notice] = "User created."
      redirect_to admin_user_path(@user)
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # If password is blank, don’t try to change it
    if user_params[:password].blank?
      cleaned_params = user_params.except(:password, :password_confirmation)
    else
      cleaned_params = user_params
    end

    if @user.update(cleaned_params)
      flash[:notice] = "User updated."
      redirect_to admin_user_path(@user)
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      flash[:alert] = "You cannot delete your own account."
    else
      @user.destroy
      flash[:notice] = "User deleted."
    end

    redirect_to admin_users_path
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # 🔑 make is_apprentice + all OJT fields editable here
  def user_params
    params.require(:user).permit(
      :email,
      :password,
      :password_confirmation,
      :first_name,
      :last_name,
      :division_id,
      :role,
      :is_apprentice,
      :uaojt_username,
      :uaojt_password,             # virtual accessor, goes to encrypted column
      :uaojt_hours_rep_id,
      :uaojt_apprenticeship_year,
      :uaojt_school_start,
      :uaojt_school_end
    )
  end
end
