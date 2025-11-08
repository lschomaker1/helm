# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin?
  end

  def new?
    create?
  end

  def create?
    admin?
  end

  def edit?
    update?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.role == "admin"

      scope.none
    end
  end
end
