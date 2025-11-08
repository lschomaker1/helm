class WorkOrderCallsController < ApplicationController
  before_action :set_work_order
  before_action :set_work_order_call, only: [:show]

  def show
    authorize @work_order_call

    # Time entries by this technician on this WO
    @time_entries = @work_order.time_entries
                               .where(user_id: @work_order_call.technician_id)
                               .order(started_at: :desc)
  end

  def new
    @work_order_call = @work_order.work_order_calls.build
    authorize @work_order_call
    load_technicians
  end

  def create
    @work_order_call = @work_order.work_order_calls.build(work_order_call_params)
    authorize @work_order_call

    if @work_order_call.save
      redirect_to work_order_path(@work_order), notice: "Technician call created."
    else
      load_technicians
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_work_order
    @work_order = WorkOrder.find(params[:work_order_id])
  end

  def set_work_order_call
    @work_order_call = @work_order.work_order_calls.find(params[:id])
  end

  def load_technicians
    @technicians = User.where(division: @current_division, role: "technician")
  end

  def work_order_call_params
    params.require(:work_order_call).permit(:technician_id)
  end
end
