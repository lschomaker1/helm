class SearchController < ApplicationController
  before_action :authenticate_user!

  def index
    @query = params[:q].to_s.strip
    @sort  = params[:sort].presence || "recent_calls"

    if @query.present?
      @customers       = customer_results
      @work_orders     = work_order_results
      @purchase_orders = purchase_order_results
    else
      @customers       = Customer.none
      @work_orders     = WorkOrder.none
      @purchase_orders = PurchaseOrder.none
    end
  end

  private

  def like_operator
    # Use :ILIKE for Postgres, :LIKE for SQLite/MySQL if needed
    @like_operator ||= ActiveRecord::Base.connection.adapter_name == "PostgreSQL" ? "ILIKE" : "LIKE"
  end

  def customer_results
    scope = Customer.left_outer_joins(:work_orders)
                    .where(
                      "customers.name #{like_operator} :q OR "\
                      "customers.email #{like_operator} :q OR "\
                      "customers.contact_name #{like_operator} :q OR "\
                      "customers.phone #{like_operator} :q OR "\
                      "customers.address #{like_operator} :q",
                      q: "%#{@query}%"
                    )
                    .group("customers.id")

    case @sort
    when "recent_calls"
      scope.order(Arel.sql("MAX(work_orders.created_at) DESC NULLS LAST"))
    when "most_calls"
      scope.order(Arel.sql("COUNT(work_orders.id) DESC"))
    else
      scope.order(:name)
    end
  end

  def work_order_results
    WorkOrder.includes(:customer)
             .where(
               "CAST(work_orders.id AS TEXT) #{like_operator} :q OR "\
               "work_orders.description #{like_operator} :q",
               q: "%#{@query}%"
             )
             .order(created_at: :desc)
  end

  def purchase_order_results
    PurchaseOrder.includes(:work_order)
                 .where("purchase_orders.number #{like_operator} :q", q: "%#{@query}%")
                 .order(created_at: :desc)
  end
end
