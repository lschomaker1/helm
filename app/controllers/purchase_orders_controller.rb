# app/controllers/purchase_orders_controller.rb
class PurchaseOrdersController < ApplicationController
  before_action :set_purchase_order, only: %i[show edit update destroy]

  def index
    @purchase_orders = policy_scope(PurchaseOrder).where(division: @current_division)
  end

  def show
    authorize @purchase_order
  end

  def new
    @purchase_order = PurchaseOrder.new(
      division: @current_division,
      created_by: current_user,
      status: "draft"
    )
    authorize @purchase_order
    load_work_orders
  end

  def create
    @purchase_order = PurchaseOrder.new(purchase_order_params)
    @purchase_order.division = @current_division
    @purchase_order.created_by = current_user
    authorize @purchase_order

    if @purchase_order.save
      redirect_to @purchase_order, notice: "Purchase order created."
    else
      load_work_orders
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @purchase_order
    load_work_orders
  end

  def update
    authorize @purchase_order
    if @purchase_order.update(purchase_order_params)
      redirect_to @purchase_order, notice: "Purchase order updated."
    else
      load_work_orders
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @purchase_order
    @purchase_order.destroy
    redirect_to purchase_orders_path, notice: "Purchase order deleted."
  end

  private

  def set_purchase_order
    @purchase_order = PurchaseOrder.find(params[:id])
  end

  def load_work_orders
    @work_orders = WorkOrder.where(division: @current_division)
  end

  def purchase_order_params
    params.require(:purchase_order).permit(
      :number, :vendor_name, :total_amount, :status, :work_order_id
    )
  end
end
