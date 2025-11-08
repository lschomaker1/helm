# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user   = user
    @record = record
  end

  # By default, logged-in users can at least hit index, and scopes do the filtering.
  def index?
    user.present?
  end

  def show?
    scope.where(id: record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  # ---- Role helpers --------------------------------------------------------

  def admin?
    user&.role == "admin"
  end

  def manager?
    user&.role == "manager"
  end

  def dispatcher?
    user&.role == "dispatcher"
  end

  def technician?
    user&.role == "technician"
  end

  def admin_or_manager?
    admin? || manager?
  end

  # ---- Division helper -----------------------------------------------------

  # Compare division for any record that has division or division_id.
  def same_division?(record_to_check = record)
    rec_division_id =
      if record_to_check.respond_to?(:division_id)
        record_to_check.division_id
      elsif record_to_check.respond_to?(:division) && record_to_check.division
        record_to_check.division.id
      end

    user_division_id =
      if user.respond_to?(:division_id)
        user.division_id
      elsif user.respond_to?(:division) && user.division
        user.division.id
      end

    rec_division_id.present? &&
      user_division_id.present? &&
      rec_division_id == user_division_id
  end

  # Pundit helper so `show?` can call `scope`
  def scope
    Pundit.policy_scope!(user, record.class)
  end

  # ---- Scope base class ----------------------------------------------------

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
