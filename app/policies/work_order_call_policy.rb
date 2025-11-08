class WorkOrderCallPolicy < ApplicationPolicy
  def show?
    return false unless user.present?
    return false unless same_division?(record.work_order)

    # Admins/managers/dispatchers can see all; tech only if assigned
    admin_or_manager? || dispatcher? || technician_assigned?
  end

  def new?
    create?
  end

  def create?
    return false unless user.present?
    same_division?(record.work_order) && (admin_or_manager? || dispatcher?)
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.admin? || user.manager? || user.dispatcher?
        scope.joins(:work_order).where(work_orders: { division_id: user.division_id })
      elsif user.technician?
        scope.joins(:work_order)
             .where(work_order_calls: { technician_id: user.id },
                    work_orders: { division_id: user.division_id })
      else
        scope.none
      end
    end
  end

  private

  def technician_assigned?
    technician? && record.technician_id == user.id
  end
end
