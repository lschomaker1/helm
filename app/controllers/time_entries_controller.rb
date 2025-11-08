# app/controllers/time_entries_controller.rb
class TimeEntriesController < ApplicationController
  before_action :set_time_entry, only: [:show, :edit, :update, :destroy]

  # GET /time_entries
  def index
    @time_entries = policy_scope(TimeEntry)
                      .includes(:user, :work_order)
                      .order(started_at: :desc)
  end

  # GET /time_entries/:id
  def show
    authorize @time_entry
  end

  # GET /time_entries/new
  # Optional: ?work_order_id=123 when coming from a WO page
  def new
    @time_entry = TimeEntry.new

    if params[:work_order_id].present?
      @time_entry.work_order = WorkOrder.find(params[:work_order_id])
    end

    @time_entry.user ||= current_user
    authorize @time_entry

    load_form_collections
  end

  # POST /time_entries
  def create
    @time_entry = TimeEntry.new(time_entry_params)

    # Techs can only log their own time
    if current_user.technician?
      @time_entry.user = current_user
    elsif @time_entry.user.nil?
      @time_entry.user = current_user
    end

    authorize @time_entry

    if @time_entry.save
      redirect_to(@time_entry.work_order || @time_entry,
                  notice: "Time entry logged.")
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  # GET /time_entries/:id/edit
  def edit
    authorize @time_entry
    load_form_collections
  end

  # PATCH/PUT /time_entries/:id
  def update
    authorize @time_entry

    # Techs cannot change the user
    if current_user.technician?
      @time_entry.assign_attributes(time_entry_params.except(:user_id))
      @time_entry.user = current_user
    else
      @time_entry.assign_attributes(time_entry_params)
    end

    if @time_entry.save
      redirect_to(@time_entry.work_order || @time_entry,
                  notice: "Time entry updated.")
    else
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /time_entries/:id
  def destroy
    authorize @time_entry
    work_order = @time_entry.work_order
    @time_entry.destroy

    redirect_to(work_order || time_entries_path,
                notice: "Time entry deleted.")
  end

  def batch_new
    @work_order = WorkOrder.find(params[:work_order_id])
    authorize TimeEntry.new(user: current_user, work_order: @work_order)

    @start_date = params[:start_date].presence&.to_date || Date.today
    @end_date   = params[:end_date].presence&.to_date   || @start_date
    @dates      = (@start_date..@end_date).to_a
  end

  # POST /work_orders/:work_order_id/time_entries/batch_create
  def batch_create
    @work_order = WorkOrder.find(params[:work_order_id])
    authorize TimeEntry.new(user: current_user, work_order: @work_order)

    @start_date = params[:start_date].to_date
    @end_date   = params[:end_date].to_date
    @dates      = (@start_date..@end_date).to_a

    errors = []

    ActiveRecord::Base.transaction do
      @dates.each do |date|
        hours_str = params.dig(:hours, date.to_s)
        next if hours_str.blank?

        te = TimeEntry.new(
          work_order: @work_order,
          user:       current_user,
          started_at: date,             # we only care about the date
          hours:      hours_str.to_f
        )

        unless te.save
          errors << "#{date}: #{te.errors.full_messages.to_sentence}"
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      flash.now[:alert] = "Could not save all entries: #{errors.join(', ')}"
      render :batch_new, status: :unprocessable_entity
    else
      redirect_to @work_order, notice: "Time entries saved."
    end
  end


  private

  def set_time_entry
    @time_entry = TimeEntry.find(params[:id])
  end


  def load_form_collections
    @users = User.where(division: @current_division)
    @work_orders = policy_scope(WorkOrder)
  end

  # Strong params
  def time_entry_params
    params.require(:time_entry).permit(
      :user_id,
      :work_order_id,
      :started_at,
      :ended_at,
      :hours,
      :rate_type,
      :notes
    )
  end

end
