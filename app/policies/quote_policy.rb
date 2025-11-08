class QuotePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false unless user.present?
    same_division?
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
    same_division? && (admin_or_manager? || dispatcher?)
  end

  def destroy?
    return false unless user.present?
    same_division? && (admin_or_manager? || dispatcher?)
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
end
