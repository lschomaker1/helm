class TimeEntryPolicy < ApplicationPolicy
  # List of entries – filtered by Scope
  def index?
    user.present?
  end

  # Techs: their own entries
  # Managers/Admins/Dispatchers: any in their division
  def show?
    return false unless user.present?

    owns_entry? ||
      (same_division? && (admin_or_manager? || dispatcher?))
  end

  def new?
    create?
  end

  def batch_new?
    batch_create?
  end

  # CREATE:
  #   - technician: can log their own time on WOs in their division
  #   - manager/dispatcher/admin: any user on WOs in their division
  def create?
    return false unless user.present?

    if technician?
      owns_entry? && same_division?
    else
      same_division?
    end
  end

  def batch_create?
    return false unless user.present?

    if technician?
      owns_entry? && same_division?
    else
      same_division?
    end
  end

  def edit?
    update?
  end

  def update?
    return false unless user.present?

    if technician?
      owns_entry? && same_division?
    else
      same_division?
    end
  end

  def destroy?
    return false unless user.present?

    if technician?
      owns_entry? && same_division?
    else
      same_division?
    end
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.admin? || user.manager? || user.dispatcher?
        scope.joins(:work_order)
             .where(work_orders: { division_id: user.division_id })
      elsif user.technician?
        scope.where(user_id: user.id)
      else
        scope.none
      end
    end
  end

  private

  def owns_entry?
    record.respond_to?(:user_id) && record.user_id == user.id
  end

  # For time entries, we consider the division of the associated work order
  def same_division?(record_to_check = record)
    if record_to_check.respond_to?(:work_order) && record_to_check.work_order
      super(record_to_check.work_order)
    else
      super
    end
  end
end
