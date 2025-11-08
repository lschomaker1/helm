# app/controllers/customers_controller.rb
class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]

  def index
    @customers = policy_scope(Customer).where(division: @current_division)
  end

  def show
    authorize @customer
  end

  def new
    @customer = Customer.new(division: @current_division)
    authorize @customer
  end

  def create
    @customer = Customer.new(customer_params)
    @customer.division ||= @current_division

    authorize @customer

    if @customer.save
      redirect_to @customer, notice: "Customer created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @customer
  end

  def update
    authorize @customer

    if @customer.update(customer_params)
      redirect_to @customer, notice: "Customer updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @customer
    if @customer.work_orders.exists?
      redirect_to customers_path, alert: "Cannot delete this customer — work orders are still associated."
    else
      @customer.destroy
      redirect_to customers_path, notice: "Customer deleted."
    end
  rescue ActiveRecord::InvalidForeignKey
    redirect_to customers_path, alert: "Cannot delete this customer — it has linked work orders."
  end


  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(
      :name,
      :address,
      :city,
      :state,
      :postal_code,
      :phone,
      :email,
      :contact_name,
      :billing_address,
      :shipping_address,
      :notes,
      :division_id
    )
  end
end
