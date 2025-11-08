class WorkOrder < ApplicationRecord
  belongs_to :customer
  belongs_to :division
  belongs_to :assigned_to, class_name: "User", optional: true
  belongs_to :created_by,  class_name: "User", optional: true
  belongs_to :quote,       optional: true

  has_many :time_entries, dependent: :destroy
  has_many :work_order_calls, dependent: :destroy
  has_many :assigned_technicians, through: :work_order_calls, source: :technician


  STATUSES   = %w[open in_progress completed canceled].freeze
  PRIORITIES = %w[urgent high normal low].freeze

  # Labor rates in dollars per hour
  LABOR_RATES = {
    "regular"     => 125.0,
    "overtime"    => 187.50,
    "double_time" => 250.0
  }.freeze

  before_validation :assign_number, on: :create
  before_validation :set_defaults,  on: :create

  validates :number, presence: true, uniqueness: true

  # Prevent number from changing once created
  attr_readonly :number

  # --- Invoice helpers -------------------------------------------------------

  # Group hours by rate_type: { "regular" => 4.5, "overtime" => 2.0, ... }
  def hours_by_rate_type
    time_entries.group(:rate_type).sum(:hours)
  end

  def labor_total
    hours_by_rate_type.sum do |rate_type, hours|
      rate = LABOR_RATES[rate_type] || 0
      rate.to_d * hours.to_d
    end
  end

  def material_total
    base   = (material_cost || 0).to_d
    markup = (material_markup_percent || 0).to_d
    base * (1 + markup / 100)
  end

  # If associated with a quote, invoice from quote total;
  # otherwise use labor + material.
  def invoice_subtotal
    if quote&.total_amount.present?
      quote.total_amount.to_d
    else
      labor_total + material_total
    end
  end

  def ensure_invoice_number
    return if invoice_number.present?

    prefix = division&.name&.slice(0, 3)&.upcase || "INV"
    self.invoice_number ||= "#{prefix}-#{Time.current.strftime('%Y%m%d')}-#{id || 'NEW'}"
  end

  # Recalculate totals and assign invoice_number; persists changes.
  def finalize_invoice_totals!
    ensure_invoice_number
    self.invoice_total = invoice_subtotal
    save!
  end

  private

  def set_defaults
    self.status   ||= "open"
    self.priority ||= "normal"
    self.material_cost ||= 0
    self.material_markup_percent ||= 25
  end

  def assign_number
    # Don't override if somehow already set
    return if number.present?

    # Prefix based on division name (e.g. "FRE", "OMA", "LEN")
    prefix =
      if division&.name.present?
        division.name[0, 3].to_s.upcase
      else
        "WO"
      end

    # Generate unique code like FRE189203 (prefix + 6 digits)
    loop do
      candidate = "#{prefix}#{format('%06d', rand(0..999_999))}"
      unless self.class.exists?(number: candidate)
        self.number = candidate
        break
      end
    end
  end
end
