# app/jobs/uaojt_monthly_sync_job.rb
class UaojtMonthlySyncJob < ApplicationJob
  queue_as :default

  # for_month: Date or String, default = previous month
  def perform(for_month = nil)
    month = for_month ? Date.parse(for_month.to_s) : Date.current.prev_month
    month = month.beginning_of_month
    range = month..month.end_of_month
    

    User.where(is_apprentice: true).find_each do |user|
      next unless user.uaojt_enabled?
      next if user.uaojt_username.blank? || user.uaojt_password_encrypted.blank?
      hours_rep_id = user.uaojt_hours_rep_id.presence || client.current_hours_report_id(user.uaojt_user_id || user_id_from_userinfo)
      user.update!(uaojt_hours_rep_id: hours_rep_id)

      log = user.uaojt_sync_logs.build(
        month: month,
        ran_at: Time.current
      )

      begin
        client = UaojtClient.new(
          username: user.uaojt_username,
          password: user.uaojt_password_encrypted
        )

        client.login!
        info   = client.user_info
        local  = info["local"]
        craft  = info["craft"]
        added_by = info["id"]

        service_task_id = 301   # Air Conditioning Service – change if needed
        school_task_id  = 309   # DAY SCHOOL HVACR – set to your real task id
        report_id = client.current_hours_report_id(:added_by)
        service_task_payload = {
          "id"           => service_task_id,
          "name"         => "Air Conditioning Service",
          "craft_id"     => craft["id"],
          "local_id"     => local["id"],
          "non-ojt"      => 0,
          "status"       => 1,
          "local_number" => local["local_number"],
          "local"        => local,
          "craftName"    => craft["name"]
        }

        school_task_payload = {
          "id"           => school_task_id,
          "name"         => "DAY SCHOOL HVACR",
          "craft_id"     => craft["id"],
          "local_id"     => local["id"],
          "non-ojt"      => 0,
          "status"       => 1,
          "local_number" => local["local_number"],
          "local"        => local,
          "craftName"    => craft["name"]
        }

        entries = []

        # 1) Work order time entries -> OJT hours
        time_entries = user.time_entries.where(started_at: range)
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

        # 2) School schedule -> 8h per weekday in window intersecting this month
        if user.uaojt_school_start && user.uaojt_school_end
          (user.uaojt_school_start..user.uaojt_school_end).each do |date|
            next unless date.between?(range.begin, range.end)
            next if date.saturday? || date.sunday?

            entries << {
              date:         date,
              hours:        8.0,
              note:         "Day school HVACR (auto-filled)",
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
            hours_rep_id: user.uaojt_hours_rep_id,
            entries:      entries
          )
          log.success = true
          log.message = "Synced #{entries.size} day(s) for #{month.strftime('%B %Y')}."
        end
      rescue => e
        log.success = false
        log.message = "Error: #{e.class} - #{e.message}"
      ensure
        log.save!
        UaojtMailer.monthly_sync_result(user, month, log).deliver_later
      end
    end
  end
end
