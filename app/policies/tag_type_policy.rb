# frozen_string_literal: true

class TagTypePolicy < ApplicationPolicy
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

  def show?
    authenticated?
  end

  def destroy?
    admin_user?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end

end
