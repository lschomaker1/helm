class QuotesController < ApplicationController
  before_action :set_quote, only: %i[show edit update destroy]

  # GET /quotes
  def index
    @quotes = policy_scope(Quote).includes(:customer, :division)
  end

  # GET /quotes/:id
  def show
    authorize @quote
  end

  # GET /quotes/new
  def new
    @quote = Quote.new(
      division: @current_division,
      status:   "draft"
    )
    authorize @quote
    load_collections
  end

  # POST /quotes
  def create
    @quote = Quote.new(quote_params)
    @quote.division ||= @current_division

    authorize @quote
    load_collections

    if @quote.save
      redirect_to @quote, notice: "Quote created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /quotes/:id/edit
  def edit
    authorize @quote
    load_collections
  end

  # PATCH/PUT /quotes/:id
  def update
    authorize @quote
    load_collections

    if @quote.update(quote_params)
      redirect_to @quote, notice: "Quote updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /quotes/:id
  def destroy
    authorize @quote
    @quote.destroy
    redirect_to quotes_path, notice: "Quote deleted."
  end

  private

  def set_quote
    @quote = Quote.find(params[:id])
  end

  def load_collections
    @customers = Customer.where(division: @current_division)
    @divisions = Division.all
  end

  def quote_params
    params.require(:quote).permit(
      :number,
      :customer_id,
      :division_id,
      :total_amount,
      :status,
      :description
    )
  end
end
