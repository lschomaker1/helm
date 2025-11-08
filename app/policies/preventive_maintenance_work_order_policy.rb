# app/policies/preventive_maintenance_work_order_policy.rb
class PreventiveMaintenanceWorkOrderPolicy < ApplicationPolicy
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

  def create?
    return false unless user.present?
    same_division? && (admin_or_manager? || dispatcher?)
  end

  def new?
    create?
  end

  def update?
    return false unless user.present?
    return false unless same_division?

    admin_or_manager? ||
      dispatcher? ||
      technician_assigned?
  end

  def edit?
    update?
  end

  def destroy?
    return false unless user.present?
    same_division? && admin?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.admin?
        scope.all
      elsif user.respond_to?(:division_id)
        scope.where(division_id: user.division_id)
      else
        scope.none
      end
    end
  end

  private

  def technician_assigned?
    technician? && record.respond_to?(:assigned_to_id) &&
      record.assigned_to_id == user.id
  end

  def created_by_user?
    record.respond_to?(:created_by_id) &&
      record.created_by_id == user.id
  end
end
