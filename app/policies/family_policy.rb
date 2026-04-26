# frozen_string_literal: true

class FamilyPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    authenticated?
  end

  def create?
    admin_user?
  end

  def new?
    create?
  end

  def update?
    admin_user?
  end

  def edit?
    update?
  end

  def destroy?
    admin_user?
  end

  def assign_tags?
    admin_user?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end

end
