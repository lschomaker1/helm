class TechReferenceController < ApplicationController
  before_action :authenticate_user!

  def index
    @query = params[:q].to_s.strip

    base = User.all
    if @query.present?
      base = base.where(
        "users.email ILIKE :q OR users.name ILIKE :q OR users.full_name ILIKE :q OR users.phone ILIKE :q",
        q: "%#{@query}%"
      )
    end

    @technicians = base.where(role: :technician)
    @managers    = base.where(role: :manager)
    @dispatchers = base.where(role: :dispatcher)
  end
end
