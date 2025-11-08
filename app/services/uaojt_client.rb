# app/services/uaojt_client.rb
require "net/http"
require "uri"
require "json"
require "cgi"

class UaojtClient
  BASE = URI("https://uaojt.com")

  def initialize(username:, password:)
    @username   = username
    @password   = password
    @cookies    = {}     # { "name" => "value" }
    @csrf_token = nil    # last known CSRF token (raw)
  end

  # --------------------------------------------------------------------------
  # PUBLIC API
  # --------------------------------------------------------------------------

  # Log into the apprentice portal.
  def login!
    fetch_csrf_token_for_login!

    headers = { "x-csrf-token" => @csrf_token }

    body = {
      username: @username,
      password: @password
    }.to_json

    resp = post("/login_post", body, headers)

    unless resp.is_a?(Net::HTTPSuccess)
      raise "UAOJT login failed: HTTP #{resp.code} #{resp.body[0, 300]}"
    end

    @csrf_token ||= @cookies["XSRF-TOKEN"]
    true
  end

  # Single-day submit (still available, but we’ll mostly use bulk)
  def submit_hours!(
    hours_rep_id:,
    task_id:,
    date:,
    hours:,
    note: "",
    added_by:,
    task_payload: nil
  )
    submit_hours_bulk!(
      hours_rep_id: hours_rep_id,
      entries: [
        {
          date:         date,
          hours:        hours,
          note:         note,
          task_id:      task_id,
          task_payload: task_payload,
          added_by:     added_by
        }
      ]
    )
  end

  # Bulk submit: sends ALL days in one payload so the API doesn’t “move” rows.
  #
  # entries: array of hashes:
  #   {
  #     date: Date/Time/String,
  #     hours: Numeric,
  #     note: String,
  #     task_id: Integer,
  #     task_payload: Hash (task object),
  #     added_by: Integer
  #   }
  #
  def submit_hours_bulk!(hours_rep_id:, entries:)
    refresh_csrf_token_for_api!

    csrf = @cookies["XSRF-TOKEN"] || @csrf_token
    raise "No CSRF token available when submitting hours (bulk)" if csrf.nil?

    hours_array = entries.map do |e|
      date = e[:date]
      date_str =
        if date.is_a?(Date) || date.is_a?(Time)
          date.strftime("%Y-%m-%d")
        else
          date.to_s
        end

      {
        "id"           => 0,
        "hours_rep_id" => hours_rep_id,
        "task_id"      => e[:task_id],
        "task"         => e[:task_payload],
        "added_by"     => e[:added_by],
        "hours"        => e[:hours],
        "day_done"     => date_str,
        "note"         => e[:note].to_s
      }
    end

    payload = {
      "hours_array" => hours_array,
      "badreport"   => 0
    }

    path = "/api/hourreport/hours_log_store/#{hours_rep_id}"
    resp = post(path, payload.to_json, "x-csrf-token" => csrf)

    unless resp.is_a?(Net::HTTPSuccess)
      raise "UAOJT hours bulk submit failed: HTTP #{resp.code} #{resp.body[0, 300]}"
    end

    true
  end

  # Fetch per-user info from /api/user/userinfo.
  def user_info
    refresh_csrf_token_for_api! if @csrf_token.nil?

    csrf = @cookies["XSRF-TOKEN"] || @csrf_token
    raise "No CSRF token available for user_info" if csrf.nil?

    uri = BASE + "/api/user/userinfo"
    req = Net::HTTP::Get.new(uri)
    attach_common_headers(req, html: false)
    req["x-csrf-token"] = csrf

    resp = do_request(uri, req)

    unless resp.is_a?(Net::HTTPSuccess)
      raise "UAOJT userinfo failed: HTTP #{resp.code} #{resp.body[0, 300]}"
    end

    data = JSON.parse(resp.body)
    unless data["success"]
      raise "UAOJT userinfo returned success=false: #{resp.body[0, 300]}"
    end

    data["message"]
  end

  # Debug helpers
  def debug_cookies
    @cookies.dup
  end

  def debug_csrf
    @csrf_token
  end

  def current_hours_report_id(user_id)
    refresh_csrf_token_for_api!

    csrf = @cookies["XSRF-TOKEN"] || @csrf_token
    raise "No CSRF token available for current_hours_report_id" if csrf.nil?

    uri = BASE + "/api/hourreports?page=1&perPage=9007199254740991&order_direction=desc&user_id=#{user_id}&watch=0"

    req = Net::HTTP::Get.new(uri)
    attach_common_headers(req, html: false)
    req["x-csrf-token"] = csrf

    resp = do_request(uri, req)
    unless resp.is_a?(Net::HTTPSuccess)
      raise "UAOJT current_hours_report_id failed: HTTP #{resp.code} #{resp.body[0, 300]}"
    end

    data = JSON.parse(resp.body)

    # Assuming response looks like: { "success": true, "message": [ { "id": 49995, ... } ] }
    reports = data["message"] || []
    latest = reports.first
    report_id = latest["id"] || latest["hours_rep_id"]

    raise "Could not find hours_rep_id in response" if report_id.blank?

    report_id
  end

  # --------------------------------------------------------------------------
  # PRIVATE
  # --------------------------------------------------------------------------
  private

  def get(path)
    uri = BASE + path
    req = Net::HTTP::Get.new(uri)
    attach_common_headers(req, html: true)
    do_request(uri, req)
  end

  def get_json(path)
    uri = BASE + path
    req = Net::HTTP::Get.new(uri)
    attach_common_headers(req, html: false)
    do_request(uri, req)
  end

  def post(path, body, extra_headers = {})
    uri = BASE + path
    req = Net::HTTP::Post.new(uri)
    attach_common_headers(req, html: false)
    req["Content-Type"] = "application/json"
    extra_headers.each { |k, v| req[k] = v }
    req.body = body
    do_request(uri, req)
  end

  def attach_common_headers(req, html:)
    req["Accept-Language"] = "en-US,en;q=0.9"
    req["User-Agent"]      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " \
                             "AppleWebKit/537.36 (KHTML, like Gecko) " \
                             "Chrome/120.0.0.0 Safari/537.36"

    if html
      req["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9," \
                      "image/avif,image/webp,image/apng,*/*;q=0.8," \
                      "application/signed-exchange;v=b3;q=0.7"
    else
      req["Accept"]  = "application/json, text/plain, */*"
      req["Origin"]  = "https://uaojt.com"
      req["Referer"] = "https://uaojt.com/login"
    end

    cookie_str = @cookies.map { |k, v| "#{k}=#{v}" }.join("; ")
    req["Cookie"] = cookie_str unless cookie_str.empty?
  end

  def do_request(uri, req)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    resp = http.request(req)
    store_cookies(resp)
    resp
  end

  def store_cookies(resp)
    Array(resp.get_fields("set-cookie")).each do |cookie|
      pair = cookie.split(";", 2).first
      name, value = pair.split("=", 2)
      next if name.nil? || value.nil?
      @cookies[name] = value
    end
  end

  # Initial CSRF fetch for login
  def fetch_csrf_token_for_login!
    begin
      get("/login/")
    rescue => e
      Rails.logger.warn("UAOJT /login GET failed (continuing anyway): #{e.class} #{e.message}") if defined?(Rails)
    end

    resp  = get_json("/csrf?watch=0")
    token = resp.body.to_s.strip
    raise "CSRF endpoint /csrf?watch=0 returned empty body (login)" if token.empty?

    @csrf_token = token
    @cookies["XSRF-TOKEN"] = CGI.escape(token)

    token
  end

  # CSRF refresh for API calls after login
  def refresh_csrf_token_for_api!
    resp  = get_json("/csrf?watch=0")
    token = resp.body.to_s.strip
    raise "CSRF endpoint /csrf?watch=0 returned empty body (api)" if token.empty?

    @csrf_token = token
    @cookies["XSRF-TOKEN"] = CGI.escape(token)

    token
  end
end
