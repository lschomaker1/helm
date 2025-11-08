class WorkOrdersController < ApplicationController
  before_action :set_work_order, only: %i[show edit update destroy complete invoice]

  def index
    authorize WorkOrder

    scoped = policy_scope(WorkOrder)

    case current_user.role
    when "technician"
      @open_calls = scoped.where(assigned_to_id: current_user.id, status: "open").order(priority: :asc)
      @incomplete_calls = scoped.where(assigned_to_id: current_user.id, status: "in_progress").order(priority: :asc)
      @pm_calls = scoped.where(assigned_to_id: current_user.id, status: "pm").order(priority: :asc)
    else
      @work_orders = scoped
                       .includes(:customer, :division, :assigned_to)
                       .order(created_at: :desc)
    end
  end

  def show
    authorize @work_order
    @time_entries = @work_order.time_entries.includes(:user).order(started_at: :desc)
  end

  def new
    @work_order = WorkOrder.new(
      division:   @current_division,
      created_by: current_user,
      status:     "open"
    )
    authorize @work_order
    load_customers_and_technicians
  end

  def create
    @work_order = WorkOrder.new(work_order_params)
    @work_order.division   ||= @current_division
    @work_order.created_by ||= current_user

    authorize @work_order
    load_customers_and_technicians

    if @work_order.save
      redirect_to @work_order, notice: "Work order created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @work_order
    load_customers_and_technicians
  end

  def update
    authorize @work_order
    load_customers_and_technicians

    if @work_order.update(work_order_params)
      redirect_to @work_order, notice: "Work order updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /work_orders/:id
  def destroy
    authorize @work_order

    if @work_order.time_entries.exists?
      redirect_to work_orders_path, alert: "Cannot delete this work order — it has time entries logged."
    else
      @work_order.destroy
      redirect_to work_orders_path, notice: "Work order deleted."
    end
  end

  # PATCH /work_orders/:id/complete
  def complete
    authorize @work_order

    @work_order.status       = "completed"
    @work_order.completed_at ||= Time.current

    @work_order.finalize_invoice_totals!

    redirect_to work_order_path(@work_order), notice: "Work order marked as completed and invoice totals calculated."
  end

  # GET /work_orders/:id/invoice.pdf
  def invoice
    authorize @work_order

    @work_order.ensure_invoice_number
    @work_order.save! if @work_order.changed?

    respond_to do |format|
      format.pdf do
        pdf = WorkOrderInvoicePdf.new(@work_order)
        send_data pdf.render,
                  filename: "Invoice-#{@work_order.invoice_number || @work_order.number}.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
      format.html do
        redirect_to @work_order, alert: "Use the PDF format to download the invoice."
      end
    end
  end

  private

  def set_work_order
    @work_order = WorkOrder.find(params[:id])
  end

  def load_customers_and_technicians
    @customers   = Customer.where(division: @current_division)
    @technicians = User.where(division: @current_division, role: "technician")
  end

  def work_order_params
    params.require(:work_order).permit(
      :title,
      :description,
      :status,
      :priority,
      :scheduled_at,
      :completed_at,
      :location,
      :customer_id,
      :assigned_to_id,
      :quote_id,
      :material_cost,
      :material_markup_percent
    )
  end
end
