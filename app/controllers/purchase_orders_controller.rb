class PurchaseOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work_order, only: [:new, :create, :index]
  before_action :set_purchase_order, only: [:show]

  def index
    @purchase_orders =
      if @work_order
        @work_order.purchase_orders.order(created_at: :desc)
      else
        PurchaseOrder.includes(:work_order).order(created_at: :desc)
      end
  end

  def show
  end

  def new
    @purchase_order = @work_order.purchase_orders.build
  end

  def create
    @purchase_order = @work_order.purchase_orders.build(purchase_order_params)
    @purchase_order.created_by = current_user

    if @purchase_order.save
      redirect_to @work_order, notice: "Purchase order #{@purchase_order.number} created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_work_order
    @work_order = WorkOrder.find(params[:work_order_id]) if params[:work_order_id].present?
  end

  def set_purchase_order
    @purchase_order = PurchaseOrder.find(params[:id])
  end

  def purchase_order_params
    params.require(:purchase_order).permit(:vendor_name, :total_amount, :status, :notes)
  end
end
