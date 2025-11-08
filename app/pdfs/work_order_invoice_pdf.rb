require "prawn/table"

class WorkOrderInvoicePdf < Prawn::Document
  def initialize(work_order)
    super(page_size: "LETTER", margin: 36)
    @work_order = work_order
    font_families.update("Helvetica" => {
      normal: "Helvetica",
      bold:   "Helvetica-Bold"
    })
    font "Helvetica"

    header
    move_down 20
    customer_and_job_info
    move_down 20
    labor_table
    move_down 20
    material_section
    move_down 20
    totals_section
    move_down 30
    footer
  end

  private

  def header
    logo = logo_path
    if File.exist?(logo)
      image logo, at: [bounds.left, cursor], width: 100
    end

    bounding_box([bounds.right - 250, cursor - 10], width: 250) do
      text "Helm Service Invoice", size: 20, style: :bold, align: :right
      move_down 5
      text "Invoice ##{@work_order.invoice_number || 'TBD'}", size: 12, align: :right
      text "Date: #{Date.current.strftime('%Y-%m-%d')}", size: 11, align: :right
    end
  end

  def customer_and_job_info
    data_left = [
      ["Bill To:", @work_order.customer&.name.to_s],
      ["Address:", @work_order.customer&.address.to_s],
      ["City/State:", [@work_order.customer&.city, @work_order.customer&.state].compact.join(", ")],
      ["Phone:", @work_order.customer&.phone.to_s],
      ["Email:", @work_order.customer&.email.to_s]
    ]

    data_right = [
      ["Work Order #:", @work_order.number],
      ["Status:", @work_order.status.to_s.titleize],
      ["Completed At:", @work_order.completed_at&.strftime("%Y-%m-%d %H:%M") || "—"],
      ["Location:", @work_order.location.to_s],
      ["Division:", @work_order.division&.name.to_s]
    ]

    bounding_box([bounds.left, cursor], width: bounds.width / 2 - 10) do
      table(data_left, cell_style: { borders: [], padding: [2, 2, 2, 0], size: 10 }) do
        columns(0).font_style = :bold
      end
    end

    bounding_box([bounds.left + bounds.width / 2 + 10, cursor + 60], width: bounds.width / 2 - 10) do
      table(data_right, cell_style: { borders: [], padding: [2, 2, 2, 0], size: 10 }) do
        columns(0).font_style = :bold
      end
    end
  end

  def labor_table
    hours_by_type = @work_order.hours_by_rate_type
    return if hours_by_type.empty?

    text "Labor", size: 14, style: :bold
    move_down 5

    header = ["Type", "Hours", "Rate", "Amount"]
    rows = hours_by_type.map do |rate_type, hours|
      rate  = WorkOrder::LABOR_RATES[rate_type] || 0
      total = rate.to_d * hours.to_d
      [label_for_rate_type(rate_type), format_hours(hours), money(rate), money(total)]
    end

    table([header] + rows, header: true, width: bounds.width) do
      row(0).font_style = :bold
      row(0).background_color = "eeeeee"
      columns(1..3).align = :right
      self.row_colors = %w[ffffff f8f8f8]
      self.cell_style = { size: 10, padding: [4, 4, 4, 4] }
    end
  end

  def material_section
    text "Materials", size: 14, style: :bold
    move_down 5

    base   = (@work_order.material_cost || 0).to_d
    markup = (@work_order.material_markup_percent || 0).to_d
    total  = @work_order.material_total

    table(
      [
        ["Base Cost:", money(base)],
        ["Markup (%):", "#{markup.to_s}%"],
        ["Material Total:", money(total)]
      ],
      cell_style: { borders: [], padding: [2, 2, 2, 0], size: 10 }
    ) do
      columns(0).font_style = :bold
      columns(1).align = :right
    end
  end

  def totals_section
    text "Totals", size: 14, style: :bold
    move_down 5

    labor   = @work_order.labor_total
    mat_tot = @work_order.material_total
    subtotal = @work_order.invoice_subtotal

    rows = []
    if @work_order.quote&.total_amount.present?
      rows << ["Per Quote ##{@work_order.quote.number}", money(@work_order.quote.total_amount)]
    else
      rows << ["Labor Total", money(labor)]
      rows << ["Material Total", money(mat_tot)]
    end

    rows << ["Invoice Total", money(subtotal)]

    table rows, cell_style: { borders: [], padding: [2, 2, 2, 0], size: 11 } do
      columns(0).font_style = :bold
      columns(1).align = :right
      row(-1).font_style = :bold
    end
  end

  def footer
    move_down 10
    stroke_horizontal_rule
    move_down 5
    text "Thank you for your business.", size: 10, align: :center
    move_down 2
    text "Helm | Service Division", size: 9, align: :center
  end

  def label_for_rate_type(rate_type)
    case rate_type
    when "regular"     then "Regular Time"
    when "overtime"    then "Overtime"
    when "double_time" then "Double Time"
    else rate_type.to_s.titleize
    end
  end

  def format_hours(hours)
    format("%.2f", hours.to_f)
  end

  def money(amount)
    "$#{format('%.2f', amount.to_f)}"
  end

  def logo_path
    Rails.root.join("app/assets/images/helm_logo.png")
  end
end
