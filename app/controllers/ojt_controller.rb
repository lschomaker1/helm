class OjtController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_uaojt_enabled!

  def show
    @user = current_user
    @logs = current_user.uaojt_sync_logs.recent.limit(50)
  end

  def update
    @user = current_user

    if @user.update(ojt_params)
      flash[:notice] = "OJT settings updated."
    else
      flash[:alert]  = @user.errors.full_messages.to_sentence
    end

    redirect_to ojt_path
  end

  # POST /ojt/sync_current_month
  def sync_current_month
    @user = current_user
    month = Date.current.beginning_of_month
    range = month..month.end_of_month

    log = @user.uaojt_sync_logs.build(
      month: month,
      ran_at: Time.current
    )

  begin
    raise "OJT integration is not enabled for this user." unless @user.uaojt_enabled?
    raise "Missing UAOJT username/password." if @user.uaojt_username.blank? || @user.uaojt_password.blank?

    client = UaojtClient.new(
      username: @user.uaojt_username,
      password: @user.uaojt_password
    )

    client.login!
    info = client.user_info

    raise "UAOJT /api/user/userinfo returned nil." if info.nil?
    raise "UAOJT /api/user/userinfo returned unexpected type: #{info.class}" unless info.is_a?(Hash)

    # Defensive parsing of userinfo, with fallbacks
    # Example payload you showed:
    # {
    #   "id" => 1607,
    #   "local_id" => 1489,
    #   "local_num" => "023",
    #   "local" => { ... },
    #   "craft_id" => 2,
    #   "craft" => { ... }
    # }
    added_by = info["id"]
    raise "userinfo missing 'id'" if added_by.nil?

    local =
      info["local"] ||
      (info["local_id"] && {
        "id"           => info["local_id"],
        "local_number" => info["local_num"] || info["local_number"]
      })

    craft =
      info["craft"] ||
      (info["craft_id"] && {
        "id"   => info["craft_id"],
        "name" => info["craft_name"] || "HVACR"
      })

    raise "userinfo missing 'local' and local_id/local_num" if local.nil?
    raise "userinfo missing 'craft' and craft_id" if craft.nil?

    local_id      = local["id"]
    local_number  = local["local_number"] || info["local_num"]
    craft_id      = craft["id"]
    craft_name    = craft["name"] || info["craft_name"] || "HVACR"

    raise "local data missing id" if local_id.nil?
    raise "craft data missing id" if craft_id.nil?

    # Determine hours_rep_id
    hours_rep_id =
      if @user.uaojt_hours_rep_id.present?
        @user.uaojt_hours_rep_id
      else
        rid = client.current_hours_report_id(added_by)
        @user.update!(uaojt_hours_rep_id: rid)
        rid
      end

    # Task IDs – adjust these to the real IDs in your UAOJT instance
    service_task_id = 301   # "Air Conditioning Service"
    school_task_id  = 309   # "DAY SCHOOL HVACR"

    service_task_payload = {
      "id"           => service_task_id,
      "name"         => "Air Conditioning Service",
      "craft_id"     => craft_id,
      "local_id"     => local_id,
      "non-ojt"      => 0,
      "status"       => 1,
      "local_number" => local_number,
      "local"        => local,
      "craftName"    => craft_name
    }

    school_task_payload = {
      "id"           => school_task_id,
      "name"         => "DAY SCHOOL HVACR",
      "craft_id"     => craft_id,
      "local_id"     => local_id,
      "non-ojt"      => 0,
      "status"       => 1,
      "local_number" => local_number,
      "local"        => local,
      "craftName"    => craft_name
    }

    entries = []

    # 1) Work order time entries -> OJT hours
    time_entries = @user.time_entries.where(started_at: range)
    time_entries.group_by { |te| te.started_at.to_date }.each do |date, entries_for_day|
      total_hours = entries_for_day.sum(&:hours).to_f
      next if total_hours <= 0.0

      entries << {
        date:         date,
        hours:        total_hours,
        note:         "",
        task_id:      service_task_id,
        task_payload: service_task_payload,
        added_by:     added_by
      }
    end

    # 2) School schedule: 8h/day on weekdays within school window intersecting this month
    if @user.uaojt_school_start && @user.uaojt_school_end
      (@user.uaojt_school_start..@user.uaojt_school_end).each do |date|
        next unless date.between?(range.begin, range.end)
        next if date.saturday? || date.sunday?

        entries << {
          date:         date,
          hours:        8.0,
          note:         "Day school HVACR (manual run)",
          task_id:      school_task_id,
          task_payload: school_task_payload,
          added_by:     added_by
        }
      end
    end

    if entries.empty?
      log.success = true
      log.message = "No hours to sync for #{month.strftime('%B %Y')}."
    else
      client.submit_hours_bulk!(
        hours_rep_id: hours_rep_id,
        entries:      entries
      )

      log.success = true
      log.message = "Synced #{entries.size} day(s) for #{month.strftime('%B %Y')}."
    end
  rescue => e
    # This will catch NoMethodError and everything else
    log.success = false
    log.message = "Error during sync: #{e.class} - #{e.message}"
  ensure
    log.save!
  end

  if log.success?
    redirect_to ojt_path, notice: log.message
  else
    redirect_to ojt_path, alert: log.message
  end
end


  private

  def ensure_uaojt_enabled!
    unless current_user&.uaojt_enabled?
      flash[:alert] = "OJT integration is only available for Freeport apprentices."
      redirect_to root_path
    end
  end

  def ojt_params
    params.require(:user).permit(
      :uaojt_username,
      :uaojt_password,
      :uaojt_hours_rep_id,
      :uaojt_apprenticeship_year,
      :uaojt_school_start,
      :uaojt_school_end
    )
  end
end
