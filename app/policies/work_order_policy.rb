class WorkOrderPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false unless user.present?
    return false unless same_division?

    admin_or_manager? ||
      dispatcher? ||
      technician_assigned? ||
      created_by_user?
  end

  def new?
    create?
  end

  def create?
    return false unless user.present?
    same_division? && (admin_or_manager? || dispatcher?)
  end

  def edit?
    update?
  end

  def update?
    return false unless user.present?
    return false unless same_division?

    if admin_or_manager? || dispatcher?
      true
    elsif technician?
      technician_assigned?
    else
      false
    end
  end

  def destroy?
    return false unless user.present?
    return false unless same_division?

    admin_or_manager?
  end

  # Complete uses the same rules as update
  def complete?
    update?
  end

  # Anyone allowed to view can see invoice
  def invoice?
    show?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      base = scope.where(division_id: user.division_id)

      if user.admin? || user.manager? || user.dispatcher?
        base
      elsif user.technician?
        base.where(assigned_to_id: user.id)
      else
        scope.none
      end
    end
  end

  private

  def technician_assigned?
    technician? &&
      record.respond_to?(:assigned_to_id) &&
      record.assigned_to_id == user.id
  end

  def created_by_user?
    record.respond_to?(:created_by_id) &&
      record.created_by_id == user.id
  end
end
